# Guion corto de demo (NoShowModel2)

0) **Contexto**  
   - Namespace: `MLTEST`  
   - Modelo activo: `NoShowModel2`  
   - Endpoint REST: `POST /api/ml/noshow/score`

1) **Verificar que el modelo está disponible** (SQL)
```sql
SELECT MODEL_NAME, DEFAULT_TRAINED_MODEL_NAME, STATUS
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
  -d '{"months":3,"targetOccupancy":0.85,"patients":200}'
```

7) **Calcular NoShow de la última cita de un paciente**
```bash
curl "http://localhost:52773/csp/mltest/api/ml/stats/lastAppointmentByPatient?patientId=1"
```

8) **Interpretar la respuesta**
- `predictedLabel`: salida de `PREDICT(...)`, 1 indica No-Show.
- `probability`: salida de `PROBABILITY(... FOR 1)`, probabilidad de No-Show.
- `scoredAt`: timestamp servido por IRIS.

9) **UI sencilla en IRIS CSP**
- Página: `http://localhost:52773/csp/mltest/GCSP.Basic.cls`
- Botones para: ver estadísticas, score por `appointmentId`, score por último `patientId`, generar mock data rápido.
