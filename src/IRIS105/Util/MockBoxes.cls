Class IRIS105.Util.MockBoxes Extends %RegisteredObject
{

ClassMethod Create(count As %Integer = 3) As %Status
{
    TRY {
        For idx=1:1:count {
            Set box = ##class(IRIS105.Box).%New()
            Set box.BoxId = "BOX-"_idx
            Set box.Name = "BOX-"_idx
            Set box.Location = "Sede 1"
            
            $$$ThrowOnError(box.%Save())
        }
Quit $$$OK
    }
CATCH ex {
        Quit ex.AsStatus()
    }
}

}
