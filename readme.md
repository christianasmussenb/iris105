# POC – Agente de IA + IntegratedML en InterSystems IRIS 2024.1  
**Predicción de No-Show en agendas médicas**

## 1. Descripción general

Esta prueba de concepto (POC) muestra cómo combinar **Machine Learning nativo de InterSystems IRIS (IntegratedML + %AutoML)** con un **agente de IA** (LLM externo) para predecir el **riesgo de no presentación (No-Show)** en citas médicas y exponer esos resultados vía **IRIS Interoperability**.

Todo el desarrollo se realizará en:

- **Namespace**: `MLTEST`  
- **Paquete de clases**: `IRIS105.*`  
- **IDE**: Visual Studio Code conectado a IRIS (extensión InterSystems ObjectScript / SQLTools).

---

## 2. Objetivos de la POC

1. **Modelar datos de agenda médica** (pacientes, médicos, boxes, especialidades, citas, pagadores).
2. **Generar datos sintéticos (mock)** que:
   - Consideren **3 boxes** de atención.
   - **8 médicos**.
   - **3 especialidades**.
   - Una **utilización promedio de agenda de ~85%**.
   - Mezcla de pagadores: **80% Fonasa / 20% Isapres**.
3. Entrenar y validar un modelo **IntegratedML + %AutoML** para predecir el `NoShow` de las citas.
4. Exponer el modelo mediante:
   - Funciones SQL `PREDICT(...)`.
   - Un **servicio REST** en IRIS Interoperability.
5. Integrar un **agente de IA** que consulte IRIS (SQL + servicios ML) como “tools” para responder preguntas en lenguaje natural.
6. Dejar una **base de MLOps básico**:
   - Consultas a vistas `INFORMATION_SCHEMA.ML_*`.
   - Procedimiento sencillo de reentrenamiento y promoción de modelos.

---

## 3. Arquitectura propuesta

### 3.1. Vista de alto nivel

- **Capa de Datos (IRIS – namespace `MLTEST`)**
  - Clases persistentes bajo `IRIS105.*`.
  - Tablas principales:
    - `IRIS105.Patient`
    - `IRIS105.Physician`
    - `IRIS105.Box`
    - `IRIS105.Specialty`
    - `IRIS105.Payer`
    - `IRIS105.Appointment`
    - `IRIS105.AppointmentRisk` (resultados de scoring).

- **Capa de ML (IntegratedML + %AutoML)**
  - Modelo productivo: `NoShowModel2` definido sobre `IRIS105.Appointment`.
  - Entrenamiento y validación con provider `%AutoML` usando comandos `TRAIN` / `VALIDATE`.
  - Monitoreo con vistas `INFORMATION_SCHEMA.ML_MODELS`, `ML_TRAINED_MODELS`, `ML_TRAINING_RUNS`, `ML_VALIDATION_RUNS`, `ML_VALIDATION_METRICS`.

- **Capa de Interoperabilidad (Producción IRIS)**
  - **Servicio REST** `IRIS105.REST.NoShowService`  
    - `/api/ml/noshow/score` (usa `NoShowModel2` por defecto, `appointmentId` o `features`).
    - `/api/ml/stats/summary` (estadísticas básicas de tablas/modelo).
    - `/api/ml/stats/lastAppointmentByPatient` (última cita del paciente y score).
    - `/api/ml/mock/generate` (genera datos sintéticos adicionales).
  - **Business Process** `IRIS105.BP.NoShowScoring`  
    - Llama al modelo IntegratedML vía SQL.
    - Aplica umbrales de riesgo.
  - **Business Operation** `IRIS105.BO.NoShowPersistence`  
    - Persiste predicciones en `AppointmentRisk`.
    - Opcional: emite mensajes para otros sistemas (alertas, BI, etc.).

- **Capa de Agente de IA**
  - Micro-servicio o clase wrapper (`IRIS105.Agent.*`) que:
    - Expone un endpoint tipo `/api/agent/chat`.
    - Llama a un **LLM externo** (OpenAI u otro).
    - Implementa “tools”:
      - `GetHighRiskAppointments(fecha)`
      - `SimulateScenario(params)`
      - `GetModelStatus()`

- **Herramientas de desarrollo**
  - Visual Studio Code + extensión InterSystems.
  - Repositorio de código (Git) con `README.md` y estructura de carpetas clara.

---

## 4. Modelo de datos y datos sintéticos

### 4.1. Entidades principales

Todas las clases se crean en el paquete `IRIS105`:

- `IRIS105.Patient`
  - `PatientId`
  - `Run` / identificador local (opcional)
  - `FirstName`, `LastName`
  - `Sex` (M/F)
  - `BirthDate`
  - `Age` (campo derivado o calculado en queries)
  - `PayerId` (FK a `IRIS105.Payer`)
  - **Dimensiones opcionales**:
    - `Region` / `Comuna`
    - `SocioEconomicSegment` (A/B/C/D, opcional)

