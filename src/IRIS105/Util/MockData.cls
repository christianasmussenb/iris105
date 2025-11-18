Class IRIS105.Util.MockData Extends %RegisteredObject
{

ClassMethod Generate(pConfig As %DynamicObject = "") As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        If '$IsObject(pConfig) {
            Set pConfig = ##class(IRIS105.Util.MockConfig).GetDefault()
        }
        
        Set params = ##class(%DynamicObject).%New()
        Set horizonMonths = $Select(pConfig.%IsDefined("horizonMonths"):pConfig.%Get("horizonMonths"),1:3)
        Set slotsPerDay = $Select(pConfig.%IsDefined("slotsPerDay"):pConfig.%Get("slotsPerDay"),1:8)
        Set physicianCount = $Select(pConfig.%IsDefined("physicians"):pConfig.%Get("physicians"),1:8)
        Set boxCount = $Select(pConfig.%IsDefined("boxes"):pConfig.%Get("boxes"),1:3)
        Set specialtyCount = $Select(pConfig.%IsDefined("specialties"):pConfig.%Get("specialties"),1:3)
        Set occupancyPct = $Select(pConfig.%IsDefined("occupancyPct"):pConfig.%Get("occupancyPct"),1:0.85)
        Set patientCount = $Select(pConfig.%IsDefined("patients"):pConfig.%Get("patients"),1:100)
        Set totalDays = horizonMonths * 30
        
        Do params.%Set("horizonMonths",horizonMonths)
        Do params.%Set("slotsPerDay",slotsPerDay)
        Do params.%Set("physicians",physicianCount)
        Do params.%Set("boxes",boxCount)
        Do params.%Set("specialties",specialtyCount)
        Do params.%Set("occupancyPct",occupancyPct)
        Do params.%Set("patients",patientCount)
        Do params.%Set("totalDays",totalDays)
        
        Write !,"[MockData] Iniciando generación (",totalDays," días, ",physicianCount," médicos, ",patientCount," pacientes)..."
        
        Set tSC = ##class(IRIS105.Util.MockPayers).Create()
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockSpecialties).Create(specialtyCount)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockBoxes).Create(boxCount)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockPhysicians).Create(physicianCount, specialtyCount, boxCount)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockPatients).Create(patientCount)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockAppointments).GenerateAppointments(params)
        Quit:$$$ISERR(tSC)
        
        Write !,"[MockData] Generación completada correctamente",!
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
