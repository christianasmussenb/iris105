Include %occErrors

Class IRIS105.REST.NoShowService Extends %CSP.REST
{

Parameter DefaultModelName = "NoShowModel2";

/// Validacion simple de Bearer token contra un Global
ClassMethod OnPreDispatch() As %Status [ ProcedureBlock = 1, ServerOnly = 1 ]
{
    Set tSC = $$$OK
    Try {
        // Allow unauthenticated health check
        Set uri = $Get(%request.CgiEnvs("REQUEST_URI"))
        If (uri["/api/health") {
            Set tSC = $$$OK
            Quit
        }
        Set hdr = %request.GetCgiEnv("HTTP_AUTHORIZATION")
        Set token = ""
        If $Extract(hdr,1,7)="Bearer " {
            Set token = $Extract(hdr,8,*)
        }
        If token="" {
            Do ..%SendAuthError("Missing bearer token")
            Set tSC = $$$ERROR($$$GeneralError,"Missing bearer token")
            Quit
        }
        If '$Data(^IRIS105("API","Tokens",token)) {
            Do ..%SendAuthError("Invalid token")
            Set tSC = $$$ERROR($$$GeneralError,"Invalid token")
            Quit
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/api/ml/noshow/score" Method="POST" Call="Score"/>
    <Route Url="/api/ml/stats/summary" Method="GET" Call="StatsSummary"/>
    <Route Url="/api/ml/stats/model" Method="GET" Call="ModelDetails"/>
    <Route Url="/api/ml/mock/generate" Method="POST" Call="GenerateMock"/>
    <Route Url="/api/ml/stats/lastAppointmentByPatient" Method="GET" Call="LastAppointmentByPatient"/>
    <Route Url="/api/health" Method="GET" Call="Health"/>
    <Route Url="/api/ml/analytics/busiest-day" Method="GET" Call="BusiestDay"/>
    <Route Url="/api/ml/analytics/top-specialties" Method="GET" Call="TopSpecialties"/>
    <Route Url="/api/ml/analytics/top-physicians" Method="GET" Call="TopPhysicians"/>
    <Route Url="/api/ml/analytics/top-noshow" Method="GET" Call="TopNoShow"/>
    <Route Url="/api/ml/analytics/occupancy-weekly" Method="GET" Call="OccupancyWeekly"/>
    <Route Url="/api/ml/analytics/scheduled-patients" Method="GET" Call="ScheduledPatients"/>
    <Route Url="/api/ml/analytics/occupancy-trend" Method="GET" Call="OccupancyTrend"/>
    <Route Url="/api/ml/appointments/active" Method="GET" Call="ActiveAppointments"/>
    <Route Url="/api/ml/config/capacity" Method="GET" Call="CapacityConfig"/>
    <Route Url="/api/ml/config/capacity" Method="POST" Call="CapacityConfig"/>
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

/// Devuelve detalles del modelo y sus runs (MODELS, TRAINED_MODELS, TRAINING_RUNS, VALIDATION_RUNS, VALIDATION_METRICS)
ClassMethod ModelDetails() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set model = ..#DefaultModelName
        If %request.Get("modelName")'="" {
            Set model = %request.Get("modelName")
        }
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("modelName", model)
        Do resp.%Set("models", ..%SelectToArray(
            "SELECT MODEL_NAME, DESCRIPTION, PREDICTING, PREDICTING_TYPE, FEATURE_LIST, CREATED_AT, DEFAULT_TRAINED_MODEL_NAME, DEFAULT_TRAINED_MODEL_ALGORITHM, MODEL_SQL FROM INFORMATION_SCHEMA.ML_MODELS WHERE MODEL_NAME=?",
            "modelName,description,predicting,predictingType,featureList,createdAt,defaultTrainedModelName,defaultTrainedModelAlgorithm,modelSQL",
            model))
        Do resp.%Set("trainedModels", ..%SelectToArray(
            "SELECT MODEL_INFO, MODEL_NAME, MODEL_TYPE, PROVIDER, TRAINED_MODEL_NAME, TRAINED_TIMESTAMP FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS WHERE MODEL_NAME=?",
            "modelInfo,modelName,modelType,provider,trainedModelName,trainedTimestamp",
            model))
        Do resp.%Set("trainingRuns", ..%SelectToArray(
            "SELECT COMPLETED_TIMESTAMP, LOG, ML_CONFIGURATION_NAME, MODEL_NAME, PROVIDER, RUN_STATUS, SETTINGS, START_TIMESTAMP, STATUS_CODE, TRAINING_DURATION, TRAINING_RUN_NAME, TRAINING_RUN_QUERY FROM INFORMATION_SCHEMA.ML_TRAINING_RUNS WHERE MODEL_NAME=?",
            "completedTimestamp,log,mlConfigurationName,modelName,provider,runStatus,settings,startTimestamp,statusCode,trainingDuration,trainingRunName,trainingRunQuery",
            model))
        Do resp.%Set("validationRuns", ..%SelectToArray(
            "SELECT COMPLETED_TIMESTAMP, LOG, MODEL_NAME, RUN_STATUS, SETTINGS, START_TIMESTAMP, STATUS_CODE, TRAINED_MODEL_NAME, VALIDATION_DURATION, VALIDATION_RUN_NAME, VALIDATION_RUN_QUERY FROM INFORMATION_SCHEMA.ML_VALIDATION_RUNS WHERE MODEL_NAME=?",
            "completedTimestamp,log,modelName,runStatus,settings,startTimestamp,statusCode,trainedModelName,validationDuration,validationRunName,validationRunQuery",
            model))
        Do resp.%Set("validationMetrics", ..%SelectToArray(
            "SELECT METRIC_NAME, METRIC_VALUE, MODEL_NAME, TARGET_VALUE, TRAINED_MODEL_NAME, VALIDATION_RUN_NAME FROM INFORMATION_SCHEMA.ML_VALIDATION_METRICS WHERE MODEL_NAME=?",
            "metricName,metricValue,modelName,targetValue,trainedModelName,validationRunName",
            model))
        Do ..%SendJSON(resp)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Devuelve la ultima cita de un paciente y su score
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

/// Devuelve metricas basicas de las tablas y del modelo
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

/// Ejecuta la generacion de datos mock (parametros opcionales)
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
            " (SELECT COALESCE(AVG(NoShow),0) FROM IRIS105.Appointment) AS NoShowRate,"_
            " (SELECT COUNT(*) FROM IRIS105.Box) AS Boxes,"_
            " (SELECT COUNT(*) FROM IRIS105.Physician) AS Physicians,"_
            " (SELECT COUNT(*) FROM IRIS105.Specialty) AS Specialties"
    Set rs = ##class(%SQL.Statement).%ExecDirect(,q)
    If rs.%Next() {
        Do pObj.%Set("patients", rs.Patients)
        Do pObj.%Set("appointments", rs.Appointments)
        Do pObj.%Set("scoredAppointments", rs.Scored)
        Do pObj.%Set("noShowRate", rs.NoShowRate)
        Do pObj.%Set("boxes", rs.Boxes)
        Do pObj.%Set("physicians", rs.Physicians)
        Do pObj.%Set("specialties", rs.Specialties)
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
        Do pObj.%Set("defaultTrainedModel", rs.%Get("DEFAULT_TRAINED_MODEL_NAME"))
        Do pObj.%Set("modelStatus", rs.%Get("STATUS"))
    }
}

ClassMethod %SelectToArray(pSQL As %String, pAliases As %String, pModel As %String = "") As %DynamicArray
{
    Set arr = ##class(%DynamicArray).%New()
    Set stmt = ##class(%SQL.Statement).%New()
    Set sc = stmt.%Prepare(pSQL)
    If $$$ISERR(sc) Quit arr
    If pModel'="" {
        Set rs = stmt.%Execute(pModel)
    } Else {
        Set rs = stmt.%Execute()
    }
    If '$IsObject(rs) Quit arr
    Set aliasCount = $L(pAliases,",")
    While rs.%Next() {
        Set row = ##class(%DynamicObject).%New()
        For i=1:1:aliasCount {
            Set alias = $Piece(pAliases,",",i)
            If alias="" Set alias="COL"_i
            Do row.%Set(alias, rs.%GetData(i))
        }
        Do arr.%Push(row)
    }
    Quit arr
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

ClassMethod %SendSQLError(pStatus As %Status, pDetail As %String = "") [ ProcedureBlock = 1 ]
{
    Set obj = ##class(%DynamicObject).%New()
    Do obj.%Set("error", 1)
    Do obj.%Set("message", $System.Status.GetErrorText(pStatus))
    If pDetail'="" Do obj.%Set("detail", pDetail)
    Do ..%SendJSON(obj, 400)
}

ClassMethod %SendAuthError(pMessage As %String) [ ProcedureBlock = 1 ]
{
    Set %response.Status = 401
    Set %response.ContentType = "application/json"
    Set obj = ##class(%DynamicObject).%New()
    Do obj.%Set("error", 1)
    Do obj.%Set("message", pMessage)
    Write obj.%ToJSON()
}

/// Dia con mas citas agendadas
ClassMethod BusiestDay() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set sql = "SELECT TOP 1 TO_CHAR(StartDateTime,'YYYY-MM-DD') AS DayDate,"_
                  " COUNT(*) AS Appointments"_ 
                  " FROM IRIS105.Appointment"_ 
                  " GROUP BY TO_CHAR(StartDateTime,'YYYY-MM-DD')"_ 
                  " ORDER BY Appointments DESC, DayDate DESC"
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        Set rs = stmt.%Execute()
        Set resp = ##class(%DynamicObject).%New()
        If rs.%Next() {
            Do resp.%Set("date", rs.%Get("DayDate"))
            Do resp.%Set("dayOfWeek", "")
            Do resp.%Set("appointments", rs.%Get("Appointments"))
        } Else {
            Do resp.%Set("date","")
            Do resp.%Set("dayOfWeek","")
            Do resp.%Set("appointments",0)
        }
        Do ..%SendJSON(resp)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Especialidades con mas citas (y no-show)
ClassMethod TopSpecialties() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set limit = ..%GetLimit(5)
        Set sql = "SELECT TOP "_limit_" A.SpecialtyId AS specialtyId, COALESCE(S.Name,'') AS name,"_
                  " COUNT(*) AS appointments,"_
                  " SUM(CASE WHEN A.NoShow=1 THEN 1 ELSE 0 END) AS noShow"_ 
                  " FROM IRIS105.Appointment A"_ 
                  " LEFT JOIN IRIS105.Specialty S ON A.SpecialtyId = S.SpecialtyId"_ 
                  " GROUP BY A.SpecialtyId, S.Name"_ 
                  " ORDER BY appointments DESC"
        Set arr = ..%SelectToArray(sql,"specialtyId,name,appointments,noShow")
        Set out = ##class(%DynamicObject).%New()
        Do out.%Set("items", arr)
        Do ..%SendJSON(out)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Medicos con mas citas (y no-show)
ClassMethod TopPhysicians() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set limit = ..%GetLimit(5)
        Set sql = "SELECT TOP "_limit_" A.PhysicianId AS physicianId,"_
                  " COALESCE(P.FirstName||' '||P.LastName,'') AS name,"_
                  " COUNT(*) AS appointments,"_
                  " SUM(CASE WHEN A.NoShow=1 THEN 1 ELSE 0 END) AS noShow"_ 
                  " FROM IRIS105.Appointment A"_ 
                  " LEFT JOIN IRIS105.Physician P ON A.PhysicianId = P.PhysicianId"_ 
                  " GROUP BY A.PhysicianId, P.FirstName, P.LastName"_ 
                  " ORDER BY appointments DESC"
        Set arr = ..%SelectToArray(sql,"physicianId,name,appointments,noShow")
        Set out = ##class(%DynamicObject).%New()
        Do out.%Set("items", arr)
        Do ..%SendJSON(out)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Ranking de no-show por especialidad o medico
ClassMethod TopNoShow() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set debug = ##class(%DynamicArray).%New()
        Do debug.%Push("step=start")
        Set rawBy = ..%QueryParam("by")
        Set by = $ZCONVERT(rawBy,"L")
        If (by'="physician")&&(by'="specialty") Set by = "specialty"
        Do debug.%Push("step=by value="_by)
        Set limit = ..%GetLimit(5)
        Do debug.%Push("step=limit value="_limit)
        If by="physician" {
            Set sql = "SELECT A.PhysicianId AS id,"_
                      " COALESCE(P.FirstName||' '||P.LastName,'') AS name,"_
                      " COUNT(*) AS appointments,"_
                      " SUM(CASE WHEN A.NoShow=1 THEN 1 ELSE 0 END) AS noShow"_ 
                      " FROM IRIS105.Appointment A"_ 
                      " LEFT JOIN IRIS105.Physician P ON A.PhysicianId = P.PhysicianId"_ 
                      " GROUP BY A.PhysicianId, P.FirstName, P.LastName"_ 
                      " ORDER BY appointments DESC"
        } Else {
            Set sql = "SELECT A.SpecialtyId AS id,"_
                      " COALESCE(S.Name,'') AS name,"_
                      " COUNT(*) AS appointments,"_
                      " SUM(CASE WHEN A.NoShow=1 THEN 1 ELSE 0 END) AS noShow"_ 
                      " FROM IRIS105.Appointment A"_ 
                      " LEFT JOIN IRIS105.Specialty S ON A.SpecialtyId = S.SpecialtyId"_ 
                      " GROUP BY A.SpecialtyId, S.Name"_ 
                      " ORDER BY appointments DESC"
        }
        Do debug.%Push("step=sql "_sql)
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        If $$$ISERR(tSC) {
            Do debug.%Push("step=prepare error "_stmt.%Message)
            Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
        }
        Do debug.%Push("step=execute")
        Set rs = stmt.%Execute()
        Set arr = ##class(%DynamicArray).%New()
        Set pushed = 0
        While rs.%Next() {
            Set appt = rs.%Get("appointments")
            Set ns = rs.%Get("noShow")
            Set rate = $Select(appt>0:ns*1.0/appt,1:0)
            Do debug.%Push("row id="_rs.%Get("id")_" appt="_appt_" ns="_ns_" rate="_rate)
            Set row = ##class(%DynamicObject).%New()
            Do row.%Set("id", rs.%Get("id"))
            Do row.%Set("name", rs.%Get("name"))
            Do row.%Set("appointments", appt)
            Do row.%Set("noShow", ns)
            Do row.%Set("noShowRate", rate)
            Do arr.%Push(row)
            Set pushed = pushed + 1
            Quit:pushed>=limit
        }
        If arr.%Size()=0 {
            Do debug.%Push("step=no rows")
        }
        Do debug.%Push("step=rows "_pushed)
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("by", by)
        Do resp.%Set("items", arr)
        Do resp.%Set("debug", debug)
        Do ..%SendJSON(resp)
    } Catch ex {
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("error",1)
        Do resp.%Set("message",$System.Status.GetErrorText(ex.AsStatus()))
        If $IsObject(debug) Do resp.%Set("debug", debug)
        Do ..%SendJSON(resp, 500)
        Quit
    }
    Quit $$$OK
}