- `IRIS105.Physician`
  - `PhysicianId`
  - `FirstName`, `LastName`
  - `SpecialtyId` (FK)
  - `DefaultBoxId` (FK, opcional)

- `IRIS105.Specialty`
  - `SpecialtyId`
  - `Name` (ej. “Medicina Interna”, “Traumatología”, “Pediatría”)

- `IRIS105.Box`
  - `BoxId`
  - `Name`
  - `Location` (ej. sucursal/sede)

- `IRIS105.Payer`
  - `PayerId`
  - `Name` (ej. “Fonasa”, “Colmena”, “Consalud”, etc.)
  - `Type` (FONASA / ISAPRE)

- `IRIS105.Appointment`
  - `AppointmentId`
  - `PatientId`
  - `PhysicianId`
  - `BoxId`
  - `SpecialtyId`
  - `StartDateTime`
  - `EndDateTime`
  - `BookingChannel` (WEB / CALLCENTER / PRESENCIAL)
  - `BookingDaysInAdvance` (número de días)
  - `HasSMSReminder` (0/1)
  - `Reason` (texto breve)
  - `NoShow` (0/1 – etiqueta histórica)

- `IRIS105.AppointmentRisk`
  - `AppointmentId` (FK)
  - `ScoredAt`
  - `NoShowProb` (0..1)
  - `RiskLevel` (LOW / MEDIUM / HIGH)
  - `ModelName`, `TrainedModelName`

---

### 4.2. Parámetros para generación de datos mock

- **Horizonte de datos**:
  - Sugerido: **3–6 meses** de agenda histórica para tener volumen suficiente.

- **Boxes (`IRIS105.Box`)**:
  - 3 boxes, por ejemplo:
    - BOX-1, BOX-2, BOX-3
  - Asociados a una misma sede o a sedes distintas (opcional).

- **Médicos (`IRIS105.Physician`)**:
  - 8 médicos distribuidos entre 3 especialidades, por ejemplo:
    - Especialidad A: Medicina Interna → 3 médicos
    - Especialidad B: Traumatología → 3 médicos
    - Especialidad C: Pediatría → 2 médicos

- **Ocupación de agendas (~85%)**:
  - Definir una grilla de atención diaria por médico, ej.:
    - Lunes–Viernes, 8 bloques de 30 minutos por jornada (ej. 09:00–13:00).
  - Total de slots = (médicos × días × slots por día).
  - Se genera un ~85% de esos slots como citas ocupadas (`IRIS105.Appointment`).

- **Mezcla de pagadores (“payers”)**:
  - **80% Fonasa** / **20% Isapres**.
  - En la generación de pacientes:
    - `Payer.Type = FONASA` en 80% de los casos.
    - El 20% restante repartido entre 2–3 Isapres (ej. “Colmena”, “Consalud”, “Banmédica”).

---

### 4.3. Diversidad de población (sexo, edad)

Para que el dataset sea verosímil y útil para entrenamiento:

- **Distribución por sexo** (binaria para simplificar la POC):
  - ~52% mujeres, ~48% hombres.
  - Esto se asigna al crear registros en `IRIS105.Patient`.

- **Distribución por edad** (basada en consultas ambulatorias generales):
  - 0–17 años: 10% (principalmente para Pediatría).
  - 18–39 años: 30%.
  - 40–64 años: 35%.
  - 65+ años: 25%.
- En la generación de citas:
  - Para Pediatría, preferir pacientes 0–17.
  - Para Medicina Interna, más presencia en 40–64 y 65+.
  - Para Traumatología, mezcla amplia 18–64.

---

### 4.4. Otras dimensiones recomendadas

Para enriquecer el modelo y la demo, se recomienda incluir:

- **Día de la semana** (derivado de `StartDateTime`).
- **Franja horaria**:
  - Mañana / Tarde (campo derivado).
- **Tipo de cita**:
  - `VisitType` (PRIMERA_VEZ / CONTROL / URGENCIA_PROGRAMADA).
- **Antecedente de no-show previo**:
  - `PastNoShowCount` por paciente, calculado al generar los datos.
- **Tiempo de espera**:
  - Diferencia entre la fecha de reserva y la fecha de la cita (ya representada en `BookingDaysInAdvance`).
- **Canal de recordatorio adicional** (opcional):
  - Email / WhatsApp (simple flag booleana para la POC).

---

## 5. Flujo de ML con IntegratedML + %AutoML

En el namespace `MLTEST`, el modelo IntegratedML se define y usa desde SQL:

### 1. **Definición de modelo productivo (NoShowModel2)**

