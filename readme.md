# IRIS105 - POC de prediccion de No-Show en InterSystems IRIS

Proyecto de muestra para calcular riesgo de inasistencia en citas medicas usando IntegratedML en el namespace `MLTEST`, con API REST de scoring y una pagina CSP basica para demo rapida.

## Estado del proyecto (fin del sprint)
- Listo: clases persistentes para pacientes, medicos, boxes, especialidades y citas; generador de datos sintetic (mock) y script de compilacion del paquete.
- Listo: servicio REST `IRIS105.REST.NoShowService` con endpoints de scoring (`/api/ml/noshow/score`), estadisticas, analytics y health check; pagina CSP `/csp/mltest2/GCSP.Basic.cls` que consume la API.
- Listo: flujo guiado de entrenamiento SQL en la UI (`GCSP.Basic`) con pasos 1..6, boton `Submit` y panel de resultados.
- Listo: endpoint `POST /api/ml/model/step/execute` para ejecutar de forma controlada los pasos SQL del modelo desde la UI.
- Listo: plantillas SQL para el modelo IntegratedML (`sql/NoShow_model.sql`) y consultas de apoyo (`sql/demo_queries.sql`).
- Listo: endpoints de analytics con trazas incluidas en la respuesta (`debug`) para facilitar integracion con Custom GPT.
- Listo: endpoints `/api/ml/analytics/scheduled-patients`, `/api/ml/analytics/occupancy-trend`, `/api/ml/appointments/active` y `/api/ml/config/capacity` (GET/POST) con OpenAPI actualizado.
- Listo: clase de setup `IRIS105.Util.ProjectSetup` para inicializar globals de tokens y capacidad base.
- Listo: nueva pagina `GCSP.Agenda` (agenda semanal/mensual con filtros por especialidad/medico/paciente) conectada desde `GCSP.Basic`.
- Listo: despliegue de agenda por celdas `(dia,hora)` con color de fondo segun tasa de `NoShow` agregada de las citas contenidas en cada celda.
- Listo: el scoring por `appointmentId` persiste en `IRIS105.AppointmentRisk` con upsert por cita (actualiza si ya existe).
- Pendiente: pruebas automatizadas, CI/CD y scripts de despliegue/dockers.
- Pendiente: endurecer autenticacion (las web apps se crean con acceso no autenticado para demo).

## Avance reciente (sprint)
- Implementados endpoints `scheduled-patients`, `occupancy-trend`, `appointments/active` y `config/capacity` (GET/POST) en `IRIS105.REST.NoShowService`.
- Implementado endpoint `POST /api/ml/model/step/execute` para pasos SQL (verificar, crear, entrenar, validar, revisar metricas, predecir).
- Actualizada `GCSP.Basic` con bloque "Entrenamiento SQL (paso a paso)", botones 1..6, `Submit` y limpieza de resultados al cambiar de paso.
- Corregida compatibilidad de `INFORMATION_SCHEMA.ML_MODELS` para IRIS 2024.1 (uso de `CREATE_TIMESTAMP`, `PREDICTING_COLUMN_NAME`, `WITH_COLUMNS`; no usar `STATUS`).
- `occupancy-weekly` y `occupancy-trend` usan capacidad heurística: `slotsPerDay x 3 pacientes/hora x factor` (1 para box/médico, #médicos para specialty); se puede sobreescribir con `/api/ml/config/capacity`.
- OpenAPI actualizado (3.1.0, versión API `1.0.1`) en `docs/openapi.yaml`, con exclusión explícita de `POST /api/ml/model/step/execute` para Custom GPT.
- Agregada clase `IRIS105.Util.ProjectSetup` para inicializar globals de tokens y capacidad base.
- Ajuste en `IRIS105.Util.WebAppSetup`: `DispatchClass` se setea siempre (incluido vacío) para evitar que `/csp/mltest2` renderice `GCSP.Basic` en todas las rutas.
- Pendientes priorizados: definir capacidad realista persistente; revisar índices compuestos en `Appointment`; reimportar spec en el GPT y validar warnings; agregar pruebas básicas/curl para los nuevos endpoints.

## Cambios ejecutados y probados (2026-02-27)
- Agenda `GCSP.Agenda`: se cambió el despliegue por celda `(día,hora)` y se colorea el fondo según tasa agregada de `NoShow` dentro de la celda.
- Mock data: se aplicaron restricciones horarias globales para todas las especialidades y todos los boxes:
  - Lunes a viernes: `08:00-18:00`
  - Sábado: `09:00-14:00`
  - Domingo: sin agenda
- Mock data: se incorporó parámetro de `NoShow` por especialidad (`specialtyNoShowRates`) con fallback `defaultNoShowRate`.
- Mock data: limpieza previa de base antes de regenerar (`clearBeforeGenerate=1`), incluyendo `AppointmentRisk`, `Appointment`, `Physician`, `Patient`, `Box`, `Specialty`, `Payer` y `^IRIS105("Capacity")`.
- API/UI: `POST /api/ml/mock/generate` y `GCSP.Basic` actualizados para recibir `clearBeforeGenerate`, `defaultNoShowRate` y `specialtyNoShowRates`.
- Corrección técnica durante pruebas: ajuste en `IRIS105.Util.MockData.%ExecNonQuery` para evitar error de compilación por `QUIT` con argumento inválido.

### Evidencia de validación (ejecutada)
- Generación mock ejecutada con:
  - `{"months":3,"targetOccupancy":0.85,"patients":200,"clearBeforeGenerate":1,"specialtyNoShowRates":{"SPEC-1":0.12,"SPEC-2":0.20,"SPEC-3":0.08}}`
- Resultado de generación:
  - `4` pagadores, `3` especialidades, `3` boxes, `8` médicos, `200` pacientes, `5379` citas.
- Validación de restricciones horarias sobre `IRIS105.Appointment`:
  - `SundayRows=0`
  - `SaturdayOut=0`
  - `WeekdayOut=0`
  - `MinuteOut=0`
  - `DurationOut=0`
- Validación de tasa real `NoShow` por especialidad:
  - `SPEC-1`: `0.1174` (objetivo `0.12`)
  - `SPEC-2`: `0.1909` (objetivo `0.20`)
  - `SPEC-3`: `0.0782` (objetivo `0.08`)

## Requisitos rapidos
- InterSystems IRIS 2024.1 (local o contenedor).
- Namespace `MLTEST` creado (ver ejemplo abajo).
- VS Code con extension InterSystems ObjectScript (opcional pero recomendado).

## Puesta en marcha rapida
1) Crear namespace (ejemplo en un contenedor llamado `iris`):
```bash
iris session IRIS -U %SYS <<'EOF'
Do ##class(%SYS.Namespace).Create("MLTEST","USER")
Do ##class(%EnsembleMgr).EnableNamespace("MLTEST",1)
Halt
EOF
```
2) Copiar el contenido de `src/` al host o contenedor (ejemplo usa volumen en `/opt/irisapp/iris/src/`).

