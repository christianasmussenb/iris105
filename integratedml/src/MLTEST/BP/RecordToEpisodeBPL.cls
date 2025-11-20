/// 
Class MLTEST.BP.RecordToEpisodeBPL Extends Ens.BusinessProcessBPL
{

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='User.IctusMap.Record' response='MLTEST.Data.Episode' height='2000' width='2000' >
<context>
<property name='episode' type='MLTEST.Data.Episode' instantiate='1' />
<property name='prediction' type='%String' instantiate='0' >
<parameters>
<parameter name='MAXLEN'  value='50' />
</parameters>
</property>
<property name='predictionRequest' type='MLTEST.Data.PredictionRequest' instantiate='1' />
</context>
<sequence xend='200' yend='650' >
<transform name='ADT^A01 to Episode' class='MLTEST.A01ToEpisodeDTL' source='request' target='context.episode' xpos='200' ypos='250' />
<assign name="Create prediction request" property="context.predictionRequest.EpisodeId" value="context.episode.%Id()" action="set" xpos='200' ypos='350' />
<call name='Calculate stay' target='MLTEST.BO.PredictStayEpisode' async='0' xpos='200' ypos='450' >
<request type='MLTEST.Data.PredictionRequest' >
<assign property="callrequest" value="context.predictionRequest" action="set" />
</request>
<response type='MLTEST.Data.PredictionResponse' >
<assign property="context.prediction" value="callresponse.PredictedStay" action="set" />
</response>
</call>
<trace name='Write trace with prediction' value='"Predicted stay = "_context.prediction' xpos='200' ypos='550' />
</sequence>
</process>
}

}
