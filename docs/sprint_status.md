# Estado del sprint – IRIS105 No-Show

## Avance
- Endpoint `GET /api/ml/analytics/occupancy-weekly` implementado en `IRIS105.REST.NoShowService`: agrupa por specialty/box/physician, valida rango (default últimas 6 semanas), permite `slotsPerDay`, devuelve week `YYYY-Www` con capacity/booked/occupancyRate.
- Probado vía túnel `https://iris105.htc21.site/csp/mltest` con token demo; respuestas 200 con datos reales.
- `docs/openapi.yaml` (OpenAPI 3.1.0) actualizado con el endpoint y esquema `OccupancyWeeklyResponse`; descripciones acotadas a <300 caracteres para el Custom GPT.

## Pendientes prioritarios
1) Endpoints faltantes:
   - `/api/ml/analytics/scheduled-patients` (filtros specialty/box, rango fechas, nombres de paciente/médico).
   - `/api/ml/config/capacity` (capacidad base por box/especialidad).
   - `/api/ml/analytics/occupancy-trend` (últimas N semanas).
   - `/api/ml/appointments/active` (rango de fechas, base para otros).
2) Capacidad realista: definir/guardar capacidad por box/especialidad (tabla/config) para que `occupancyRate` solo supere 1 en sobrecupo real.
3) Performance: evaluar índices compuestos en `IRIS105.Appointment` sobre `StartDateTime` + (`SpecialtyId`/`BoxId`/`PhysicianId`) para analytics por rango.
4) OpenAPI/GPT: reimportar `docs/openapi.yaml` en el Custom GPT y corregir cualquier warning residual.
5) Pruebas: scripts curl o tests básicos para nuevos endpoints; validar errores por rangos inválidos y groupBy.

## Uso rápido del nuevo endpoint
- `GET /api/ml/analytics/occupancy-weekly?groupBy=specialty&startDate=2025-12-01&endDate=2026-01-31&slotsPerDay=8`
- Header: `Authorization: Bearer <token>`
- Notas: `occupancyRate` puede ser >1 si la capacidad heurística es baja; ajustar `slotsPerDay` o definir capacidades específicas.