3) Compilar paquete:
```objectscript
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```
   O usando Docker: `./scripts/compile_package.sh iris MLTEST`.

4) Crear web apps (REST + CSP) en `%SYS`:
```objectscript
Do ##class(IRIS105.Util.WebAppSetup).ConfigureAll()
```
   Nota: `/csp/mltest2` debe quedar sin `DispatchClass` para permitir servir `GCSP.Basic.cls` y `GCSP.Agenda.cls` por ruta.

5) Generar datos mock (limpia base primero; usa 3 meses, 0.85 de ocupacion, 8 medicos, 100 pacientes; horarios L-V 08:00-18:00 y S 09:00-14:00):
```objectscript
Do ##class(IRIS105.Util.MockData).Generate()
```

6) Entrenar el modelo IntegratedML (namespace `MLTEST`):
```sql
\i sql/NoShow_model.sql
```

## Datos y modelo
- Clases persistentes: `IRIS105.Patient`, `Physician`, `Box`, `Specialty`, `Appointment`, `AppointmentRisk`.
- Campos clave para el modelo: PatientId, PhysicianId, BoxId, SpecialtyId, StartDateTime, BookingChannel, BookingDaysInAdvance, HasSMSReminder, Reason.
- Generador de citas (`IRIS105.Util.MockAppointments`) agenda por combinacion de `box + especialidad + hora` (sin domingos), con horario fijo L-V 08:00-18:00 y S 09:00-14:00, y tasa `NoShow` configurable por especialidad.

## API REST (base: `/csp/mltest`)
- `POST /api/ml/noshow/score`: score por `appointmentId` o por `features` adhoc. Cuando se usa `appointmentId`, persiste/actualiza `IRIS105.AppointmentRisk`.
- `GET /api/ml/stats/summary`: totales de tablas y estado del modelo por defecto (`NoShowModel2`).
- `GET /api/ml/stats/model`: informacion de modelos, trained models y runs en INFORMATION_SCHEMA.
- `POST /api/ml/model/step/execute`: ejecuta paso SQL del flujo de entrenamiento/prediccion (`step` de 1 a 6).
- `POST /api/ml/mock/generate`: genera datos sintetic (parms opcionales: months, targetOccupancy, seed, patients, clearBeforeGenerate, defaultNoShowRate, specialtyNoShowRates).
- `GET /api/ml/stats/lastAppointmentByPatient?patientId=...`: busca la ultima cita de un paciente y la puntua.
- `GET /api/ml/analytics/busiest-day`: fecha con mas citas.
- `GET /api/ml/analytics/top-specialties?limit=5`: ranking de especialidades por citas/no-show.
- `GET /api/ml/analytics/top-physicians?limit=5`: ranking de medicos por citas/no-show.
- `GET /api/ml/analytics/top-noshow?by=physician|specialty&limit=5`: ranking por tasa de no-show.
- `GET /api/ml/analytics/occupancy-weekly`: ocupacion semanal por grupo.
- `GET /api/ml/analytics/scheduled-patients`: citas agendadas con filtros por box/especialidad/nombres.
- `GET /api/ml/analytics/occupancy-trend`: ocupacion semanal agregada (ultimas N semanas).
- `GET /api/ml/appointments/active`: citas activas en un rango de fechas.
- `GET|POST /api/ml/config/capacity`: capacidad base por box/especialidad/medico.
- `GET /api/health`: health check simple del servicio REST.

