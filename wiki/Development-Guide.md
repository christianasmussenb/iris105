# Development Guide - Guía de Desarrollo

Esta guía te ayudará a desarrollar y extender IRIS105.

## 🛠️ Configuración del Entorno de Desarrollo

### Visual Studio Code

#### Extensiones Requeridas

1. **InterSystems ObjectScript** (intersystems-community.vscode-objectscript)
   - Syntax highlighting para ObjectScript
   - Compilación integrada
   - Debugging

2. **InterSystems Language Server** (intersystems.language-server)
   - IntelliSense para ObjectScript
   - Go to definition
   - Find references

#### Configuración de Conexión

Archivo `.vscode/settings.json`:

```json
{
  "objectscript.conn": {
    "server": "localhost",
    "port": 52773,
    "username": "_SYSTEM",
    "password": "SYS",
    "ns": "MLTEST",
    "active": true
  },
  "objectscript.export": {
    "folder": "src",
    "addCategory": false
  }
}
```

### Workspace

Usar el archivo `iris105.code-workspace` incluido en el proyecto.

## 📁 Estructura del Proyecto

```
iris105/
├── src/
│   ├── IRIS105/
│   │   ├── Domain/          # Clases persistentes
│   │   │   ├── Patient.cls
│   │   │   ├── Physician.cls
│   │   │   ├── Appointment.cls
│   │   │   └── ...
│   │   ├── REST/            # API REST
│   │   │   └── NoShowService.cls
│   │   └── Util/            # Utilidades
│   │       ├── MockData.cls
│   │       ├── NoShowPredictor.cls
│   │       └── ...
│   └── GCSP/
│       └── Basic.cls        # UI Demo
├── sql/
│   ├── NoShow_model.sql     # Script de entrenamiento
│   └── demo_queries.sql     # Queries de ejemplo
├── docs/
│   ├── openapi.yaml         # Spec OpenAPI
│   └── ...
└── scripts/
    └── compile_package.sh   # Compilación
```

## 🔨 Compilación y Build

### Compilar Todo el Paquete

```objectscript
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```

Flags:
- `c` - Compilar
- `k` - Mantener código fuente generado
- `r` - Compilar recursivamente (subpaquetes)

### Compilar Clase Individual

```objectscript
Do $system.OBJ.Compile("IRIS105.REST.NoShowService","ck")
```

### Usando Script de Compilación

```bash
./scripts/compile_package.sh <container-name> <namespace>

# Ejemplo:
./scripts/compile_package.sh iris MLTEST
```

### Purgar Cache de SQL

Después de cambios en REST o SQL:

```objectscript
Do $SYSTEM.SQL.Purge()
```

## 📝 Convenciones de Código

### Nomenclatura

**Clases**:
- PascalCase: `Patient`, `NoShowService`
- Namespace: `IRIS105.<Package>.<Class>`

**Métodos**:
- PascalCase: `ScoreAppointment()`, `GenerateMockData()`

**Variables**:
- camelCase locales: `appointmentId`, `resultSet`
- UPPERCASE para constantes: `MAXRETRIES`

**Propiedades**:
- PascalCase: `FirstName`, `StartDateTime`

### Estándares de Código

#### 1. Transacciones

**SIEMPRE** usar TSTART/TCOMMIT para operaciones de escritura:

```objectscript
ClassMethod CreateAppointment(data As %DynamicObject) As %Status
{
  TSTART
  Try {
    Set appointment = ##class(Appointment).%New()
    Set appointment.PatientId = data.patientId
    // ... set other properties
    Set sc = appointment.%Save()
    If $$$ISERR(sc) {
      TROLLBACK
      Return sc
    }
    TCOMMIT
  } Catch ex {
    TROLLBACK
    Return ex.AsStatus()
  }
  Return $$$OK
}
```

#### 2. SQL Safety

**SIEMPRE** usar `%SQL.Statement` con parámetros:

```objectscript
// ✅ CORRECTO
Set sql = "SELECT * FROM Appointment WHERE PatientId = ?"
Set stmt = ##class(%SQL.Statement).%New()
Set sc = stmt.%Prepare(sql)
Set rs = stmt.%Execute(patientId)

// ❌ INCORRECTO - SQL Injection vulnerable
Set sql = "SELECT * FROM Appointment WHERE PatientId = "_patientId
Set rs = ##class(%SQL.Statement).%ExecDirect(,sql)
```

#### 3. Manejo de Errores

**SIEMPRE** usar Try/Catch:

```objectscript
ClassMethod MyMethod() As %Status
{
  Try {
    // código que puede fallar
    Set result = ..DoSomething()
    Return $$$OK
  } Catch ex {
    // log error
    Do ..LogError(ex.DisplayString())
    Return ex.AsStatus()
  }
}
```

