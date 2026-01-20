Class IRIS105.Util.ProjectSetup Extends %RegisteredObject
{

/// Inicializa globals requeridos (tokens y capacidad base).
ClassMethod Init(pNamespace As %String = "", pToken As %String = "demo-readonly-token", pSlotsPerDay As %Integer = 8, pSeedCapacity As %Boolean = 1) As %Status
{
    #include %occErrors
    Set sc = $$$OK
    New $Namespace
    Set oldNS = $Namespace
    Try {
        If pNamespace'="" Set $Namespace = pNamespace
        If pToken'="" Set ^IRIS105("API","Tokens",pToken) = 1
        If pSeedCapacity {
            Set sc = ..%SeedCapacity("specialty", "IRIS105.Specialty", "SpecialtyId", pSlotsPerDay)
            Quit:$$$ISERR(sc)
            Set sc = ..%SeedCapacity("box", "IRIS105.Box", "BoxId", pSlotsPerDay)
            Quit:$$$ISERR(sc)
            Set sc = ..%SeedCapacity("physician", "IRIS105.Physician", "PhysicianId", pSlotsPerDay)
            Quit:$$$ISERR(sc)
        }
        If '$Data(^IRIS105("Setup","InitializedAt")) {
            Set ^IRIS105("Setup","InitializedAt") = $ZDATETIME($HOROLOG,3,1,3)
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Set $Namespace = oldNS
    Quit sc
}

ClassMethod %SeedCapacity(pGroupBy As %String, pTable As %String, pIdField As %String, pSlotsPerDay As %Integer) As %Status
{
    #include %occErrors
    Set sc = $$$OK
    If pSlotsPerDay<1 Set pSlotsPerDay = 1
    Set sql = "SELECT "_pIdField_" AS Id FROM "_pTable_" WHERE "_pIdField_" IS NOT NULL"
    Try {
        Set stmt = ##class(%SQL.Statement).%New()
        Set sc = stmt.%Prepare(sql)
        Quit:$$$ISERR(sc)
        Set rs = stmt.%Execute()
        While rs.%Next() {
            Set id = rs.%Get("Id")
            If id="" Continue
            If '$Data(^IRIS105("Capacity",pGroupBy,id)) {
                Set ^IRIS105("Capacity",pGroupBy,id) = pSlotsPerDay
            }
        }
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

}
