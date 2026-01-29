# Architecture - Arquitectura del Sistema

Esta página describe la arquitectura técnica de IRIS105 y cómo interactúan sus componentes.

## 🏗️ Vista General

IRIS105 utiliza una arquitectura de tres capas basada en InterSystems IRIS:

```
┌─────────────────────────────────────────────┐
│         Capa de Presentación                │
│   ┌────────────┐      ┌─────────────────┐  │
│   │  CSP UI    │      │  External Apps  │  │
│   │ (Basic.cls)│      │  (Custom GPT)   │  │
│   └────────────┘      └─────────────────┘  │
└─────────────┬───────────────────┬───────────┘
              │                   │
              ▼                   ▼
┌─────────────────────────────────────────────┐
│           Capa de API (REST)                │
│         NoShowService.cls                   │
│  ┌──────────────────────────────────────┐  │
│  │ 15 Endpoints REST con Bearer Auth    │  │
│  │ - Scoring  - Analytics  - Config     │  │
│  │ - Stats    - Mock Data  - Health     │  │
│  └──────────────────────────────────────┘  │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│        Capa de Lógica de Negocio            │
│                                             │
│  ┌──────────────┐    ┌──────────────────┐  │
│  │NoShowPredictor│    │ Mock Generators  │  │
│  │   (Scoring)   │    │  (8 classes)     │  │
│  └──────────────┘    └──────────────────┘  │
│                                             │
│  ┌──────────────┐    ┌──────────────────┐  │
│  │ ProjectSetup │    │  WebAppSetup     │  │
│  └──────────────┘    └──────────────────┘  │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│         Capa de Datos                       │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │    Clases Persistentes (%Persistent) │  │
│  │  Patient │ Physician │ Appointment   │  │
│  │  Box     │ Specialty │ Payer         │  │
│  │  AppointmentRisk                     │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │       IntegratedML Model             │  │
│  │      NoShowModel2 (%AutoML)          │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## 📦 Componentes Principales

### 1. Capa de Dominio (`src/IRIS105/Domain/`)

Clases persistentes que modelan las entidades del sistema:

#### **Patient** (`Patient.cls`)
- Información del paciente
- Campos: FirstName, LastName, DateOfBirth, Gender, Phone, Email, Address

#### **Physician** (`Physician.cls`)
- Información del médico
- Campos: FirstName, LastName, LicenseNumber, SpecialtyId

#### **Box** (`Box.cls`)
- Salas de consulta/boxes
- Campos: BoxCode, Location, IsActive

#### **Specialty** (`Specialty.cls`)
- Especialidades médicas
- Campos: SpecialtyName, Description

#### **Appointment** (`Appointment.cls`)
- **Entidad central** para el modelo ML
- Campos clave:
  - `PatientId`, `PhysicianId`, `BoxId`, `SpecialtyId`
  - `StartDateTime`, `BookingChannel`, `BookingDaysInAdvance`
  - `HasSMSReminder`, `Reason`
  - `NoShow` (target para el modelo ML)

#### **AppointmentRisk** (`AppointmentRisk.cls`)
- Tabla para resultados de scoring (no activamente usada)
- Campos: AppointmentId, PredictedLabel, Probability, ScoredAt

#### **Payer** (`Payer.cls`)
- Entidades pagadoras/aseguradoras
- Campos: PayerName, PayerType, ContactInfo

### 2. Capa de Lógica de Negocio (`src/IRIS105/Util/`)

#### **Scoring y Predicción**

**NoShowPredictor** (`NoShowPredictor.cls`)
- Wrapper para scoring con IntegratedML
- Método `Score(appointmentId)` usando SQL PREDICT/PROBABILITY

#### **Generadores de Datos Mock**

8 clases especializadas para generar datos sintéticos:
- `MockPatients.cls` - Genera pacientes
- `MockPhysicians.cls` - Genera médicos
- `MockBoxes.cls` - Genera boxes/salas
- `MockSpecialties.cls` - Genera especialidades
- `MockPayers.cls` - Genera pagadores
- `MockAppointments.cls` - **Principal**: genera citas con patrón de no-show (~15%)
- `MockData.cls` - **Orquestador**: coordina todos los generadores

#### **Configuración**

**ProjectSetup** (`ProjectSetup.cls`)
- Inicializa globals del proyecto:
  - `^IRIS105("API","Tokens",...)` para autenticación
  - `^IRIS105("Config","Capacity",...)` para capacidad base

**WebAppSetup** (`WebAppSetup.cls`)
- Crea/actualiza Web Applications:
  - `/csp/mltest` - REST API
  - Configuración sin auth para demo

### 3. Capa de API REST (`src/IRIS105/REST/`)

**NoShowService** (`NoShowService.cls`) - 1099 líneas
- Extiende `%CSP.REST`
- 15+ endpoints organizados por categoría
- Autenticación Bearer Token
- URL mapping en XData `UrlMap`

#### Endpoints Organizados

**Scoring**
- `POST /api/ml/noshow/score` - Scoring por ID o features ad-hoc

**Estadísticas**
- `GET /api/ml/stats/summary` - Totales y métricas generales
- `GET /api/ml/stats/model` - Info de modelos ML
- `GET /api/ml/stats/lastAppointmentByPatient` - Score última cita de paciente

**Analytics**
- `GET /api/ml/analytics/busiest-day` - Día con más citas
- `GET /api/ml/analytics/top-specialties` - Ranking especialidades
- `GET /api/ml/analytics/top-physicians` - Ranking médicos
- `GET /api/ml/analytics/top-noshow` - Ranking por tasa no-show
- `GET /api/ml/analytics/occupancy-weekly` - Ocupación semanal
- `GET /api/ml/analytics/scheduled-patients` - Pacientes agendados
- `GET /api/ml/analytics/occupancy-trend` - Tendencia de ocupación

**Appointments**
- `GET /api/ml/appointments/active` - Citas activas por rango

**Configuración**
- `GET /api/ml/config/capacity` - Obtener configuración de capacidad
- `POST /api/ml/config/capacity` - Actualizar capacidad

**Mock Data**
- `POST /api/ml/mock/generate` - Generar datos adicionales

**Health Check**
- `GET /api/health` - Estado del servicio (sin auth)

### 4. IntegratedML - Modelo de Machine Learning

**NoShowModel2** - Modelo principal
- **Framework**: %AutoML de IntegratedML
- **Tipo**: Clasificación binaria
- **Target**: Campo `NoShow` (0 o 1)
- **Features**:
  - PatientId
  - PhysicianId
  - BoxId
  - SpecialtyId
  - StartDateTime
  - BookingChannel
  - BookingDaysInAdvance
  - HasSMSReminder
  - Reason

**Configuración de Entrenamiento**:
```sql
TRAIN MODEL NoShowModel2 USING {
  "seed": 42,
  "TrainMode": "BALANCE",  -- Maneja desbalanceo de clases
  "MaxTime": 60            -- Tiempo máximo en segundos
}
```

**Scoring en SQL**:
```sql
SELECT 
  AppointmentId,
  PREDICT(NoShowModel2) AS PredictedLabel,
  PROBABILITY(NoShowModel2 FOR 1) AS NoShowProbability