#### 4. Validación de Inputs

**SIEMPRE** validar inputs en setters:

```objectscript
Property Email As %String(MAXLEN = 255);

Method EmailSet(email As %String) As %Status
{
  // Validar formato email
  If '..IsValidEmail(email) {
    Return $$$ERROR($$$GeneralError, "Invalid email format")
  }
  Set i%Email = email
  Return $$$OK
}
```

#### 5. Documentación

**SIEMPRE** documentar métodos públicos:

```objectscript
/// Scores an appointment for no-show prediction
/// @param appointmentId - The ID of the appointment to score
/// @return DynamicObject containing predictedLabel and probability
ClassMethod Score(appointmentId As %String) As %DynamicObject
{
  // implementation
}
```

## 🏗️ Añadir Nuevas Funcionalidades

### Añadir Nuevo Endpoint REST

#### 1. Definir en UrlMap

Editar `IRIS105.REST.NoShowService.cls`:

```objectscript
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <!-- Añadir nueva ruta -->
  <Route Url="/api/ml/myendpoint" Method="GET" Call="GetMyData" />
</Routes>
}
```

#### 2. Implementar Método

```objectscript
ClassMethod GetMyData() As %Status
{
  Set response = {}
  
  Try {
    // Validar autenticación
    If '..ValidateToken() {
      Do ..ReturnError("Unauthorized")
      Return $$$OK
    }
    
    // Lógica del endpoint
    Set data = ..CollectData()
    
    // Retornar respuesta
    Do ..ReturnSuccess(data)
    
  } Catch ex {
    Do ..ReturnError(ex.DisplayString())
  }
  
  Return $$$OK
}
```

#### 3. Actualizar OpenAPI

Editar `docs/openapi.yaml`:

```yaml
paths:
  /api/ml/myendpoint:
    get:
      summary: My new endpoint
      tags:
        - Custom
      security:
        - BearerAuth: []
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/MyDataResponse'
```

#### 4. Compilar y Probar

```objectscript
Do $system.OBJ.Compile("IRIS105.REST.NoShowService","ck")
Do $SYSTEM.SQL.Purge()
```

```bash
curl http://localhost:52773/csp/mltest/api/ml/myendpoint \
  -H "Authorization: Bearer demo-readonly-token"
```

### Añadir Nueva Clase Persistente

#### 1. Crear Clase

```objectscript
Class IRIS105.Domain.Insurance Extends %Persistent
{

/// Insurance company name
Property CompanyName As %String(MAXLEN = 100) [ Required ];

/// Policy number
Property PolicyNumber As %String(MAXLEN = 50) [ Required ];

/// Patient reference
Relationship Patient As Patient [ Cardinality = one, Inverse = Insurances ];

/// Storage definition
Storage Default
{
<Data name="InsuranceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>CompanyName</Value>
</Value>
<Value name="3">
<Value>PolicyNumber</Value>
</Value>
</Data>
<DataLocation>^IRIS105.InsuranceD</DataLocation>
<DefaultData>InsuranceDefaultData</DefaultData>
<IdLocation>^IRIS105.InsuranceD</IdLocation>
<IndexLocation>^IRIS105.InsuranceI</IndexLocation>
<StreamLocation>^IRIS105.InsuranceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
```

#### 2. Actualizar Relaciones

En `Patient.cls`:

```objectscript
Relationship Insurances As Insurance [ Cardinality = many, Inverse = Patient ];
```

#### 3. Compilar

```objectscript
Do $system.OBJ.Compile("IRIS105.Domain.Insurance","ck")
Do $system.OBJ.Compile("IRIS105.Domain.Patient","ck")
```

### Añadir Generador de Mock Data

#### 1. Crear Clase Generadora

```objectscript
Class IRIS105.Util.MockInsurances Extends %RegisteredObject
{

ClassMethod Generate(count As %Integer = 50) As %Status
{
  TSTART
  Try {
    For i=1:1:count {
      Set insurance = ##class(IRIS105.Domain.Insurance).%New()
      Set insurance.CompanyName = ..GetRandomCompany()
      Set insurance.PolicyNumber = ..GeneratePolicyNumber()
      
      Set sc = insurance.%Save()
      If $$$ISERR(sc) {
        TROLLBACK
        Return sc
      }
    }
    TCOMMIT
  } Catch ex {
    TROLLBACK
    Return ex.AsStatus()
  }
  
  Return $$$OK
}

ClassMethod GetRandomCompany() As %String [ Private ]
{
  Set companies = ##class(%ListOfDataTypes).%New()
  Do companies.Insert("BlueCross")
  Do companies.Insert("United Health")
  // ... más compañías
  
  Set idx = $Random(companies.Count()) + 1
  Return companies.GetAt(idx)
}

}
```

