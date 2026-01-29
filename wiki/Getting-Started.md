# Getting Started - Guía de Inicio Rápido

Esta guía te ayudará a poner en marcha IRIS105 en tu entorno local.

## 📋 Requisitos Previos

### Software Requerido
- **InterSystems IRIS 2024.1** (o superior)
- **Visual Studio Code** (recomendado)
- **Git** para clonar el repositorio

### Extensiones VS Code (Opcionales)
- InterSystems ObjectScript
- InterSystems Language Server

## 🔧 Instalación

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/christianasmussenb/iris105.git
cd iris105
```

### Paso 2: Crear el Namespace MLTEST

Desde una sesión de IRIS en el namespace `%SYS`:

```objectscript
Do ##class(%SYS.Namespace).Create("MLTEST","USER")
Do ##class(%EnsembleMgr).EnableNamespace("MLTEST",1)
```

O usando Docker:

```bash
docker exec -it <container-name> iris session IRIS -U %SYS <<'EOF'
Do ##class(%SYS.Namespace).Create("MLTEST","USER")
Do ##class(%EnsembleMgr).EnableNamespace("MLTEST",1)
Halt
EOF
```

### Paso 3: Cargar las Clases

Si usas Docker con volúmenes montados:

```bash
# Montar src/ en /opt/irisapp/iris/src/
docker run -v $(pwd)/src:/opt/irisapp/iris/src ...
```

### Paso 4: Compilar el Paquete

Desde el namespace `MLTEST`:

```objectscript
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```

O usando el script de compilación:

```bash
./scripts/compile_package.sh iris MLTEST
```

### Paso 5: Configurar Web Applications

Ejecutar en el namespace `%SYS`:

```objectscript
Do ##class(IRIS105.Util.WebAppSetup).ConfigureAll()
```

Esto crea:
- `/csp/mltest` - REST API endpoints
- `/csp/mltest/GCSP.Basic.cls` - UI de demostración

### Paso 6: Inicializar el Proyecto

```objectscript
Do ##class(IRIS105.Util.ProjectSetup).Init()
```

Esto configura:
- Tokens de autenticación en `^IRIS105("API","Tokens",...)`
- Capacidad base para cálculos de ocupación

### Paso 7: Generar Datos de Prueba

```objectscript
Do ##class(IRIS105.Util.MockData).Generate()
```

Parámetros por defecto:
- **3 meses** de datos
- **85%** de ocupación objetivo
- **8 médicos**
- **100 pacientes**
- **15%** de no-show aproximadamente

### Paso 8: Entrenar el Modelo IntegratedML

Desde SQL en el namespace `MLTEST`:

```sql
\i sql/NoShow_model.sql
```

O manualmente:

```sql
CREATE MODEL NoShowModel2 PREDICTING (NoShow) 
FROM IRIS105_Domain.Appointment;

TRAIN MODEL NoShowModel2 USING {
  "seed": 42, 
  "TrainMode": "BALANCE", 
  "MaxTime": 60
};

VALIDATE MODEL NoShowModel2;
```

## ✅ Verificación

### 1. Verificar que el modelo está entrenado

```sql
SELECT MODEL_NAME, DEFAULT_TRAINED_MODEL_NAME, STATUS
FROM INFORMATION_SCHEMA.ML_MODELS
WHERE MODEL_NAME='NoShowModel2';
```

### 2. Probar el endpoint de health

```bash
curl http://localhost:52773/csp/mltest/api/health
```

Respuesta esperada:
```json
{
  "status": "healthy",
  "service": "IRIS105 NoShow API",
  "timestamp": "2026-01-29T..."
}
```

### 3. Obtener estadísticas del dataset

Primero, cargar un token de prueba:

```objectscript
Set ^IRIS105("API","Tokens","demo-readonly-token")=1
```

Luego:

```bash
curl http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"
```

### 4. Probar scoring

```bash
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-1"}'
```

### 5. Acceder a la UI de Demo

Abre en tu navegador:
```
http://localhost:52773/csp/mltest/GCSP.Basic.cls
```

## 🎯 Próximos Pasos

Una vez que tengas el sistema funcionando:

1. **Explora la API** - Ver [API Reference](API-Reference)
2. **Entrena modelos personalizados** - Ver [ML Model](ML-Model)
3. **Desarrolla nuevas funciones** - Ver [Development Guide](Development-Guide)

## 🐛 Problemas Comunes

### Error: Namespace no existe
```objectscript
Do ##class(%SYS.Namespace).Create("MLTEST","USER")
```

### Error: Clases no se encuentran
Verificar que el paquete esté compilado:
```objectscript
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```

### Error: Modelo no encontrado
Entrenar el modelo:
```sql
\i sql/NoShow_model.sql
```

### Error: Token inválido
Cargar el token:
```objectscript
Set ^IRIS105("API","Tokens","tu-token-aqui")=1
```

Para más ayuda, consulta la página de [Troubleshooting](Troubleshooting).

## 📚 Recursos Adicionales

- [Documentación de InterSystems IRIS](https://docs.intersystems.com/)
- [IntegratedML Guide](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIML)
- [REST API Development](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST)

---

**Siguiente**: [Architecture →](Architecture)
