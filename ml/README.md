# EcoPulse ML Pipeline

Este módulo contiene un pipeline inicial de Machine Learning para EcoPulse.

## Objetivo

Entrenar un modelo Random Forest para estimar consumo de combustible en galones a partir de variables del trayecto, vehículo y comportamiento de conducción.

## Importante

El modelo no debe considerarse productivo hasta entrenarse con datos reales, validados y representativos.

No se debe prometer un error menor al 15% sin:

- Datos reales de trayectos.
- Comparación con OBD-II o registros confiables de combustible.
- Validación por tipo de vehículo.
- Validación por ciudad, pendiente, tráfico y estilo de conducción.
- Métricas MAE, RMSE, R2, MAPE y WAPE.
- Evaluación en datos no vistos.

## Instalar dependencias

```bash
python -m venv .venv