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
    Set cfg.slotsPerDay = 8
    Set cfg.patients = 100
    
    Set payer = ##class(%DynamicObject).%New()
    Set payer.FONASA = 0.8
    Set payer.ISAPRE = 0.2
    Set cfg.payerMix = payer
    
    Quit cfg
}

}
