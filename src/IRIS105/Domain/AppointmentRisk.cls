Class IRIS105.AppointmentRisk Extends %Persistent
{

Property AppointmentId As %String(MAXLEN = 64);

Property ScoredAt As %TimeStamp;

Property NoShowProb As %Double;

Property RiskLevel As %String(MAXLEN = 16);

Property ModelName As %String(MAXLEN = 128);

Property TrainedModelName As %String(MAXLEN = 128);

Index AppointmentRiskByAppointment On AppointmentId [ Unique ];

Storage Default
{
<Data name="AppointmentRiskDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AppointmentId</Value>
</Value>
<Value name="3">
<Value>ScoredAt</Value>
</Value>
<Value name="4">
<Value>NoShowProb</Value>
</Value>
<Value name="5">
<Value>RiskLevel</Value>
</Value>
<Value name="6">
<Value>ModelName</Value>
</Value>
<Value name="7">
<Value>TrainedModelName</Value>
</Value>
</Data>
<DataLocation>^IRIS105.AppointmentRiskD</DataLocation>
<DefaultData>AppointmentRiskDefaultData</DefaultData>
<IdLocation>^IRIS105.AppointmentRiskD</IdLocation>
<IndexLocation>^IRIS105.AppointmentRiskI</IndexLocation>
<StreamLocation>^IRIS105.AppointmentRiskS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
