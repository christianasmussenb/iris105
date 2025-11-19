Class IRIS105.REST.NoShowService Extends %CSP.REST
{

// ##Include %occErrors

Parameter DefaultModelName = "NoShowModel2";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/api/ml/noshow/score" Method="POST" Call="Score"/>
    <Route Url="/api/ml/stats/summary" Method="GET" Call="StatsSummary"/>
    <Route Url="/api/ml/mock/generate" Method="POST" Call="GenerateMock"/>
    <Route Url="/api/ml/stats/lastAppointmentByPatient" Method="GET" Call="LastAppointmentByPatient"/>
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

/// Devuelve la última cita de un paciente y su score
ClassMethod LastAppointmentByPatient() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set patientId = %request.Get("patientId")
        If patientId="" {
            Set tSC = $$$ERROR($$$GeneralError,"patientId is required")
            Quit
        }
        Set stmt = ##class(%SQL.Statement).%New()
        Do stmt.%Prepare("SELECT TOP 1 AppointmentId FROM IRIS105.Appointment WHERE PatientId=? ORDER BY StartDateTime DESC")
        Set rs = stmt.%Execute(patientId)
        If 'rs.%Next() {
            Set tSC = $$$ERROR($$$GeneralError,"No appointments found for patient "_patientId)
            Quit
        }
        Set apptId = rs.AppointmentId
        Set tSC = ..ScoreAppointment(apptId, .result)
        Quit:$$$ISERR(tSC)
        Do result.%Set("patientId", patientId)
        Do ..%SendJSON(result)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

ClassMethod ScoreAppointment(pAppointmentId, Output pResult As %DynamicObject) As %Status
{
    Quit ##class(IRIS105.Util.NoShowPredictor).ScoreAppointment(pAppointmentId, ..#DefaultModelName, "", .pResult)
}

/// Devuelve métricas básicas de las tablas y del modelo
ClassMethod StatsSummary() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set result = ##class(%DynamicObject).%New()
        Do ..%FillCounts(.result)
        Do ..%FillModelInfo(.result)
        Do ..%SendJSON(result)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Ejecuta la generación de datos mock (parámetros opcionales)
ClassMethod GenerateMock() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set request = ..%ReadJSONBody()
        If '$IsObject(request) {
            Set request = ##class(%DynamicObject).%New()
        }
        Set config = ##class(IRIS105.Util.MockConfig).GetDefault()
        If request.%IsDefined("months") {
            Do config.%Set("horizonMonths", request.%Get("months"))
        }
        If request.%IsDefined("targetOccupancy") {
            Do config.%Set("occupancyPct", request.%Get("targetOccupancy"))
        }
        If request.%IsDefined("seed") {
            Do config.%Set("seed", request.%Get("seed"))
        }
        If request.%IsDefined("patients") {
            Do config.%Set("patients", request.%Get("patients"))
        }
        Set out = ##class(IRIS105.Util.MockData).Generate(config)
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("status","ok")
        Do resp.%Set("result", out)
        Do ..%SendJSON(resp, 201)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

ClassMethod %FillCounts(ByRef pObj As %DynamicObject)
{
    Set q = "SELECT (SELECT COUNT(*) FROM IRIS105.Patient) AS Patients,"_ 
            " (SELECT COUNT(*) FROM IRIS105.Appointment) AS Appointments,"_
            " (SELECT COUNT(*) FROM IRIS105.AppointmentRisk) AS Scored,"_
            " (SELECT COALESCE(AVG(NoShow),0) FROM IRIS105.Appointment) AS NoShowRate"
    Set rs = ##class(%SQL.Statement).%ExecDirect(,q)
    If rs.%Next() {
        Do pObj.%Set("patients", rs.Patients)
        Do pObj.%Set("appointments", rs.Appointments)
        Do pObj.%Set("scoredAppointments", rs.Scored)
        Do pObj.%Set("noShowRate", rs.NoShowRate)
    }
}

ClassMethod %FillModelInfo(ByRef pObj As %DynamicObject)
{
    Set q = "SELECT DEFAULT_TRAINED_MODEL_NAME, STATUS"_ 
            " FROM INFORMATION_SCHEMA.ML_MODELS WHERE MODEL_NAME=?"
    Set stmt = ##class(%SQL.Statement).%New()
    Do stmt.%Prepare(q)
    Set rs = stmt.%Execute(..#DefaultModelName)
    If rs.%Next() {
        Do pObj.%Set("model", ..#DefaultModelName)
        Do pObj.%Set("defaultTrainedModel", rs.DEFAULT_TRAINED_MODEL_NAME)
        Do pObj.%Set("modelStatus", rs.STATUS)
    }
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
