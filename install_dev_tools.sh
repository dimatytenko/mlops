#!/usr/bin/env bash
set -euo pipefail

# =========================
# Helpers
# =========================
log()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m $*" >&2; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# =========================
# Detect OS
# =========================
OS="$(uname -s)"
IS_MAC=false
IS_LINUX=false
case "$OS" in
  Darwin) IS_MAC=true ;;
  Linux)  IS_LINUX=true ;;
  *) err "Unsupported OS: $OS"; exit 1 ;;
esac

# =========================
# Bootstrap package manager
# =========================
if $IS_MAC; then
  if ! cmd_exists brew; then
    warn "Homebrew не знайдено. Встановлюю Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # add to current session
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile || true
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
      echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile || true
    fi
  else
    # update brew is not necessary; skip for speed
    true
  fi
fi

if $IS_LINUX; then
  if ! cmd_exists apt-get; then
    err "Need apt-get (Ubuntu/Debian)."; exit 1
  fi
  sudo apt-get update -y
fi

# =========================
# Docker + Docker Compose
# =========================
install_docker_mac() {
  if ! cmd_exists docker; then
    log "Встановлюю Docker Desktop (brew cask)..."
    brew install --cask docker
    warn "Відкрийте Applications → Docker і дозвольте необхідні права."
  else
    ok "Docker вже встановлено: $(docker --version 2>/dev/null || echo 'unknown')"
  fi

  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose v2 доступний (docker compose)."
  elif cmd_exists docker-compose; then
    ok "Знайдено legacy docker-compose."
  else
    log "Встановлюю docker-compose (fallback)..."
    brew install docker-compose || warn "Не вдалося встановити docker-compose через brew."
  fi
}

install_docker_linux() {
  if ! cmd_exists docker; then
    log "Встановлюю Docker (Ubuntu/Debian)..."
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker
  fi
  ok "Docker: $(docker --version 2>/dev/null || echo 'unknown')"

  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose v2 (plugin) доступний."
  elif cmd_exists docker-compose; then
    ok "Знайдено legacy docker-compose."
  else
    log "Встановлюю docker-compose плагін..."
    sudo apt-get install -y docker-compose-plugin || sudo apt-get install -y docker-compose
  fi

  # Add to docker group (not necessary for macOS)
  if getent group docker >/dev/null 2>&1 && ! id -nG "$USER" | grep -q "\bdocker\b"; then
    log "Додаю $USER до групи docker..."
    sudo usermod -aG docker "$USER" || true
  fi
}

log "=== Крок 1: Docker & Compose ==="
if $IS_MAC; then install_docker_mac; else install_docker_linux; fi

# =========================
# Python (>=3.9) + pip
# =========================
PY_BIN="python3"
py_version() { "$PY_BIN" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null || echo "0.0.0"; }
py_ge_39() { "$PY_BIN" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,9) else 1)'; }

log "=== Крок 2: Python (>=3.9) ==="
if cmd_exists "$PY_BIN" && py_ge_39; then
  ok "Знайдено $PY_BIN версія $(py_version)"
else
  warn "Потрібен Python ≥ 3.9 (зараз: $(py_version))"
  if $IS_MAC; then
    log "Встановлюю Python через Homebrew..."
    brew install python
    # On macOS brew usually installs python3 and pip3
  else
    log "Встановлюю Python через apt..."
    sudo apt-get install -y python3 python3-pip
  fi
  ok "Python встановлено: $($PY_BIN --version 2>/dev/null || echo 'unknown')"
fi

log "=== Крок 3: pip ==="
if "$PY_BIN" -m pip --version >/dev/null 2>&1; then
  ok "pip вже на місці."
else
  if $IS_MAC; then
    warn "pip відсутній — спробую через ensurepip..."
    "$PY_BIN" -m ensurepip --upgrade || brew reinstall python
  else
    sudo apt-get install -y python3-pip
  fi
fi
"$PY_BIN" -m pip install --upgrade pip >/dev/null 2>&1 && ok "pip оновлено."

# =========================
# Python packages check/install
# =========================
log "=== Крок 4: Пакети: Django, torch, torchvision, Pillow ==="

have_module() {
  local mod_name="$1"
  "$PY_BIN" - <<'PY' "$mod_name" >/dev/null 2>&1
import importlib, sys
mod = sys.argv[1]
sys.exit(0 if importlib.util.find_spec(mod) else 1)
PY
}

ensure_pkg() {
  local mod_name="$1"        # module name for import
  local pip_name="${2:-$1}"  # package name in pip
  if have_module "$mod_name"; then
    ok "Python package '$pip_name' already installed."
  else
    log "Installing '$pip_name'..."
    "$PY_BIN" -m pip install -U "$pip_name"
    ok "'$pip_name' installed."
  fi
}

# Django
ensure_pkg "django" "Django"
# Pillow
ensure_pkg "PIL" "Pillow"

# Torch/vision:
# On macOS + Apple Silicon you will get MPS (Metal) from official PyPI wheels.
# On Linux — CPU wheels from PyPI by default.
ensure_pkg "torch" "torch"
ensure_pkg "torchvision" "torchvision"

# =========================
# Summary
# =========================
log "=== Summary of versions ==="
( docker --version 2>/dev/null || true )
( docker compose version 2>/dev/null || docker-compose --version 2>/dev/null || true )
"$PY_BIN" --version
"$PY_BIN" - <<'PY'
import importlib, sys
mods = ["django","PIL","torch","torchvision"]
for m in mods:
    try:
        mod = importlib.import_module(m)
        ver = getattr(mod, "__version__", "unknown")
        print(f"{m}: {ver}")
    except Exception as e:
        print(f"{m}: NOT INSTALLED ({e})")
PY

ok "Done. On macOS open Docker Desktop manually (first run). On Linux after adding to docker group — log out or run 'newgrp docker'."