```sql
CREATE MODEL NoShowModel2
PREDICTING (NoShow)
FROM IRIS105.Appointment
WITH (
  PatientId,
  PhysicianId,
  BoxId,
  SpecialtyId,
  StartDateTime,
  BookingChannel,
  BookingDaysInAdvance,
  HasSMSReminder,
  Reason
);

### 2. **Entrenamiento del modelo**

```sql
TRAIN MODEL NoShowModel2
USING {
  "seed": 42,
  "TrainMode": "BALANCE",
  "MaxTime": 60,
  "MinimumDesiredScore": 0.80
};

### 3. **Validación del modelo**

```sql
VALIDATE MODEL NoShowModel2;

### 4. **Uso en predicción vía IntegratedML**

```sql
SELECT AppointmentId,
       PREDICT(NoShowModel2) AS PredictedLabel,
       PROBABILITY(NoShowModel2 FOR 1) AS NoShowProb
FROM IRIS105.Appointment
WHERE StartDateTime BETWEEN '2025-11-18' AND '2025-11-19';

### 5. **Consumo vía API REST (para páginas web u otros clientes)**

- Servicio: `IRIS105.REST.NoShowService`  
- Endpoint: `POST /api/ml/noshow/score`  
- Modelo por defecto: `NoShowModel2` (se puede especificar `trainedModelName` si se desea fijar un run concreto).

**Ejemplos de request**

1) Scoring de una cita ya cargada:

```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":123}'
```

2) Scoring con payload ad-hoc (sin persistir la cita):

```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Content-Type: application/json" \
  -d '{
        "modelName":"NoShowModel2",
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
```

**Ejemplo de respuesta**

```json
{
  "appointmentId": 123,
  "predictedLabel": 1,
  "probability": 0.84,
  "modelName": "NoShowModel2",
  "trainedModelName": "",
  "scoredAt": "2025-11-18T15:42:10"
}
```

- `predictedLabel` proviene de `PREDICT(...)`.
- `probability` proviene de `PROBABILITY(... FOR 1)`.
- Estos mismos comandos SQL se usan internamente en `IRIS105.Util.NoShowPredictor`.
- Mejora pendiente: publicar o fijar el `DEFAULT_TRAINED_MODEL_NAME` de `NoShowModel2` (ej. `ALTER MODEL NoShowModel2 SET DEFAULT TRAINED_MODEL '<run>'` o `PUBLISH MODEL NoShowModel2`) para que `trainedModelName` siempre se devuelva en la API sin necesidad de especificarlo en cada request.

### 6. Endpoints auxiliares y UI CSP simple

- Estadísticas: `GET /csp/mltest/api/ml/stats/summary`
- Última cita por paciente (con score): `GET /csp/mltest/api/ml/stats/lastAppointmentByPatient?patientId=1`
- Generación de mock data: `POST /csp/mltest/api/ml/mock/generate` (params opcionales `months`, `targetOccupancy`, `patients`, `seed`)
- Página CSP liviana: `http://localhost:52773/csp/mltest/GCSP.Basic.cls`
  - Botones para stats, score por appointment, score por último paciente y generación rápida de mocks.

### 7. Avance y pendientes para el siguiente sprint

**Avance**:  
- API REST funcionando (`score`, `stats/summary`, `stats/model`, `stats/lastAppointmentByPatient`, `mock/generate`).  
- UI CSP básica para consumir endpoints y visualizar stats/modelo.  
- Modelo `NoShowModel2` entrenado y validado; consultas de métricas operativas.

**Pendientes priorizados**:  
- Publicar/fijar `DEFAULT_TRAINED_MODEL_NAME` para `NoShowModel2` y ajustar parámetros de riesgo (umbrales rojo/amarillo/verde).  
- Implementar scoring batch por día específico (ej. `POST /api/ml/noshow/score/batch?date=YYYY-MM-DD`) y reflejar riesgos agregados en `AppointmentRisk`.  
- Persistir cada score en `IRIS105.AppointmentRisk` vía API/BP y exponer el conteo en `stats/summary`.  
- Semáforo de riesgo en la UI (rojo/amarillo/verde según probabilidad configurada).  
- Documentar los umbrales de riesgo y dejarlos parametrizables para futuras demos.  
- Añadir ejemplos curl para batch por día y actualizar `docs/demo_script.md` tras implementar.  
- (Opcional) Tests rápidos de los nuevos endpoints de batch y persistencia.

### 5. Mantenimiento básico

- Consultas a INFORMATION_SCHEMA.ML_* para:
    - Ver modelos entrenados.
    - Ver métricas de validación.

- ALTER MODEL para:
  - Fijar DEFAULT model.
  - PURGE de runs antiguos.

## 6. Plan de trabajo – 4 semanas (Sprints)

### Sprint 1 – Setup, modelo de datos y tooling

