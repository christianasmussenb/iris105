
-- Plantilla IntegratedML + %AutoML para el modelo NoShow
-- Ejecutar en namespace MLTEST

-- 1) Definición del modelo (ejemplo)
CREATE MODEL NoShowModel
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

-- 2) Entrenamiento (ejemplo de parámetros para %AutoML)
TRAIN MODEL NoShowModel
USING {
	"seed": 42,
	"TrainMode": "BALANCE",
	"MaxTime": 60,
	"MinimumDesiredScore": 0.80
};

-- 3) Validación
VALIDATE MODEL NoShowModel;

-- 4) Fijar como default (opcional)
-- ALTER MODEL NoShowModel SET DEFAULT;

-- Fin de integratedml_model.sql
