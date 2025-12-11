# MLflow + PushGateway (ArgoCD)

Проєкт демонструє інтеграцію MLflow з Prometheus PushGateway через ArgoCD для відстеження експериментів машинного навчання.

## Структура проєкту

```
mlops-experiments/
├── argocd/
│   └── applications/
│       ├── mlflow.yaml
│       ├── minio.yaml
│       ├── postgres.yaml
│       └── pushgateway.yaml
├── experiments/
│   ├── train_and_push.py
│   └── requirements.txt
├── best_model/
│   └── .gitkeep
└── README.md
```

## Деплой через ArgoCD

### 1. Застосування застосунків

```bash
kubectl apply -n argocd -f argocd/applications/
```

### 2. Перевірка статусу

```bash
kubectl get applications -n argocd
```

Очікуваний вивід:
```
NAME         SYNC STATUS   HEALTH STATUS
mlflow       Synced        Healthy
minio        Synced        Healthy
postgres     Synced        Healthy
pushgateway  Synced        Healthy
```

Або через ArgoCD CLI:
```bash
argocd app list
```

### 3. Перевірка ресурсів у кластері

```bash
kubectl get pods,svc -n mlflow
kubectl get pods,svc -n monitoring
```

Очікувані сервіси:
- `minio` (ClusterIP) - S3-сумісне сховище для артефактів
- `postgres-postgresql` (ClusterIP) - база даних для MLflow
- `mlflow` (ClusterIP, порт 5000) - MLflow Tracking Server
- `pushgateway-prometheus-pushgateway` (ClusterIP, порт 9091) - Prometheus PushGateway

## Перевірка доступності сервісів

### MLflow UI

```bash
kubectl port-forward -n mlflow svc/mlflow 5000:5000
```

Відкрийте в браузері: http://localhost:5000

### PushGateway

PushGateway доступний у кластері за адресою:
```
http://pushgateway-prometheus-pushgateway.monitoring.svc.cluster.local:9091
```

Для локального доступу:
```bash
kubectl port-forward -n monitoring svc/pushgateway-prometheus-pushgateway 9091:9091
```

Перевірка через curl:
```bash
curl http://localhost:9091/metrics
```

## Запуск навчання та пушу метрик

### 1. Підготовка середовища

```bash
cd experiments/
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Налаштування змінних середовища (за потреби)

```bash
export MLFLOW_TRACKING_URI=http://localhost:5000
export PUSHGATEWAY_URL=http://pushgateway-prometheus-pushgateway.monitoring.svc.cluster.local:9091
```

Якщо запускаєте зсередини кластера (наприклад, з Pod), використовуйте:
```bash
export MLFLOW_TRACKING_URI=http://mlflow.mlflow.svc.cluster.local:5000
export PUSHGATEWAY_URL=http://pushgateway-prometheus-pushgateway.monitoring.svc.cluster.local:9091
```

### 3. Запуск скрипта

```bash
python train_and_push.py
```

### 4. Приклад виводу

```
2024-01-15 10:23:45,123 INFO mlflow.tracking.fluent: Experiment with name 'iris-demo' does not exist. Creating a new experiment.
run_id=abc123def456 accuracy=0.9333 loss=0.1234
run_id=def456ghi789 accuracy=0.9667 loss=0.0987
run_id=ghi789jkl012 accuracy=0.9500 loss=0.1123
Найкраща модель з run_id=def456ghi789 збережена до /path/to/mlops-experiments/best_model
Найкращий запуск: run_id=def456ghi789, accuracy=0.9667, loss=0.0987
```

Після успішного виконання модель з найкращою accuracy буде збережена у директорії `best_model/`.

## Перегляд метрик у Grafana

### 1. Відкрийте Grafana

Перейдіть в Grafana → Explore → виберіть Data source: Prometheus

### 2. Виконайте запити

**Accuracy:**
```promql
mlflow_accuracy
```

**Loss:**
```promql
mlflow_loss
```

**З фільтрацією за run_id:**
```promql
mlflow_accuracy{run_id="def456ghi789"}
```

### 3. Візуалізація

Можна створити графік або таблицю з метриками. У таблиці будуть видно:
- `run_id` - ідентифікатор запуску MLflow
- `mlflow_accuracy` - точність моделі
- `mlflow_loss` - функція втрат

## MLflow UI

Після port-forward відкрийте http://localhost:5000

У MLflow UI можна:
- Переглянути всі експерименти та запуски
- Порівняти метрики різних запусків
- Завантажити артефакти (моделі) з кожного запуску
- Переглянути параметри навчання (learning_rate, epochs)

## Перевірка метрик у PushGateway

Після запуску `train_and_push.py` метрики будуть доступні в PushGateway:

```bash
curl http://localhost:9091/metrics | grep mlflow
```

Очікуваний вивід:
```
# HELP mlflow_accuracy Model accuracy
# TYPE mlflow_accuracy gauge
mlflow_accuracy{job="mlflow-training",run_id="abc123def456"} 0.9333
mlflow_accuracy{job="mlflow-training",run_id="def456ghi789"} 0.9667
mlflow_accuracy{job="mlflow-training",run_id="ghi789jkl012"} 0.9500
# HELP mlflow_loss Model log loss
# TYPE mlflow_loss gauge
mlflow_loss{job="mlflow-training",run_id="abc123def456"} 0.1234
mlflow_loss{job="mlflow-training",run_id="def456ghi789"} 0.0987
mlflow_loss{job="mlflow-training",run_id="ghi789jkl012"} 0.1123
```

## Скриншоти

Додайте скриншоти у директорію `screenshots/`:
- `mlflow-ui.png` - інтерфейс MLflow з запусками
- `grafana-explore.png` - метрики в Grafana Explore

## Troubleshooting

### MLflow не доступний

```bash
kubectl get pods -n mlflow
kubectl logs -n mlflow deployment/mlflow
```

### PushGateway не отримує метрики

Перевірте доступність з Pod:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://pushgateway-prometheus-pushgateway.monitoring.svc.cluster.local:9091/metrics
```

### Помилки підключення до бази даних

Перевірте, чи PostgreSQL готовий:
```bash
kubectl get pods -n mlflow | grep postgres
kubectl logs -n mlflow <postgres-pod-name>
```