Objetivo: Dejar el entorno listo y el modelo de datos definido.

Crear namespace MLTEST en IRIS 2024.1.

Configurar conexión de Visual Studio Code a MLTEST.

Definir clases de dominio en paquete IRIS105.*:

Patient, Physician, Box, Specialty, Payer, Appointment, AppointmentRisk.

Crear clase utilitaria IRIS105.Util.MockConfig con parámetros de generación (horizonte, ocupación, mix de pagadores).

Documentar en el repo la arquitectura y este README.md.

Entregables:

- Namespace operativo MLTEST.

- Clases de dominio compiladas.

- Diagrama lógico de datos (opcional, en docs/).

### Sprint 2 – Generación de datos mock y primer modelo IntegratedML

Objetivo: Poblar tablas y entrenar el primer modelo.

Implementar IRIS105.Util.MockData:

Generación de pacientes según distribución sexo/edad.

Creación de médicos, boxes y especialidades.

Construcción de agenda con ~85% de ocupación a lo largo de 3–6 meses.

Asignación de NoShow con reglas probabilísticas (ej. más no-show en jóvenes, en ciertas franjas horarias, sin recordatorio SMS).

Cargar datos en las tablas en MLTEST.

Crear y entrenar el modelo IntegratedML NoShowModel.

Ejecutar VALIDATE MODEL y revisar métricas en INFORMATION_SCHEMA.ML_*.

Entregables:

- Dataset sintético completo.

- Script SQL para CREATE/TRAIN/VALIDATE MODEL.

- Reporte simple de métricas del modelo (AUC/Accuracy).

### Sprint 3 – Interoperability: servicio REST de scoring

Objetivo: Exponer el modelo como servicio en una Producción IRIS.

Crear Producción IRIS105.Production.NoShow.

Implementar:

IRIS105.BS.NoShowREST (Business Service REST).

IRIS105.BP.NoShowScoring (Business Process).

IRIS105.BO.NoShowPersistence (Business Operation).

Endpoint sugerido:

POST /api/ml/noshow/score

Entrada: JSON con uno o más AppointmentId o datos de cita.

Salida: NoShowProb, RiskLevel, ModelName.

Persistir los resultados en IRIS105.AppointmentRisk.

Probar el flujo end-to-end con Postman / curl.

Entregables:

- Producción configurada y en RUNNING.

- Endpoint REST funcional.

- Ejemplos de requests/responses documentados.

### Sprint 4 – Agente de IA, demo final y MLOps ligero

Objetivo: Integrar un LLM como agente y cerrar la POC.

Implementar clase wrapper IRIS105.Agent.Controller:

Endpoint /api/agent/chat.

Integración con LLM (OpenAI u otro) mediante HTTP.

Definición de “tools”:

GetHighRiskAppointments(fecha): consulta SQL a AppointmentRisk.

SimulateScenario(params): llama a /api/ml/noshow/score.

GetModelStatus(): consulta INFORMATION_SCHEMA.ML_*.

Diseñar 5–6 prompts de ejemplo para demo:

“Muéstrame las citas de mañana con mayor riesgo de no-show.”

“¿Por qué esta cita tiene 85% de probabilidad de no presentar al paciente?”

“¿Qué pasa si agregamos recordatorio SMS a las citas del lunes en la mañana?”

Implementar script sencillo de reentrenamiento periódico (tarea programada) que:

TRAIN + VALIDATE + comparación de métricas.

Actualiza el modelo por defecto si mejora.

Preparar documentación final:

Diagramas simples de la arquitectura.

Pasos para reproducir la POC en otro entorno.

Entregables:

- Agente de IA funcional (vía HTTP) apoyado en IRIS.

- Tarea de reentrenamiento básico documentada.

- Guía de demo y slide/resumen técnico.

## 7. Próximos pasos / extensiones posibles

Incluir más fuentes de datos (ej. asistencia a recordatorios, clima, feriados).

Conectar IRIS con un dashboard BI (IRIS BI / Power BI / Tableau).

Integrar con un sistema real de agenda clínica.

Implementar lógica de acciones automáticas:

Reconfirmar citas de alto riesgo.

Enviar recordatorios adicionales.

Sugerir sobreventa controlada de agenda.

## 8. Repositorio y estructura sugerida

/
├─ src/
│  ├─ IRIS105/
│  │  ├─ Domain/        # Clases Patient, Physician, Box, etc.
│  │  ├─ ML/            # Scripts IntegratedML, utilidades ML
│  │  ├─ Interop/       # Producción, BS/BP/BO
│  │  └─ Agent/         # Integración con LLM
├─ sql/
│  ├─ create_tables.sql
│  ├─ integratedml_model.sql
│  └─ demo_queries.sql
├─ docs/
│  ├─ arquitectura.md
│  └─ demo_script.md
└─ README.md
