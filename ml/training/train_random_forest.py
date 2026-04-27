"""
EcoPulse Random Forest training pipeline.

Objetivo:
    Entrenar un modelo inicial para estimar consumo y eco-score usando datos de trayectos.

Importante:
    Este script no garantiza precisión productiva sin un dataset real, validado y representativo.
    Si no existe dataset, puede generar datos sintéticos solo para probar el pipeline.

Uso:
    python ml/training/train_random_forest.py --dataset ml/dataset/ecopulse_trips.csv

Uso con datos sintéticos:
    python ml/training/train_random_forest.py --generate-synthetic
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Tuple

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split


FEATURE_COLUMNS = [
    "speed_mean",
    "speed_max",
    "acceleration_mean",
    "deceleration_mean",
    "road_grade_mean",
    "vehicle_weight_kg",
    "engine_power_hp",
    "trip_distance_km",
    "trip_duration_seconds",
    "idle_time_seconds",
    "sensor_variance",
    "aggressive_events_count",
    "hard_braking_count",
]

TARGET_COLUMN = "fuel_consumed_gallons"


def generate_synthetic_dataset(rows: int = 1200) -> pd.DataFrame:
    """Genera datos sintéticos únicamente para validar el pipeline técnico."""
    rng = np.random.default_rng(42)

    speed_mean = rng.uniform(10, 70, rows)
    speed_max = speed_mean + rng.uniform(5, 45, rows)
    acceleration_mean = rng.uniform(0.1, 2.8, rows)
    deceleration_mean = rng.uniform(-3.5, -0.1, rows)
    road_grade_mean = rng.uniform(-4, 8, rows)
    vehicle_weight_kg = rng.uniform(900, 1900, rows)
    engine_power_hp = rng.uniform(70, 220, rows)
    trip_distance_km = rng.uniform(1, 80, rows)
    trip_duration_seconds = rng.uniform(300, 7200, rows)
    idle_time_seconds = rng.uniform(0, 1200, rows)
    sensor_variance = rng.uniform(0.01, 2.0, rows)
    aggressive_events_count = rng.integers(0, 12, rows)
    hard_braking_count = rng.integers(0, 10, rows)

    base_efficiency_km_per_gallon = rng.uniform(25, 48, rows)

    penalty = (
        1
        + aggressive_events_count * 0.025
        + hard_braking_count * 0.018
        + np.maximum(road_grade_mean, 0) * 0.015
        + idle_time_seconds / 3600 * 0.08
    )

    fuel_consumed_gallons = (trip_distance_km / base_efficiency_km_per_gallon) * penalty

    return pd.DataFrame(
        {
            "speed_mean": speed_mean,
            "speed_max": speed_max,
            "acceleration_mean": acceleration_mean,
            "deceleration_mean": deceleration_mean,
            "road_grade_mean": road_grade_mean,
            "vehicle_weight_kg": vehicle_weight_kg,
            "engine_power_hp": engine_power_hp,
            "trip_distance_km": trip_distance_km,
            "trip_duration_seconds": trip_duration_seconds,
            "idle_time_seconds": idle_time_seconds,
            "sensor_variance": sensor_variance,
            "aggressive_events_count": aggressive_events_count,
            "hard_braking_count": hard_braking_count,
            "fuel_consumed_gallons": fuel_consumed_gallons,
        }
    )


def load_dataset(dataset_path: Path | None, generate_synthetic: bool) -> pd.DataFrame:
    """Carga dataset real o genera dataset sintético para pruebas."""
    if generate_synthetic:
        return generate_synthetic_dataset()

    if dataset_path is None:
        raise ValueError("Debes proporcionar --dataset o usar --generate-synthetic.")

    if not dataset_path.exists():
        raise FileNotFoundError(f"No existe el dataset: {dataset_path}")

    return pd.read_csv(dataset_path)


def validate_dataset(df: pd.DataFrame) -> pd.DataFrame:
    """Valida columnas requeridas y limpia valores básicos."""
    required_columns = FEATURE_COLUMNS + [TARGET_COLUMN]

    missing_columns = [column for column in required_columns if column not in df.columns]

    if missing_columns:
        raise ValueError(f"Faltan columnas requeridas: {missing_columns}")

    clean_df = df[required_columns].copy()

    for column in required_columns:
        clean_df[column] = pd.to_numeric(clean_df[column], errors="coerce")

    clean_df = clean_df.dropna()
    clean_df = clean_df[clean_df[TARGET_COLUMN] > 0]
    clean_df = clean_df[clean_df["trip_distance_km"] > 0]
    clean_df = clean_df[clean_df["trip_duration_seconds"] > 0]

    if len(clean_df) < 100:
        raise ValueError(
            "El dataset limpio tiene menos de 100 filas. No es suficiente para validar un modelo."
        )

    return clean_df


def calculate_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> dict:
    """Calcula métricas de evaluación del modelo."""
    mae = mean_absolute_error(y_true, y_pred)
    rmse = float(np.sqrt(mean_squared_error(y_true, y_pred)))
    r2 = r2_score(y_true, y_pred)

    non_zero_mask = y_true != 0

    if non_zero_mask.any():
        mape = float(
            np.mean(np.abs((y_true[non_zero_mask] - y_pred[non_zero_mask]) / y_true[non_zero_mask]))
            * 100
        )
    else:
        mape = None

    wape = float(np.sum(np.abs(y_true - y_pred)) / np.sum(np.abs(y_true)) * 100)

    return {
        "mae": round(float(mae), 6),
        "rmse": round(float(rmse), 6),
        "r2": round(float(r2), 6),
        "mape_pct": None if mape is None else round(mape, 6),
        "wape_pct": round(wape, 6),
    }


def train_model(df: pd.DataFrame) -> Tuple[RandomForestRegressor, dict]:
    """Entrena Random Forest y retorna modelo con métricas."""
    x = df[FEATURE_COLUMNS]
    y = df[TARGET_COLUMN]

    x_train, x_test, y_train, y_test = train_test_split(
        x,
        y,
        test_size=0.2,
        random_state=42,
    )

    model = RandomForestRegressor(
        n_estimators=300,
        max_depth=14,
        min_samples_split=4,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1,
    )

    model.fit(x_train, y_train)

    train_predictions = model.predict(x_train)
    test_predictions = model.predict(x_test)

    metrics = {
        "train": calculate_metrics(y_train.to_numpy(), train_predictions),
        "test": calculate_metrics(y_test.to_numpy(), test_predictions),
        "rows_total": int(len(df)),
        "rows_train": int(len(x_train)),
        "rows_test": int(len(x_test)),
        "features": FEATURE_COLUMNS,
        "target": TARGET_COLUMN,
        "note": (
            "Estas métricas solo son confiables si el dataset es real, representativo "
            "y validado contra mediciones confiables como OBD-II o registros de consumo."
        ),
    }

    return model, metrics


def save_artifacts(model: RandomForestRegressor, metrics: dict, output_dir: Path) -> None:
    """Guarda modelo, métricas y columnas esperadas."""
    output_dir.mkdir(parents=True, exist_ok=True)

    model_path = output_dir / "fuel_consumption_random_forest.joblib"
    metrics_path = output_dir / "fuel_consumption_metrics.json"
    features_path = output_dir / "feature_columns.json"

    joblib.dump(model, model_path)

    metrics_path.write_text(
        json.dumps(metrics, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    features_path.write_text(
        json.dumps(FEATURE_COLUMNS, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"Modelo guardado en: {model_path}")
    print(f"Métricas guardadas en: {metrics_path}")
    print(f"Features guardadas en: {features_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=str, default=None)
    parser.add_argument("--generate-synthetic", action="store_true")
    parser.add_argument("--output-dir", type=str, default="ml/models")

    args = parser.parse_args()

    dataset_path = Path(args.dataset) if args.dataset else None
    output_dir = Path(args.output_dir)

    df = load_dataset(
        dataset_path=dataset_path,
        generate_synthetic=args.generate_synthetic,
    )

    clean_df = validate_dataset(df)

    model, metrics = train_model(clean_df)

    print(json.dumps(metrics, indent=2, ensure_ascii=False))

    save_artifacts(
        model=model,
        metrics=metrics,
        output_dir=output_dir,
    )


if __name__ == "__main__":
    main()