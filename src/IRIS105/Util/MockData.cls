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
        Set params.horizonMonths = $Get(pConfig.horizonMonths,3)
        Set params.slotsPerDay = $Get(pConfig.slotsPerDay,8)
        Set params.physicians = $Get(pConfig.physicians,8)
        Set params.boxes = $Get(pConfig.boxes,3)
        Set params.specialties = $Get(pConfig.specialties,3)
        Set params.occupancyPct = $Get(pConfig.occupancyPct,0.85)
        Set params.patients = $Get(pConfig.patients,100)
        Set params.totalDays = params.horizonMonths * 30
        
        Set tSC = ##class(IRIS105.Util.MockPayers).Create()
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockSpecialties).Create(params.specialties)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockBoxes).Create(params.boxes)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockPhysicians).Create(params.physicians, params.specialties, params.boxes)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockPatients).Create(params.patients)
        Quit:$$$ISERR(tSC)
        Set tSC = ##class(IRIS105.Util.MockAppointments).GenerateAppointments(params)
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