FROM IRIS105_Domain.Appointment
WHERE AppointmentId = 'APPT-1';
```

### 5. UI de Demostración (`src/GCSP/`)

**Basic** (`Basic.cls`)
- Página CSP básica para demo
- Consume REST API vía JavaScript
- Funciones:
  - Ver estadísticas
  - Scoring por cita
  - Score última cita por paciente
  - Generar mock data
  - Ver métricas del modelo

## 🔐 Autenticación y Seguridad

### Bearer Token Authentication

Todos los endpoints (excepto `/api/health`) requieren:
```
Authorization: Bearer <token>
```

### Validación de Token
```objectscript
// En NoShowService.cls
Method ValidateToken() As %Boolean
{
  Set token = %request.Get("Authorization")
  Set token = $Piece(token, "Bearer ", 2)
  Return $Data(^IRIS105("API","Tokens",token))
}
```

### Agregar Token
```objectscript
Set ^IRIS105("API","Tokens","demo-readonly-token")=1
```

**Nota**: La configuración actual es para demo. Para producción se requiere:
- HTTPS obligatorio
- Tokens con expiración
- Rate limiting
- Logging de accesos
- Validación de permisos por endpoint

## 💾 Almacenamiento y Globals

### Globals Usadas

**Tokens de API**:
```
^IRIS105("API","Tokens",<token>)=1
```

**Configuración de Capacidad**:
```
^IRIS105("Config","Capacity","Box",<boxId>)=<capacity>
^IRIS105("Config","Capacity","Specialty",<specialtyId>)=<capacity>
^IRIS105("Config","Capacity","Physician",<physicianId>)=<capacity>
```

### Almacenamiento de Clases Persistentes

Todas las clases en `IRIS105.Domain.*` usan storage personalizado:
```objectscript
Storage Default
{
<Data name="PatientDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
...
</Data>
<DataLocation>^IRIS105.PatientD</DataLocation>
<DefaultData>PatientDefaultData</DefaultData>
<IdLocation>^IRIS105.PatientD</IdLocation>
<IndexLocation>^IRIS105.PatientI</IndexLocation>
<StreamLocation>^IRIS105.PatientS</StreamLocation>
<Type>%Storage.Persistent</Type>
}
```

## 🔄 Flujo de Datos

### Flujo de Scoring

1. **Request**: Cliente envía POST a `/api/ml/noshow/score`
2. **Auth**: Validación de Bearer token
3. **Input**: Procesar `appointmentId` o `features` ad-hoc
4. **Query**: Construir SQL con PREDICT/PROBABILITY
5. **Execute**: `%SQL.Statement` ejecuta scoring
6. **Response**: JSON con `predictedLabel` y `probability`

### Flujo de Entrenamiento

1. **Generar datos**: `MockData.Generate()`
2. **Crear modelo**: `CREATE MODEL NoShowModel2 ...`
3. **Entrenar**: `TRAIN MODEL NoShowModel2 USING {...}`
4. **Validar**: `VALIDATE MODEL NoShowModel2`
5. **Usar**: Disponible para PREDICT/PROBABILITY en SQL

### Flujo de Analytics

1. **Request**: GET a endpoint de analytics
2. **Parámetros**: `groupBy`, `startDate`, `endDate`, `limit`, etc.
3. **Query**: SQL dinámico con GROUP BY y agregaciones
4. **Debug**: Captura steps y SQL para troubleshooting
5. **Response**: JSON con `data` y `debug` traces

## 📊 Esquema de Base de Datos

### Relaciones Entre Tablas

```
Patient (1) ──────┐
                  │
