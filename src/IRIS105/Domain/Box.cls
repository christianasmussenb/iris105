Class IRIS105.Box Extends %Persistent
{

Property BoxId As %String(MAXLEN = 64);

Property Name As %String(MAXLEN = 128);

Property Location As %String(MAXLEN = 128);

Index BoxIdIndex On BoxId;

Storage Default
{
<Data name="BoxDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BoxId</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Location</Value>
</Value>
</Data>
<DataLocation>^IRIS105.BoxD</DataLocation>
<DefaultData>BoxDefaultData</DefaultData>
<IdLocation>^IRIS105.BoxD</IdLocation>
<IndexLocation>^IRIS105.BoxI</IndexLocation>
<StreamLocation>^IRIS105.BoxS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