/// Health check basico
ClassMethod Health() As %Status [ ProcedureBlock = 1 ]
{
    Set resp = ##class(%DynamicObject).%New()
    Do resp.%Set("status","ok")
    Do resp.%Set("service","IRIS105.REST.NoShowService")
    Do resp.%Set("ts",$ZDATETIME($HOROLOG,3,1,3))
    Do ..%SendJSON(resp)
    Quit $$$OK
}

/// Ocupacion semanal por especialidad, box o medico
ClassMethod OccupancyWeekly() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        // Parametros
        Set groupBy = ..%NormalizeGroupBy(..%QueryParam("groupBy"))
        Set slotsPerDay = ..%IntegerParam("slotsPerDay", 8, 1, 200)
        Set startDate = ..%QueryParam("startDate")
        Set endDate = ..%QueryParam("endDate")
        Set tSC = ..%BuildDateRange(startDate, endDate, .fromTs, .toTs, .rangeObj)
        Quit:$$$ISERR(tSC)
        
        // Factor por grupo (ej: cantidad de medicos por especialidad)
        Set factorMap = ..%BuildCapacityFactor(groupBy)
        
        // Query agregada por dia para permitir semanas parciales
        Set sql = ..%OccupancySQL(groupBy)
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        Set rs = stmt.%Execute(fromTs, toTs)
        
        Kill stats
        While rs.%Next() {
            Set gid = rs.%Get("GroupId")
            Set gname = rs.%Get("GroupName")
            Set booked = +rs.%Get("Booked")
            Set weekLbl = ..%FormatWeek(rs.%Get("WeekYear"), rs.%Get("WeekNum"))
            If (weekLbl="")!(gid="") {
                // skip invalid rows
                Continue
            }
            Set stats(weekLbl,gid,"name") = gname
            Set stats(weekLbl,gid,"booked") = $Get(stats(weekLbl,gid,"booked")) + booked
            Set factor = $Select(factorMap.%IsDefined(gid):factorMap.%Get(gid),1:1)
            Set capDay = slotsPerDay * factor
            Set stats(weekLbl,gid,"capacity") = $Get(stats(weekLbl,gid,"capacity")) + capDay
        }
        
        // Construir respuesta ordenada
        Set weeks = ##class(%DynamicArray).%New()
        Set weekLbl = ""
        For {
            Set weekLbl = $Order(stats(weekLbl))
            Quit:weekLbl=""
            Set wobj = ##class(%DynamicObject).%New()
            Do wobj.%Set("week", weekLbl)
            Do wobj.%Set("items", ##class(%DynamicArray).%New())
            Set gid = ""
            For {
                Set gid = $Order(stats(weekLbl,gid))
                Quit:gid=""
                Set item = ##class(%DynamicObject).%New()
                Do item.%Set("id", gid)
                Do item.%Set("name", $Get(stats(weekLbl,gid,"name")))
                Set cap = $Get(stats(weekLbl,gid,"capacity"),0)
                Set booked = $Get(stats(weekLbl,gid,"booked"),0)
                Do item.%Set("capacity", cap)
                Do item.%Set("booked", booked)
                Do item.%Set("occupancyRate", $Select(cap>0:booked*1.0/cap,1:0))
                Do wobj.items.%Push(item)
            }
            Do weeks.%Push(wobj)
        }
        
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("groupBy", groupBy)
        If $IsObject(rangeObj) Do resp.%Set("dateRange", rangeObj)
        Do resp.%Set("slotsPerDay", slotsPerDay)
        Do resp.%Set("weeks", weeks)
        Do ..%SendJSON(resp)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Pacientes agendados con filtros basicos
ClassMethod ScheduledPatients() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set specialtyId = ..%QueryParam("specialtyId")
        Set boxId = ..%QueryParam("boxId")
        Set patientName = ..%QueryParam("patientName")
        Set physicianName = ..%QueryParam("physicianName")
        Set limit = ..%GetListLimit(100, 500)
        Set tSC = ..%BuildDateRange(..%QueryParam("startDate"), ..%QueryParam("endDate"), .fromTs, .toTs, .rangeObj)
        Quit:$$$ISERR(tSC)
        
        Set patientName = $ZCONVERT(patientName,"U")
        Set physicianName = $ZCONVERT(physicianName,"U")
        Set patientLike = $Select(patientName'="":"%"_patientName_"%",1:"")
        Set physicianLike = $Select(physicianName'="":"%"_physicianName_"%",1:"")
        
        Set sql = "SELECT TOP "_limit_" A.AppointmentId,"_
                  " A.StartDateTime, A.EndDateTime,"_
                  " A.PatientId, COALESCE(P.FirstName||' '||P.LastName,'') AS PatientName,"_
                  " A.PhysicianId, COALESCE(Ph.FirstName||' '||Ph.LastName,'') AS PhysicianName,"_
                  " A.BoxId, COALESCE(B.Name,'') AS BoxName,"_
                  " A.SpecialtyId, COALESCE(S.Name,'') AS SpecialtyName,"_
                  " A.NoShow"_ 
                  " FROM IRIS105.Appointment A"_ 
                  " LEFT JOIN IRIS105.Patient P ON A.PatientId = P.PatientId"_ 
                  " LEFT JOIN IRIS105.Physician Ph ON A.PhysicianId = Ph.PhysicianId"_ 
                  " LEFT JOIN IRIS105.Box B ON A.BoxId = B.BoxId"_ 
                  " LEFT JOIN IRIS105.Specialty S ON A.SpecialtyId = S.SpecialtyId"_ 
                  " WHERE A.StartDateTime BETWEEN ? AND ?"_ 
                  " AND (?='' OR A.SpecialtyId=?)"_ 
                  " AND (?='' OR A.BoxId=?)"_ 
                  " AND (?='' OR UPPER(COALESCE(P.FirstName||' '||P.LastName,'')) LIKE ?)"_ 
                  " AND (?='' OR UPPER(COALESCE(Ph.FirstName||' '||Ph.LastName,'')) LIKE ?)"_ 
                  " ORDER BY A.StartDateTime ASC"
        
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        Set rs = stmt.%Execute(fromTs, toTs, specialtyId, specialtyId, boxId, boxId, patientName, patientLike, physicianName, physicianLike)
        
        Set items = ##class(%DynamicArray).%New()
        While rs.%Next() {
            Set row = ##class(%DynamicObject).%New()
            Do row.%Set("appointmentId", rs.%Get("AppointmentId"))
            Do row.%Set("startDateTime", rs.%Get("StartDateTime"))
            Do row.%Set("endDateTime", rs.%Get("EndDateTime"))
            Do row.%Set("patientId", rs.%Get("PatientId"))
            Do row.%Set("patientName", rs.%Get("PatientName"))
            Do row.%Set("physicianId", rs.%Get("PhysicianId"))
            Do row.%Set("physicianName", rs.%Get("PhysicianName"))
            Do row.%Set("boxId", rs.%Get("BoxId"))
            Do row.%Set("boxName", rs.%Get("BoxName"))
            Do row.%Set("specialtyId", rs.%Get("SpecialtyId"))
            Do row.%Set("specialtyName", rs.%Get("SpecialtyName"))
            Do row.%Set("noShow", rs.%Get("NoShow"))
            Do items.%Push(row)
        }
        
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("filters", ##class(%DynamicObject).%New())
        Do resp.filters.%Set("specialtyId", specialtyId)
        Do resp.filters.%Set("boxId", boxId)
        Do resp.filters.%Set("patientName", ..%QueryParam("patientName"))
        Do resp.filters.%Set("physicianName", ..%QueryParam("physicianName"))
        Do resp.%Set("dateRange", rangeObj)
        Do resp.%Set("limit", limit)
        Do resp.%Set("items", items)
        Do resp.%Set("count", items.%Size())
        Do ..%SendJSON(resp)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Ocupacion semanal agregada para las ultimas N semanas
ClassMethod OccupancyTrend() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set weeks = ..%IntegerParam("weeks", 6, 1, 52)
        Set slotsPerDay = ..%IntegerParam("slotsPerDay", 8, 1, 200)
        Set endDate = ..%QueryParam("endDate")
        If endDate="" Set endDate = $ZDATE($HOROLOG,3)
        Set endH = $ZDATEH(endDate,3)
        If endH<0 {
            Set tSC = $$$ERROR($$$GeneralError,"Invalid endDate (expected YYYY-MM-DD)")
            Quit
        }
        Set startDate = $ZDATE(endH-((weeks*7)-1),3)
        Set tSC = ..%BuildDateRange(startDate, endDate, .fromTs, .toTs, .rangeObj)
        Quit:$$$ISERR(tSC)
        
        Set sql = "SELECT YEAR(A.StartDateTime) AS WeekYear,"_
                  " DATEPART('week',A.StartDateTime) AS WeekNum,"_
                  " COUNT(*) AS Booked"_ 
                  " FROM IRIS105.Appointment A"_ 
                  " WHERE A.StartDateTime BETWEEN ? AND ?"_ 
                  " GROUP BY YEAR(A.StartDateTime), DATEPART('week',A.StartDateTime)"_ 
                  " ORDER BY WeekYear, WeekNum"
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        Set rs = stmt.%Execute(fromTs, toTs)
        
        Set weeksArr = ##class(%DynamicArray).%New()
        While rs.%Next() {
            Set weekLbl = ..%FormatWeek(rs.%Get("WeekYear"), rs.%Get("WeekNum"))
            If weekLbl="" Continue
            Set booked = +rs.%Get("Booked")
            Set cap = slotsPerDay * 7
            Set row = ##class(%DynamicObject).%New()
            Do row.%Set("week", weekLbl)
            Do row.%Set("booked", booked)
            Do row.%Set("capacity", cap)
            Do row.%Set("occupancyRate", $Select(cap>0:booked*1.0/cap,1:0))
            Do weeksArr.%Push(row)
        }
        
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("weeks", weeksArr)
        Do resp.%Set("weeksCount", weeks)
        Do resp.%Set("slotsPerDay", slotsPerDay)
        Do resp.%Set("dateRange", rangeObj)
        Do ..%SendJSON(resp)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Citas activas en un rango de fechas (base para otros analytics)
ClassMethod ActiveAppointments() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set limit = ..%GetListLimit(200, 1000)
        Set startDate = ..%QueryParam("startDate")
        Set endDate = ..%QueryParam("endDate")
        If startDate="" Set startDate = $ZDATE($HOROLOG,3)
        If endDate="" Set endDate = $ZDATE($HOROLOG+30,3)
        Set tSC = ..%BuildDateRange(startDate, endDate, .fromTs, .toTs, .rangeObj)
        Quit:$$$ISERR(tSC)
        
        Set sql = "SELECT TOP "_limit_" A.AppointmentId,"_
                  " A.StartDateTime, A.EndDateTime,"_
                  " A.PatientId, COALESCE(P.FirstName||' '||P.LastName,'') AS PatientName,"_
                  " A.PhysicianId, COALESCE(Ph.FirstName||' '||Ph.LastName,'') AS PhysicianName,"_
                  " A.BoxId, COALESCE(B.Name,'') AS BoxName,"_
                  " A.SpecialtyId, COALESCE(S.Name,'') AS SpecialtyName,"_
                  " A.NoShow"_ 
                  " FROM IRIS105.Appointment A"_ 
                  " LEFT JOIN IRIS105.Patient P ON A.PatientId = P.PatientId"_ 
                  " LEFT JOIN IRIS105.Physician Ph ON A.PhysicianId = Ph.PhysicianId"_ 
                  " LEFT JOIN IRIS105.Box B ON A.BoxId = B.BoxId"_ 
                  " LEFT JOIN IRIS105.Specialty S ON A.SpecialtyId = S.SpecialtyId"_ 
                  " WHERE A.StartDateTime BETWEEN ? AND ?"_ 
                  " ORDER BY A.StartDateTime ASC"
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        Set rs = stmt.%Execute(fromTs, toTs)
        
        Set items = ##class(%DynamicArray).%New()
        While rs.%Next() {
            Set row = ##class(%DynamicObject).%New()
            Do row.%Set("appointmentId", rs.%Get("AppointmentId"))
            Do row.%Set("startDateTime", rs.%Get("StartDateTime"))
            Do row.%Set("endDateTime", rs.%Get("EndDateTime"))
            Do row.%Set("patientId", rs.%Get("PatientId"))
            Do row.%Set("patientName", rs.%Get("PatientName"))
            Do row.%Set("physicianId", rs.%Get("PhysicianId"))
            Do row.%Set("physicianName", rs.%Get("PhysicianName"))
            Do row.%Set("boxId", rs.%Get("BoxId"))
            Do row.%Set("boxName", rs.%Get("BoxName"))
            Do row.%Set("specialtyId", rs.%Get("SpecialtyId"))
            Do row.%Set("specialtyName", rs.%Get("SpecialtyName"))
            Do row.%Set("noShow", rs.%Get("NoShow"))
            Do items.%Push(row)
        }
        
        Set resp = ##class(%DynamicObject).%New()
        Do resp.%Set("dateRange", rangeObj)
        Do resp.%Set("limit", limit)
        Do resp.%Set("items", items)
        Do resp.%Set("count", items.%Size())
        Do ..%SendJSON(resp)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

/// Configuracion de capacidad por box/especialidad/medico
ClassMethod CapacityConfig() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        If %request.Method="POST" {
            Set payload = ..%ReadJSONBody()
            If '$IsObject(payload) {
                Set tSC = $$$ERROR($$$GeneralError,"Invalid JSON body")
                Quit
            }
            Set items = payload.%Get("items")
            If '$IsObject(items) {
                Set tSC = $$$ERROR($$$GeneralError,"items array is required")
                Quit
            }
            Set saved = ##class(%DynamicArray).%New()
            For i=0:1:items.%Size()-1 {
                Set item = items.%Get(i)
                If '$IsObject(item) Continue
                Set groupBy = ""
                If item.%IsDefined("groupBy") {
                    Set groupBy = ..%NormalizeGroupByStrict(item.%Get("groupBy"))
                }
                Set id = item.%Get("id")
                Set slots = +item.%Get("slotsPerDay")
                If (groupBy="")!(id="")!(slots<=0) Continue
                Set ^IRIS105("Capacity",groupBy,id) = slots
                Set row = ##class(%DynamicObject).%New()
                Do row.%Set("groupBy", groupBy)
                Do row.%Set("id", id)
                Do row.%Set("slotsPerDay", slots)
                Do saved.%Push(row)
            }
            Set resp = ##class(%DynamicObject).%New()
            Do resp.%Set("items", saved)
            Do resp.%Set("count", saved.%Size())
            Do ..%SendJSON(resp)
        } Else {
            Set groupBy = ""
            Set rawGroup = ..%QueryParam("groupBy")
            If rawGroup'="" Set groupBy = ..%NormalizeGroupByStrict(rawGroup)
            Set id = ..%QueryParam("id")
            Set items = ##class(%DynamicArray).%New()
            If groupBy'="" {
                If id'="" {
                    Set slots = $Get(^IRIS105("Capacity",groupBy,id))
                    If slots'="" {
                        Set row = ##class(%DynamicObject).%New()
                        Do row.%Set("groupBy", groupBy)
                        Do row.%Set("id", id)
                        Do row.%Set("slotsPerDay", +slots)
                        Do items.%Push(row)
                    }
                } Else {
                    Set gid = ""
                    For {
                        Set gid = $Order(^IRIS105("Capacity",groupBy,gid))
                        Quit:gid=""
                        Set row = ##class(%DynamicObject).%New()
                        Do row.%Set("groupBy", groupBy)
                        Do row.%Set("id", gid)
                        Do row.%Set("slotsPerDay", +$Get(^IRIS105("Capacity",groupBy,gid)))
                        Do items.%Push(row)
                    }
                }
            } Else {
                Set grp = ""
                For {
                    Set grp = $Order(^IRIS105("Capacity",grp))
                    Quit:grp=""
                    Set gid = ""
                    For {
                        Set gid = $Order(^IRIS105("Capacity",grp,gid))
                        Quit:gid=""
                        Set row = ##class(%DynamicObject).%New()
                        Do row.%Set("groupBy", grp)
                        Do row.%Set("id", gid)
                        Do row.%Set("slotsPerDay", +$Get(^IRIS105("Capacity",grp,gid)))
                        Do items.%Push(row)
                    }
                }
            }
            Set resp = ##class(%DynamicObject).%New()
            Do resp.%Set("items", items)
            Do resp.%Set("count", items.%Size())
            Do ..%SendJSON(resp)
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    If $$$ISERR(tSC) {
        Do ..%HandleError(tSC)
    }
    Quit $$$OK
}

