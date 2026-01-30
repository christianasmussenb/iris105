# API Reference - Referencia Completa de la API REST

Documentación completa de todos los endpoints disponibles en IRIS105 NoShow Service.

## 🔗 Base URL

```
http://localhost:52773/csp/mltest
```

## 🔐 Autenticación

La mayoría de los endpoints requieren autenticación Bearer Token:

```http
Authorization: Bearer <your-token>
```

**Excepción**: `/api/health` no requiere autenticación.

### Configurar Token

```objectscript
Set ^IRIS105("API","Tokens","demo-readonly-token")=1
```

## 📋 Endpoints

### Health Check

#### `GET /api/health`

Verifica el estado del servicio.

**No requiere autenticación** ✅

**Response**:
```json
{
  "status": "healthy",
  "service": "IRIS105 NoShow API",
  "timestamp": "2026-01-29T14:30:00Z"
}
```

**Ejemplo**:
```bash
curl http://localhost:52773/csp/mltest/api/health
```

---

## 🎯 Scoring

### `POST /api/ml/noshow/score`

Predice la probabilidad de no-show para una cita.

**Requiere autenticación** 🔒

#### Scoring por Appointment ID

**Request Body**:
```json
{
  "appointmentId": "APPT-1"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "appointmentId": "APPT-1",
    "predictedLabel": 0,
    "probability": 0.23,
    "scoredAt": "2026-01-29 14:30:00",
    "model": "NoShowModel2"
  }
}
```

#### Scoring con Features Ad-Hoc

**Request Body**:
```json
{
  "features": {
    "PatientId": 10,
    "PhysicianId": 3,
    "BoxId": 2,
    "SpecialtyId": 1,
    "StartDateTime": "2025-11-18 10:30:00",
    "BookingChannel": "WEB",
    "BookingDaysInAdvance": 5,
    "HasSMSReminder": 1,
    "Reason": "Control post operatorio"
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "predictedLabel": 0,
    "probability": 0.18,
    "scoredAt": "2026-01-29 14:30:00",
    "model": "NoShowModel2"
  }
}
```

**Ejemplo**:
```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-1"}'
```

**Campos de Features**:
- `PatientId` (integer): ID del paciente
- `PhysicianId` (integer): ID del médico
- `BoxId` (integer): ID del box/sala
- `SpecialtyId` (integer): ID de la especialidad
- `StartDateTime` (string): Fecha/hora formato "YYYY-MM-DD HH:MM:SS"
- `BookingChannel` (string): Canal de reserva ("WEB", "PHONE", "APP")
- `BookingDaysInAdvance` (integer): Días de anticipación
- `HasSMSReminder` (integer): 0 o 1
- `Reason` (string): Motivo de la cita

---

## 📊 Estadísticas

### `GET /api/ml/stats/summary`

Obtiene un resumen estadístico del sistema.

**Requiere autenticación** 🔒

**Response**:
```json
{
  "success": true,
  "data": {
    "totalPatients": 100,
    "totalPhysicians": 8,
    "totalBoxes": 5,
    "totalSpecialties": 6,
    "totalAppointments": 1234,
    "totalNoShow": 185,
    "noShowRate": 0.15,
    "defaultModel": "NoShowModel2"
  }
}
```

**Ejemplo**:
```bash
curl http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/stats/model`

Información detallada de los modelos IntegratedML.

**Requiere autenticación** 🔒

**Response**:
```json
{
  "success": true,
  "data": {
    "models": [
      {
        "MODEL_NAME": "NoShowModel2",
        "MODEL_TYPE": "classification",
        "TRAINED_MODEL_NAME": "NoShowModel2-1",
        "STATUS": "trained"
      }
    ],
    "trainedModels": [...],
    "validationRuns": [...],
    "metrics": [...]
  }
}
```

**Ejemplo**:
```bash
curl http://localhost:52773/csp/mltest/api/ml/stats/model \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/stats/lastAppointmentByPatient`

Score de la última cita de un paciente específico.

**Requiere autenticación** 🔒

**Query Parameters**:
- `patientId` (required): ID del paciente

