
-- Plantilla IntegratedML + %AutoML para el modelo NoShowModel2
-- Ejecutar en namespace MLTEST

-- 1) Definición del modelo (versión oficial: NoShowModel2)
CREATE MODEL NoShowModel2
PREDICTING (NoShow)
WITH (
	PatientId INTEGER,
	PhysicianId INTEGER,
	BoxId INTEGER,
	SpecialtyId INTEGER,
	StartDateTime TIMESTAMP,
	BookingChannel VARCHAR(50),
	BookingDaysInAdvance INTEGER,
	HasSMSReminder BOOLEAN,
	Reason VARCHAR(200)
)
FROM IRIS105.Appointment;

-- (Opcional) Modelo base previo para comparar
-- CREATE MODEL NoShowModel ... (mismos campos)

-- 2) Entrenamiento (ejemplo de parámetros para %AutoML)
TRAIN MODEL NoShowModel2
USING {
	"seed": 42,
	"TrainMode": "BALANCE",
	"MaxTime": 60,
	"MinimumDesiredScore": 0.80
};

-- 3) Validación
VALIDATE MODEL NoShowModel2;

-- 4) Ejemplo de scoring directo en SQL con PREDICT/PROBABILITY
SELECT AppointmentId,
       PREDICT(NoShowModel2) AS PredictedLabel,
       PROBABILITY(NoShowModel2 FOR 1) AS NoShowProb
FROM IRIS105.Appointment
WHERE AppointmentId IN (1,2,3);

-- 5) Métricas y runs registrados
SELECT * FROM INFORMATION_SCHEMA.ML_MODELS WHERE MODEL_NAME='NoShowModel2';
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS WHERE MODEL_NAME='NoShowModel2';
SELECT * FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS WHERE MODEL_NAME='NoShowModel2';
SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_RUNS WHERE MODEL_NAME='NoShowModel2';
SELECT * FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS WHERE MODEL_NAME='NoShowModel2';

-- 4) Fijar como default (opcional)
-- ALTER MODEL NoShowModel2 SET DEFAULT;

-- Fin de integratedml_model.sql
