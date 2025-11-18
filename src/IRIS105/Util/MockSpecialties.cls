Class IRIS105.Util.MockSpecialties Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 3) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set defaults = "Medicina Interna,Traumatologia,Pediatria"
        Set entryCount = $Length(defaults,",") + 1
        Set created = 0
        
        For idx=1:1:count {
            Set nameIndex = ((idx-1) # entryCount) + 1
            Set name = $Piece(defaults,",",nameIndex)
            
            Set tSpecialty = ##class(IRIS105.Specialty).%New()
            Set tSpecialty.SpecialtyId = "SPEC-"_idx
            Set tSpecialty.Name = name
            
            Set tSC = tSpecialty.%Save()
            Quit:$$$ISERR(tSC)
            Set created = created + 1
        }
        If '$SYSTEM.Status.IsError(tSC) Write !,"[MockSpecialties] Generadas ",created," especialidades"
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
