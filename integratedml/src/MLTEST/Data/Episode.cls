Class MLTEST.Data.Episode Extends (%Persistent, %XML.Adaptor)
{

Property AdmissionDate As %TimeStamp;

Property DischargeDate As %TimeStamp;

Property AdmissionWeekDay As %Integer;

Property DischargeWeekDay As %Integer;

Property Hospital As %Integer;

Property Province As %Integer;

Property Age As %Integer;

Property Sex As %Integer;

Property Stay As %Float;

Property PredictedStay As %Float;

Storage Default
{
<Data name="EpisodeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AdmissionDate</Value>
</Value>
<Value name="3">
<Value>DischargeDate</Value>
</Value>
<Value name="4">
<Value>AdmissionWeekDay</Value>
</Value>
<Value name="5">
<Value>DischargeWeekDay</Value>
</Value>
<Value name="6">
<Value>Hospital</Value>
</Value>
<Value name="7">
<Value>Province</Value>
</Value>
<Value name="8">
<Value>Age</Value>
</Value>
<Value name="9">
<Value>Sex</Value>
</Value>
<Value name="10">
<Value>Stay</Value>
</Value>
<Value name="11">
<Value>PredictedStay</Value>
</Value>
</Data>
<DataLocation>^MLTEST.Data.EpisodeD</DataLocation>
<DefaultData>EpisodeDefaultData</DefaultData>
<IdLocation>^MLTEST.Data.EpisodeD</IdLocation>
<IndexLocation>^MLTEST.Data.EpisodeI</IndexLocation>
<StreamLocation>^MLTEST.Data.EpisodeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
