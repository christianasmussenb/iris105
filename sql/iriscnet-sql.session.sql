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
GO