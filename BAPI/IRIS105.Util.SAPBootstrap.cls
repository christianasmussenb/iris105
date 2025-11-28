Class IRIS105.Util.SAPBootstrap Extends %RegisteredObject
{

/// Setup completo: Importa SAPJCo y genera clases de mensajes para RFC/BAPIs.
/// pJarPath: ruta al sapjco3.jar accesible por el SO donde corre IRIS.
/// pGatewayPort/Host: Java Gateway (debe estar levantado).
/// pTargetPackage: package donde caerán las clases ISCu* Request/Response.
/// pRfcListCSV: lista separada por coma de funciones SAP a generar.
/// pDestinationName: (opcional) nombre de destination JCo para hacer ping.
/// Devuelve %Status.
ClassMethod Setup(pJarPath As %String, pGatewayPort As %Integer = 55555, pGatewayHost As %String = "127.0.0.1", pTargetPackage As %String = "IRIS105.SAP", pRfcListCSV As %String = "", pDestinationName As %String = "") As %Status
{
    set sc = $$$OK
    do ..LogInfo("=== SAPBootstrap.Setup START ===")
    do ..LogInfo("JarPath="_pJarPath_"; Gateway="_pGatewayHost_":"_pGatewayPort_"; TargetPackage="_pTargetPackage)

    // 0) Prerequisitos mínimos
    set sc = ..CheckPrereqs()
    quit:$$$ISERR(sc) sc

    // 1) Importar SAPJCo + generar proxies base com.sap.conn.jco.*
    set sc = ..ImportJCo(pJarPath, pGatewayPort, pGatewayHost)
    quit:$$$ISERR(sc) sc

    // 2) Generar clases de mensajes para RFC/BAPIs
    if pRfcListCSV'="" {
        set sc = ..GenerateMessageClasses(pRfcListCSV, pTargetPackage)
        quit:$$$ISERR(sc) sc
    } else {
        do ..LogWarn("No se indicó pRfcListCSV. Se omite generación de clases de mensajes.")
    }

    // 3) Ping opcional a destination
    if pDestinationName'="" {
        set scPing = ..PingDestination(pDestinationName)
        if $$$ISERR(scPing) {
            do ..LogWarn("PingDestination falló (no fatal): "_$system.Status.GetOneErrorText(scPing))
        }
    }

    do ..LogInfo("=== SAPBootstrap.Setup END OK ===")
    quit sc
}

/// Verifica que existan clases del SAP adapter.
/// Si no están, no tiene sentido seguir.
ClassMethod CheckPrereqs() As %Status
{
    set sc = $$$OK

    if '##class(%Dictionary.ClassDefinition).%ExistsId("EnsLib.SAP.BootStrap") {
        set sc = $$$ERROR($$$GeneralError, "No existe EnsLib.SAP.BootStrap. Falta instalar/activar SAP Adapter.")
        do ..LogErr($system.Status.GetOneErrorText(sc))
        quit sc
    }

    if '##class(%Dictionary.ClassDefinition).%ExistsId("EnsLib.SAP.Utils") {
        set sc = $$$ERROR($$$GeneralError, "No existe EnsLib.SAP.Utils. Falta instalar SAP Adapter o estás en un namespace sin él.")
        do ..LogErr($system.Status.GetOneErrorText(sc))
        quit sc
    }

    do ..LogInfo("Prereqs OK: EnsLib.SAP.* presente.")
    quit sc
}

/// Importa sapjco3.jar y genera proxies base JCo en el namespace.
/// Requiere Java Gateway levantado.
ClassMethod ImportJCo(pJarPath As %String, pPort As %Integer, pHost As %String) As %Status
{
    do ..LogInfo("Importando sapjco3.jar y proxies base...")

    set sc = ##class(EnsLib.SAP.BootStrap).ImportSAP(pJarPath, pPort, pHost)
    if $$$ISERR(sc) {
        do ..LogErr("ImportSAP error: "_$system.Status.GetOneErrorText(sc))
        quit sc
    }

    // Validación rápida: clase Java proxy base
    if ##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCo") {
        do ..LogInfo("JCo proxies OK en este namespace.")
    } else {
        do ..LogWarn("No se detectó com.sap.conn.jco.JCo en este namespace. Revisa jar/gateway.")
    }

    quit sc
}

/// Genera clases Request/Response desde una lista CSV.
/// pRfcListCSV: "Z_FM_1,Z_FM_2,RFC_PING"
ClassMethod GenerateMessageClasses(pRfcListCSV As %String, pPackage As %String) As %Status
{
    do ..LogInfo("Generando clases de mensajes en package "_pPackage_" ...")

    set scAll = $$$OK
    set list = $zstrip(pRfcListCSV,"<>W")
    set n = $length(list, ",")

    for i=1:1:n {
        set rfc = $zstrip($piece(list,",",i),"<W")
        continue:rfc=""

        do ..LogInfo(" - CreateClasses para "_rfc)
        set sc = ..SafeCreateClasses(rfc, pPackage)
        if $$$ISERR(sc) {
            do ..LogErr("   ERROR en "_rfc_": "_$system.Status.GetOneErrorText(sc))
            set scAll = sc
            // si quieres seguir con los otros, comenta el quit siguiente
            quit
        } else {
            do ..LogInfo("   OK "_rfc)
        }
    }

    quit scAll
}

/// Wrapper defensivo para CreateClasses (por si cambia firma/método)
ClassMethod SafeCreateClasses(pRfcName As %String, pPackage As %String) As %Status
{
    // Verifica método CreateClasses exista
    if '##class(%Dictionary.MethodDefinition).%ExistsId("EnsLib.SAP.Utils:CreateClasses") {
        set sc = $$$ERROR($$$GeneralError, "EnsLib.SAP.Utils.CreateClasses no existe en esta instalación.")
        quit sc
    }

    set sc = ##class(EnsLib.SAP.Utils).CreateClasses(pRfcName, pPackage)
    quit sc
}

/// Hace ping usando JCoDestination si hay destino configurado.
/// No es fatal si falla.
ClassMethod PingDestination(pDest As %String) As %Status [ ProcedureBlock = 1 ]
{
    do ..LogInfo("Probando ping a destination "_pDest_" ...")

    set sc = $$$OK

    // Si no existen proxies Java, no hay cómo hacer ping.
    if '##class(%Dictionary.ClassDefinition).%ExistsId("com.sap.conn.jco.JCoDestinationManager") {
        set sc = $$$ERROR($$$GeneralError, "No existe JCoDestinationManager en este namespace. Omite ping.")
        quit sc
    }

    try {
        set dest = ##class(com.sap.conn.jco.JCoDestinationManager).getDestination(pDest)
        do dest.ping()
        do ..LogInfo("Ping OK a destination "_pDest)
    } catch ex {
        set sc = $$$ERROR($$$GeneralError, "Ping SAP falló: "_ex.DisplayString())
    }

    quit sc
}

/// Logging helpers
ClassMethod LogInfo(msg As %String)
{
    do $system.Event.Log("IRIS105.Util.SAPBootstrap", msg, "Info")
}

ClassMethod LogWarn(msg As %String)
{
    do $system.Event.Log("IRIS105.Util.SAPBootstrap", msg, "Warning")
}

ClassMethod LogErr(msg As %String)
{
    do $system.Event.Log("IRIS105.Util.SAPBootstrap", msg, "Error")
}

}
