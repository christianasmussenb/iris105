Class IRIS105.Domain.AppointmentRisk Extends %RegisteredObject
{
}    Property NoShowProb As %Double;
    Property RiskLevel As %String(MAXLEN = 16);
    Property ModelName As %String(MAXLEN = 128);
    Property TrainedModelName As %String(MAXLEN = 128);
    Index AppointmentRiskByAppointment On AppointmentId;
}