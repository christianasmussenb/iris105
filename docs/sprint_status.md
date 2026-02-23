# Estado del sprint – IRIS105 No-Show

## Avance
- Endpoint `GET /api/ml/analytics/occupancy-weekly` implementado en `IRIS105.REST.NoShowService`: agrupa por specialty/box/physician, valida rango (default últimas 6 semanas), permite `slotsPerDay`, devuelve week `YYYY-Www` con capacity/booked/occupancyRate. Capacidad heurística por día = `slotsPerDay x 3 pacientes/hora x factor` (1 para box/médico, #médicos para specialty); se puede sobrescribir con `/api/ml/config/capacity`.
- Probado vía túnel `https://iris105.htc21.site/csp/mltest` con token demo; respuestas 200 con datos reales.
- `docs/openapi.yaml` (OpenAPI 3.1.0) actualizado con todos los endpoints y esquemas (`OccupancyWeeklyResponse`, `ScheduledPatientsResponse`, `OccupancyTrendResponse`, `ActiveAppointmentsResponse`, `CapacityConfigRequest/Response`); descripciones acotadas a <300 caracteres para el Custom GPT.
- Endpoints implementados: `/api/ml/analytics/scheduled-patients`, `/api/ml/analytics/occupancy-trend`, `/api/ml/appointments/active`, `/api/ml/config/capacity` (GET/POST) y OpenAPI actualizado.
- Clase de setup agregada: `IRIS105.Util.ProjectSetup` para inicializar globals de tokens y capacidad base.
- Nuevo endpoint `POST /api/ml/model/step/execute` para ejecutar el flujo SQL guiado del modelo (`step` 1..6).
- UI `GCSP.Basic` actualizada con sección "Entrenamiento SQL (paso a paso)": botones 1..6, botón `Submit` y panel de resultados; al cambiar de paso se limpia la ventana de respuesta.
- Ajuste de compatibilidad en consultas de `INFORMATION_SCHEMA.ML_MODELS`: reemplazo de `STATUS` por `CREATE_TIMESTAMP` y uso de `PREDICTING_COLUMN_NAME`, `PREDICTING_COLUMN_TYPE`, `WITH_COLUMNS`.
- Validado en ambiente local: `/api/health`, `/api/ml/stats/summary`, `/api/ml/stats/model` y `/api/ml/model/step/execute` respondiendo 200.

## Pendientes prioritarios
1) Capacidad realista: definir/guardar capacidad por box/especialidad (tabla/config) para que `occupancyRate` solo supere 1 en sobrecupo real; revisar interacciones con `config/capacity`.
2) Performance: evaluar índices compuestos en `IRIS105.Appointment` sobre `StartDateTime` + (`SpecialtyId`/`BoxId`/`PhysicianId`) para analytics por rango.
3) OpenAPI/GPT: reimportar `docs/openapi.yaml` en el Custom GPT y corregir cualquier warning residual.
4) Pruebas: scripts curl o tests básicos para nuevos endpoints; validar errores por rangos inválidos y groupBy.

## Uso rápido del nuevo endpoint
- `GET /api/ml/analytics/occupancy-weekly?groupBy=specialty&startDate=2025-12-01&endDate=2026-01-31&slotsPerDay=8`
- Header: `Authorization: Bearer <token>`
- Notas: `occupancyRate` puede ser >1 si la capacidad heurística es baja; ajustar `slotsPerDay` o definir capacidades específicas.

## Uso rápido del endpoint de ejecución SQL guiada
- `POST /api/ml/model/step/execute`
- Header: `Authorization: Bearer <token>`
- Body de ejemplo: `{"step":3}`
- Respuesta: incluye `status`, `sql` ejecutado y `rows`/`metrics` según el paso.