**Response**:
```json
{
  "success": true,
  "data": {
    "appointmentId": "APPT-123",
    "patientId": 1,
    "startDateTime": "2026-02-15 10:00:00",
    "predictedLabel": 0,
    "probability": 0.12,
    "scoredAt": "2026-01-29 14:30:00"
  }
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/stats/lastAppointmentByPatient?patientId=1" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

## 📈 Analytics

### `GET /api/ml/analytics/busiest-day`

Identifica el día con más citas agendadas.

**Requiere autenticación** 🔒

**Response**:
```json
{
  "success": true,
  "data": {
    "date": "2026-01-15",
    "appointmentCount": 45
  }
}
```

**Ejemplo**:
```bash
curl http://localhost:52773/csp/mltest/api/ml/analytics/busiest-day \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/analytics/top-specialties`

Ranking de especialidades por número de citas.

**Requiere autenticación** 🔒

**Query Parameters**:
- `limit` (optional, default: 5): Número de resultados

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "specialtyId": 1,
      "specialtyName": "Cardiología",
      "totalAppointments": 250,
      "noShowCount": 35,
      "noShowRate": 0.14
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/analytics/top-specialties?limit=10" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/analytics/top-physicians`

Ranking de médicos por número de citas.

**Requiere autenticación** 🔒

**Query Parameters**:
- `limit` (optional, default: 5): Número de resultados

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "physicianId": 3,
      "physicianName": "Dr. Juan Pérez",
      "totalAppointments": 180,
      "noShowCount": 22,
      "noShowRate": 0.12
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/analytics/top-physicians?limit=10" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/analytics/top-noshow`

Ranking por mayor tasa de no-show.

**Requiere autenticación** 🔒

**Query Parameters**:
- `by` (optional, default: "physician"): Agrupar por "physician", "specialty", o "box"
- `limit` (optional, default: 5): Número de resultados

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "name": "Dr. María García",
      "totalAppointments": 120,
      "noShowCount": 25,
      "noShowRate": 0.21
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/analytics/top-noshow?by=specialty&limit=5" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/analytics/occupancy-weekly`

Análisis de ocupación semanal por grupo.

**Requiere autenticación** 🔒

**Query Parameters**:
- `groupBy` (optional, default: "specialty"): "specialty", "box", o "physician"
- `startDate` (optional): Fecha inicio "YYYY-MM-DD"
- `endDate` (optional): Fecha fin "YYYY-MM-DD"
- `slotsPerDay` (optional, default: 8): Slots disponibles por día

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "groupId": 1,
      "groupName": "Cardiología",
      "week": "2026-W03",
      "capacity": 240,
      "booked": 205,
      "occupancyRate": 0.85
    }
  ],
  "debug": [
    {
      "step": "parameters",
      "groupBy": "specialty",
      "startDate": "2025-12-01",
      "endDate": "2026-01-31"
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/analytics/occupancy-weekly?groupBy=specialty&startDate=2025-12-01&endDate=2026-01-31" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/analytics/scheduled-patients`

Lista de pacientes con citas agendadas, con filtros opcionales.

**Requiere autenticación** 🔒

**Query Parameters**:
- `startDate` (optional): Fecha inicio "YYYY-MM-DD"
- `endDate` (optional): Fecha fin "YYYY-MM-DD"
- `boxId` (optional): Filtrar por box
- `specialtyId` (optional): Filtrar por especialidad
- `searchName` (optional): Buscar por nombre de paciente
- `limit` (optional, default: 100): Número máximo de resultados

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "appointmentId": "APPT-123",
      "patientId": 10,
      "patientName": "María González",
      "physicianName": "Dr. Juan Pérez",
      "specialtyName": "Cardiología",
      "boxCode": "B-01",
      "startDateTime": "2026-02-01 10:00:00"
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/analytics/scheduled-patients?specialtyId=1&limit=50" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `GET /api/ml/analytics/occupancy-trend`

Tendencia de ocupación semanal agregada.

**Requiere autenticación** 🔒

**Query Parameters**:
- `weeks` (optional, default: 8): Número de semanas hacia atrás
- `slotsPerDay` (optional, default: 8): Slots disponibles por día

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "week": "2026-W01",
      "totalCapacity": 1200,
      "totalBooked": 980,
      "occupancyRate": 0.82
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/analytics/occupancy-trend?weeks=12" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

## 📅 Appointments

### `GET /api/ml/appointments/active`

Obtiene citas activas en un rango de fechas.

**Requiere autenticación** 🔒

**Query Parameters**:
- `startDate` (optional): Fecha inicio "YYYY-MM-DD"
- `endDate` (optional): Fecha fin "YYYY-MM-DD"
- `limit` (optional, default: 100): Número máximo de resultados

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "appointmentId": "APPT-456",
      "patientName": "Carlos Ruiz",
      "physicianName": "Dr. Ana López",
      "specialtyName": "Traumatología",
      "startDateTime": "2026-02-05 14:30:00",
      "status": "Scheduled"
    }
  ]
}
```

**Ejemplo**:
```bash
curl "http://localhost:52773/csp/mltest/api/ml/appointments/active?startDate=2026-02-01&endDate=2026-02-28" \
  -H "Authorization: Bearer demo-readonly-token"
