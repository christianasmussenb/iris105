Class CUBO.BI.MockDataGenerator Extends %RegisteredObject [ ProcedureBlock ]
{

/// Ejecuta el llenado completo de dimensiones y fact con datos simulados.
ClassMethod RunAll(startDate As %String = "2024-01-01", months As %Integer = 12, aseguradoras As %Integer = 6, centros As %Integer = 4, maxInvoicesPerDay As %Integer = 8) As %Status
{
    set sc=..ClearAll()
    quit:'$SYSTEM.Status.IsOK(sc) sc

    set sc=..FillDimAseguradora(aseguradoras)
    quit:'$SYSTEM.Status.IsOK(sc) sc

    set sc=..FillDimCentro(centros)
    quit:'$SYSTEM.Status.IsOK(sc) sc

    set sc=..FillDimTiempo(startDate,months)
    quit:'$SYSTEM.Status.IsOK(sc) sc

    set sc=..FillFact(startDate,months,aseguradoras,centros,maxInvoicesPerDay)
    quit sc
}

/// Borra datos previos de dimensiones y fact para partir limpio.
ClassMethod ClearAll() As %Status
{
    set sc=##class(CUBO.BI.FactFacturaGlosaCartera).%KillExtent()
    quit:'$SYSTEM.Status.IsOK(sc) sc
    set sc=##class(CUBO.BI.DimTiempo).%KillExtent()
    quit:'$SYSTEM.Status.IsOK(sc) sc
    set sc=##class(CUBO.BI.DimAseguradora).%KillExtent()
    quit:'$SYSTEM.Status.IsOK(sc) sc
    set sc=##class(CUBO.BI.DimCentro).%KillExtent()
    quit sc
}

ClassMethod FillDimAseguradora(top As %Integer = 6) As %Status
{
    set sc=$SYSTEM.Status.OK()
    set data(1)="SaludPlus^Fonasa^Publica"
    set data(2)="VivaCare^Isapre^Privada"
    set data(3)="AndesVida^Isapre^Privada"
    set data(4)="Protegida EPS^EPS^Publica"
    set data(5)="Integral Salud^EPS^Privada"
    set data(6)="Red Mutual^Otro^Privada"
    set data(7)="Pacifica^Isapre^Privada"
    set data(8)="Universal^Fonasa^Publica"

    for i=1:1:top {
        if '$data(data(i)) quit
        set row=data(i)
        set obj=##class(CUBO.BI.DimAseguradora).%New()
        set obj.AseguradoraID=i
        set obj.Nombre=$piece(row,"^",1)
        set obj.Tipo=$piece(row,"^",2)
        set obj.Segmento=$piece(row,"^",3)
        set sc=obj.%Save()
        quit:'$SYSTEM.Status.IsOK(sc)
    }
    quit $SYSTEM.Status.OK()
}

ClassMethod FillDimCentro(top As %Integer = 4) As %Status
{
    set sc=$SYSTEM.Status.OK()
    set data(1)="Clinica Central^Hospital^Santiago^RM"
    set data(2)="Centro Norte^Ambulatorio^Valparaiso^V"
    set data(3)="Red Sur^Hospital^Concepcion^VIII"
    set data(4)="Clinica Andes^Ambulatorio^La Serena^IV"
    set data(5)="Urgencias Costa^Urgencias^Valdivia^XIV"

    for i=1:1:top {
        if '$data(data(i)) quit
        set row=data(i)
        set obj=##class(CUBO.BI.DimCentro).%New()
        set obj.CentroID=i
        set obj.Nombre=$piece(row,"^",1)
        set obj.TipoCentro=$piece(row,"^",2)
        set obj.Ciudad=$piece(row,"^",3)
        set obj.Region=$piece(row,"^",4)
        set sc=obj.%Save()
        quit:'$SYSTEM.Status.IsOK(sc)
    }
    quit $SYSTEM.Status.OK()
}

ClassMethod FillDimTiempo(startDate As %String = "2024-01-01", months As %Integer = 12) As %Status
{
    set start=$ZDATEH(startDate,3)
    quit:start="" $SYSTEM.Status.Error(5001,"Fecha invalida: "_startDate)
    quit:start<0 $SYSTEM.Status.Error(5001,"Fecha invalida: "_startDate)
    set days=months*31
    set sc=$SYSTEM.Status.OK()
    for i=0:1:days-1 {
        set hDate=start+i
        set dateStr=$ZDATE(hDate,3)
        set obj=##class(CUBO.BI.DimTiempo).%New()
        set obj.DateKey=$translate(dateStr,"-","")
        set obj.Fecha=hDate
        set obj.Dia=+$piece(dateStr,"-",3)
        set obj.Mes=+$piece(dateStr,"-",2)
        set obj.Anio=+$piece(dateStr,"-",1)
        set obj.Trimestre=((obj.Mes-1)\3)+1
        set obj.Semana=((hDate-start)\7)+1
        set sc=obj.%Save()
        quit:'$SYSTEM.Status.IsOK(sc)
    }
    quit $SYSTEM.Status.OK()
}

ClassMethod FillFact(startDate As %String = "2024-01-01", months As %Integer = 12, aseguradoras As %Integer = 6, centros As %Integer = 4, maxInvoicesPerDay As %Integer = 8) As %Status
{
    set start=$ZDATEH(startDate,3)
    quit:start="" $SYSTEM.Status.Error(5001,"Fecha invalida: "_startDate)
    quit:start<0 $SYSTEM.Status.Error(5001,"Fecha invalida: "_startDate)
    set days=months*31
    set today=$piece($horolog,",",1)
    set sc=$SYSTEM.Status.OK()

    set lineas(1)="Ambulatorio"
    set lineas(2)="Hospitalizacion"
    set lineas(3)="Urgencias"
    set lineas(4)="Cirugia"
    set fuentes(1)="R58",fuentes(2)="R60",fuentes(3)="R82",fuentes(4)="R615"

    set invCounter=1
    for d=0:1:days-1 {
        set fechaFactura=start+d
        for a=1:1:aseguradoras {
            for c=1:1:centros {
                set nFact=$random(maxInvoicesPerDay+1)
                for n=1:1:nFact {
                    set factura=##class(CUBO.BI.FactFacturaGlosaCartera).%New()
                    set factura.FacturaNum="F"_$translate($ZDATE(fechaFactura,3),"-","")_"-"_a_"-"_c_"-"_n
                    set factura.AseguradoraID=a
                    set factura.CentroID=c
                    set factura.PacienteID=$random(5000)+1
                    set factura.EpisodioID=$random(3000)+1
                    set factura.FechaFactura=fechaFactura
                    set factura.FechaRadicacion=fechaFactura+$random(6)
                    set factura.FechaVencimiento=fechaFactura+60

                    set factura.LineaNegocio=lineas((($random(100)\25)+1))
                    set factura.FuenteReporte=fuentes((($random(100)\25)+1))

                    set base=100000 + $random(1900001)
                    set factura.MontoFacturado=base
                    set factura.MontoRadicado=base*((95+$random(6))/100)

                    set percGlosa=$random(21)/100
                    set factura.MontoGlosaInicial=factura.MontoRadicado*percGlosa
                    set factura.NumGlosas=$select(percGlosa=0:0,1:($random(3)+1))

                    set percRechazo=$random(60)/100
                    set factura.MontoRechazado=factura.MontoGlosaInicial*percRechazo

                    set percRecuperado=$random(70)/100
                    set factura.MontoRecuperado=(factura.MontoGlosaInicial-factura.MontoRechazado)*percRecuperado
                    set factura.MontoAceptado=factura.MontoRadicado - factura.MontoRechazado + factura.MontoRecuperado

                    if factura.MontoGlosaInicial>0 {
                        set factura.FechaGlosa=factura.FechaRadicacion+$random(15)+1
                        set factura.MontoGlosaFirmada=factura.MontoGlosaInicial*(0.6+($random(40)/100))
                        set factura.MontoGlosaEnTramite=factura.MontoGlosaInicial - factura.MontoGlosaFirmada
                    } else {
                        set factura.FechaGlosa=""
                        set factura.MontoGlosaFirmada=0
                        set factura.MontoGlosaEnTramite=0
                    }

                    set pagoChance=$random(100)
                    if pagoChance<65 {
                        set factura.FechaPago=factura.FechaFactura+(10+$random(20))
                        set factura.SaldoCartera=0
                        set factura.DiasMora=0
                        set factura.EstadoFactura="Pagada"
                        set factura.EstadoCartera="Cerrada"
                    } elseif pagoChance<85 {
                        set factura.FechaPago=""
                        set factura.SaldoCartera=factura.MontoRadicado*0.4
                        set factura.DiasMora=10+$random(60)
                        set factura.EstadoFactura="En proceso"
                        set factura.EstadoCartera=..CarteraBucket(factura.DiasMora)
                    } else {
                        set factura.FechaPago=""
                        set factura.SaldoCartera=factura.MontoRadicado*0.8
                        set factura.DiasMora=60+$random(150)
                        set factura.EstadoFactura="En cartera"
                        set factura.EstadoCartera=..CarteraBucket(factura.DiasMora)
                    }

                    set factura.DiasDesdeRadicacion=$select(today>factura.FechaRadicacion:today-factura.FechaRadicacion,1:0)

                    set sc=factura.%Save()
                    quit:'$SYSTEM.Status.IsOK(sc)
                    set invCounter=invCounter+1
                }
                quit:'$SYSTEM.Status.IsOK($get(sc))
            }
            quit:'$SYSTEM.Status.IsOK($get(sc))
        }
        quit:'$SYSTEM.Status.IsOK($get(sc))
    }
    quit $SYSTEM.Status.OK()
}

ClassMethod CarteraBucket(dias As %Integer) As %String
{
    quit $select(dias=0:"Cerrada",dias<31:"0-30",dias<61:"31-60",dias<91:"61-90",1:">90")
}

}
