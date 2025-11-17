Class IRIS105.Util.MockPhysicians Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 8, specialtyCount As %Integer = 3, boxCount As %Integer = 3) As %Status
{
    TRY {
        If specialtyCount<1 Set specialtyCount = 1
        If boxCount<1 Set boxCount = 1
        
        For idx=1:1:count {
            Set physician = ##class(IRIS105.Physician).%New()
            Set physician.PhysicianId = "PHY-"_idx
            Set physician.FirstName = "Dr"_idx
            Set physician.LastName = "Apellido"_idx
            
            Set specialtyIndex = ((idx-1) # specialtyCount) + 1
            Set physician.SpecialtyId = "SPEC-"_specialtyIndex
            
            Set boxIndex = ((idx-1) # boxCount) + 1
            Set physician.DefaultBoxId = "BOX-"_boxIndex
            
            $$$ThrowOnError(physician.%Save())
        }
Quit $$$OK
    }
CATCH ex {
        Quit ex.AsStatus()
    }
}

}