#### 2. Integrar en MockData

Editar `IRIS105.Util.MockData.cls`:

```objectscript
ClassMethod Generate(...) As %Status
{
  // ... existing code
  
  // Generar insurances
  Write !, "Generating insurances..."
  Set sc = ##class(MockInsurances).Generate(100)
  If $$$ISERR(sc) Return sc
  
  // ... continue
}
```

## 🧪 Testing

### Testing Manual con SQL

```sql
-- Test crear appointment
INSERT INTO IRIS105_Domain.Appointment 
  (PatientId, PhysicianId, BoxId, SpecialtyId, StartDateTime)
VALUES (1, 2, 3, 1, '2026-03-01 10:00:00');

-- Test scoring
SELECT 
  AppointmentId,
  PREDICT(NoShowModel2) AS Label,
  PROBABILITY(NoShowModel2 FOR 1) AS Prob
FROM IRIS105_Domain.Appointment
WHERE AppointmentId = (SELECT MAX(AppointmentId) FROM IRIS105_Domain.Appointment);

-- Cleanup
DELETE FROM IRIS105_Domain.Appointment 
WHERE AppointmentId = (SELECT MAX(AppointmentId) FROM IRIS105_Domain.Appointment);
```

### Testing Manual con cURL

```bash
# Test health
curl http://localhost:52773/csp/mltest/api/health

# Test con autenticación
curl http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"

# Test POST
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-1"}'
```

### Unit Tests (Futuro)

Para producción, implementar tests con `%UnitTest`:

```objectscript
Class IRIS105.Tests.AppointmentTest Extends %UnitTest.TestCase
{

Method TestCreateAppointment()
{
  Set appointment = ##class(IRIS105.Domain.Appointment).%New()
  Set appointment.PatientId = 1
  Set appointment.PhysicianId = 2
  
  Set sc = appointment.%Save()
  Do $$$AssertStatusOK(sc, "Appointment save failed")
  Do $$$AssertNotEquals(appointment.%Id(), "", "Appointment ID not generated")
}

Method TestScoring()
{
  // Setup
  Set appointmentId = ..CreateTestAppointment()
  
  // Execute
  Set result = ##class(IRIS105.Util.NoShowPredictor).Score(appointmentId)
  
  // Verify
  Do $$$AssertNotNull(result, "Result is null")
  Do $$$AssertTrue(result.%IsDefined("predictedLabel"), "No predictedLabel")
  
  // Cleanup
  Do ..DeleteTestAppointment(appointmentId)
}

}
```

## 🐛 Debugging

### Logs

Añadir logging en tu código:

```objectscript
// Simple write
Write !, "Debug: appointmentId = ", appointmentId

// Log a global
Set ^MyDebugLog($Increment(^MyDebugLog)) = $ZDateTime($Now(),3)_" - "_message

// Log a archivo
Set file = ##class(%File).%New("/tmp/iris105_debug.log")
Do file.Open("WSA")  // Write, Stream, Append
Do file.WriteLine($ZDateTime($Now(),3)_" - "_message)
Do file.Close()
```

### VS Code Debugger

1. Configurar breakpoint en VS Code
2. Ejecutar método en debug mode
3. Inspeccionar variables

### Terminal Debugging

```objectscript
// Entrar en namespace
ZN "MLTEST"

// Ejecutar método con BREAK
BREAK

// Inspeccionar variables
Write appointmentId
Write result.%ToJSON()

// Continuar
CONTINUE
```

## 📦 Deploy

### Export de Clases

```objectscript
// Export paquete completo
Do $system.OBJ.Export("IRIS105.*.cls", "/tmp/iris105_export.xml")

// Export clase individual
Do $system.OBJ.Export("IRIS105.REST.NoShowService.cls", "/tmp/service.xml")
```

### Import en Otro Namespace

```objectscript
ZN "PRODUCTION"
Do $system.OBJ.Load("/tmp/iris105_export.xml", "ck")
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```

### Docker Deployment

Ver scripts en `/scripts` para automatización.

## 📚 Recursos Útiles

### Documentación IRIS
- [ObjectScript Reference](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS)
- [SQL Reference](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL)
- [REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST)

### InterSystems Developer Community
- [community.intersystems.com](https://community.intersystems.com)

### Este Proyecto
- [BUENAS_PRACTICAS_IRIS_COMBINADAS.md](../BUENAS_PRACTICAS_IRIS_COMBINADAS.md)
- [INSTRUCTIONS.md](../INSTRUCTIONS.md)
- [CLAUDE.md](../CLAUDE.md)

---

**Ver también**:
- [Architecture](Architecture) - Entender la arquitectura
- [ML Model](ML-Model) - Trabajar con IntegratedML
- [Troubleshooting](Troubleshooting) - Resolver problemas
