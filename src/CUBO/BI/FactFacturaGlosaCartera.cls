Class CUBO.BI.FactFacturaGlosaCartera Extends (%Persistent, %Populate) [ Final ]
{

Property FactID As %Integer [ Identity ];

Property FacturaNum As %String(MAXLEN = 50);

Property AseguradoraID As %Integer;

Property CentroID As %Integer;

Property PacienteID As %Integer;

Property EpisodioID As %Integer;

Property FechaFactura As %Date;

Property FechaRadicacion As %Date;

Property FechaGlosa As %Date;

Property FechaVencimiento As %Date;

Property FechaPago As %Date;

Property MontoFacturado As %Numeric(SCALE = 2);

Property MontoRadicado As %Numeric(SCALE = 2);

Property MontoAceptado As %Numeric(SCALE = 2);

Property MontoRechazado As %Numeric(SCALE = 2);

Property MontoRecuperado As %Numeric(SCALE = 2);

Property MontoGlosaInicial As %Numeric(SCALE = 2);

Property MontoGlosaFirmada As %Numeric(SCALE = 2);

Property MontoGlosaEnTramite As %Numeric(SCALE = 2);

Property NumGlosas As %Integer;

Property SaldoCartera As %Numeric(SCALE = 2);

Property DiasMora As %Integer;

Property DiasDesdeRadicacion As %Integer;

Property LineaNegocio As %String(MAXLEN = 80);

Property EstadoFactura As %String(MAXLEN = 50);

Property EstadoCartera As %String(MAXLEN = 50);

Property FuenteReporte As %String(MAXLEN = 20);

Index idxFactura On FacturaNum;

Index idxAseguradora On AseguradoraID;

Index idxCentro On CentroID;

Index idxFechaFactura On FechaFactura;

Storage Default
{
<Data name="FactFacturaGlosaCarteraDefaultData">
<Value name="1">
<Value>FacturaNum</Value>
</Value>
<Value name="2">
<Value>AseguradoraID</Value>
</Value>
<Value name="3">
<Value>CentroID</Value>
</Value>
<Value name="4">
<Value>PacienteID</Value>
</Value>
<Value name="5">
<Value>EpisodioID</Value>
</Value>
<Value name="6">
<Value>FechaFactura</Value>
</Value>
<Value name="7">
<Value>FechaRadicacion</Value>
</Value>
<Value name="8">
<Value>FechaGlosa</Value>
</Value>
<Value name="9">
<Value>FechaVencimiento</Value>
</Value>
<Value name="10">
<Value>FechaPago</Value>
</Value>
<Value name="11">
<Value>MontoFacturado</Value>
</Value>
<Value name="12">
<Value>MontoRadicado</Value>
</Value>
<Value name="13">
<Value>MontoAceptado</Value>
</Value>
<Value name="14">
<Value>MontoRechazado</Value>
</Value>
<Value name="15">
<Value>MontoRecuperado</Value>
</Value>
<Value name="16">
<Value>MontoGlosaInicial</Value>
</Value>
<Value name="17">
<Value>MontoGlosaFirmada</Value>
</Value>
<Value name="18">
<Value>MontoGlosaEnTramite</Value>
</Value>
<Value name="19">
<Value>NumGlosas</Value>
</Value>
<Value name="20">
<Value>SaldoCartera</Value>
</Value>
<Value name="21">
<Value>DiasMora</Value>
</Value>
<Value name="22">
<Value>DiasDesdeRadicacion</Value>
</Value>
<Value name="23">
<Value>LineaNegocio</Value>
</Value>
<Value name="24">
<Value>EstadoFactura</Value>
</Value>
<Value name="25">
<Value>EstadoCartera</Value>
</Value>
<Value name="26">
<Value>FuenteReporte</Value>
</Value>
</Data>
<DataLocation>^CUBO.BI.FactFactura8DBCD</DataLocation>
<DefaultData>FactFacturaGlosaCarteraDefaultData</DefaultData>
<IdLocation>^CUBO.BI.FactFactura8DBCD</IdLocation>
<IndexLocation>^CUBO.BI.FactFactura8DBCI</IndexLocation>
<StreamLocation>^CUBO.BI.FactFactura8DBCS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
