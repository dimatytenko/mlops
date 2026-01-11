import os
import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

# --------- ENV ---------
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://mlflow.application.svc.cluster.local:5000")
REGISTERED_MODEL_NAME = os.getenv("REGISTERED_MODEL_NAME", "iris_rf_model")
EXPERIMENT_NAME = os.getenv("EXPERIMENT_NAME", "iris_rf_experiment")

mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
mlflow.set_experiment(EXPERIMENT_NAME)

def main():
    X, y = load_iris(return_X_y=True)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    clf = RandomForestClassifier(n_estimators=int(os.getenv("N_ESTIMATORS", "200")),
                                 max_depth=int(os.getenv("MAX_DEPTH", "5")),
                                 random_state=42)
    with mlflow.start_run() as run:
        clf.fit(X_train, y_train)

        train_acc = clf.score(X_train, y_train)
        test_acc = clf.score(X_test, y_test)

        mlflow.log_param("n_estimators", clf.n_estimators)
        mlflow.log_param("max_depth", clf.max_depth)
        mlflow.log_metric("train_accuracy", train_acc)
        mlflow.log_metric("test_accuracy", test_acc)

        mlflow.sklearn.log_model(
            sk_model=clf,
            artifact_path="model",
            registered_model_name=REGISTERED_MODEL_NAME
        )

        print(f"✔ Registered {REGISTERED_MODEL_NAME}. Run ID: {run.info.run_id}; test_acc={test_acc:.4f}")

if __name__ == "__main__":
    main()