import os
import json
import time
import logging
import httpx
import mlflow.pyfunc
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client import CollectorRegistry
from starlette.responses import Response

# --------- Logging ---------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --------- ENV ---------
MLFLOW_TRACKING_URI = os.getenv(
    "MLFLOW_TRACKING_URI", "http://mlflow.application.svc.cluster.local:5000")
MODEL_NAME = os.getenv("MODEL_NAME", "iris_rf_model")
MODEL_STAGE = os.getenv("MODEL_STAGE", "Production")
DRIFT_ENABLED = os.getenv("DRIFT_ENABLED", "false").lower() == "true"
GITLAB_WEBHOOK_URL = os.getenv("GITLAB_WEBHOOK_URL", "")
GITLAB_TOKEN = os.getenv("GITLAB_TOKEN", "")

# --------- MLflow Model Load ---------
os.environ["MLFLOW_TRACKING_URI"] = MLFLOW_TRACKING_URI
MODEL_URI = f"models:/{MODEL_NAME}/{MODEL_STAGE}"
model = mlflow.pyfunc.load_model(model_uri=MODEL_URI)

# --------- Metrics ---------
registry = CollectorRegistry()
REQUESTS = Counter("inference_requests_total", "Total inference requests", [
                   "endpoint"], registry=registry)
ERRORS = Counter("inference_errors_total", "Total inference errors", [
                 "endpoint", "type"], registry=registry)
LATENCY = Histogram("inference_latency_seconds", "Inference latency seconds", [
                    "endpoint"], registry=registry)
DRIFT_DETECTED = Counter("inference_drift_detected_total",
                         "Total drift detections", registry=registry)
MODEL_INFO = Gauge("inference_model_info", "Model info as labels", [
                   "name", "stage"], registry=registry)
MODEL_INFO.labels(name=MODEL_NAME, stage=MODEL_STAGE).set(1)

# --------- Drift Detection ---------


def detect_drift(df: pd.DataFrame) -> bool:
    """
    Drift detection: перевірка діапазонів/NaN.
    Може бути замінено на Great Expectations або Alibi Detect.
    """
    if not DRIFT_ENABLED:
        return False
    if df.isna().any().any():
        logger.warning("Drift detected: NaN values found")
        print("Drift detected: NaN values in input data")
        return True
    # легкий sanity-check: велике відхилення значень
    desc = df.describe().to_dict()
    for col, stats in desc.items():
        if stats.get("std", 0) == 0:
            continue
        # якщо std >> mean — сигнал
        mean = abs(stats.get("mean", 0)) or 1e-9
        if stats.get("std", 0) / mean > 50:
            logger.warning(
                f"Drift detected: high std/mean ratio in column {col}")
            print(f"Drift detected: statistical anomaly in column {col}")
            return True
    return False


async def trigger_retrain_webhook():
    """Викликає GitLab webhook для запуску retrain пайплайну"""
    if not GITLAB_WEBHOOK_URL or not GITLAB_TOKEN:
        logger.warning("GitLab webhook URL or token not configured")
        return

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                GITLAB_WEBHOOK_URL,
                headers={"PRIVATE-TOKEN": GITLAB_TOKEN},
                json={"ref": "main", "variables": [
                    {"key": "TRIGGER", "value": "drift"}]},
                timeout=10.0
            )
            if response.status_code == 200:
                logger.info("Retrain webhook triggered successfully")
                print("Retrain webhook triggered: drift detected")
            else:
                logger.error(
                    f"Failed to trigger webhook: {response.status_code}")
    except Exception as e:
        logger.error(f"Error triggering webhook: {str(e)}")

# --------- FastAPI ---------
app = FastAPI(title="Inference API", version="1.0.0")


class PredictRequest(BaseModel):
    # очікуємо {"instances": [[...], [...]]} або {"instances": {...}} для табличних фіч
    instances: list


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL_NAME, "stage": MODEL_STAGE}


@app.get("/metrics")
def metrics():
    data = generate_latest(registry)
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)


@app.post("/predict")
async def predict(req: PredictRequest):
    REQUESTS.labels(endpoint="/predict").inc()
    start = time.time()
    try:
        # нормалізація входу до DataFrame
        X = req.instances
        if isinstance(X, dict):
            df = pd.DataFrame([X])
        else:
            # якщо масив масивів — зробимо DataFrame без колонок
            df = pd.DataFrame(X)

        # Логування вхідних даних
        logger.info(f"Input data received: {df.to_dict('records')}")
        print(f"Input data: {df.to_dict('records')}")

        drift = detect_drift(df)

        preds = model.predict(df)
        predictions_serialized = _to_serializable(preds)

        # Логування відповіді
        logger.info(
            f"Predictions: {predictions_serialized}, drift_detected: {drift}")
        print(f"Predictions: {predictions_serialized}")

        # Метрика drift
        if drift:
            DRIFT_DETECTED.inc()
            # Виклик webhook для retrain
            await trigger_retrain_webhook()

        payload = {"predictions": predictions_serialized,
                   "drift_detected": drift}
        return payload
    except HTTPException:
        ERRORS.labels(endpoint="/predict", type="http").inc()
        raise
    except Exception as e:
        ERRORS.labels(endpoint="/predict", type="exception").inc()
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        LATENCY.labels(endpoint="/predict").observe(time.time() - start)


def _to_serializable(x):
    try:
        if hasattr(x, "tolist"):
            return x.tolist()
        json.dumps(x)  # перевірка серіалізації
        return x
    except Exception:
        return str(x)