Physician (1) ────┼────► (N) Appointment ────► (1) AppointmentRisk
                  │              │
Box (1) ──────────┤              │
                  │              ▼
Specialty (1) ────┘         NoShowModel2
                            (IntegratedML)
```

### Índices Recomendados

Para mejor performance en analytics:

```sql
CREATE INDEX AppointmentDateIdx 
  ON IRIS105_Domain.Appointment (StartDateTime);

CREATE INDEX AppointmentSpecialtyDateIdx 
  ON IRIS105_Domain.Appointment (SpecialtyId, StartDateTime);

CREATE INDEX AppointmentBoxDateIdx 
  ON IRIS105_Domain.Appointment (BoxId, StartDateTime);

CREATE INDEX AppointmentPhysicianDateIdx 
  ON IRIS105_Domain.Appointment (PhysicianId, StartDateTime);
```

## 🚀 Deployment Target

**Namespace**: MLTEST  
**IRIS Version**: 2024.1+  
**Port**: 52773 (default)  
**Base URL**: `/csp/mltest`

## 📈 Escalabilidad y Performance

### Consideraciones Actuales (POC)
- Sin índices compuestos optimizados
- Queries sin cache específico
- Sin connection pooling explícito
- Sin particionamiento de datos

### Mejoras Recomendadas para Producción
1. Añadir índices compuestos en `Appointment`
2. Implementar cache de queries frecuentes
3. Configurar sharding para datos históricos
4. Implementar rate limiting en API
5. Añadir monitoring y alerting

---

**Siguiente**: [API Reference →](API-Reference)
