# IRIS105 - POC de prediccion de No-Show en InterSystems IRIS

Proyecto de muestra para calcular riesgo de inasistencia en citas medicas usando IntegratedML en el namespace `MLTEST`, con API REST de scoring y una pagina CSP basica para demo rapida.

## Estado del proyecto (fin del sprint)
- Listo: clases persistentes para pacientes, medicos, boxes, especialidades y citas; generador de datos sintetic (mock) y script de compilacion del paquete.
- Listo: servicio REST `IRIS105.REST.NoShowService` con endpoints de scoring (`/api/ml/noshow/score`), estadisticas, analytics y health check; pagina CSP `/csp/mltest/GCSP.Basic.cls` que consume la API.
- Listo: plantillas SQL para el modelo IntegratedML (`sql/NoShow_model.sql`) y consultas de apoyo (`sql/demo_queries.sql`).
- Listo: endpoints de analytics con trazas incluidas en la respuesta (`debug`) para facilitar integracion con Custom GPT.
- Pendiente: persistir los resultados de scoring en `IRIS105.AppointmentRisk` (hoy solo se devuelven en la respuesta), pruebas automatizadas, CI/CD y scripts de despliegue/dockers.
- Pendiente: endurecer autenticacion (las web apps se crean con acceso no autenticado para demo).

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

5) Generar datos mock (usa valores por defecto: 3 meses, 0.85 de ocupacion, 8 medicos, 100 pacientes):
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
- Generador de citas (`IRIS105.Util.MockAppointments`) asigna especialidad y box de forma ciclica y marca `NoShow` al azar (~15% por defecto).

## API REST (base: `/csp/mltest`)
- `POST /api/ml/noshow/score`: score por `appointmentId` o por `features` adhoc.
- `GET /api/ml/stats/summary`: totales de tablas y estado del modelo por defecto (`NoShowModel2`).
- `GET /api/ml/stats/model`: informacion de modelos, trained models y runs en INFORMATION_SCHEMA.
- `POST /api/ml/mock/generate`: genera datos sintetic (parms opcionales: months, targetOccupancy, seed, patients).
- `GET /api/ml/stats/lastAppointmentByPatient?patientId=...`: busca la ultima cita de un paciente y la puntua.
- `GET /api/ml/analytics/busiest-day`: fecha con mas citas.
- `GET /api/ml/analytics/top-specialties?limit=5`: ranking de especialidades por citas/no-show.
- `GET /api/ml/analytics/top-physicians?limit=5`: ranking de medicos por citas/no-show.
- `GET /api/ml/analytics/top-noshow?by=physician|specialty&limit=5`: ranking por tasa de no-show.
- `GET /api/health`: health check simple del servicio REST.

Ejemplos:
```bash
# Score por cita
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-1"}'

# Score con payload adhoc
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
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
curl http://localhost:52773/csp/mltest/api/ml/stats/summary
curl http://localhost:52773/csp/mltest/api/ml/stats/model

# Generar mock adicional
curl -X POST http://localhost:52773/csp/mltest/api/ml/mock/generate \
  -H "Content-Type: application/json" \
  -d '{"months":3,"targetOccupancy":0.85,"patients":200}'

# Health check sin token
curl http://localhost:52773/csp/mltest/api/health
```

## UI CSP de demo
- Pagina: `http://localhost:52773/csp/mltest/GCSP.Basic.cls`
- Acciones: ver estadisticas, score por cita, score ultima cita por paciente, generar mock, ver runs/metricas del modelo.

## Notas para Custom GPT y uso de endpoints
- Autenticacion: `Authorization: Bearer <token>`, validado contra `^IRIS105("API","Tokens",token)` en el namespace de la web app (MLTEST). Cargar el token con `Set ^IRIS105("API","Tokens","demo-readonly-token")=1`.
- Lectura de parametros: usar query string (`?by=...&limit=...`) o JSON (`by`, `limit` en el body). El endpoint usa `%request.Data(...)` y fallback a `QUERY_STRING` para evitar errores de propiedades inexistentes.
- Trazas: los endpoints de analytics incluyen `debug` en la respuesta con pasos (`step=...`), el SQL y cada fila procesada (id, citas, noShow, tasa). Dejarlo activo para facilitar integracion y troubleshooting en el GPT.
- Evitar `TOP ?` parametrizado: concatenar el limite en el SQL o cortar en memoria; algunas versiones de IRIS no soportan `TOP ?` y provocan errores de parseo/caché.
- En caso de cambios de clase, recompilar y purgar cache de consultas: `Do $system.OBJ.Compile("IRIS105.REST.NoShowService","ck")` y `Do $SYSTEM.SQL.Purge()`.
- Objetivo de despliegue: exponer la API como Actions para un Custom GPT, usando los endpoints anteriores (incluyendo `debug` en analytics) y el health check `/api/health` para verificaciones rapidas.

## Scripts y utilitarios
- `scripts/compile_package.sh`: compila el paquete `IRIS105` dentro de un contenedor Docker (`./scripts/compile_package.sh iris MLTEST`).
- `IRIS105.Util.WebAppSetup`: crea/actualiza las Web Applications REST y CSP (`ConfigureAll` o `Upsert`).

## Documentacion relacionada
- `docs/arquitectura.md`: vision funcional del POC y flujos.
- `docs/sprint1_setup.md`: pasos de setup inicial y compilacion.
- `docs/demo_script.md`: guion rapido de demo (SQL + cURL).
- `BUENAS_PRACTICAS_IRIS_COMBINADAS.md`: guia general de buenas practicas para proyectos IRIS.
