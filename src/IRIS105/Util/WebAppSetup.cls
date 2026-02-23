Class IRIS105.Util.WebAppSetup Extends %RegisteredObject
{

/// Crea o actualiza las Web Applications:
/// - API REST en /csp/mltest (DispatchClass: IRIS105.REST.NoShowService)
/// - Página CSP en /csp/mltest2 (solo CSP/ZEN habilitado)
ClassMethod ConfigureAll() As %Status
{
    #include %occErrors
    New $Namespace
    Set oldNS = $Namespace
    Set $Namespace = "%SYS"
    Set sc = $$$OK
    Try {
        Set sc = ..Upsert("/csp/mltest", "MLTEST", 1, 1, "IRIS105.REST.NoShowService", "/csp/mltest/")
        Quit:$$$ISERR(sc)
        Set sc = ..Upsert("/csp/mltest2", "MLTEST", 1, 0, "", "/csp/mltest2/")
    } Catch ex {
        Set sc = ex.AsStatus()
    }
    Set $Namespace = oldNS
    Quit sc
}

/// Crea o actualiza una Web Application usando Security.Applications
ClassMethod Upsert(pName As %String, pNamespace As %String, pCSPEnabled As %Boolean = 1, pRESTEnabled As %Boolean = 0, pDispatchClass As %String = "", pCookiePath As %String = "") As %Status
{
    #include %occErrors
    Set status = $$$OK
    Try {
        Set props = ##class(%DynamicObject).%New()
        Do props.%Set("NameSpace", pNamespace)
        Do props.%Set("Enabled", 1)
        Do props.%Set("CSPEnabled", pCSPEnabled)
        Do props.%Set("CSPZENEnabled", pCSPEnabled)
        Do props.%Set("RESTEnabled", pRESTEnabled)
        // Siempre setear DispatchClass (incluso vacío) para evitar que quede un valor heredado.
        Do props.%Set("DispatchClass", pDispatchClass)
        If pCookiePath'="" Do props.%Set("SessionCookiePath", pCookiePath)
        Do props.%Set("AuthenticationMethods", "64,4") // Password + Unauthenticated (demo)
        If '##class(Security.Applications).Exists(pName) {
            Set status = ##class(Security.Applications).Create(pName, props)
        } Else {
            Set status = ##class(Security.Applications).Modify(pName, props)
        }
    } Catch ex {
        Set status = ex.AsStatus()
    }
    Quit status
}

}
