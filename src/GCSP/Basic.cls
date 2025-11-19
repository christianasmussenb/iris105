Class GCSP.Basic Extends %CSP.Page
{

ClassMethod OnPage() As %Status
{
    Set base = "/csp/mltest"
    Write "<!DOCTYPE html>"
    Write "<html lang=""es"">"
    Write "<head>"
    Write "<meta charset=""UTF-8"">"
    Write "<title>NoShow Demo</title>"
    Write "<style>"
    Write "body{font-family:Arial, sans-serif;max-width:960px;margin:20px auto;padding:0 16px;background:#f7f7f7;color:#222;}"
    Write ".card{background:#fff;border:1px solid #ddd;border-radius:8px;padding:16px;margin-bottom:12px;box-shadow:0 1px 2px rgba(0,0,0,0.05);}"
    Write ".row{display:flex;gap:12px;flex-wrap:wrap;}"
    Write ".row .card{flex:1;min-width:250px;}"
    Write "button{background:#0f62fe;color:#fff;border:none;border-radius:6px;padding:10px 14px;cursor:pointer;font-weight:600;}"
    Write "button:hover{background:#0d53d9;}"
    Write "input, select{padding:8px;border:1px solid #ccc;border-radius:6px;width:100%;box-sizing:border-box;}"
    Write ".label{font-size:12px;color:#555;margin-bottom:4px;display:block;}"
    Write "pre{background:#111;color:#0f0;padding:12px;border-radius:6px;overflow:auto;}"
    Write "</style>"
    Write "</head>"
    Write "<body>"
    Write "<h1>NoShowModel2 - Demo rápida</h1>"
    
    Write "<div class=""card"">"
    Write "<h3>Estadísticas</h3>"
    Write "<button onclick=""loadStats()"">Ver estadísticas</button>"
    Write "<pre id=""stats"">Esperando...</pre>"
    Write "</div>"
    
    Write "<div class=""row"">"
    Write "<div class=""card"">"
    Write "<h3>Score por AppointmentId</h3>"
    Write "<label class=""label"">AppointmentId</label>"
    Write "<input id=""apptId"" placeholder=""APPT-12"">"
    Write "<button style=""margin-top:8px;"" onclick=""scoreAppointment()"">Calcular NoShow</button>"
    Write "<pre id=""scoreAppt"">Esperando...</pre>"
    Write "</div>"
    
    Write "<div class=""card"">"
    Write "<h3>Score por PatientId (última cita)</h3>"
    Write "<label class=""label"">PatientId</label>"
    Write "<input id=""patientId"" placeholder=""1"">"
    Write "<button style=""margin-top:8px;"" onclick=""scoreLastPatient()"">Calcular NoShow</button>"
    Write "<pre id=""scorePatient"">Esperando...</pre>"
    Write "</div>"
    Write "</div>"
    
    Write "<div class=""card"">"
    Write "<h3>Generar datos mock</h3>"
    Write "<div class=""row"">"
    Write "<div style=""flex:1;min-width:150px;""><label class=""label"">Meses</label><input id=""months"" type=""number"" min=""1"" max=""12"" placeholder=""3""></div>"
    Write "<div style=""flex:1;min-width:150px;""><label class=""label"">Occupancy (0-1)</label><input id=""occupancy"" type=""number"" step=""0.05"" min=""0"" max=""1"" placeholder=""0.85""></div>"
    Write "<div style=""flex:1;min-width:150px;""><label class=""label"">Pacientes</label><input id=""patients"" type=""number"" min=""10"" max=""10000"" placeholder=""100""></div>"
    Write "</div>"
    Write "<button style=""margin-top:8px;"" onclick=""generateMock()"">Generar</button>"
    Write "<pre id=""mockResult"">Esperando...</pre>"
    Write "</div>"
    
    Write "<script>"
    Write "const base='"_base_"';"
    Write "async function loadStats(){const r=await fetch(base+'/api/ml/stats/summary');document.getElementById('stats').textContent=await r.text();}"
    Write "async function scoreAppointment(){const id=document.getElementById('apptId').value;const r=await fetch(base+'/api/ml/noshow/score',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({appointmentId:id})});document.getElementById('scoreAppt').textContent=await r.text();}"
    Write "async function scoreLastPatient(){const pid=document.getElementById('patientId').value;if(!pid){document.getElementById('scorePatient').textContent='Debe indicar PatientId';return;}const qs='?patientId='+encodeURIComponent(pid);const r=await fetch(base+'/api/ml/stats/lastAppointmentByPatient' + qs);const txt=await r.text();document.getElementById('scorePatient').textContent=txt;}"
    Write "async function generateMock(){const months=document.getElementById('months').value;const occupancy=document.getElementById('occupancy').value;const patients=document.getElementById('patients').value;const payload={};if(months)payload.months=+months;if(occupancy)payload.targetOccupancy=+occupancy;if(patients)payload.patients=+patients;const r=await fetch(base+'/api/ml/mock/generate',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});document.getElementById('mockResult').textContent=await r.text();}"
    Write "</script>"
    Write "</body></html>"
    Quit $$$OK
}

}
