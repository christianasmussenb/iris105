
-- Plantilla IntegratedML + %AutoML para el modelo NoShow
-- Ejecutar en namespace MLTEST

CREATE MODEL NoShowModel
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

-- 2) Entrenamiento (ejemplo de parámetros para %AutoML)
TRAIN MODEL NoShowModel
USING {
	"seed": 42,
	"TrainMode": "BALANCE",
	"MaxTime": 60,
	"MinimumDesiredScore": 0.80
};

TRAIN MODEL NoShowModel2 FROM IRIS105.Appointment
USING {
	"seed": 42,
	"TrainMode": "BALANCE",
	"MaxTime": 60,
	"MinimumDesiredScore": 0.80
}

-- 3) Validación
VALIDATE MODEL NoShowModel;

select * from
/*INFORMATION_SCHEMA.ML_MODELS*/
/*INFORMATION_SCHEMA.ML_TRAINED_MODELS*/
/*INFORMATION_SCHEMA.ML_TRAINING_RUNS*/
/*INFORMATION_SCHEMA.ML_VALIDATION_RUNS*/
INFORMATION_SCHEMA.ML_VALIDATION_METRICS 

-- 4) Fijar como default (opcional)
-- ALTER MODEL NoShowModel SET DEFAULT;

-- Fin de integratedml_model.sql
