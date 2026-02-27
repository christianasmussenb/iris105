# Estado del sprint – IRIS105 No-Show

## Actualizacion 2026-02-27 (despliegue de agenda + mock con restricciones)
- Agenda `GCSP.Agenda` actualizada:
  - Render por celdas `(dia,hora)` en lugar de lista plana diaria.
  - Color de fondo de cada celda segun tasa agregada de `NoShow` de las citas contenidas.
  - Leyenda visual de riesgo (`sin dato`, `0%`, `1-24%`, `25-44%`, `>=45%`).
- Generacion mock `IRIS105.Util.MockData` y `IRIS105.Util.MockAppointments` actualizada:
  - Limpieza previa opcional (`clearBeforeGenerate`, default `1`) para regeneracion limpia.
  - Restricciones de agenda globales para todas las especialidades y boxes:
    - L-V `08:00-18:00`
    - S `09:00-14:00`
    - Domingo excluido
  - Duracion de cita estandarizada a `60` minutos.
  - Parametro de `NoShow` por especialidad (`specialtyNoShowRates`) con fallback (`defaultNoShowRate`).
- API/UI actualizadas:
  - `POST /api/ml/mock/generate` ahora acepta `clearBeforeGenerate`, `defaultNoShowRate`, `specialtyNoShowRates`.
  - `GCSP.Basic` agrega input JSON para tasas por especialidad y selector de limpieza previa.
- Correccion aplicada durante prueba:
  - Ajuste de compilacion en `IRIS105.Util.MockData.%ExecNonQuery` (eliminado `QUIT` con argumento dentro de bloque no valido).

## Pruebas ejecutadas (2026-02-27)
- Generacion mock por API:
  - Payload: `{"months":3,"targetOccupancy":0.85,"patients":200,"clearBeforeGenerate":1,"specialtyNoShowRates":{"SPEC-1":0.12,"SPEC-2":0.20,"SPEC-3":0.08}}`
  - Resultado: `5379` citas generadas (`status=ok`).
- Validacion de reglas horarias:
  - `SundayRows=0`
  - `SaturdayOut=0`
  - `WeekdayOut=0`
  - `MinuteOut=0`
  - `DurationOut=0`
- Validacion de `NoShow` por especialidad:
  - `SPEC-1`: `0.117386` (objetivo `0.12`)
  - `SPEC-2`: `0.190853` (objetivo `0.20`)
  - `SPEC-3`: `0.078246` (objetivo `0.08`)

## Avance
- Endpoint `GET /api/ml/analytics/occupancy-weekly` implementado en `IRIS105.REST.NoShowService`: agrupa por specialty/box/physician, valida rango (default últimas 6 semanas), permite `slotsPerDay`, devuelve week `YYYY-Www` con capacity/booked/occupancyRate. Capacidad heurística por día = `slotsPerDay x 3 pacientes/hora x factor` (1 para box/médico, #médicos para specialty); se puede sobrescribir con `/api/ml/config/capacity`.
- Probado vía túnel `https://iris105.htc21.site/csp/mltest` con token demo; respuestas 200 con datos reales.
- `docs/openapi.yaml` (OpenAPI 3.1.0, API `1.0.1`) actualizado con todos los endpoints y esquemas (`OccupancyWeeklyResponse`, `ScheduledPatientsResponse`, `OccupancyTrendResponse`, `ActiveAppointmentsResponse`, `CapacityConfigRequest/Response`) y exclusión explícita de `POST /api/ml/model/step/execute` para Custom GPT.
- Endpoints implementados: `/api/ml/analytics/scheduled-patients`, `/api/ml/analytics/occupancy-trend`, `/api/ml/appointments/active`, `/api/ml/config/capacity` (GET/POST) y OpenAPI actualizado.
- Clase de setup agregada: `IRIS105.Util.ProjectSetup` para inicializar globals de tokens y capacidad base.
- Nuevo endpoint `POST /api/ml/model/step/execute` para ejecutar el flujo SQL guiado del modelo (`step` 1..6).
- UI `GCSP.Basic` actualizada con sección "Entrenamiento SQL (paso a paso)": botones 1..6, botón `Submit` y panel de resultados; al cambiar de paso se limpia la ventana de respuesta.
- Nueva UI `GCSP.Agenda` (`/csp/mltest2/GCSP.Agenda.cls`): agenda semanal/mensual con filtros por especialidad, médico y paciente; detalle por cita y recarga automática.
- Corregido problema de navegación CSP: `/csp/mltest2` no debe tener `DispatchClass=GCSP.Basic`; se ajustó `IRIS105.Util.WebAppSetup` para setear `DispatchClass` siempre (incluido vacío) y evitar que todas las rutas rendericen Basic.
- Ajuste de compatibilidad en consultas de `INFORMATION_SCHEMA.ML_MODELS`: reemplazo de `STATUS` por `CREATE_TIMESTAMP` y uso de `PREDICTING_COLUMN_NAME`, `PREDICTING_COLUMN_TYPE`, `WITH_COLUMNS`.
- Validado en ambiente local: `/api/health`, `/api/ml/stats/summary`, `/api/ml/stats/model` y `/api/ml/model/step/execute` respondiendo 200.

## Pendientes prioritarios
1) Capacidad realista: definir/guardar capacidad por box/especialidad (tabla/config) para que `occupancyRate` solo supere 1 en sobrecupo real; revisar interacciones con `config/capacity`.
2) Performance: evaluar índices compuestos en `IRIS105.Appointment` sobre `StartDateTime` + (`SpecialtyId`/`BoxId`/`PhysicianId`) para analytics por rango.
3) OpenAPI/GPT: reimportar `docs/openapi.yaml` en el Custom GPT (sin `model/step/execute`) y corregir cualquier warning residual.
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
