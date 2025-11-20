Class MLTEST.BP.RecordToEpisode Extends Ens.BusinessProcess
{

/// Description
Method OnRequest(pRequest As User.IctusMap.Record, pResponse As MLTEST.Data.Episode) As %Status
{
        Set newEpisode = ##class("MLTEST.Data.Episode").%New()
        Set newEpisode.Age = pRequest.Edad
        Set newEpisode.AdmissionWeekDay = ^Ens.LookupTable("Day",pRequest.DiaSemanaIngreso)
        Set newEpisode.DischargeWeekDay = ^Ens.LookupTable("Day",pRequest.DiaSemanaAlta)
        Set newEpisode.Hospital = ^Ens.LookupTable("Hospital",pRequest.Hospital)
        Set newEpisode.Sex = ^Ens.LookupTable("Sex",pRequest.Sexo)
        Set newEpisode.Province = ^Ens.LookupTable("Province",pRequest.Provincia)
        
        Set horologAdmission = $ZDATETIMEH(pRequest.FechaIngreso,3,5)
        Set horologDischarge = $ZDATETIMEH(pRequest.FechaAlta,3,5)

        Set newEpisode.AdmissionDate = ##class("%Library.UTC").ConvertHorologToTimeStamp(horologAdmission)
        Set daysOfStay = ##class("%Library.UTC").Diff(##class("%Library.UTC").ConvertHorologToTimeStamp(horologDischarge), newEpisode.AdmissionDate)/86400
        Set newEpisode.Stay = daysOfStay\1+''(daysOfStay#1)

        set sc = newEpisode.%Save()
        set pResponse = newEpisode
        Return sc
}

Storage Default
{
<Data name="RecordToEpisodeDefaultData">
<Subscript>"RecordToEpisode"</Subscript>
<Value name="1">
<Value>ModelName</Value>
</Value>
</Data>
<DefaultData>RecordToEpisodeDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
