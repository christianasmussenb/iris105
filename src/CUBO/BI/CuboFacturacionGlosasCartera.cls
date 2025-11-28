/// 
Class CUBO.BI.CuboFacturacionGlosasCartera Extends %DeepSee.CubeDefinition [ DependsOn = CUBO.BI.FactFacturaGlosaCartera ]
{

/// Cube definition from Architect.
XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
<cube xmlns="http://www.intersystems.com/deepsee" name="CuboFacturacionGlosasCartera" disabled="false" abstract="false" sourceClass="CUBO.BI.FactFacturaGlosaCartera" owner="_SYSTEM" caption="Facturación, Glosas y Cartera" namedFactNums="true" countMeasureName="%COUNT" bucketSize="8" bitmapChunkInMemory="false" precompute="0" disableListingGroups="false" enableSqlRestrict="false">
  <dimension name="Tiempo" disabled="false" hasAll="true" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="FechaFactura" disabled="false" hidden="false">
      <level name="Fecha" displayName="Fecha" disabled="false" sourceProperty="FechaFactura" factNumber="6" list="false" useDisplayValue="false" useAsFilter="true" hidden="false">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="Aseguradora" disabled="false" hasAll="true" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="Aseguradora" disabled="false" hidden="false">
      <level name="AseguradoraID" disabled="false" sourceProperty="AseguradoraID" factNumber="2" list="false" useDisplayValue="false" useAsFilter="true" hidden="false">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="Centro" disabled="false" hasAll="true" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="Centro" disabled="false" hidden="false">
      <level name="CentroID" disabled="false" sourceProperty="CentroID" factNumber="3" list="false" useDisplayValue="false" useAsFilter="true" hidden="false">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="EstadoFactura" disabled="false" hasAll="true" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="EstadoFactura" disabled="false" hidden="false">
      <level name="EstadoFactura" disabled="false" sourceProperty="EstadoFactura" factNumber="24" list="false" useDisplayValue="false" useAsFilter="true" hidden="false">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="EstadoCartera" disabled="false" hasAll="true" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="EstadoCartera" disabled="false" hidden="false">
      <level name="EstadoCartera" disabled="false" sourceProperty="EstadoCartera" factNumber="25" list="false" useDisplayValue="false" useAsFilter="true" hidden="false">
      </level>
    </hierarchy>
  </dimension>
  <dimension name="LineaNegocio" disabled="false" hasAll="true" type="data" hidden="false" showHierarchies="default">
    <hierarchy name="LineaNegocio" disabled="false" hidden="false">
      <level name="LineaNegocio" disabled="false" sourceProperty="LineaNegocio" factNumber="23" list="false" useDisplayValue="false" useAsFilter="true" hidden="false">
      </level>
    </hierarchy>
  </dimension>
  <measure name="TotalFacturado" disabled="false" sourceProperty="MontoFacturado" factNumber="11" hidden="false" searchable="false">
  </measure>
  <measure name="TotalRadicado" disabled="false" sourceProperty="MontoRadicado" factNumber="12" hidden="false" searchable="false">
  </measure>
  <measure name="TotalAceptado" disabled="false" sourceProperty="MontoAceptado" factNumber="13" hidden="false" searchable="false">
  </measure>
  <measure name="TotalRechazado" disabled="false" sourceProperty="MontoRechazado" factNumber="14" hidden="false" searchable="false">
  </measure>
  <measure name="TotalRecuperado" disabled="false" sourceProperty="MontoRecuperado" factNumber="15" hidden="false" searchable="false">
  </measure>
  <measure name="TotalGlosado" disabled="false" sourceProperty="MontoGlosaInicial" factNumber="16" hidden="false" searchable="false">
  </measure>
  <measure name="SaldoCartera" disabled="false" sourceProperty="SaldoCartera" factNumber="20" hidden="false" searchable="false">
  </measure>
  <measure name="DiasMoraPromedio" disabled="false" sourceProperty="DiasMora" factNumber="21" hidden="false" searchable="false">
  </measure>
</cube>
}

Parameter DOMAIN;

}
