# ML Model - Guía de IntegratedML

Esta página describe cómo trabajar con el modelo de machine learning IntegratedML en IRIS105.

## 🤖 Introducción a IntegratedML

IntegratedML es la tecnología de ML integrada en InterSystems IRIS que permite entrenar y usar modelos de machine learning directamente desde SQL, sin necesidad de exportar datos o usar frameworks externos.

### Ventajas de IntegratedML

- ✅ **Sin movimiento de datos**: Entrena directamente sobre datos en IRIS
- ✅ **SQL nativo**: Usa CREATE MODEL, TRAIN, PREDICT en SQL
- ✅ **AutoML integrado**: %AutoML selecciona automáticamente el mejor algoritmo
- ✅ **Sin dependencias**: No requiere Python, R o bibliotecas externas
- ✅ **Producción lista**: Modelo disponible inmediatamente para scoring

## 📊 Modelo NoShowModel2

### Configuración del Modelo

**Tipo**: Clasificación binaria  
**Target**: Campo `NoShow` (0 = asistió, 1 = no asistió)  
**Features**: 9 campos de `Appointment`  
**Framework**: %AutoML

### Features del Modelo

| Feature | Tipo | Descripción |
|---------|------|-------------|
| `PatientId` | Integer | ID del paciente |
| `PhysicianId` | Integer | ID del médico |
| `BoxId` | Integer | ID de la sala/box |
| `SpecialtyId` | Integer | ID de la especialidad |
| `StartDateTime` | Timestamp | Fecha/hora de la cita |
| `BookingChannel` | String | Canal de reserva (WEB, PHONE, APP) |
| `BookingDaysInAdvance` | Integer | Días de anticipación |
| `HasSMSReminder` | Integer | Si tiene recordatorio SMS (0/1) |
| `Reason` | String | Motivo de la cita |

## 🎓 Entrenamiento del Modelo

### Opción 1: Usar el Script SQL

El proyecto incluye un script completo para crear y entrenar el modelo:

```bash
# Desde SQL en namespace MLTEST
\i sql/NoShow_model.sql
```

### Opción 2: Comandos SQL Manuales

#### 1. Crear el Modelo

```sql
CREATE MODEL NoShowModel2 
PREDICTING (NoShow) 
FROM IRIS105_Domain.Appointment;
```

Esto define que queremos predecir el campo `NoShow` basándonos en los otros campos de `Appointment`.

#### 2. Entrenar el Modelo

```sql
TRAIN MODEL NoShowModel2 USING {
  "seed": 42,
  "TrainMode": "BALANCE",
  "MaxTime": 60
};
```

**Parámetros de entrenamiento**:
- `seed`: 42 - Semilla para reproducibilidad
- `TrainMode`: "BALANCE" - Maneja desbalanceo de clases (importante porque hay más citas asistidas que no-show)
- `MaxTime`: 60 - Tiempo máximo en segundos

#### 3. Validar el Modelo

```sql
VALIDATE MODEL NoShowModel2;
```

Esto ejecuta validación cruzada y calcula métricas de performance.

### Monitorear el Entrenamiento

Durante el entrenamiento, puedes consultar el estado:

```sql
SELECT MODEL_NAME, TRAINED_MODEL_NAME, TRAINING_STATUS
FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS
WHERE MODEL_NAME = 'NoShowModel2'
ORDER BY RUN_START_TIMESTAMP DESC;
```

## 📈 Métricas del Modelo

### Ver Métricas de Validación

```sql
SELECT 
  TRAINED_MODEL_NAME,
  VALIDATION_METRIC_NAME,
  VALIDATION_METRIC_VALUE
FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS
WHERE TRAINED_MODEL_NAME LIKE 'NoShowModel2%'
ORDER BY TRAINED_MODEL_NAME, VALIDATION_METRIC_NAME;
```

### Métricas Típicas

- **Accuracy**: Precisión general
- **Precision**: Precisión de predicciones positivas
- **Recall**: Tasa de detección de positivos
- **F1-Score**: Media armónica de precision y recall
- **AUC**: Área bajo la curva ROC

### Ejemplo de Salida

```
TRAINED_MODEL_NAME    | METRIC_NAME | VALUE
----------------------|-------------|-------
NoShowModel2-1        | Accuracy    | 0.847
NoShowModel2-1        | Precision   | 0.782
NoShowModel2-1        | Recall      | 0.691
NoShowModel2-1        | F1Score     | 0.733
NoShowModel2-1        | AUC         | 0.892
```

## 🎯 Uso del Modelo (Scoring)

### Scoring en SQL Directo

#### Predicción Simple

```sql
SELECT 
  AppointmentId,
  PREDICT(NoShowModel2) AS PredictedLabel
FROM IRIS105_Domain.Appointment
WHERE AppointmentId = 'APPT-123';
```