Ejemplos:
```bash
# Score por cita
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-1"}'

# Score con payload adhoc
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{
        "features":{
          "PatientId":10,
          "PhysicianId":3,
          "BoxId":2,
          "SpecialtyId":1,
          "StartDateTime":"2025-11-18 10:30:00",
          "BookingChannel":"WEB",
          "BookingDaysInAdvance":5,
          "HasSMSReminder":1,
          "Reason":"Control post operatorio"
        }
      }'

# Estadisticas y runs
curl http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"
curl http://localhost:52773/csp/mltest/api/ml/stats/model \
  -H "Authorization: Bearer demo-readonly-token"

# Ejecutar un paso SQL del flujo guiado (1..6)
curl -X POST http://localhost:52773/csp/mltest/api/ml/model/step/execute \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"step":3}'

# Generar mock adicional
curl -X POST http://localhost:52773/csp/mltest/api/ml/mock/generate \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"months":3,"targetOccupancy":0.85,"patients":200,"clearBeforeGenerate":1,"specialtyNoShowRates":{"SPEC-1":0.12,"SPEC-2":0.20,"SPEC-3":0.08}}'

# Health check sin token
curl http://localhost:52773/csp/mltest/api/health
```

## UI CSP de demo
- Pagina recomendada (sin auth CSP): `http://localhost:52773/csp/mltest2/GCSP.Basic.cls`
- Nueva agenda visual: `http://localhost:52773/csp/mltest2/GCSP.Agenda.cls` (vista semanal/mensual, filtros por especialidad/medico/paciente, celdas por `dia/hora` coloreadas por riesgo agregado de no-show, detalle por cita y actualizacion automatica por cambio de filtros).
- Base API en la pantalla: `/csp/mltest` (usar token Bearer en el campo "Bearer Token").
- Acciones: ver estadisticas, score por cita, score ultima cita por paciente, generar mock, ver runs/metricas del modelo.
- Nuevo: bloque "Entrenamiento SQL (paso a paso)" con botones 1..6, `Submit` para ejecutar el paso y ventana de resultados.

## Notas para Custom GPT y uso de endpoints
- Autenticacion: `Authorization: Bearer <token>`, validado contra `^IRIS105("API","Tokens",token)` en el namespace de la web app (MLTEST). Cargar el token con `Set ^IRIS105("API","Tokens","demo-readonly-token")=1`.
- Compatibilidad IRIS 2024.1: en `INFORMATION_SCHEMA.ML_MODELS` usar `CREATE_TIMESTAMP` (no `STATUS`) y columnas `PREDICTING_COLUMN_NAME`, `PREDICTING_COLUMN_TYPE`, `WITH_COLUMNS`.
- Lectura de parametros: usar query string (`?by=...&limit=...`) o JSON (`by`, `limit` en el body). El endpoint usa `%request.Data(...)` y fallback a `QUERY_STRING` para evitar errores de propiedades inexistentes.
- Trazas: los endpoints de analytics incluyen `debug` en la respuesta con pasos (`step=...`), el SQL y cada fila procesada (id, citas, noShow, tasa). Dejarlo activo para facilitar integracion y troubleshooting en el GPT.
- OpenAPI para GPT: `docs/openapi.yaml` excluye intencionalmente `POST /api/ml/model/step/execute`; ese endpoint sigue disponible en backend/UI pero no en Actions del Custom GPT.
- Evitar `TOP ?` parametrizado: concatenar el limite en el SQL o cortar en memoria; algunas versiones de IRIS no soportan `TOP ?` y provocan errores de parseo/caché.
- En caso de cambios de clase, recompilar y purgar cache de consultas: `Do $system.OBJ.Compile("IRIS105.REST.NoShowService","ck")` y `Do $SYSTEM.SQL.Purge()`.
- Objetivo de despliegue: exponer la API como Actions para un Custom GPT, usando los endpoints anteriores (incluyendo `debug` en analytics) y el health check `/api/health` para verificaciones rapidas.

## Scripts y utilitarios
- `scripts/compile_package.sh`: compila el paquete `IRIS105` dentro de un contenedor Docker (`./scripts/compile_package.sh iris MLTEST`).
- `IRIS105.Util.WebAppSetup`: crea/actualiza las Web Applications REST y CSP (`ConfigureAll` o `Upsert`).
- `IRIS105.Util.ProjectSetup`: inicializa globals del proyecto (tokens y capacidad base) con `Init`.

## Documentacion relacionada
- `docs/arquitectura.md`: vision funcional del POC y flujos.
- `docs/sprint1_setup.md`: pasos de setup inicial y compilacion.
- `docs/demo_script.md`: guion rapido de demo (SQL + cURL).
- `docs/custom_gpt_cloudflare_runbook.md`: despliegue de localhost a Cloudflare Tunnel e import de `openapi.yaml` en Custom GPT.
- `BUENAS_PRACTICAS_IRIS_COMBINADAS.md`: guia general de buenas practicas para proyectos IRIS.
