Class IRIS105.Util.MockConfig Extends %RegisteredObject
{

/// Retorna la configuración por defecto para la generación de datos mock
ClassMethod GetDefault() As %DynamicObject [ ProcedureBlock = 1 ]
{
    Set cfg = ##class(%DynamicObject).%New()
    Set cfg.horizonMonths = 3
    Set cfg.occupancyPct = 0.85
    Set cfg.physicians = 8
    Set cfg.boxes = 3
    Set cfg.specialties = 3
    Set cfg.slotsPerDay = 10
    Set cfg.patients = 100
    Set cfg.clearBeforeGenerate = 1
    Set cfg.defaultNoShowRate = 0.15
    
    // Horarios operativos fijos para la agenda mock
    Set cfg.weekdayStartHour = 8
    Set cfg.weekdayEndHour = 18
    Set cfg.saturdayStartHour = 9
    Set cfg.saturdayEndHour = 14
    
    // Parámetro de no-show por especialidad (fallback: defaultNoShowRate)
    Set specialtyRates = ##class(%DynamicObject).%New()
    Do specialtyRates.%Set("SPEC-1", 0.12)
    Do specialtyRates.%Set("SPEC-2", 0.20)
    Do specialtyRates.%Set("SPEC-3", 0.08)
    Set cfg.specialtyNoShowRates = specialtyRates
    
    Set payer = ##class(%DynamicObject).%New()
    Set payer.FONASA = 0.8
    Set payer.ISAPRE = 0.2
    Set cfg.payerMix = payer
    
    Quit cfg
}

}
