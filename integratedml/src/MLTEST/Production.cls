Class MLTEST.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="MLTEST.Production" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="MLTEST.BP.RecordToEpisode" Category="" ClassName="MLTEST.BP.RecordToEpisode" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="MLTEST.BP.RecordToEpisodeTrain" Category="" ClassName="MLTEST.BP.RecordToEpisodeTrain" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="CSVToEpisodeTrain" Category="" ClassName="EnsLib.RecordMap.Service.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordMap">IctusMap</Setting>
    <Setting Target="Adapter" Name="Charset">utf-8</Setting>
    <Setting Target="Adapter" Name="FilePath">/shared/csv/trainIn/</Setting>
    <Setting Target="Host" Name="TargetConfigNames">MLTEST.BP.RecordToEpisodeTrain</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.csv</Setting>
  </Item>
  <Item Name="CSVToEpisode" Category="" ClassName="EnsLib.RecordMap.Service.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordMap">IctusMap</Setting>
    <Setting Target="Adapter" Name="Charset">utf-8</Setting>
    <Setting Target="Adapter" Name="FilePath">/shared/csv/newIn/</Setting>
    <Setting Target="Host" Name="TargetConfigNames">MLTEST.BP.RecordToEpisode</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.csv</Setting>
  </Item>
  <Item Name="HL7ToEpisode" Category="" ClassName="EnsLib.HL7.Service.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="MessageSchemaCategory">2.5.1</Setting>
    <Setting Target="Adapter" Name="FilePath">/shared/hl7/in/</Setting>
    <Setting Target="Host" Name="TargetConfigNames">MLTEST.BP.RecordToEpisodeBPL</Setting>
    <Setting Target="Host" Name="DefCharEncoding">utf-8</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.hl7</Setting>
  </Item>
  <Item Name="MLTEST.BO.PredictStayEpisode" Category="" ClassName="MLTEST.BO.PredictStayEpisode" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="ModelName">StayModel</Setting>
  </Item>
  <Item Name="MLTEST.BP.RecordToEpisodeBPL" Category="" ClassName="MLTEST.BP.RecordToEpisodeBPL" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
</Production>
}

}
