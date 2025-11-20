Class MLTEST.Data.PredictionResponse Extends Ens.Response
{

Property PredictedStay As %String;

Property EpisodeId As %Integer;

Storage Default
{
<Data name="PredictionResponseDefaultData">
<Subscript>"PredictionResponse"</Subscript>
<Value name="1">
<Value>PredictedStay</Value>
</Value>
<Value name="2">
<Value>EpisodeId</Value>
</Value>
</Data>
<DefaultData>PredictionResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