ClassMethod %GetLimit(pDefault As %Integer = 5, pMax As %Integer = 50) As %Integer
{
    Set limit = pDefault
    Set val = ..%QueryParam("limit")
    If val'="" {
        Set val = +val
        If val>0 Set limit = val
    }
    If limit>pMax Set limit = pMax
    Quit limit
}

ClassMethod %GetListLimit(pDefault As %Integer = 100, pMax As %Integer = 500) As %Integer
{
    Set limit = pDefault
    Set val = ..%QueryParam("limit")
    If val'="" {
        Set val = +val
        If val>0 Set limit = val
    }
    If limit>pMax Set limit = pMax
    Quit limit
}

ClassMethod %QueryParam(pName As %String) As %String
{
    Set val = ""
    If '$IsObject(%request) Quit val
    Set bodyVal = $Get(%request.Data(pName))
    If bodyVal'="" Quit bodyVal
    Set qs = $Get(%request.CgiEnvs("QUERY_STRING"))
    If qs="" Quit val
    For i=1:1:$Length(qs,"&") {
        Set pair = $Piece(qs,"&",i)
        Set key = $Piece(pair,"=",1)
        If $ZCONVERT(key,"L")=$ZCONVERT(pName,"L") {
            Set val = $Piece(pair,"=",2)
            Quit
        }
    }
    Quit val
}

