# AIOps Quality Project

Повноцінний MLOps/AIOps-проєкт для продакшн-розгортання ML-моделей за допомогою MLflow Model Registry, FastAPI, Kubernetes, Helm, ArgoCD, Prometheus, Grafana, Loki та GitLab CI.

---

## Мета проєкту

Створити end‑to‑end інфраструктуру для життєвого циклу ML‑моделей:
- навчання та реєстрація моделей у **MLflow Model Registry**;
- деплой у кластер Kubernetes як REST‑сервіс (**FastAPI**) через **Helm + ArgoCD**;
- збір метрик (**Prometheus + Grafana**) і логів (**Loki + Promtail**);
- виявлення дрейфу даних (**Great Expectations / Alibi Detect**);
- автоматичний retrain через **GitLab CI/CD** у разі дрейфу або деградації якості.

---

## Структура проєкту

```
mlops/
├── app/
│  └── main.py                   # FastAPI‑сервіс для інференсу
├── model/
│  └── train.py                  # Скрипт тренування та реєстрації моделі
├── helm/
│  ├── Chart.yaml
│  ├── values.yaml               # Параметри деплою
│  └── templates/                # Helm templates (Deployment, Service тощо)
├── argocd/
│  └── application.yaml          # GitOps‑деплой через ArgoCD
├── .gitlab-ci.yml               # CI/CD пайплайн для retrain та деплою
├── grafana/
│  └── dashboards.json           # Дашборд для моніторингу
├── prometheus/
│  └── additionalScrapeConfigs.yaml
├── README.md
```

---

## Основні компоненти

| Компонент | Призначення |
|------------|--------------|
| **FastAPI** | REST‑API для інференсу моделі (`/predict`, `/health`, `/metrics`) |
| **Helm** | Деплой FastAPI‑сервісу в Kubernetes |
| **ArgoCD** | GitOps‑підхід — автооновлення кластера при змінах у Git |
| **Prometheus + Grafana** | Моніторинг запитів, помилок, latency та дрейфу |
| **Loki + Promtail** | Централізований збір логів stdout із контейнерів |
| **Great Expectations / Alibi Detect** | Перевірка якості даних та виявлення дрейфу |
| **GitLab CI/CD** | Автоматичне тренування, білд образу та деплой нової моделі |

---

## Розгортання

### 1. Попередні вимоги
- Kubernetes кластер (EKS, Minikube тощо)
- ArgoCD, підключений до Git‑репозиторію
- MLflow Tracking Server (PostgreSQL + MinIO)
- Docker Registry (AWS ECR або GitLab Container Registry)
- Prometheus та Grafana налаштовані на збір метрик

### 2. Локальний запуск FastAPI

```bash
cd app
export MLFLOW_TRACKING_URI=http://localhost:5000
export MODEL_NAME=iris_rf_model
export MODEL_STAGE=Production
uvicorn main:app --reload --port 8080
```

Перевірка:
```bash
curl -X POST localhost:8080/predict \
  -H 'Content-Type: application/json' \
  -d '{"instances": [[5.1, 3.5, 1.4, 0.2]]}'
```

### 3. Збірка Docker‑образу

```bash
docker build -t inference-api .
docker tag inference-api:latest <account_id>.dkr.ecr.us-east-1.amazonaws.com/inference-api:latest
docker push <account_id>.dkr.ecr.us-east-1.amazonaws.com/inference-api:latest
```

### 4. Деплой через Helm + ArgoCD

ArgoCD автоматично підхоплює зміни у Helm‑чарті та оновлює продакшн‑сервіс.

---

## Моніторинг

### Метрики Prometheus (`/metrics`)
- `inference_requests_total` — кількість запитів
- `inference_latency_seconds` — затримка відповіді
- `inference_errors_total` — кількість помилок
- `inference_drift_detected_total` — кількість виявлених дрейфів
- `inference_model_info` — інформація про поточну модель

### Grafana
Імпортуй `grafana/dashboards.json` для створення дашборду з:
- запитами за хвилину
- latency (p95)
- помилками
- дрейф‑івентами

---

## Drift Detection

```python
def detect_drift(df):
    if df.isna().any().any():
        return True
    if df.std().mean() > df.mean().mean() * 10:
        return True
    return False
```

**Рекомендовані фреймворки:**
- **Great Expectations** — для перевірки якості даних;
- **Alibi Detect** — для онлайн‑виявлення дрейфу.

---

## CI/CD

| Етап | Job | Опис |
|------|-----|------|
| **train** | `train_model` | Тренує модель і реєструє її в MLflow |
| **build** | `build_image` | Збирає Docker‑образ і пушить у реєстр |
| **deploy** | `deploy_helm` | Оновлює Helm‑чарт → ArgoCD синхронізує кластер |

---

## Автоматичний retrain

1. Drift‑детектор фіксує відхилення у вхідних даних.  
2. Надсилає webhook у GitLab для запуску job `train_model`.  
3. Модель реєструється в **MLflow Registry** як нова версія.  
4. CI/CD білдить новий Docker‑образ і оновлює Helm‑чарт.  
5. **ArgoCD** застосовує оновлення без даунтайму.

---

## Використані технології

| Категорія | Технологія |
|------------|-------------|
| Мова | Python 3.10 |
| Framework | FastAPI |
| Оркестрація | Kubernetes |
| CI/CD | GitLab |
| GitOps | ArgoCD |
| Моніторинг | Prometheus, Grafana |
| Логування | Loki, Promtail |
| ML Lifecycle | MLflow |

---

## Результат

- Повністю автоматизований життєвий цикл ML‑моделі.
- Безпечне оновлення моделей через GitOps.
- Прозорий моніторинг метрик і логів.
- Інтегрований механізм retrain при дрейфі або погіршенні якості.