Class IRIS105.Util.MockPatients Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 100) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set payerChoices = "PAYER-1,PAYER-2,PAYER-3,PAYER-4"
        Set payerCount = $Length(payerChoices,",") + 1
        Set created = 0
        
        For idx=1:1:count {
            Set tPatient = ##class(IRIS105.Patient).%New()
            Set tPatient.PatientId = "PAT-"_idx
            Set tPatient.FirstName = "Nombre"_idx
            Set tPatient.LastName = "Apellido"_idx
            
            Set tPatient.Sex = $Select(($Random(100)<52):"F",1:"M")
            Set birthYear = 2025 - (20 + $Random(60))
            Set tPatient.BirthDate = $ZDATEH(birthYear_"-01-01",3)
            
            Set payerIndex = $Random(payerCount) + 1
            Set tPatient.PayerId = $Piece(payerChoices,",",payerIndex)
            
            Set tSC = tPatient.%Save()
            Quit:$$$ISERR(tSC)
            Set created = created + 1
        }
        If '$SYSTEM.Status.IsError(tSC) {
            Write !,"[MockPatients] Generados ",created," pacientes"
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
