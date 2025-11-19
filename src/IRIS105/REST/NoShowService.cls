Class IRIS105.REST.NoShowService Extends %CSP.REST
{

// ##Include %occErrors

Parameter DefaultModelName = "NoShowModel2";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/api/ml/noshow/score" Method="POST" Call="Score"/>
</Routes>
}

ClassMethod Score() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set request = ..%ReadJSONBody()
        If '$IsObject(request) {
            Set request = ##class(%DynamicObject).%New()
        }
        
        Set modelName = ..#DefaultModelName
        If request.%IsDefined("modelName") {
            Set modelName = request.%Get("modelName")
        }
        
        Set trainedModelName = ""
        If request.%IsDefined("trainedModelName") {
            Set trainedModelName = request.%Get("trainedModelName")
        }
        
        If request.%IsDefined("appointmentId") {
            Set appointmentId = request.%Get("appointmentId")
            Set tSC = ##class(IRIS105.Util.NoShowPredictor).ScoreAppointment(appointmentId, modelName, trainedModelName, .result)
        } ElseIf request.%IsDefined("features") {
            Set payload = request.%Get("features")
            If '$IsObject(payload) {
                Set tSC = $$$ERROR($$$GeneralError,"The 'features' property must be a JSON object")
            } Else {
                Set tSC = ##class(IRIS105.Util.NoShowPredictor).ScorePayload(payload, modelName, trainedModelName, .result)
            }
        } Else {
            Set tSC = $$$ERROR($$$GeneralError,"Provide either 'appointmentId' or a 'features' object in the request body")
        }
        Quit:$$$ISERR(tSC)
        
        Do ..%SendJSON(result)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

ClassMethod %ReadJSONBody() As %DynamicObject [ ProcedureBlock = 1 ]
{
    If '$IsObject(%request.Content) {
        Quit ##class(%DynamicObject).%New()
    }
    Do %request.Content.Rewind()
    Set json = ""
    While '%request.Content.AtEnd {
        Set json = json_%request.Content.Read(32000)
    }
    If json="" {
        Quit ##class(%DynamicObject).%New()
    }
    Quit ##class(%DynamicObject).%FromJSON(json)
}

ClassMethod %SendJSON(pObj As %DynamicObject, pStatusCode As %Integer = 200) [ ProcedureBlock = 1 ]
{
    Set %response.Status = pStatusCode
    Set %response.ContentType = "application/json"
    If '$IsObject(pObj) {
        Set pObj = ##class(%DynamicObject).%New()
    }
    Write pObj.%ToJSON()
}

ClassMethod %HandleError(pStatus As %Status) [ ProcedureBlock = 1 ]
{
    #dim error As %DynamicObject
    Set error = ##class(%DynamicObject).%New()
    Do error.%Set("error", 1)
    Do error.%Set("message", $System.Status.GetErrorText(pStatus))
    Do ..%SendJSON(error, 400)
}

}
