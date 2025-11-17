
-- Consultas de ejemplo para demo y pruebas

-- Obtener predicción por appointment
SELECT AppointmentId,
	   PREDICT(NoShowModel) AS NoShowProb
FROM IRIS105.Appointment
WHERE StartDateTime BETWEEN '2025-11-18' AND '2025-11-19';

-- Consultar resultados persistidos
SELECT * FROM IRIS105_AppointmentRisk
WHERE ScoredAt > CURRENT_TIMESTAMP - INTERVAL '7' DAY;

-- Consultar modelos y runs
SELECT * FROM INFORMATION_SCHEMA.ML_MODELS;
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS;

-- Fin de demo_queries.sql
