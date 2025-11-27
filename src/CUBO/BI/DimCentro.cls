Class CUBO.BI.DimCentro Extends (%Persistent, %Populate) [ Final ]
{

Property CentroID As %Integer;

Property Nombre As %String(MAXLEN = 200);

Property TipoCentro As %String(MAXLEN = 50);

Property Ciudad As %String(MAXLEN = 100);

Property Region As %String(MAXLEN = 100);

Index idxCentroID On CentroID [ Unique ];

Storage Default
{
<Data name="DimCentroDefaultData">
<Value name="1">
<Value>CentroID</Value>
</Value>
<Value name="2">
<Value>Nombre</Value>
</Value>
<Value name="3">
<Value>TipoCentro</Value>
</Value>
<Value name="4">
<Value>Ciudad</Value>
</Value>
<Value name="5">
<Value>Region</Value>
</Value>
</Data>
<DataLocation>^CUBO.BI.DimCentroD</DataLocation>
<DefaultData>DimCentroDefaultData</DefaultData>
<IdLocation>^CUBO.BI.DimCentroD</IdLocation>
<IndexLocation>^CUBO.BI.DimCentroI</IndexLocation>
<StreamLocation>^CUBO.BI.DimCentroS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
