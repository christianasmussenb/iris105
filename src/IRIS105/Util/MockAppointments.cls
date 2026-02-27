Class IRIS105.Util.MockAppointments Extends %RegisteredObject
{

ClassMethod GenerateAppointments(params As %DynamicObject) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set occupancy = +$Select(params.%IsDefined("occupancyPct"):params.%Get("occupancyPct"),1:0.85)
        Set nPhysicians = $Select(params.%IsDefined("physicians"):params.%Get("physicians"),1:8)
        Set nBoxes = $Select(params.%IsDefined("boxes"):params.%Get("boxes"),1:3)
        Set nSpecialties = $Select(params.%IsDefined("specialties"):params.%Get("specialties"),1:3)
        Set totalDays = $Select(params.%IsDefined("totalDays"):params.%Get("totalDays"),1:90)
        Set nPatients = $Select(params.%IsDefined("patients"):params.%Get("patients"),1:100)
        Set defaultNoShowRate = +$Select(params.%IsDefined("defaultNoShowRate"):params.%Get("defaultNoShowRate"),1:0.15)
        Set weekdayStartHour = +$Select(params.%IsDefined("weekdayStartHour"):params.%Get("weekdayStartHour"),1:8)
        Set weekdayEndHour = +$Select(params.%IsDefined("weekdayEndHour"):params.%Get("weekdayEndHour"),1:18)
        Set saturdayStartHour = +$Select(params.%IsDefined("saturdayStartHour"):params.%Get("saturdayStartHour"),1:9)
        Set saturdayEndHour = +$Select(params.%IsDefined("saturdayEndHour"):params.%Get("saturdayEndHour"),1:14)
        
        Set specialtyNoShowRates = ""
        If params.%IsDefined("specialtyNoShowRates") {
            Set specialtyNoShowRates = params.%Get("specialtyNoShowRates")
        }
        If '$IsObject(specialtyNoShowRates) {
            Set specialtyNoShowRates = ##class(%DynamicObject).%New()
        }
        
        If nPhysicians<1 {
            Set tSC = $$$ERROR($$$GeneralError,"At least one physician is required")
            Quit:$$$ISERR(tSC)
        }
        If totalDays<1 {
            Set tSC = $$$ERROR($$$GeneralError,"Total days must be positive")
            Quit:$$$ISERR(tSC)
        }
        If nPatients<1 {
            Set tSC = $$$ERROR($$$GeneralError,"At least one patient is required")
            Quit:$$$ISERR(tSC)
        }
        If nBoxes<1 Set nBoxes = 1
        If nSpecialties<1 Set nSpecialties = 1
        If occupancy<0 Set occupancy = 0
        If occupancy>1 Set occupancy = 1
        If weekdayStartHour<0 Set weekdayStartHour = 0
        If weekdayEndHour>24 Set weekdayEndHour = 24
        If saturdayStartHour<0 Set saturdayStartHour = 0
        If saturdayEndHour>24 Set saturdayEndHour = 24
        If weekdayEndHour<=weekdayStartHour {
            Set tSC = $$$ERROR($$$GeneralError,"Invalid weekday schedule (start/end hour)")
            Quit:$$$ISERR(tSC)
        }
        If saturdayEndHour<=saturdayStartHour {
            Set tSC = $$$ERROR($$$GeneralError,"Invalid saturday schedule (start/end hour)")
            Quit:$$$ISERR(tSC)
        }
        
        // Lista de médicos por especialidad para distribuir citas de forma consistente
        Set stmtPhys = ##class(%SQL.Statement).%New()
        Set tSC = stmtPhys.%Prepare("SELECT PhysicianId, SpecialtyId FROM IRIS105.Physician ORDER BY PhysicianId")
        Quit:$$$ISERR(tSC)
        Set rsPhys = stmtPhys.%Execute()
        Set allPhysCount = 0
        While rsPhys.%Next() {
            Set phyId = rsPhys.%Get("PhysicianId")
            Set specId = rsPhys.%Get("SpecialtyId")
            If phyId="" Continue
            Set allPhysCount = allPhysCount + 1
            Set allPhys(allPhysCount) = phyId
            If specId'="" {
                Set specPhysCount(specId) = +$Get(specPhysCount(specId)) + 1
                Set specPhys(specId,specPhysCount(specId)) = phyId
            }
        }
        If allPhysCount<1 {
            Set tSC = $$$ERROR($$$GeneralError,"No physicians available to assign appointments")
            Quit:$$$ISERR(tSC)
        }
        
        // 1=Domingo, 7=Sábado (DATEPART weekday en IRIS)
        Set stmtDow = ##class(%SQL.Statement).%New()
        Set tSC = stmtDow.%Prepare("SELECT DATEPART('weekday',CAST(? AS DATE)) AS DOW")
        Quit:$$$ISERR(tSC)
        
        Set apptCounter = 1
        For dayOffset=0:1:(totalDays-1) {
            Set dayDate = $ZDATE($HOROLOG + dayOffset,3)
            Set rsDow = stmtDow.%Execute(dayDate)
            Set dow = 0
            If $IsObject(rsDow), rsDow.%Next() Set dow = +rsDow.%Get("DOW")
            If dow=1 Continue
            
            Set startHour = weekdayStartHour
            Set endHour = weekdayEndHour
            If dow=7 {
                Set startHour = saturdayStartHour
                Set endHour = saturdayEndHour
            }
            
            For hour=startHour:1:(endHour-1) {
                Set hstr = $Select(hour<10:"0"_hour,1:hour)
                Set startStamp = dayDate_" "_hstr_":00:00"
                Set endHourStamp = hour + 1
                Set ehstr = $Select(endHourStamp<10:"0"_endHourStamp,1:endHourStamp)
                Set endStamp = dayDate_" "_ehstr_":00:00"
                For boxIdx=1:1:nBoxes {
                    Set boxId = "BOX-"_boxIdx
                    For specIdx=1:1:nSpecialties {
                        Set specId = "SPEC-"_specIdx
                        If ($Random(10000) < (occupancy*10000)) {
                            Set tAppointment = ##class(IRIS105.Appointment).%New()
                            Set tAppointment.AppointmentId = "APPT-"_apptCounter
                            Set tAppointment.PatientId = "PAT-"_($Random(nPatients)+1)
                            Set tAppointment.BoxId = boxId
                            Set tAppointment.SpecialtyId = specId
                            
                            Set phyCount = +$Get(specPhysCount(specId))
                            If phyCount>0 {
                                Set nextSpecIdx = +$Get(specPhysCursor(specId)) + 1
                                If nextSpecIdx>phyCount Set nextSpecIdx = 1
                                Set specPhysCursor(specId) = nextSpecIdx
                                Set tAppointment.PhysicianId = $Get(specPhys(specId,nextSpecIdx))
                            } Else {
                                Set nextAnyIdx = +$Get(anyPhysCursor) + 1
                                If nextAnyIdx>allPhysCount Set nextAnyIdx = 1
                                Set anyPhysCursor = nextAnyIdx
                                Set tAppointment.PhysicianId = $Get(allPhys(nextAnyIdx))
                            }
                            
                            Set tAppointment.StartDateTime = startStamp
                            Set tAppointment.EndDateTime = endStamp
                            Set tAppointment.BookingChannel = $Select(($Random(3)=0):"WEB",($Random(2)=0):"CALLCENTER",1:"PRESENCIAL")
                            Set tAppointment.BookingDaysInAdvance = $Random(45)
                            Set tAppointment.HasSMSReminder = ($Random(100)<70)
                            Set tAppointment.Reason = "Consulta"
                            Set noShowRate = ..%SpecialtyNoShowRate(specId, specialtyNoShowRates, defaultNoShowRate)
                            Set tAppointment.NoShow = ($Random(10000) < (noShowRate*10000))
                            
                            Set tSC = tAppointment.%Save()
                            Quit:$$$ISERR(tSC)
                            
                            Set apptCounter = apptCounter + 1
                        }
                    }
                    Quit:$$$ISERR(tSC)
                }
                Quit:$$$ISERR(tSC)
            }
            Quit:$$$ISERR(tSC)
        }
        
        If '$SYSTEM.Status.IsError(tSC) {
            Write !,"[MockAppointments] Generadas ",(apptCounter-1)," citas"
        }
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

ClassMethod %SpecialtyNoShowRate(pSpecialtyId As %String, pRates As %DynamicObject, pDefault As %Double = 0.15) As %Double [ ProcedureBlock = 1 ]
{
    Set rate = +pDefault
    If $IsObject(pRates), pRates.%IsDefined(pSpecialtyId) {
        Set rate = +pRates.%Get(pSpecialtyId)
    }
    If rate<0 Set rate = 0
    If rate>1 Set rate = 1
    Quit rate
}

}