ClassMethod %DayName(pISODate As %String) As %String
{
    Quit ""
}

ClassMethod %FormatWeek(pYear As %Integer, pWeek As %Integer) As %String
{
    Set y = +pYear
    Set w = +pWeek
    If (y=0)!(w=0) Quit ""
    If w<10 Set w = "0"_w
    Quit y_"-W"_w
}

ClassMethod %FormatWeekFromDate(pISODate As %String) As %String
{
    Set h = $ZDATEH(pISODate,3)
    If h<0 Quit ""
    Quit $ZDATE(h,8)
}

ClassMethod %NormalizeGroupBy(pValue As %String = "") As %String
{
    Set grp = $ZCONVERT($Get(pValue),"L")
    If (grp'="physician")&&(grp'="box")&&(grp'="specialty") {
        Set grp = "specialty"
    }
    Quit grp
}

ClassMethod %NormalizeGroupByStrict(pValue As %String = "") As %String
{
    Set grp = $ZCONVERT($Get(pValue),"L")
    If (grp="physician")!(grp="box")!(grp="specialty") Quit grp
    Quit ""
}

ClassMethod %IntegerParam(pName As %String, pDefault As %Integer, pMin As %Integer = 1, pMax As %Integer = 999) As %Integer
{
    Set raw = ..%QueryParam(pName)
    If raw="" Quit pDefault
    Set num = +raw
    If num<pMin Set num = pMin
    If num>pMax Set num = pMax
    Quit num
}

