Class IRIS105.Util.MockPatients Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 100) As %Status
{
    TRY {
        Set payerChoices = "PAYER-1,PAYER-2,PAYER-3,PAYER-4"
        
        For idx=1:1:count {
            Set patient = ##class(IRIS105.Patient).%New()
            Set patient.PatientId = "PAT-"_idx
            Set patient.FirstName = "Nombre"_idx
            Set patient.LastName = "Apellido"_idx
            
            Set sex = $Select(($Random(100)<52):"F",1:"M")
            Set patient.Sex = sex
            
            Set birthYear = 2025 - (20 + $Random(60))
            Set patient.BirthDate = birthYear_"-01-01"
            
            Set payerIndex = $Random($Length(payerChoices,",") + 1) + 1
            Set patient.PayerId = $Piece(payerChoices,",",payerIndex)
            
            $$$ThrowOnError(patient.%Save())
        }
Quit $$$OK
    }
CATCH ex {
        Quit ex.AsStatus()
    }
}

}
