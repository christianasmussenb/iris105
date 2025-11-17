
-- SQL / DDL templates para el POC IRIS105
-- Nota: en IRIS normalmente se usan clases persistentes (%Persistent).
-- Estas sentencias son plantillas para crear tablas SQL si se usa SQL directo
-- o para documentar el esquema. Ajustar según entorno IRIS / IntegratedML.

CREATE TABLE IF NOT EXISTS IRIS105_Patient (
	PatientId VARCHAR(64) PRIMARY KEY,
	Run VARCHAR(64),
	FirstName VARCHAR(128),
	LastName VARCHAR(128),
	Sex CHAR(1),
	BirthDate DATE,
	PayerId VARCHAR(64),
	Region VARCHAR(128),
	SocioEconomicSegment VARCHAR(8)
);

CREATE TABLE IF NOT EXISTS IRIS105_Physician (
	PhysicianId VARCHAR(64) PRIMARY KEY,
	FirstName VARCHAR(128),
	LastName VARCHAR(128),
	SpecialtyId VARCHAR(64),
	DefaultBoxId VARCHAR(64)
);

CREATE TABLE IF NOT EXISTS IRIS105_Box (
	BoxId VARCHAR(64) PRIMARY KEY,
	Name VARCHAR(128),
	Location VARCHAR(128)
);

CREATE TABLE IF NOT EXISTS IRIS105_Specialty (
	SpecialtyId VARCHAR(64) PRIMARY KEY,
	Name VARCHAR(128)
);

CREATE TABLE IF NOT EXISTS IRIS105_Payer (
	PayerId VARCHAR(64) PRIMARY KEY,
	Name VARCHAR(128),
	Type VARCHAR(32)
);

CREATE TABLE IF NOT EXISTS IRIS105_Appointment (
	AppointmentId VARCHAR(64) PRIMARY KEY,
	PatientId VARCHAR(64),
	PhysicianId VARCHAR(64),
	BoxId VARCHAR(64),
	SpecialtyId VARCHAR(64),
	StartDateTime TIMESTAMP,
	EndDateTime TIMESTAMP,
	BookingChannel VARCHAR(32),
	BookingDaysInAdvance INTEGER,
	HasSMSReminder BOOLEAN,
	Reason VARCHAR(256),
	NoShow BOOLEAN
);

CREATE TABLE IF NOT EXISTS IRIS105_AppointmentRisk (
	AppointmentId VARCHAR(64) PRIMARY KEY,
	ScoredAt TIMESTAMP,
	NoShowProb DOUBLE,
	RiskLevel VARCHAR(16),
	ModelName VARCHAR(128),
	TrainedModelName VARCHAR(128)
);

-- Fin de create_tables.sql
