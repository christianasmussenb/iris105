# Arquitectura funcional (POC No-Show)

Esta POC usa InterSystems IRIS 2024.1 en el namespace `MLTEST`, combinando IntegratedML y un servicio REST expuesto para consumo web y chat en lenguaje natural.

## Capas del sistema

```
Internet / Cloudflare Tunnel
        │
        ▼
IRIS Web Server (puerto 52773)
        │
        ├─ /csp/mltest  ──────────────────────────────────────────────────────┐
        │    IRIS105.REST.NoShowService (REST, Bearer token)                  │
        │                                                                     │
        ├─ /csp/mltest2  ─────────────────────────────────────────────────────┤
        │    GCSP.Basic.cls   — operaciones generales (stats, scoring, mock)  │
        │    GCSP.Agenda.cls  — agenda visual semanal/mensual con riesgo ML   │
        │                                                                     │
        └─ /csp/mlchat  ──────────────────────────────────────────────────────┤
             WSGI [Experimental] → wsgi.py → FastAPI app                      │
             Chat en lenguaje natural (Claude tool_use → IRIS REST)           │
                                                                              │
                                    MLTEST namespace                          │
                                    ┌─────────────────────────────────────────┘
                                    │
                                    ├── IRIS105.Domain.*     (tablas persistentes)
                                    │   Patient, Physician, Box, Specialty,
                                    │   Appointment, AppointmentRisk
                                    │
                                    ├── IntegratedML         (modelo ML)
                                    │   NoShowModel2 — PREDICT() + PROBABILITY()
                                    │
                                    └── ^IRIS105 globals      (config runtime)
                                        Tokens, Capacity
```

## Componentes

### 1. Datos (`IRIS105.Domain.*`)
Tablas persistentes extendiendo `%Persistent`. Entidad central: `Appointment` vinculada a Patient, Physician, Box y Specialty.

### 2. Modelo ML (IntegratedML)
- Modelo: `NoShowModel2`, entrenado con `%AutoML`, modo `BALANCE`
- Features: PatientId, PhysicianId, BoxId, SpecialtyId, StartDateTime, BookingChannel, BookingDaysInAdvance, HasSMSReminder, Reason
- Scoring SQL: `PREDICT(NoShowModel2)` y `PROBABILITY(NoShowModel2 FOR 1)`
- Resultados persistidos en `AppointmentRisk` (upsert por appointmentId)

### 3. API REST (`IRIS105.REST.NoShowService`)
15 endpoints organizados en grupos: scoring, stats, analytics, appointments, config, mock, health.  
Autenticación Bearer token via global `^IRIS105("API","Tokens",token)`.

### 4. UI CSP
- `GCSP.Basic`: operaciones generales, entrenamiento guiado paso a paso
- `GCSP.Agenda`: agenda visual con celdas `(día,hora)` coloreadas por tasa de no-show agregada

### 5. Chat app (`iris105-chat`)
App Python (FastAPI) deployada como WSGI dentro del propio IRIS.
- Claude (`claude-sonnet-4-6`) procesa lenguaje natural con `tool_use`
- 12 tools mapean a endpoints REST de IRIS (solo lectura)
- Historial de conversación mantenido en el frontend (`sessionStorage`)
- UI vanilla JS servida como archivo estático por FastAPI

## Flujo de datos

```
Mock Data Generation
  → Patient / Physician / Appointment tables
    → IntegratedML Model Training (NoShowModel2)
      ├── REST API Scoring  → AppointmentRisk (persistido)
      ├── CSP UI (Basic / Agenda)
      └── Chat App (Claude tool_use → IRIS REST → respuesta en español)
```

## Despliegue

- **Local dev**: contenedor Docker `intersystemsdc/irishealth-ml-community:latest`
- **Público**: Cloudflare Tunnel expone `localhost:52773` en `iris105m4.htc21.site`
- **Chat**: WSGI Experimental en `/csp/mlchat`, archivos en `/opt/iris105-chat/` del contenedor

Ver `docs/docker-replication-guide.md` para replicar desde cero.
