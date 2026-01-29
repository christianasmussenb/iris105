# Troubleshooting - Solución de Problemas

Soluciones a problemas comunes en IRIS105.

## 🔧 Problemas de Instalación y Configuración

### Namespace no Existe

**Error**:
```
<NAMESPACE>MLTEST
```

**Solución**:
```objectscript
ZN "%SYS"
Do ##class(%SYS.Namespace).Create("MLTEST","USER")
Do ##class(%EnsembleMgr).EnableNamespace("MLTEST",1)
```

---

### Clases no se Encuentran

**Error**:
```
ERROR #5540: Class 'IRIS105.Domain.Patient' does not exist
```

**Solución**:
```objectscript
ZN "MLTEST"
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```

Si las clases no están en el sistema:
```bash
# Copiar src/ al contenedor
docker cp ./src <container>:/opt/irisapp/iris/src/

# Cargar clases
iris session IRIS -U MLTEST "Do $system.OBJ.LoadDir(\"/opt/irisapp/iris/src\",\"ckr\")"
```

---

### Error de Compilación

**Error**:
```
ERROR #5540: Unable to compile class
```

**Diagnóstico**:
```objectscript
// Ver errores de compilación
Do $system.OBJ.Compile("IRIS105.Domain.Patient","ckd")
```

**Causas comunes**:
1. Sintaxis incorrecta
2. Clase base no existe
3. Referencias a clases inexistentes

**Solución**: Revisar mensaje de error específico y corregir código.

---

## 🌐 Problemas de Web Applications

### Web App no Existe

**Error**: 404 al acceder a `/csp/mltest/api/health`

**Solución**:
```objectscript
ZN "%SYS"
Do ##class(IRIS105.Util.WebAppSetup).ConfigureAll()
```

---

### Error 401 Unauthorized

**Error**: Todos los endpoints (excepto /health) retornan 401

**Causa**: Token no configurado o inválido

**Solución**:
```objectscript
ZN "MLTEST"
Set ^IRIS105("API","Tokens","demo-readonly-token")=1
```

Verificar:
```objectscript
ZWrite ^IRIS105("API","Tokens",*)
```

---

### Error de CORS

**Error**: En navegador, error CORS al llamar API desde otra origen

**Solución temporal**: Añadir headers CORS en `NoShowService.cls`:

```objectscript
ClassMethod OnPreDispatch(...) As %Boolean
{
  Set %response.ContentType = "application/json"
  Do %response.SetHeader("Access-Control-Allow-Origin","*")
  Do %response.SetHeader("Access-Control-Allow-Methods","GET,POST,OPTIONS")
  Do %response.SetHeader("Access-Control-Allow-Headers","Authorization,Content-Type")
  
  // Handle OPTIONS preflight
  If %request.Method = "OPTIONS" {
    Return 1  // Don't continue to main handler
  }
  
  Return ..ValidateToken()
}
```

**Nota**: Para producción, configurar orígenes específicos, no `*`.

---

## 🤖 Problemas de Machine Learning

### Modelo no Encontrado

**Error**:
```json
{
  "success": false,
  "error": "Model NoShowModel2 not found"
}
```

**Solución**:
```sql
-- Verificar si existe
SELECT MODEL_NAME FROM INFORMATION_SCHEMA.ML_MODELS;

-- Si no existe, crear
CREATE MODEL NoShowModel2 PREDICTING (NoShow) FROM IRIS105_Domain.Appointment;
```

---

### Modelo no Entrenado

**Error**:
```
ERROR: Model 'NoShowModel2' has no trained model
```

**Solución**:
```sql
TRAIN MODEL NoShowModel2 USING {
  "seed": 42,
  "TrainMode": "BALANCE",
  "MaxTime": 60
};
```

Verificar:
```sql
SELECT TRAINED_MODEL_NAME, TRAINING_STATUS
FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS
WHERE MODEL_NAME = 'NoShowModel2';
```

---

### Error al Entrenar: No Hay Datos

**Error**:
```
ERROR: Insufficient data to train model
```

**Causa**: Tabla `Appointment` vacía o con muy pocos registros

