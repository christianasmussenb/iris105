Class IRIS105.REST.Mock Extends %RegisteredObject
{

/// Helper para generación de mock con parámetros sueltos
ClassMethod GenerateFromRequest(pRequest As %DynamicObject) As %Status
{
    If '$IsObject(pRequest) {
        Set pRequest = ##class(%DynamicObject).%New()
    }
    Set config = ##class(IRIS105.Util.MockConfig).GetDefault()
    If pRequest.%IsDefined("months") {
        Do config.%Set("horizonMonths", pRequest.%Get("months"))
    }
    If pRequest.%IsDefined("targetOccupancy") {
        Do config.%Set("occupancyPct", pRequest.%Get("targetOccupancy"))
    }
    If pRequest.%IsDefined("seed") {
        Do config.%Set("seed", pRequest.%Get("seed"))
    }
    If pRequest.%IsDefined("patients") {
        Do config.%Set("patients", pRequest.%Get("patients"))
    }
    If pRequest.%IsDefined("clearBeforeGenerate") {
        Do config.%Set("clearBeforeGenerate", +pRequest.%Get("clearBeforeGenerate"))
    }
    If pRequest.%IsDefined("defaultNoShowRate") {
        Do config.%Set("defaultNoShowRate", +pRequest.%Get("defaultNoShowRate"))
    }
    If pRequest.%IsDefined("specialtyNoShowRates") {
        Set rates = pRequest.%Get("specialtyNoShowRates")
        If $IsObject(rates) {
            Do config.%Set("specialtyNoShowRates", rates)
        }
    }
    Quit ##class(IRIS105.Util.MockData).Generate(config)
}

}
