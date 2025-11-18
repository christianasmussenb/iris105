Class IRIS105.Util.MockPhysicians Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 8, specialtyCount As %Integer = 3, boxCount As %Integer = 3) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        If specialtyCount<1 Set specialtyCount = 1
        If boxCount<1 Set boxCount = 1
        Set created = 0
        
        For idx=1:1:count {
            Set tPhysician = ##class(IRIS105.Physician).%New()
            Set tPhysician.PhysicianId = "PHY-"_idx
            Set tPhysician.FirstName = "Dr"_idx
            Set tPhysician.LastName = "Apellido"_idx
            
            Set specialtyIndex = ((idx-1) # specialtyCount) + 1
            Set tPhysician.SpecialtyId = "SPEC-"_specialtyIndex
            
            Set boxIndex = ((idx-1) # boxCount) + 1
            Set tPhysician.DefaultBoxId = "BOX-"_boxIndex
            
            Set tSC = tPhysician.%Save()
            Quit:$$$ISERR(tSC)
            Set created = created + 1
        }
        If '$SYSTEM.Status.IsError(tSC) {
            Write !,"[MockPhysicians] Generados ",created," médicos"
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