**Solución**:
```objectscript
ZN "MLTEST"
Do ##class(IRIS105.Util.MockData).Generate()
```

Verificar:
```sql
SELECT COUNT(*) FROM IRIS105_Domain.Appointment;
```

Mínimo recomendado: 100 registros.

---

### Performance de Scoring Lenta

**Síntoma**: Endpoint `/api/ml/noshow/score` tarda > 2 segundos

**Solución 1 - Añadir Índices**:
```sql
CREATE INDEX AppointmentPatientIdx ON IRIS105_Domain.Appointment (PatientId);
CREATE INDEX AppointmentPhysicianIdx ON IRIS105_Domain.Appointment (PhysicianId);
```

**Solución 2 - Purgar Cache SQL**:
```objectscript
Do $SYSTEM.SQL.Purge()
```

**Solución 3 - Re-entrenar con Más Tiempo**:
```sql
TRAIN MODEL NoShowModel2 USING {"MaxTime": 300};
```

---

## 📊 Problemas de Datos

### Datos Mock no se Generan

**Error**: `MockData.Generate()` retorna error

**Diagnóstico**:
```objectscript
Set sc = ##class(IRIS105.Util.MockData).Generate()
If $$$ISERR(sc) {
  Write $System.Status.GetErrorText(sc)
}
```

**Causas comunes**:
1. Namespace incorrecto
2. Clases no compiladas
3. Falta de permisos

**Solución**:
```objectscript
ZN "MLTEST"
Do $system.OBJ.CompilePackage("IRIS105","ckr")
Set sc = ##class(IRIS105.Util.MockData).Generate()
```

---

### Duplicados en Datos

**Síntoma**: Múltiples pacientes con mismo FirstName+LastName

**Causa**: Generadores mock usan listas pequeñas

**Solución**: No es un problema para POC. Para producción, usar datos reales.

---

### NoShow Rate Muy Alto o Muy Bajo

**Síntoma**: `noShowRate` en stats es 0% o 100%

**Causa**: Error en generación de datos mock

**Solución**:
```objectscript
// Limpiar datos
Do ##class(IRIS105.Domain.Appointment).%DeleteExtent()

// Regenerar
Do ##class(IRIS105.Util.MockData).Generate()
```

---

## 🔍 Problemas de API REST

### Endpoint Retorna 404

**Error**: Endpoint válido retorna 404

**Diagnóstico**:
1. Verificar URL exacta en `UrlMap` de `NoShowService.cls`
2. Verificar método HTTP (GET vs POST)

**Solución**:
```objectscript
// Recompilar servicio REST
Do $system.OBJ.Compile("IRIS105.REST.NoShowService","ck")

// Purgar cache
Do $SYSTEM.SQL.Purge()

// Reiniciar web server (si es necesario)
Do ##class(%SYS.System).WriteToConsoleLog("Restart needed")
```

---

### Response JSON Mal Formado

**Error**: JSON parsing error en cliente

**Causa**: Error en construcción de JSON en ObjectScript

**Diagnóstico**: Probar endpoint directamente:
```bash
curl -v http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"
```

**Solución típica**: Asegurar que se usa `%DynamicObject`:
```objectscript
Set response = {}
Do response.%Set("success", 1)
Do response.%Set("data", dataObject)
Write response.%ToJSON()
```

---

### Query Parameters no se Leen

**Error**: `limit` o `startDate` no tienen efecto

**Causa**: Error en lectura de parámetros

**Solución**: En `NoShowService.cls`, leer parámetros correctamente:
```objectscript
// De query string
Set limit = %request.Get("limit", 5)

// De body JSON
Set jsonBody = %request.Content
If jsonBody '= "" {
  Set obj = ##class(%DynamicAbstractObject).%FromJSON(jsonBody)
  Set limit = obj.limit
}
```

---

## 💾 Problemas de Globals

### Global no Existe

**Error**: 
```objectscript
Write ^IRIS105("API","Tokens","test")
<UNDEFINED>
```

**Solución**:
```objectscript
Do ##class(IRIS105.Util.ProjectSetup).Init()
```

