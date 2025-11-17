Class IRIS105.Physician Extends %Persistent
{

Property PhysicianId As %String(MAXLEN = 64);

Property FirstName As %String(MAXLEN = 128);

Property LastName As %String(MAXLEN = 128);

Property SpecialtyId As %String(MAXLEN = 64);

Property DefaultBoxId As %String(MAXLEN = 64);

Index PhysicianIdIndex On PhysicianId;

Storage Default
{
<Data name="PhysicianDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PhysicianId</Value>
</Value>
<Value name="3">
<Value>FirstName</Value>
</Value>
<Value name="4">
<Value>LastName</Value>
</Value>
<Value name="5">
<Value>SpecialtyId</Value>
</Value>
<Value name="6">
<Value>DefaultBoxId</Value>
</Value>
</Data>
<DataLocation>^IRIS105.PhysicianD</DataLocation>
<DefaultData>PhysicianDefaultData</DefaultData>
<IdLocation>^IRIS105.PhysicianD</IdLocation>
<IndexLocation>^IRIS105.PhysicianI</IndexLocation>
<StreamLocation>^IRIS105.PhysicianS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
