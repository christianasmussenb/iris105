Class IRIS105.Util.MockBoxes Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 3) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set created = 0
        For idx=1:1:count {
            Set tBox = ##class(IRIS105.Box).%New()
            Set tBox.BoxId = "BOX-"_idx
            Set tBox.Name = "BOX-"_idx
            Set tBox.Location = "Sede 1"
            
            Set tSC = tBox.%Save()
            Quit:$$$ISERR(tSC)
            Set created = created + 1
        }
        If '$SYSTEM.Status.IsError(tSC) {
            Write !,"[MockBoxes] Generadas ",created," cajas"
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