**Output**:
- `0` - Predicción: paciente asistirá
- `1` - Predicción: paciente NO asistirá

#### Predicción con Probabilidad

```sql
SELECT 
  AppointmentId,
  PREDICT(NoShowModel2) AS PredictedLabel,
  PROBABILITY(NoShowModel2 FOR 1) AS NoShowProbability
FROM IRIS105_Domain.Appointment
WHERE AppointmentId = 'APPT-123';
```

**Output**:
```
AppointmentId | PredictedLabel | NoShowProbability
--------------|----------------|------------------
APPT-123      | 0              | 0.23
```

### Scoring Batch (Múltiples Citas)

```sql
SELECT 
  AppointmentId,
  PatientId,
  StartDateTime,
  PREDICT(NoShowModel2) AS PredictedLabel,
  PROBABILITY(NoShowModel2 FOR 1) AS NoShowProb
FROM IRIS105_Domain.Appointment
WHERE StartDateTime > CURRENT_TIMESTAMP
  AND NoShow IS NULL
ORDER BY NoShowProb DESC
LIMIT 100;
```

Esto identifica las 100 citas futuras con mayor riesgo de no-show.

### Scoring desde ObjectScript

```objectscript
ClassMethod ScoreAppointment(appointmentId As %String) As %DynamicObject
{
  Set result = ##class(%DynamicObject).%New()
  
  Set sql = "SELECT PREDICT(NoShowModel2) AS Label, "_
            "PROBABILITY(NoShowModel2 FOR 1) AS Prob "_
            "FROM IRIS105_Domain.Appointment "_
            "WHERE AppointmentId = ?"
            
  Set stmt = ##class(%SQL.Statement).%New()
  Set status = stmt.%Prepare(sql)
  
  Set rs = stmt.%Execute(appointmentId)
  If rs.%Next() {
    Do result.%Set("predictedLabel", rs.Label)
    Do result.%Set("probability", rs.Prob)
  }
  
  Return result
}
```

### Scoring vía REST API

