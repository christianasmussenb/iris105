# Guion corto de demo (NoShowModel2)

0) **Contexto**  
   - Namespace: `MLTEST`  
   - Modelo activo: `NoShowModel2`  
   - Endpoint REST: `POST /api/ml/noshow/score`

1) **Verificar que el modelo está disponible** (SQL)
```sql
SELECT MODEL_NAME, DEFAULT_TRAINED_MODEL_NAME, CREATE_TIMESTAMP
FROM INFORMATION_SCHEMA.ML_MODELS
WHERE MODEL_NAME='NoShowModel2';
```

2) **Ejecutar un scoring directo en SQL** (uso de `PREDICT` + `PROBABILITY`)
```sql
SELECT AppointmentId,
       PREDICT(NoShowModel2) AS PredictedLabel,
       PROBABILITY(NoShowModel2 FOR 1) AS NoShowProb
FROM IRIS105.Appointment
WHERE AppointmentId IN (1,2,3);
```

3) **Consumir la API desde la terminal** (cita existente)
```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":123}'
```

4) **Consumir la API con payload ad-hoc** (para integrarlo en una página web sin persistir la cita)
```bash
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
```

5) **Ver estadísticas rápidas del dataset y del modelo**
```bash
curl http://localhost:52773/csp/mltest/api/ml/stats/summary
```

6) **Generar datos mock adicionales**
```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/mock/generate \
  -H "Content-Type: application/json" \
  -d '{"months":3,"targetOccupancy":0.85,"patients":200,"clearBeforeGenerate":1,"specialtyNoShowRates":{"SPEC-1":0.12,"SPEC-2":0.20,"SPEC-3":0.08}}'
```

7) **Validar restricciones horarias de agenda (SQL)**
```sql
SELECT COUNT(*) AS Total,
       SUM(CASE WHEN DATEPART('weekday',CAST(StartDateTime AS DATE))=1 THEN 1 ELSE 0 END) AS SundayRows,
       SUM(CASE WHEN DATEPART('weekday',CAST(StartDateTime AS DATE))=7
                 AND (DATEPART('hour',StartDateTime)<9 OR DATEPART('hour',StartDateTime)>=14)
                THEN 1 ELSE 0 END) AS SaturdayOut,
       SUM(CASE WHEN DATEPART('weekday',CAST(StartDateTime AS DATE)) BETWEEN 2 AND 6
                 AND (DATEPART('hour',StartDateTime)<8 OR DATEPART('hour',StartDateTime)>=18)
                THEN 1 ELSE 0 END) AS WeekdayOut
FROM IRIS105.Appointment;
```
Esperado: `SundayRows=0`, `SaturdayOut=0`, `WeekdayOut=0`.

8) **Validar NoShow por especialidad (SQL)**
```sql
SELECT A.SpecialtyId,
       COUNT(*) AS Total,
       SUM(CASE WHEN A.NoShow=1 THEN 1 ELSE 0 END) AS NoShowCount,
       CAST(SUM(CASE WHEN A.NoShow=1 THEN 1 ELSE 0 END) AS DECIMAL(18,6))/NULLIF(COUNT(*),0) AS NoShowRate
FROM IRIS105.Appointment A
GROUP BY A.SpecialtyId
ORDER BY A.SpecialtyId;
```
Comparar con objetivos del payload (`SPEC-1=0.12`, `SPEC-2=0.20`, `SPEC-3=0.08`).

9) **Calcular NoShow de la última cita de un paciente**
```bash
curl "http://localhost:52773/csp/mltest/api/ml/stats/lastAppointmentByPatient?patientId=1"
```

10) **Interpretar la respuesta**
- `predictedLabel`: salida de `PREDICT(...)`, 1 indica No-Show.
- `probability`: salida de `PROBABILITY(... FOR 1)`, probabilidad de No-Show.
- `scoredAt`: timestamp servido por IRIS.

11) **UI sencilla en IRIS CSP**
- Página recomendada: `http://localhost:52773/csp/mltest2/GCSP.Basic.cls`
- Base API en la pantalla: `/csp/mltest`
- Botones para: ver estadísticas, score por `appointmentId`, score por último `patientId`, generar mock data rápido.
- Incluye sección "Entrenamiento SQL (paso a paso)" con botones 1..6 y `Submit` para ejecutar cada paso.
- En "Generar datos mock" se puede cargar JSON de `NoShow por especialidad` y elegir si se limpia la base antes de regenerar.
