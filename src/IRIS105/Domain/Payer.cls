Class IRIS105.Payer Extends %Persistent
{

Property PayerId As %String(MAXLEN = 64);

Property Name As %String(MAXLEN = 128);

Property Type As %String(MAXLEN = 32);

Index PayerIdIndex On PayerId;

Storage Default
{
<Data name="PayerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PayerId</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Type</Value>
</Value>
</Data>
<DataLocation>^IRIS105.PayerD</DataLocation>
<DefaultData>PayerDefaultData</DefaultData>
<IdLocation>^IRIS105.PayerD</IdLocation>
<IndexLocation>^IRIS105.PayerI</IndexLocation>
<StreamLocation>^IRIS105.PayerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
