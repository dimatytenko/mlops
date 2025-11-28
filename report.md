# Report: Comparison of Docker images (Lesson 3)

## General information
- Model: **MobileNetV2 (TorchScript)**  
- Frameworks: PyTorch, Torchvision, Pillow
- Storage format: `model.pt`

---

## Comparison of images

| Criterion              | Fat image (`lesson3-fat`) | Slim image (`lesson3-slim`) |
|------------------------|---------------------------|-----------------------------|
| Image size          | 1.05GB                    | 769MB                       |
| Number of layers        | 16                        | 17                          |
| Base image          | `ubuntu:22.04`            |`python:3.10-slim` (multi-stage) |
| Tools inside | `apt`, `build-essential`, `git`, `curl`, dev-headers | only Python runtime + necessary packages |
| Model                 | ✔                        | ✔                           |
| Inference script       | ✔                        | ✔                           |

---

## Analysis

- **Fat image**:
  - Large size (>1 GB)
  - Has many unnecessary tools (compilers, dev-tools, apt-cache)
  - Easier to debug, because all tools are available

- **Slim image**:
  - Much smaller size
  - Multi-stage build → no unnecessary tools
  - Minimal environment (only Python runtime + libraries)

---

## Recommendations for further optimization

1. Use **quantization** (int8) for the model → smaller `model.pt` file.
2. Remove `torchvision` dependencies, keeping minimal preprocessing implementation.
3. Clean cache and `__pycache__` during build:
   ```dockerfile
   RUN find /usr/local/lib/python3.10/site-packages -name '__pycache__' -type d -exec rm -rf {} +
