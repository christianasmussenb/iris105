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
        Set clearBeforeGenerate = +$Select(pConfig.%IsDefined("clearBeforeGenerate"):pConfig.%Get("clearBeforeGenerate"),1:1)
        Set defaultNoShowRate = +$Select(pConfig.%IsDefined("defaultNoShowRate"):pConfig.%Get("defaultNoShowRate"),1:0.15)
        Set weekdayStartHour = +$Select(pConfig.%IsDefined("weekdayStartHour"):pConfig.%Get("weekdayStartHour"),1:8)
        Set weekdayEndHour = +$Select(pConfig.%IsDefined("weekdayEndHour"):pConfig.%Get("weekdayEndHour"),1:18)
        Set saturdayStartHour = +$Select(pConfig.%IsDefined("saturdayStartHour"):pConfig.%Get("saturdayStartHour"),1:9)
        Set saturdayEndHour = +$Select(pConfig.%IsDefined("saturdayEndHour"):pConfig.%Get("saturdayEndHour"),1:14)
        
        Set specialtyNoShowRates = ""
        If pConfig.%IsDefined("specialtyNoShowRates") {
            Set specialtyNoShowRates = pConfig.%Get("specialtyNoShowRates")
        }
        If '$IsObject(specialtyNoShowRates) {
            Set specialtyNoShowRates = ##class(%DynamicObject).%New()
        }
        
        // Mantener compatibilidad de la API (months -> ~30 días)
        Set totalDays = horizonMonths * 30
        
        Do params.%Set("horizonMonths",horizonMonths)
        Do params.%Set("slotsPerDay",slotsPerDay)
        Do params.%Set("physicians",physicianCount)
        Do params.%Set("boxes",boxCount)
        Do params.%Set("specialties",specialtyCount)
        Do params.%Set("occupancyPct",occupancyPct)
        Do params.%Set("patients",patientCount)
        Do params.%Set("totalDays",totalDays)
        Do params.%Set("defaultNoShowRate", defaultNoShowRate)
        Do params.%Set("specialtyNoShowRates", specialtyNoShowRates)
        Do params.%Set("weekdayStartHour", weekdayStartHour)
        Do params.%Set("weekdayEndHour", weekdayEndHour)
        Do params.%Set("saturdayStartHour", saturdayStartHour)
        Do params.%Set("saturdayEndHour", saturdayEndHour)
        
        Write !,"[MockData] Iniciando generación (",totalDays," días, ",physicianCount," médicos, ",patientCount," pacientes)..."
        If clearBeforeGenerate {
            Write !,"[MockData] Limpiando datos existentes..."
            Set tSC = ..%ClearExistingData()
            Quit:$$$ISERR(tSC)
        }
        
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

ClassMethod %ClearExistingData() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.AppointmentRisk")
        Quit:$$$ISERR(tSC)
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.Appointment")
        Quit:$$$ISERR(tSC)
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.Physician")
        Quit:$$$ISERR(tSC)
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.Patient")
        Quit:$$$ISERR(tSC)
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.Box")
        Quit:$$$ISERR(tSC)
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.Specialty")
        Quit:$$$ISERR(tSC)
        Set tSC = ..%ExecNonQuery("DELETE FROM IRIS105.Payer")
        Quit:$$$ISERR(tSC)
        Kill ^IRIS105("Capacity")
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod %ExecNonQuery(pSQL As %String) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set stmt = ##class(%SQL.Statement).%New()
        Set tSC = stmt.%Prepare(pSQL)
        If $$$ISOK(tSC) {
            Set rs = stmt.%Execute()
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
