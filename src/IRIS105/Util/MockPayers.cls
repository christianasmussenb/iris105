Class IRIS105.Util.MockPayers Extends %RegisteredObject
{

ClassMethod Create() As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set defaults = "PAYER-1|Fonasa|FONASA,PAYER-2|Colmena|ISAPRE,PAYER-3|Consalud|ISAPRE,PAYER-4|Banmedica|ISAPRE"
        Set entryCount = $Length(defaults,",") + 1
        
        For idx=1:1:entryCount {
            Set entry = $Piece(defaults,",",idx)
            Quit:entry=""
            
            Set tPayer = ##class(IRIS105.Payer).%New()
            Set tPayer.PayerId = $Piece(entry,"|",1)
            Set tPayer.Name = $Piece(entry,"|",2)
            Set tPayer.Type = $Piece(entry,"|",3)
            
            Set tSC = tPayer.%Save()
            Quit:$$$ISERR(tSC)
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
