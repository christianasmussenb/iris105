Class IRIS105.Util.MockAppointments Extends %RegisteredObject
{

ClassMethod GenerateAppointments(params As %DynamicObject) As %Status [ ProcedureBlock = 1 ]
{
    Set tSC = $$$OK
    Try {
        Set occupancy = $Select(params.%IsDefined("occupancyPct"):params.%Get("occupancyPct"),1:0.85)
        Set nPhysicians = $Select(params.%IsDefined("physicians"):params.%Get("physicians"),1:8)
        Set nBoxes = $Select(params.%IsDefined("boxes"):params.%Get("boxes"),1:3)
        Set nSpecialties = $Select(params.%IsDefined("specialties"):params.%Get("specialties"),1:3)
        Set slotsPerDay = $Select(params.%IsDefined("slotsPerDay"):params.%Get("slotsPerDay"),1:8)
        Set totalDays = $Select(params.%IsDefined("totalDays"):params.%Get("totalDays"),1:90)
        Set nPatients = $Select(params.%IsDefined("patients"):params.%Get("patients"),1:100)
        
        If nPhysicians<1 {
            Set tSC = $$$ERROR($$$GeneralError,"At least one physician is required")
            Quit:$$$ISERR(tSC)
        }
        If slotsPerDay<1 {
            Set tSC = $$$ERROR($$$GeneralError,"Slots per day must be positive")
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
        
        Set apptCounter = 1
        For dayOffset=0:1:(totalDays-1) {
            Set dayDate = $ZDATE($HOROLOG + dayOffset,3)
            For phy=1:1:nPhysicians {
                For slot=1:1:slotsPerDay {
                    If ($Random(100) < (occupancy*100)) {
                        Set tAppointment = ##class(IRIS105.Appointment).%New()
                        Set tAppointment.AppointmentId = "APPT-"_apptCounter
                        Set tAppointment.PatientId = "PAT-"_($Random(nPatients)+1)
                        Set tAppointment.PhysicianId = "PHY-"_phy
                        Set tAppointment.BoxId = "BOX-"_($Random(nBoxes)+1)
                        
                        Set specialtyIndex = ((phy-1) # nSpecialties) + 1
                        Set tAppointment.SpecialtyId = "SPEC-"_specialtyIndex
                        
                        Set hour = 8 + (slot-1)
                        Set hstr = $Select(hour<10:"0"_hour,1:hour)
                        Set startStamp = dayDate_" "_hstr_":00:00"
                        Set endStamp = dayDate_" "_hstr_":30:00"
                        Set tAppointment.StartDateTime = startStamp
                        Set tAppointment.EndDateTime = endStamp
                        
                        Set tAppointment.BookingChannel = $Select(($Random(3)=0):"WEB",($Random(2)=0):"CALLCENTER",1:"PRESENCIAL")
                        Set tAppointment.BookingDaysInAdvance = $Random(30)
                        Set tAppointment.HasSMSReminder = ($Random(2)=0)
                        Set tAppointment.Reason = "Consulta"
                        Set tAppointment.NoShow = ($Random(100) < 15)
                        
                        Set tSC = tAppointment.%Save()
                        Quit:$$$ISERR(tSC)
                        
                        Set apptCounter = apptCounter + 1
                    }
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

}
