Class IRIS105.Appointment Extends %Persistent
{

Property AppointmentId As %String(MAXLEN = 64);

Property PatientId As %String(MAXLEN = 64);

Property PhysicianId As %String(MAXLEN = 64);

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

Storage Default
{
<Data name="AppointmentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AppointmentId</Value>
</Value>
<Value name="3">
<Value>PatientId</Value>
</Value>
<Value name="4">
<Value>PhysicianId</Value>
</Value>
<Value name="5">
<Value>BoxId</Value>
</Value>
<Value name="6">
<Value>SpecialtyId</Value>
</Value>
<Value name="7">
<Value>StartDateTime</Value>
</Value>
<Value name="8">
<Value>EndDateTime</Value>
</Value>
<Value name="9">
<Value>BookingChannel</Value>
</Value>
<Value name="10">
<Value>BookingDaysInAdvance</Value>
</Value>
<Value name="11">
<Value>HasSMSReminder</Value>
</Value>
<Value name="12">
<Value>Reason</Value>
</Value>
<Value name="13">
<Value>NoShow</Value>
</Value>
</Data>
<DataLocation>^IRIS105.AppointmentD</DataLocation>
<DefaultData>AppointmentDefaultData</DefaultData>
<IdLocation>^IRIS105.AppointmentD</IdLocation>
<IndexLocation>^IRIS105.AppointmentI</IndexLocation>
<StreamLocation>^IRIS105.AppointmentS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