O manualmente:
```objectscript
Set ^IRIS105("API","Tokens","demo-readonly-token")=1
Set ^IRIS105("Config","Capacity","default")=240
```

---

### Limpiar Globals

**Para testing**: Limpiar y reinicializar globals:
```objectscript
Kill ^IRIS105
Do ##class(IRIS105.Util.ProjectSetup).Init()
```

---

## 🚀 Problemas de Performance

### API Lenta (> 5 segundos)

**Diagnóstico**:
1. Verificar tamaño de dataset
2. Revisar queries SQL complejos
3. Verificar índices

**Solución 1 - Añadir Índices**:
```sql
CREATE INDEX AppointmentDateIdx ON IRIS105_Domain.Appointment (StartDateTime);
CREATE INDEX AppointmentSpecialtyDateIdx ON IRIS105_Domain.Appointment (SpecialtyId, StartDateTime);
```

**Solución 2 - Limitar Resultados**:
En analytics endpoints, siempre usar LIMIT:
```sql
SELECT ... LIMIT 100
```

**Solución 3 - Optimizar Queries**:
Evitar subconsultas complejas, usar JOINs directos.

---

### Out of Memory

**Error**: Error de memoria al generar mock data

**Causa**: Generando demasiados registros de una vez

**Solución**:
```objectscript
// Generar en lotes
For batch=1:1:10 {
  Set sc = ##class(IRIS105.Util.MockAppointments).Generate(100)
  Hang 1  // Pausa para GC
}
```

---

## 🐛 Debugging Tips

### Habilitar Debug en API

Añadir logging en `NoShowService.cls`:

```objectscript
ClassMethod MyEndpoint() As %Status
{
  // Log request
  Set ^DebugLog($I(^DebugLog)) = $ZDateTime($Now(),3)_" - "_$ToJSON(%request)
  
  Try {
    // ... código
  } Catch ex {
    // Log error
    Set ^DebugLog($I(^DebugLog)) = "ERROR: "_ex.DisplayString()
  }
}
```

Ver logs:
```objectscript
ZWrite ^DebugLog
```

---

### Ver SQL Ejecutado

Para debugging de queries dinámicos:

```objectscript
// En el endpoint, antes de ejecutar:
Set ^DebugSQL($I(^DebugSQL)) = sql

// Ver:
ZWrite ^DebugSQL
```

---

### Verificar Estado del Sistema

```objectscript
// Ver namespace actual
Write $NAMESPACE

// Ver version IRIS
Write $ZVersion

// Ver procesos activos
Do ##class(%SYS.ProcessQuery).%DisplayProcesses()

// Ver memoria
Do ##class(%SYS.System).WriteMemoryStatus()
```

---

## 📞 Obtener Ayuda

Si el problema persiste:

1. **Revisar Logs de IRIS**:
   ```bash
   docker logs <container-name>
   ```

2. **Revisar cconsole.log**:
   ```bash
   tail -f /usr/irissys/mgr/cconsole.log
   ```

3. **InterSystems Community**:
   - [community.intersystems.com](https://community.intersystems.com)

4. **Documentación Oficial**:
   - [docs.intersystems.com](https://docs.intersystems.com)

5. **GitHub Issues**:
   - Abrir issue en el repositorio con detalles del error

---

## 🔧 Comandos Útiles de Diagnóstico

```objectscript
// Verificar compilación de paquete
Do $system.OBJ.GetPackageList(.list, "IRIS105")
ZWrite list

// Ver todas las clases IRIS105
Do $system.OBJ.ShowLoaded("IRIS105.*")

// Verificar globals usadas por una clase
Do ##class(IRIS105.Domain.Patient).%ShowGlobals()

// Ver SQL cache
Do ##class(%SQL.Manager.API).ShowCached()

// Ver web applications
Do ##class(Security.Applications).Export("/tmp/webapps.xml")
```

---

**Ver también**:
- [Getting Started](Getting-Started) - Setup inicial
- [Development Guide](Development-Guide) - Desarrollo
- [FAQ](FAQ) - Preguntas frecuentes
