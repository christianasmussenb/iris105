Class CUBO.BI.CuboFacturacionGlosasCartera Extends %DeepSee.CubeDefinition [ DependsOn = CUBO.BI.FactFacturaGlosaCartera ]
{

XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
<cube 
    name="CuboFacturacionGlosasCartera"
    caption="Facturación, Glosas y Cartera"
    owner="_SYSTEM"
    sourceClass="CUBO.BI.FactFacturaGlosaCartera"
    >

  <!-- Medidas base -->
  <measure name="TotalFacturado"   sourceProperty="MontoFacturado"/>
  <measure name="TotalRadicado"    sourceProperty="MontoRadicado"/>
  <measure name="TotalAceptado"    sourceProperty="MontoAceptado"/>
  <measure name="TotalRechazado"   sourceProperty="MontoRechazado"/>
  <measure name="TotalRecuperado"  sourceProperty="MontoRecuperado"/>
  <measure name="TotalGlosado"     sourceProperty="MontoGlosaInicial"/>
  <measure name="SaldoCartera"     sourceProperty="SaldoCartera"/>
  <measure name="DiasMoraPromedio" sourceProperty="DiasMora"/>

  <!-- Dimensión Tiempo basada en FechaFactura -->
  <dimension name="Tiempo">
    <hierarchy name="FechaFactura">
      <level name="Fecha" sourceProperty="FechaFactura" displayName="Fecha"/>
    </hierarchy>
  </dimension>

  <!-- Dimensión Aseguradora -->
  <dimension name="Aseguradora">
    <hierarchy name="Aseguradora">
      <level name="AseguradoraID" sourceProperty="AseguradoraID"/>
    </hierarchy>
  </dimension>

  <!-- Dimensión Centro -->
  <dimension name="Centro">
    <hierarchy name="Centro">
      <level name="CentroID" sourceProperty="CentroID"/>
    </hierarchy>
  </dimension>

  <!-- Estados de factura -->
  <dimension name="EstadoFactura">
    <hierarchy name="EstadoFactura">
      <level name="EstadoFactura" sourceProperty="EstadoFactura"/>
    </hierarchy>
  </dimension>

  <!-- Estados de cartera -->
  <dimension name="EstadoCartera">
    <hierarchy name="EstadoCartera">
      <level name="EstadoCartera" sourceProperty="EstadoCartera"/>
    </hierarchy>
  </dimension>

  <!-- Línea de negocio -->
  <dimension name="LineaNegocio">
    <hierarchy name="LineaNegocio">
      <level name="LineaNegocio" sourceProperty="LineaNegocio"/>
    </hierarchy>
  </dimension>

</cube>
}

}
