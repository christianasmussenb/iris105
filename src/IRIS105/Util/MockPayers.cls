Class IRIS105.Util.MockPayers Extends %RegisteredObject
{

ClassMethod Create() As %Status
{
    TRY {
        Set defaults = "PAYER-1|Fonasa|FONASA,PAYER-2|Colmena|ISAPRE,PAYER-3|Consalud|ISAPRE,PAYER-4|Banmedica|ISAPRE"
        
        For idx=1:1 {
            Set entry = $Piece(defaults,",",idx)
            Quit:entry=""
            
            Set payerId = $Piece(entry,"|",1)
            Set payer = ##class(IRIS105.Payer).%New()
            Set payer.PayerId = payerId
            Set payer.Name = $Piece(entry,"|",2)
            Set payer.Type = $Piece(entry,"|",3)
            
            $$$ThrowOnError(payer.%Save())
        }
Quit $$$OK
    }
CATCH ex {
        Quit ex.AsStatus()
    }
}

}