ClassMethod %BuildDateRange(pStart As %String, pEnd As %String, Output pStartTS As %String, Output pEndTS As %String, Output pRangeObj As %DynamicObject) As %Status
{
    #include %occErrors
    Set today = $ZDATE($HOROLOG,3)
    Set defaultStart = $ZDATE($HOROLOG-42,3)
    Set start = $Select(pStart'="":pStart, 1:defaultStart)
    Set end = $Select(pEnd'="":pEnd, 1:today)
    
    Set sh = $ZDATEH(start,3)
    If sh<0 Quit $$$ERROR($$$GeneralError,"Invalid startDate (expected YYYY-MM-DD)")
    Set eh = $ZDATEH(end,3)
    If eh<0 Quit $$$ERROR($$$GeneralError,"Invalid endDate (expected YYYY-MM-DD)")
    If eh<sh Quit $$$ERROR($$$GeneralError,"endDate must be greater than or equal to startDate")
    If (eh-sh)>365 Quit $$$ERROR($$$GeneralError,"Date range too large (max 365 days)")
    
    Set pStartTS = start_" 00:00:00"
    Set pEndTS = end_" 23:59:59"
    Set pRangeObj = ##class(%DynamicObject).%New()
    Do pRangeObj.%Set("startDate", start)
    Do pRangeObj.%Set("endDate", end)
    Quit $$$OK
}

ClassMethod %BuildCapacityFactor(pGroupBy As %String) As %DynamicObject
{
    Set map = ##class(%DynamicObject).%New()
    If pGroupBy="specialty" {
        Set stmt = ##class(%SQL.Statement).%New()
        If $$$ISOK(stmt.%Prepare("SELECT SpecialtyId, COUNT(*) AS PhysicianCount FROM IRIS105.Physician GROUP BY SpecialtyId")) {
            Set rs = stmt.%Execute()
            While rs.%Next() {
                Do map.%Set(rs.%Get("SpecialtyId"), $Select(rs.%Get("PhysicianCount")>0:rs.%Get("PhysicianCount"),1:1))
            }
        }
    }
    Quit map
}

ClassMethod %OccupancySQL(pGroupBy As %String) As %String
{
    If pGroupBy="box" {
        Quit "SELECT YEAR(A.StartDateTime) AS WeekYear,"_
             " DATEPART('week',A.StartDateTime) AS WeekNum,"_
             " A.BoxId AS GroupId, COALESCE(B.Name,'') AS GroupName,"_
             " COUNT(*) AS Booked"_
             " FROM IRIS105.Appointment A"_ 
             " LEFT JOIN IRIS105.Box B ON A.BoxId = B.BoxId"_ 
             " WHERE A.StartDateTime BETWEEN ? AND ?"_ 
             " GROUP BY YEAR(A.StartDateTime), DATEPART('week',A.StartDateTime), A.BoxId, COALESCE(B.Name,'')"_
             " ORDER BY WeekYear, WeekNum, GroupId"
    } ElseIf pGroupBy="physician" {
        Quit "SELECT YEAR(A.StartDateTime) AS WeekYear,"_
             " DATEPART('week',A.StartDateTime) AS WeekNum,"_
             " A.PhysicianId AS GroupId, COALESCE(P.FirstName||' '||P.LastName,'') AS GroupName,"_
             " COUNT(*) AS Booked"_
             " FROM IRIS105.Appointment A"_ 
             " LEFT JOIN IRIS105.Physician P ON A.PhysicianId = P.PhysicianId"_ 
             " WHERE A.StartDateTime BETWEEN ? AND ?"_ 
             " GROUP BY YEAR(A.StartDateTime), DATEPART('week',A.StartDateTime), A.PhysicianId, COALESCE(P.FirstName||' '||P.LastName,'')"_
             " ORDER BY WeekYear, WeekNum, GroupId"
    } Else {
        Quit "SELECT YEAR(A.StartDateTime) AS WeekYear,"_
             " DATEPART('week',A.StartDateTime) AS WeekNum,"_
             " A.SpecialtyId AS GroupId, COALESCE(S.Name,'') AS GroupName,"_
             " COUNT(*) AS Booked"_
             " FROM IRIS105.Appointment A"_ 
             " LEFT JOIN IRIS105.Specialty S ON A.SpecialtyId = S.SpecialtyId"_ 
             " WHERE A.StartDateTime BETWEEN ? AND ?"_ 
             " GROUP BY YEAR(A.StartDateTime), DATEPART('week',A.StartDateTime), A.SpecialtyId, COALESCE(S.Name,'')"_
             " ORDER BY WeekYear, WeekNum, GroupId"
    }
}

}
