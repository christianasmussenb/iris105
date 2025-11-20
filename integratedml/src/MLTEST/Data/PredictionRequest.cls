Class MLTEST.Data.PredictionRequest Extends Ens.Request
{

Property EpisodeId As %Integer;

Storage Default
{
<Data name="PredictionRequestDefaultData">
<Subscript>"PredictionRequest"</Subscript>
<Value name="1">
<Value>EpisodeId</Value>
</Value>
</Data>
<DefaultData>PredictionRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
