# Arquitectura funcional (POC No-Show)

Esta POC usa InterSystems IRIS 2024.1 en el namespace `MLTEST`, combinando IntegratedML y un servicio REST expuesto para consumo web.

- **Datos** (`IRIS105.*`): tablas persistentes para pacientes, médicos, boxes, especialidades, citas y la tabla de resultados `AppointmentRisk`.
- **Modelo IntegratedML**: `NoShowModel2` entrenado con `%AutoML` sobre `IRIS105.Appointment`.  
  - Scoring directo vía SQL usando `PREDICT(NoShowModel2)` y `PROBABILITY(NoShowModel2 FOR 1)`.
- **API REST** (`IRIS105.REST.NoShowService`):  
  - `POST /api/ml/noshow/score`: scoring por `appointmentId` o `features`.  
  - `GET /api/ml/stats/summary`: totales de tablas, % no-show, modelo por defecto.  
  - `POST /api/ml/mock/generate`: generar datos sintéticos adicionales.  
  - `GET /api/ml/stats/lastAppointmentByPatient`: obtiene la última cita y la puntúa.
- **Consumo web**: página CSP simple (`/csp/mltest/GCSP.Basic.cls`) y cualquier frontend puede llamar los endpoints REST y obtener `predictedLabel` + `probability` para dibujar alertas o etiquetas de riesgo.
- **Monitoreo**: vistas `INFORMATION_SCHEMA.ML_MODELS`, `ML_TRAINED_MODELS`, `ML_VALIDATION_RUNS`, `ML_VALIDATION_METRICS` registran runs y métricas del modelo que se exponen en consultas SQL o dashboards.
