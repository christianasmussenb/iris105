Class IRIS105.Util.MockAppointments Extends %RegisteredObject
{

ClassMethod GenerateAppointments(params As %DynamicObject) As %Status
{
    Set sc = 1
    TRY {
        Set occupancy = $Get(params.occupancyPct,0.85)
        Set nPhysicians = $Get(params.physicians,8)
        Set nBoxes = $Get(params.boxes,3)
        Set nSpecialties = $Get(params.specialties,3)
        Set slotsPerDay = $Get(params.slotsPerDay,8)
        Set totalDays = $Get(params.totalDays,90)
        Set nPatients = $Get(params.patients,100)
        
        If nPhysicians<1 Return 1
        If nBoxes<1 Set nBoxes = 1
        If nSpecialties<1 Set nSpecialties = 1
        If slotsPerDay<1 Return 1
        If totalDays<1 Return 1
        If nPatients<1 Return 1
        
        Set apptCounter = 1
        For d=0:1:(totalDays-1) {
            Set dayDate = $ZDATE($H+d,3)
            For phy=1:1:nPhysicians {
                For s=1:1:slotsPerDay {
                    If ($Random(100) < occupancy*100) {
                        Set appt = ##class(IRIS105.Appointment).%New()
                        Set appt.AppointmentId = "APPT-"_apptCounter
                        Set appt.PatientId = "PAT-"_($Random(nPatients)+1)
                        Set appt.PhysicianId = "PHY-"_phy
                        Set appt.BoxId = "BOX-"_($Random(nBoxes)+1)
                        
                        Set specialtyIndex = $Select(nSpecialties>0:((phy-1) # nSpecialties) + 1,1:1)
                        Set appt.SpecialtyId = "SPEC-"_specialtyIndex
                        
                        Set hour = 8 + (s-1)
                        Set hstr = $Select(hour<10:"0"_hour,1:hour)
                        Set appt.StartDateTime = dayDate_" "_hstr_":00:00"
                        Set appt.EndDateTime = dayDate_" "_hstr_":30:00"
                        
                        Set appt.BookingChannel = $Select(($Random(3)=0):"WEB",($Random(2)=0):"CALLCENTER",1:"PRESENCIAL")
                        Set appt.BookingDaysInAdvance = $Random(30)
                        Set appt.HasSMSReminder = ($Random(2)=0)
                        Set appt.Reason = "Consulta"
                        Set appt.NoShow = ($Random(100) < 15)
                        
                        Set sc = appt.%Save()
                        If '$System.Status.IsOK(sc) Return sc
                        
                        Set apptCounter = apptCounter + 1
                    }
                }
            }
        }
    }
    CATCH ex {
        Set sc = ex.AsStatus()
    }
    Quit sc
}

}
