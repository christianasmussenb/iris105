Class IRIS105.Patient Extends %Persistent
{

Property PatientId As %String(MAXLEN = 64);

Property Run As %String(MAXLEN = 64);

Property FirstName As %String(MAXLEN = 128);

Property LastName As %String(MAXLEN = 128);

Property Sex As %String(MAXLEN = 1);

Property BirthDate As %Date;

Property PayerId As %String(MAXLEN = 64);

Property Region As %String(MAXLEN = 128);

Property SocioEconomicSegment As %String(MAXLEN = 8);

Index PatientIdIndex On PatientId;

Storage Default
{
<Data name="PatientDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PatientId</Value>
</Value>
<Value name="3">
<Value>Run</Value>
</Value>
<Value name="4">
<Value>FirstName</Value>
</Value>
<Value name="5">
<Value>LastName</Value>
</Value>
<Value name="6">
<Value>Sex</Value>
</Value>
<Value name="7">
<Value>BirthDate</Value>
</Value>
<Value name="8">
<Value>PayerId</Value>
</Value>
<Value name="9">
<Value>Region</Value>
</Value>
<Value name="10">
<Value>SocioEconomicSegment</Value>
</Value>
</Data>
<DataLocation>^IRIS105.PatientD</DataLocation>
<DefaultData>PatientDefaultData</DefaultData>
<IdLocation>^IRIS105.PatientD</IdLocation>
<IndexLocation>^IRIS105.PatientI</IndexLocation>
<StreamLocation>^IRIS105.PatientS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
