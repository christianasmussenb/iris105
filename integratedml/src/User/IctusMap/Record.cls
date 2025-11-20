/// THIS IS GENERATED CODE. DO NOT EDIT.<br/>
/// RECORDMAP: Generated from RecordMap 'User.IctusMap'
/// on 2023-06-19 at 09:14:24.966 [2023-06-19 09:14:24.966 UTC]
/// by user SuperUser
Class User.IctusMap.Record Extends (%Persistent, %XML.Adaptor, Ens.Request, EnsLib.RecordMap.Base) [ Inheritance = right, ProcedureBlock ]
{

Parameter INCLUDETOPFIELDS = 1;

Property FechaIngreso As %String;

Property FechaAlta As %String;

Property DiaSemanaIngreso As %String;

Property DiaSemanaAlta As %String;

Property ZonaBasica As %String;

Property Ambito As %String;

Property Hospital As %String;

Property Area As %String;

Property Provincia As %String;

Property Edad As %String;

Property Sexo As %String;

Parameter RECORDMAPGENERATED = 1;

Storage Default
{
<Data name="RecordDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>FechaIngreso</Value>
</Value>
<Value name="3">
<Value>%Source</Value>
</Value>
<Value name="4">
<Value>DiaSemanaIngreso</Value>
</Value>
<Value name="5">
<Value>DiaSemanaAlta</Value>
</Value>
<Value name="6">
<Value>ZonaBasica</Value>
</Value>
<Value name="7">
<Value>Ambito</Value>
</Value>
<Value name="8">
<Value>Hospital</Value>
</Value>
<Value name="9">
<Value>Area</Value>
</Value>
<Value name="10">
<Value>Provincia</Value>
</Value>
<Value name="11">
<Value>Edad</Value>
</Value>
<Value name="12">
<Value>Sexo</Value>
</Value>
<Value name="13">
<Value>FechaAlta</Value>
</Value>
</Data>
<DataLocation>^User.IctusMap.RecordD</DataLocation>
<DefaultData>RecordDefaultData</DefaultData>
<ExtentSize>2000000</ExtentSize>
<IdLocation>^User.IctusMap.RecordD</IdLocation>
<IndexLocation>^User.IctusMap.RecordI</IndexLocation>
<StreamLocation>^User.IctusMap.RecordS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
