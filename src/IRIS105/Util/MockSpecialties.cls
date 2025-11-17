Class IRIS105.Util.MockSpecialties Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 3) As %Status
{
    TRY {
        Set defaults = "Medicina Interna,Traumatologia,Pediatria"
        Set entryCount = $Length(defaults,",")
        
        For idx=1:1:count {
            Set nameIndex = ((idx-1) # entryCount) + 1
            Set name = $Piece(defaults,",",nameIndex)
            
            Set specialty = ##class(IRIS105.Specialty).%New()
            Set specialty.SpecialtyId = "SPEC-"_idx
            Set specialty.Name = name
            
            $$$ThrowOnError(specialty.%Save())
        }
Quit $$$OK
    }
CATCH ex {
        Quit ex.AsStatus()
    }
}

}
