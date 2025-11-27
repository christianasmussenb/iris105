Class CUBO.BI.DimAseguradora Extends (%Persistent, %Populate) [ Final ]
{

Property AseguradoraID As %Integer;

Property Nombre As %String(MAXLEN = 200);

/// Fonasa / Isapre / EPS / otro.
Property Tipo As %String(MAXLEN = 50);

/// Publica / privada u otro criterio de segmento.
Property Segmento As %String(MAXLEN = 50);

Index idxAseguradoraID On AseguradoraID [ Unique ];

Storage Default
{
<Data name="DimAseguradoraDefaultData">
<Value name="1">
<Value>AseguradoraID</Value>
</Value>
<Value name="2">
<Value>Nombre</Value>
</Value>
<Value name="3">
<Value>Tipo</Value>
</Value>
<Value name="4">
<Value>Segmento</Value>
</Value>
</Data>
<DataLocation>^CUBO.BI.DimAseguradoraD</DataLocation>
<DefaultData>DimAseguradoraDefaultData</DefaultData>
<IdLocation>^CUBO.BI.DimAseguradoraD</IdLocation>
<IndexLocation>^CUBO.BI.DimAseguradoraI</IndexLocation>
<StreamLocation>^CUBO.BI.DimAseguradoraS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
