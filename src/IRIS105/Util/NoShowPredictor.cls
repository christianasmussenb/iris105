Class IRIS105.Util.NoShowPredictor Extends %RegisteredObject
{

Parameter FeatureColumns = "PatientId,PhysicianId,BoxId,SpecialtyId,StartDateTime,BookingChannel,BookingDaysInAdvance,HasSMSReminder,Reason";

ClassMethod ScoreAppointment(pAppointmentId As %String, pModelName As %String = "NoShowModel", pTrainedModelName As %String = "", Output pResult As %DynamicObject) As %Status
{
    Set tSC = $$$OK, pResult = ""
    Try {
        If pAppointmentId="" {
            Set tSC = $$$ERROR($$$GeneralError,"AppointmentId is required")
            Quit
        }
        
        Set predictExpr = ..%PredictExpression(pModelName, pTrainedModelName)
        Set probabilityExpr = ..%ProbabilityExpression(pModelName, pTrainedModelName)
        Set sql = "SELECT AppointmentId,"
        Set sql = sql_" "_predictExpr_" AS PredictedLabel,"
        Set sql = sql_" "_probabilityExpr_" AS NoShowProb"
        Set sql = sql_" FROM IRIS105.Appointment WHERE AppointmentId = ?"
        
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        
        Set rs = stmt.%Execute(pAppointmentId)
        If 'rs.%Next() {
            Set tSC = $$$ERROR($$$GeneralError,"AppointmentId "_pAppointmentId_" was not found")
            Quit
        }
        Set probability = +rs.NoShowProb
        Set riskLevel = ..%RiskLevel(probability)
        Set tSC = ..%UpsertAppointmentRisk(rs.AppointmentId, probability, riskLevel, pModelName, pTrainedModelName, .riskId)
        Quit:$$$ISERR(tSC)
        
        Set pResult = ##class(%DynamicObject).%New()
        Do pResult.%Set("appointmentId", rs.AppointmentId)
        Do pResult.%Set("predictedLabel", rs.PredictedLabel)
        Do pResult.%Set("probability", probability)
        Do pResult.%Set("riskLevel", riskLevel)
        Do pResult.%Set("riskId", riskId)
        Do pResult.%Set("modelName", pModelName)
        Do pResult.%Set("trainedModelName", $Select(pTrainedModelName'="":pTrainedModelName, 1:""))
        Do pResult.%Set("scoredAt", $ZDATETIME($HOROLOG, 3, 1, 3))
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod ScorePayload(pPayload As %DynamicObject, pModelName As %String = "NoShowModel", pTrainedModelName As %String = "", Output pResult As %DynamicObject) As %Status
{
    Set tSC = $$$OK, pResult = ""
    Try {
        If '$IsObject(pPayload) {
            Set tSC = $$$ERROR($$$GeneralError,"Payload must be a dynamic object")
            Quit
        }
        
        Set predictExpr = ..%PredictExpression(pModelName, pTrainedModelName)
        Set probabilityExpr = ..%ProbabilityExpression(pModelName, pTrainedModelName)
        Set sql = "SELECT "_predictExpr_" AS PredictedLabel,"
        Set sql = sql_" "_probabilityExpr_" AS NoShowProb"
        Set sql = sql_" FROM (SELECT "_..%InlineSelectList()_") AS Payload"
        
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(sql)
        Quit:$$$ISERR(tSC)
        Set params = ..%BuildPayloadParams(pPayload)
        Set rs = stmt.%ExecuteParmArray(params)
        If 'rs.%Next() {
            Set tSC = $$$ERROR($$$GeneralError,"No prediction result was returned")
            Quit
        }
        Set probability = +rs.NoShowProb
        Set riskLevel = ..%RiskLevel(probability)
        
        Set pResult = ##class(%DynamicObject).%New()
        Do pResult.%Set("predictedLabel", rs.PredictedLabel)
        Do pResult.%Set("probability", probability)
        Do pResult.%Set("riskLevel", riskLevel)
        Do pResult.%Set("modelName", pModelName)
        Do pResult.%Set("trainedModelName", $Select(pTrainedModelName'="":pTrainedModelName, 1:""))
        Do pResult.%Set("input", pPayload)
        Do pResult.%Set("scoredAt", $ZDATETIME($HOROLOG, 3, 1, 3))
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod %UpsertAppointmentRisk(pAppointmentId As %String, pProbability As %Double, pRiskLevel As %String, pModelName As %String, pTrainedModelName As %String = "", Output pRiskId As %Integer = "") As %Status
{
    Set tSC = $$$OK, pRiskId = ""
    Try {
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare("SELECT TOP 1 %ID AS RiskId FROM IRIS105.AppointmentRisk WHERE AppointmentId=?")
        Quit:$$$ISERR(tSC)
        Set rs = stmt.%Execute(pAppointmentId)
        If rs.%Next() {
            Set risk = ##class(IRIS105.AppointmentRisk).%OpenId(+rs.%Get("RiskId"))
            If '$IsObject(risk) {
                Set tSC = $$$ERROR($$$GeneralError,"Unable to open AppointmentRisk record for "_pAppointmentId)
                Quit
            }
        } Else {
            Set risk = ##class(IRIS105.AppointmentRisk).%New()
            Set risk.AppointmentId = pAppointmentId
        }
        Set risk.ScoredAt = $ZDATETIME($HOROLOG, 3, 1, 3)
        Set risk.NoShowProb = +pProbability
        Set risk.RiskLevel = pRiskLevel
        Set risk.ModelName = pModelName
        Set risk.TrainedModelName = pTrainedModelName
        Set tSC = risk.%Save()
        Quit:$$$ISERR(tSC)
        Set pRiskId = risk.%Id()
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod %RiskLevel(pProbability As %Double) As %String
{
    Set p = +pProbability
    If p>=0.70 Quit "HIGH"
    If p>=0.40 Quit "MEDIUM"
    Quit "LOW"
}

ClassMethod %PredictExpression(pModelName As %String, pTrainedModelName As %String = "") As %String
{
    Quit "PREDICT("_..%ModelSelector(pModelName, pTrainedModelName)_")"
}

ClassMethod %ProbabilityExpression(pModelName As %String, pTrainedModelName As %String = "") As %String
{
    Quit "PROBABILITY("_..%ModelSelector(pModelName, pTrainedModelName)_" FOR 1)"
}

ClassMethod %ModelSelector(pModelName As %String, pTrainedModelName As %String = "") As %String
{
    Set model = ..%QuoteIdentifier(pModelName)
    If pTrainedModelName'="" {
        Set model = model_" USE "_..%QuoteIdentifier(pTrainedModelName)
    }
    Quit model
}

ClassMethod %InlineSelectList() As %String
{
    Set cols = ..#FeatureColumns
    Set list = ""
    Set del = ""
    For i=1:1:$LENGTH(cols,",") {
        Set col = $PIECE(cols,",",i)
        Set list = list_del_"? AS "_col
        Set del = ", "
    }
    Quit list
}

ClassMethod %BuildPayloadParams(pPayload As %DynamicObject) As %ArrayOfDataTypes
{
    Set params = ##class(%ArrayOfDataTypes).%New()
    Set cols = ..#FeatureColumns
    For i=1:1:$LENGTH(cols,",") {
        Set col = $PIECE(cols,",",i)
        Set val = ""
        If pPayload.%IsDefined(col) {
            Set val = pPayload.%Get(col)
        } Else {
            Set val = ""
        }
        Do params.SetAt(val, i)
    }
    Quit params
}

ClassMethod %QuoteIdentifier(pName As %String) As %String
{
    Quit """"_$Replace(pName,"""","""""")_""""
}

}
