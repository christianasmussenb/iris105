Class IRIS105.Util.MockData Extends %RegisteredObject
{

ClassMethod Generate(pConfig As %DynamicObject = "") As %Status
{
    TRY {
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
        
        $$$ThrowOnError(##class(IRIS105.Util.MockPayers).Create())
        $$$ThrowOnError(##class(IRIS105.Util.MockSpecialties).Create(params.specialties))
        $$$ThrowOnError(##class(IRIS105.Util.MockBoxes).Create(params.boxes))
        $$$ThrowOnError(##class(IRIS105.Util.MockPhysicians).Create(params.physicians, params.specialties, params.boxes))
        $$$ThrowOnError(##class(IRIS105.Util.MockPatients).Create(params.patients))
        $$$ThrowOnError(##class(IRIS105.Util.MockAppointments).GenerateAppointments(params))
        
        Quit $$$OK
    }
CATCH ex {
        Quit ex.AsStatus()
    }
}

}