Ver [API Reference](API-Reference#scoring) para detalles completos.

```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-123"}'
```

## 🔄 Re-entrenamiento del Modelo

### ¿Cuándo Re-entrenar?

Re-entrena el modelo cuando:
- Hay nuevos datos significativos (ej: 1000+ citas nuevas)
- Las métricas de performance bajan
- Cambios en patrones de comportamiento (estacionalidad)
- Después de cambios en el proceso de negocio

### Proceso de Re-entrenamiento

#### 1. Verificar Datos Nuevos

```sql
SELECT COUNT(*) AS NewAppointments
FROM IRIS105_Domain.Appointment
WHERE AppointmentId > (
  SELECT MAX(AppointmentId) 
  FROM IRIS105_Domain.Appointment 
  WHERE TrainedModelUsed = 'NoShowModel2-1'
);
```

#### 2. Re-entrenar

```sql
TRAIN MODEL NoShowModel2 USING {
  "seed": 42,
  "TrainMode": "BALANCE",
  "MaxTime": 60
};
```

Esto crea un nuevo trained model (ej: `NoShowModel2-2`).

#### 3. Comparar Métricas

```sql
SELECT 
  TRAINED_MODEL_NAME,
  VALIDATION_METRIC_NAME,
  VALIDATION_METRIC_VALUE
FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS
WHERE TRAINED_MODEL_NAME LIKE 'NoShowModel2%'
  AND VALIDATION_METRIC_NAME IN ('Accuracy', 'F1Score', 'AUC')
ORDER BY TRAINED_MODEL_NAME, VALIDATION_METRIC_NAME;
```

#### 4. Activar Nuevo Modelo (si es mejor)

```sql
SET MODEL NoShowModel2 DEFAULT TRAINED MODEL NoShowModel2-2;
```

## 🔍 Análisis de Features

### Feature Importance

IntegratedML no expone directamente feature importance en esta versión, pero puedes analizar correlaciones:

```sql
-- Correlación entre días de anticipación y no-show
SELECT 
  CASE 
    WHEN BookingDaysInAdvance < 7 THEN '0-6 days'
    WHEN BookingDaysInAdvance < 14 THEN '7-13 days'
    ELSE '14+ days'
  END AS BookingWindow,
  COUNT(*) AS Total,
  SUM(NoShow) AS NoShowCount,
  ROUND(SUM(NoShow) * 100.0 / COUNT(*), 2) AS NoShowRate
FROM IRIS105_Domain.Appointment
GROUP BY CASE 
    WHEN BookingDaysInAdvance < 7 THEN '0-6 days'
    WHEN BookingDaysInAdvance < 14 THEN '7-13 days'
    ELSE '14+ days'
  END
ORDER BY NoShowRate DESC;
```

```sql
-- Impacto de recordatorio SMS
SELECT 
  HasSMSReminder,
  COUNT(*) AS Total,
  SUM(NoShow) AS NoShowCount,
  ROUND(SUM(NoShow) * 100.0 / COUNT(*), 2) AS NoShowRate
FROM IRIS105_Domain.Appointment
GROUP BY HasSMSReminder;
```

## 🛠️ Troubleshooting del Modelo

### Problema: Modelo no se encuentra

```sql
-- Verificar que existe
SELECT MODEL_NAME, STATUS 
FROM INFORMATION_SCHEMA.ML_MODELS
WHERE MODEL_NAME = 'NoShowModel2';
```

Si no existe, crearlo:
```sql
CREATE MODEL NoShowModel2 PREDICTING (NoShow) FROM IRIS105_Domain.Appointment;
```

### Problema: Modelo no entrenado

```sql
-- Verificar trained models
SELECT TRAINED_MODEL_NAME, TRAINING_STATUS
FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS
WHERE MODEL_NAME = 'NoShowModel2';
```

Si no hay ninguno o status != 'trained':
```sql
TRAIN MODEL NoShowModel2 USING {"MaxTime": 60};
```

### Problema: Scoring da error

**Error típico**: "Model not trained"

**Solución**:
```sql
-- Verificar modelo por defecto
SELECT MODEL_NAME, DEFAULT_TRAINED_MODEL_NAME
FROM INFORMATION_SCHEMA.ML_MODELS
WHERE MODEL_NAME = 'NoShowModel2';

-- Si DEFAULT_TRAINED_MODEL_NAME es NULL, entrenar
TRAIN MODEL NoShowModel2;
```

### Problema: Performance baja

Si el modelo tiene accuracy < 70%:

1. **Verificar calidad de datos**:
```sql
-- Revisar distribución de clases
SELECT NoShow, COUNT(*) 
FROM IRIS105_Domain.Appointment 
GROUP BY NoShow;
```

2. **Aumentar tiempo de entrenamiento**:
```sql
TRAIN MODEL NoShowModel2 USING {"MaxTime": 300};
```

3. **Revisar features nulas**:
```sql
SELECT 
  COUNT(*) AS Total,
  SUM(CASE WHEN HasSMSReminder IS NULL THEN 1 ELSE 0 END) AS NullReminder,
  SUM(CASE WHEN Reason IS NULL THEN 1 ELSE 0 END) AS NullReason
FROM IRIS105_Domain.Appointment;
```

## 📚 Comandos SQL de IntegratedML

### Gestión de Modelos

```sql
-- Crear modelo
CREATE MODEL <ModelName> PREDICTING (<TargetColumn>) FROM <Table>;

-- Entrenar modelo
TRAIN MODEL <ModelName> [USING {options}];

-- Validar modelo
VALIDATE MODEL <ModelName>;

-- Establecer modelo por defecto
SET MODEL <ModelName> DEFAULT TRAINED MODEL <TrainedModelName>;

-- Eliminar modelo
DROP MODEL <ModelName>;
```

### Uso de Modelos

```sql
-- Predicción
SELECT PREDICT(<ModelName>) FROM <Table>;

-- Probabilidad
SELECT PROBABILITY(<ModelName> FOR <value>) FROM <Table>;

-- Ambas
SELECT 
  PREDICT(<ModelName>) AS Label,
  PROBABILITY(<ModelName> FOR 1) AS Prob
FROM <Table>;
```

### Vistas de Sistema

```sql
-- Modelos disponibles
SELECT * FROM INFORMATION_SCHEMA.ML_MODELS;

-- Modelos entrenados
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS;

-- Runs de entrenamiento
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS;

-- Runs de validación
SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_RUNS;

-- Métricas
SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS;
```

## 🎓 Mejores Prácticas

1. **Balanceo de Clases**: Usar `"TrainMode": "BALANCE"` para datasets desbalanceados
2. **Reproducibilidad**: Usar `"seed"` fijo para entrenamiento reproducible
3. **Tiempo de Entrenamiento**: Empezar con 60s, aumentar si es necesario
4. **Validación**: SIEMPRE ejecutar VALIDATE después de TRAIN
5. **Monitoreo**: Revisar métricas regularmente
6. **Re-entrenamiento**: Planificar ciclo de re-entrenamiento (ej: mensual)
7. **Versionado**: Mantener registro de métricas por versión
8. **Testing**: Probar scoring en datos de prueba antes de producción

## 📖 Recursos Adicionales

- [IntegratedML Documentation](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIML)
- [AutoML Guide](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIML_automl)
- [SQL Functions Reference](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL)

---

**Ver también**:
- [API Reference](API-Reference) - Usar el modelo vía REST API
- [Development Guide](Development-Guide) - Integrar ML en tu código
