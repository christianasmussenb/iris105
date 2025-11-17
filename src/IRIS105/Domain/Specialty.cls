Class IRIS105.Specialty Extends %Persistent
{

Property SpecialtyId As %String(MAXLEN = 64);

Property Name As %String(MAXLEN = 128);

Index SpecialtyIdIndex On SpecialtyId;

Storage Default
{
<Data name="SpecialtyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SpecialtyId</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^IRIS105.SpecialtyD</DataLocation>
<DefaultData>SpecialtyDefaultData</DefaultData>
<IdLocation>^IRIS105.SpecialtyD</IdLocation>
<IndexLocation>^IRIS105.SpecialtyI</IndexLocation>
<StreamLocation>^IRIS105.SpecialtyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
