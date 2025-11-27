Class CUBO.BI.DimTiempo Extends (%Persistent, %Populate) [ Final ]
{

/// Clave de fecha en formato YYYYMMDD.
Property DateKey As %Integer;

/// Fecha calendaria.
Property Fecha As %Date;

Property Dia As %Integer;

Property Mes As %Integer;

Property Anio As %Integer;

Property Trimestre As %Integer;

Property Semana As %Integer;

Index idxDateKey On DateKey [ Unique ];

Storage Default
{
<Data name="DimTiempoDefaultData">
<Value name="1">
<Value>DateKey</Value>
</Value>
<Value name="2">
<Value>Fecha</Value>
</Value>
<Value name="3">
<Value>Dia</Value>
</Value>
<Value name="4">
<Value>Mes</Value>
</Value>
<Value name="5">
<Value>Anio</Value>
</Value>
<Value name="6">
<Value>Trimestre</Value>
</Value>
<Value name="7">
<Value>Semana</Value>
</Value>
</Data>
<DataLocation>^CUBO.BI.DimTiempoD</DataLocation>
<DefaultData>DimTiempoDefaultData</DefaultData>
<IdLocation>^CUBO.BI.DimTiempoD</IdLocation>
<IndexLocation>^CUBO.BI.DimTiempoI</IndexLocation>
<StreamLocation>^CUBO.BI.DimTiempoS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
