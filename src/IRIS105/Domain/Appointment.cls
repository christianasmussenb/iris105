Class IRIS105.Domain.Appointment Extends %RegisteredObject
{
}    Property PhysicianId As %String(MAXLEN = 64);
    Property BoxId As %String(MAXLEN = 64);
    Property SpecialtyId As %String(MAXLEN = 64);
    Property StartDateTime As %TimeStamp;
    Property EndDateTime As %TimeStamp;
    Property BookingChannel As %String(MAXLEN = 32);
    Property BookingDaysInAdvance As %Integer;
    Property HasSMSReminder As %Boolean;
    Property Reason As %String(MAXLEN = 256);
    Property NoShow As %Boolean;
    Index AppointmentIdIndex On AppointmentId;
    Index AppointmentByStart On StartDateTime;
}