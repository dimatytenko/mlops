import os
import shutil
from pathlib import Path
from typing import List, Tuple

import mlflow
from mlflow import MlflowClient
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
from sklearn.datasets import load_iris
from sklearn.linear_model import SGDClassifier
from sklearn.metrics import accuracy_score, log_loss
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler


TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
EXPERIMENT_NAME = os.getenv("MLFLOW_EXPERIMENT_NAME", "iris-demo")
PUSHGATEWAY_URL = os.getenv(
    "PUSHGATEWAY_URL", "http://pushgateway-prometheus-pushgateway.monitoring.svc.cluster.local:9091"
)


def prepare_data(test_size: float = 0.2, seed: int = 42):
    iris = load_iris()
    X_train, X_test, y_train, y_test = train_test_split(
        iris.data, iris.target, test_size=test_size, random_state=seed, stratify=iris.target
    )
    return X_train, X_test, y_train, y_test


def train_once(
    X_train, X_test, y_train, y_test, learning_rate: float, epochs: int
) -> Tuple[str, float, float]:
    mlflow.set_tracking_uri(TRACKING_URI)
    mlflow.set_experiment(EXPERIMENT_NAME)

    with mlflow.start_run(run_name=f"lr={learning_rate}-epochs={epochs}") as run:
        pipeline = make_pipeline(
            StandardScaler(),
            SGDClassifier(
                loss="log_loss",
                learning_rate="constant",
                eta0=learning_rate,
                max_iter=epochs,
                tol=1e-3,
                random_state=42,
            ),
        )

        pipeline.fit(X_train, y_train)
        y_pred = pipeline.predict(X_test)
        y_proba = pipeline.predict_proba(X_test)

        acc = accuracy_score(y_test, y_pred)
        loss = log_loss(y_test, y_proba)

        mlflow.log_params({"learning_rate": learning_rate, "epochs": epochs})
        mlflow.log_metrics({"accuracy": acc, "loss": loss})
        mlflow.sklearn.log_model(pipeline, artifact_path="model")

        push_metrics(run.info.run_id, acc, loss)

        return run.info.run_id, acc, loss


def push_metrics(run_id: str, accuracy: float, loss: float):
    registry = CollectorRegistry()
    accuracy_gauge = Gauge("mlflow_accuracy", "Model accuracy", [
                           "run_id"], registry=registry)
    loss_gauge = Gauge("mlflow_loss", "Model log loss",
                       ["run_id"], registry=registry)

    accuracy_gauge.labels(run_id=run_id).set(accuracy)
    loss_gauge.labels(run_id=run_id).set(loss)

    push_to_gateway(PUSHGATEWAY_URL, job="mlflow-training", registry=registry)


def select_best_run(runs: List[Tuple[str, float, float]]):
    return sorted(runs, key=lambda item: item[1], reverse=True)[0]


def download_best_model(run_id: str):
    project_root = Path(__file__).resolve().parents[1]
    target_dir = project_root / "best_model"
    shutil.rmtree(target_dir, ignore_errors=True)
    target_dir.mkdir(parents=True, exist_ok=True)

    client = MlflowClient(tracking_uri=TRACKING_URI)
    client.download_artifacts(
        run_id=run_id, path="model", dst_path=str(target_dir))
    print(f"Найкраща модель з run_id={run_id} збережена до {target_dir}")


def main():
    X_train, X_test, y_train, y_test = prepare_data()
    search_space = [(0.01, 50), (0.05, 100), (0.1, 150)]

    runs: List[Tuple[str, float, float]] = []
    for lr, epochs in search_space:
        run_id, acc, loss = train_once(
            X_train, X_test, y_train, y_test, lr, epochs)
        runs.append((run_id, acc, loss))
        print(f"run_id={run_id} accuracy={acc:.4f} loss={loss:.4f}")

    best_run_id, best_acc, best_loss = select_best_run(runs)
    download_best_model(best_run_id)
    print(
        f"Найкращий запуск: run_id={best_run_id}, accuracy={best_acc:.4f}, loss={best_loss:.4f}")


if __name__ == "__main__":
    main()