```

---

## ⚙️ Configuración

### `GET /api/ml/config/capacity`

Obtiene la configuración de capacidad.

**Requiere autenticación** 🔒

**Response**:
```json
{
  "success": true,
  "data": {
    "boxes": {
      "1": 240,
      "2": 240
    },
    "specialties": {
      "1": 480
    },
    "physicians": {
      "3": 240
    }
  }
}
```

**Ejemplo**:
```bash
curl http://localhost:52773/csp/mltest/api/ml/config/capacity \
  -H "Authorization: Bearer demo-readonly-token"
```

---

### `POST /api/ml/config/capacity`

Actualiza la configuración de capacidad.

**Requiere autenticación** 🔒

**Request Body**:
```json
{
  "entityType": "box",
  "entityId": 1,
  "capacity": 300
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "message": "Capacity updated",
    "entityType": "box",
    "entityId": 1,
    "capacity": 300
  }
}
```

**Ejemplo**:
```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/config/capacity \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"entityType":"box","entityId":1,"capacity":300}'
```

---

## 🎲 Mock Data

### `POST /api/ml/mock/generate`

Genera datos sintéticos adicionales.

**Requiere autenticación** 🔒

**Request Body**:
```json
{
  "months": 3,
  "targetOccupancy": 0.85,
  "seed": 42,
  "patients": 200
}
```

Todos los campos son opcionales. Defaults:
- `months`: 3
- `targetOccupancy`: 0.85
- `seed`: random
- `patients`: 100

**Response**:
```json
{
  "success": true,
  "data": {
    "message": "Mock data generated",
    "months": 3,
    "targetOccupancy": 0.85,
    "patients": 200
  }
}
```

**Ejemplo**:
```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/mock/generate \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"months":3,"targetOccupancy":0.85,"patients":200}'
```

---

## ❌ Manejo de Errores

Todos los endpoints devuelven errores en el formato:

```json
{
  "success": false,
  "error": "Descripción del error"
}
```

### Códigos HTTP

- `200 OK` - Solicitud exitosa
- `400 Bad Request` - Parámetros inválidos
- `401 Unauthorized` - Token inválido o faltante
- `404 Not Found` - Recurso no encontrado
- `500 Internal Server Error` - Error del servidor

### Ejemplos de Errores

**Token inválido**:
```json
{
  "success": false,
  "error": "Unauthorized: Invalid or missing token"
}
```

**Appointment no encontrada**:
```json
{
  "success": false,
  "error": "Appointment not found: APPT-999"
}
```

**Parámetros faltantes**:
```json
{
  "success": false,
  "error": "Missing required parameter: appointmentId"
}
```

---

## 📝 Notas Importantes

### Debug Traces

Los endpoints de analytics incluyen un array `debug` en la respuesta con información de troubleshooting:

```json
{
  "success": true,
  "data": [...],
  "debug": [
    {"step": "parameters", "groupBy": "specialty"},
    {"step": "sql", "query": "SELECT ..."},
    {"step": "row", "id": 1, "appointments": 250}
  ]
}
```

### Limitaciones de Paginación

Actualmente no hay paginación cursor-based. Use el parámetro `limit` para controlar el tamaño de respuesta.

### Rate Limiting

En esta versión POC no hay rate limiting implementado. Para producción se recomienda implementarlo.

---

Para más detalles, consulta:
- [Getting Started](Getting-Started) - Configuración inicial
- [ML Model](ML-Model) - Uso del modelo IntegratedML
- [Development Guide](Development-Guide) - Guía de desarrollo

