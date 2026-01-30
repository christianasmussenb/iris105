# FAQ - Preguntas Frecuentes

Respuestas a las preguntas más comunes sobre IRIS105.

## 🎯 General

### ¿Qué es IRIS105?

IRIS105 es una prueba de concepto (POC) que demuestra cómo usar InterSystems IRIS e IntegratedML para predecir la probabilidad de que un paciente no asista a su cita médica (No-Show).

---

### ¿Para qué sirve predecir No-Show?

La predicción de No-Show permite:
- **Optimizar agendas**: Sobrereservar de forma inteligente
- **Reducir costos**: Menos citas perdidas = menos pérdidas
- **Mejorar atención**: Identificar pacientes de riesgo para seguimiento
- **Analytics**: Entender patrones de comportamiento

---

### ¿Es IRIS105 production-ready?

**No**. Es una POC con limitaciones:
- Autenticación simplificada
- Sin tests automatizados
- Sin CI/CD
- Sin monitoring avanzado
- Sin índices optimizados

Para producción se requieren mejoras significativas.

---

## 🏗️ Arquitectura

### ¿Por qué usar IntegratedML en lugar de Python/R?

**Ventajas de IntegratedML**:
- ✅ Sin movimiento de datos
- ✅ SQL nativo
- ✅ Menor latencia
- ✅ Sin dependencias externas
- ✅ Más fácil de mantener

**Cuándo usar Python/R**:
- Modelos muy específicos no soportados por AutoML
- Necesitas control total del pipeline
- Requieres bibliotecas especializadas

---

### ¿Puedo usar este código con otra base de datos?

No directamente. El código usa:
- ObjectScript (lenguaje de IRIS)
- Clases persistentes de IRIS
- IntegratedML (específico de IRIS)
- REST framework de IRIS

Portar requeriría reescribir prácticamente todo.

---

### ¿Cómo se compara con arquitecturas ML tradicionales?

**Arquitectura tradicional**:
```
Database → ETL → Python/R → Model Training → 
  → Model Storage → API (Flask/FastAPI) → Client
```

**Arquitectura IRIS105**:
```
IRIS Database → IntegratedML (SQL) → REST API (ObjectScript) → Client
```

**Ventajas IRIS105**:
- Menos componentes
- Menor latencia
- Menos complejidad operacional

---

## 🤖 Machine Learning

### ¿Qué algoritmos usa IntegratedML?

IntegratedML con %AutoML evalúa automáticamente:
- Logistic Regression
- Decision Trees
- Random Forest
- Gradient Boosting
- Neural Networks

Y selecciona el mejor según métricas de validación.

---

### ¿Puedo ver qué algoritmo eligió?

```sql
SELECT TRAINED_MODEL_NAME, PROVIDER, ALGORITHM
FROM INFORMATION_SCHEMA.ML_TRAINED_MODELS
WHERE MODEL_NAME = 'NoShowModel2';
```

---

### ¿Qué features son más importantes?

IntegratedML no expone feature importance directamente en esta versión. Puedes analizar correlaciones manualmente:

```sql
-- Impacto de SMS reminder
SELECT HasSMSReminder, AVG(NoShow) AS AvgNoShow
FROM IRIS105_Domain.Appointment
GROUP BY HasSMSReminder;

-- Impacto de días de anticipación
SELECT 
  CASE 
    WHEN BookingDaysInAdvance < 7 THEN '<7 days'
    ELSE '7+ days'
  END AS Category,
  AVG(NoShow) AS AvgNoShow
FROM IRIS105_Domain.Appointment
GROUP BY CASE WHEN BookingDaysInAdvance < 7 THEN '<7 days' ELSE '7+ days' END;
```

---

### ¿Con qué frecuencia debo re-entrenar?

Depende de:
- **Volumen de datos nuevos**: Re-entrenar al acumular 10-20% más datos
- **Cambios en negocio**: Después de cambios significativos en procesos
- **Performance**: Si accuracy baja significativamente

Recomendación: Mensual o al acumular 1000+ citas nuevas.

---

### ¿Qué accuracy es buena?

Para predicción de No-Show:
- **< 70%**: Malo - revisar features y datos
- **70-80%**: Aceptable - útil para producción
- **80-90%**: Bueno - muy útil
- **> 90%**: Excelente (o posible overfitting - verificar)

IRIS105 típicamente logra 80-85% accuracy.

---

## 🔐 Seguridad

### ¿Es segura la autenticación actual?

**No para producción**. La implementación actual:
- Tokens simples sin expiración
- Sin HTTPS obligatorio
- Sin rate limiting
- Sin auditoría de accesos

**Para producción, implementar**:
- OAuth 2.0 o JWT
- HTTPS obligatorio
- Tokens con expiración
- Rate limiting
- Logging completo
- Roles y permisos

---

### ¿Cómo añado HTTPS?

En producción, usar:
1. Certificado SSL/TLS válido
2. Configurar en IRIS Management Portal
3. Forzar HTTPS en web apps
4. Configurar HSTS headers

---

### ¿Dónde se almacenan los tokens?

En globals: `^IRIS105("API","Tokens",<token>)=1`

**No recomendado para producción**. Usar:
- Base de datos de usuarios
- Sistema IAM externo
- JWT con validación de firma

---

## 📊 Datos

### ¿Los datos mock son realistas?

**Parcialmente**. Los generadores:
- ✅ Generan variedad razonable de nombres, fechas
- ✅ Simulan distribución de no-show (~15%)
- ✅ Incluyen variedad de canales y especialidades
- ⚠️ Patrones demasiado uniformes
- ⚠️ Sin estacionalidad real
- ⚠️ Sin correlaciones complejas

**Para análisis serio, usar datos reales**.

---

### ¿Puedo importar datos reales?

Sí. Opciones:

**1. SQL INSERT**:
```sql
INSERT INTO IRIS105_Domain.Patient (FirstName, LastName, ...)
VALUES ('Juan', 'Pérez', ...);
```

**2. CSV Import**:
```objectscript
Do ##class(%SQL.Statement).%ExecDirect(,"LOAD DATA FROM FILE 'patients.csv' INTO IRIS105_Domain.Patient")
```

**3. ObjectScript**:
```objectscript
Set patient = ##class(IRIS105.Domain.Patient).%New()
Set patient.FirstName = "Juan"
// ...
Do patient.%Save()
```

---

### ¿Cómo limpio todos los datos?

```objectscript
// Limpiar todas las tablas
Do ##class(IRIS105.Domain.Appointment).%DeleteExtent()
Do ##class(IRIS105.Domain.Patient).%DeleteExtent()
Do ##class(IRIS105.Domain.Physician).%DeleteExtent()
Do ##class(IRIS105.Domain.Box).%DeleteExtent()
Do ##class(IRIS105.Domain.Specialty).%DeleteExtent()
Do ##class(IRIS105.Domain.Payer).%DeleteExtent()
```

**⚠️ Cuidado**: Esto elimina TODOS los datos.

---

## 🌐 API REST

### ¿Puedo usar la API desde JavaScript?

Sí:

```javascript
const response = await fetch('http://localhost:52773/csp/mltest/api/ml/noshow/score', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer demo-readonly-token',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    appointmentId: 'APPT-123'
  })
});

const data = await response.json();
console.log(data);
```

---

### ¿Hay límite de requests?

**No** en esta versión POC. Para producción, implementar rate limiting.

---

### ¿Puedo usar GraphQL en lugar de REST?

No incluido. IRIS soporta REST nativamente. Para GraphQL, necesitarías implementar un servidor GraphQL aparte que consuma el REST API de IRIS.

---

### ¿Hay webhooks disponibles?

No en esta versión. Para implementar webhooks:
1. Añadir tabla de subscripciones
2. Crear endpoint POST para registro
3. Implementar dispatcher que llame URLs registradas
4. Usar %Net.HttpRequest para hacer calls

---

## 🚀 Deployment

### ¿Cómo despliego en producción?

Pasos recomendados:
1. **Hardening de seguridad** (HTTPS, auth robusta)
2. **Añadir monitoring** (logs, métricas, alertas)
3. **Optimizar performance** (índices, cache)
4. **Implementar CI/CD**
5. **Añadir tests automatizados**
6. **Documentar procedimientos operacionales**
7. **Plan de backup y recovery**

---

### ¿Funciona con Docker?

Sí. Ejemplo básico:

```dockerfile
FROM intersystemsdc/iris-community:2024.1

COPY src /opt/irisapp/iris/src
COPY sql /opt/irisapp/iris/sql

RUN iris start IRIS && \
    iris session IRIS -U %SYS "Do ##class(%SYS.Namespace).Create(\"MLTEST\",\"USER\")" && \
    iris session IRIS -U MLTEST "Do $system.OBJ.CompilePackage(\"IRIS105\",\"ckr\")" && \
    iris stop IRIS quietly
```

---

### ¿Soporta clustering/HA?

IRIS soporta clustering, pero IRIS105 no está diseñado específicamente para ello. Requiere:
- Configuración de mirroring o sharding
- Manejo de globals distribuidas
- Balance de carga para API

---

## 💻 Desarrollo

### ¿Puedo usar otro IDE además de VS Code?

Sí, opciones:
- **Atelier** (Eclipse plugin oficial de InterSystems)
- **Studio** (IDE clásico de InterSystems)
- **Cualquier editor** + export/import manual

VS Code con ObjectScript extension es la opción más moderna y recomendada.

---

### ¿Puedo programar en Python en lugar de ObjectScript?

Para la lógica del sistema, no. IRIS usa ObjectScript.

Pero puedes:
- Usar **Embedded Python** en IRIS (Python dentro de ObjectScript)
- Crear microservicio en Python que consuma el REST API
- Usar Python para ETL previo

---

### ¿Hay tests unitarios?

No en esta versión POC. Para añadir:

```objectscript
Class IRIS105.Tests.MyTest Extends %UnitTest.TestCase
{
  Method TestSomething()
  {
    Do $$$AssertEquals(1+1, 2, "Math broken!")
  }
}
```

Ejecutar:
```objectscript
Do ##class(%UnitTest.Manager).RunTest("IRIS105.Tests")
```

---

## 📈 Performance

### ¿Cuántas requests por segundo soporta?

Depende de:
- Hardware
- Complejidad del scoring
- Tamaño del dataset
- Índices disponibles

POC sin optimizar: ~10-50 req/s  
Optimizado: ~100-500 req/s  
Con cache y optimizaciones avanzadas: 1000+ req/s

---

### ¿Cómo mejoro la performance?

1. **Añadir índices**:
```sql
CREATE INDEX ON IRIS105_Domain.Appointment (StartDateTime);
```

2. **Implementar cache**:
```objectscript
Set key = "score:"_appointmentId
If $Data(^CacheDB(key)) {
  Return ^CacheDB(key)  // Cache hit
}
// ... calculate score
Set ^CacheDB(key) = result
```

3. **Usar pooling de conexiones**

4. **Optimizar queries SQL**

---

## 🔄 Integración

### ¿Puedo integrar con Custom GPT?

Sí, hay OpenAPI spec en `docs/openapi.yaml`. Pasos:
1. Subir openapi.yaml a Custom GPT
2. Configurar autenticación (API key)
3. GPT puede llamar endpoints directamente

---

### ¿Funciona con Power BI / Tableau?

Sí, vía:
- **JDBC/ODBC**: Conectar directamente a IRIS
- **REST API**: Consumir endpoints de analytics
- **SQL**: Queries directos en las tablas

---

### ¿Puedo integrarlo con mi EMR/EHR?

Sí. Opciones:
1. **REST API**: Tu EMR llama endpoints de IRIS105
2. **FHIR**: Implementar adaptador FHIR en IRIS
3. **HL7**: Usar Interoperability de IRIS para mensajes HL7
4. **Database**: Conectar vía JDBC/ODBC

---

## 📞 Soporte

### ¿Dónde obtengo ayuda?

1. **Esta Wiki** - Documentación completa
2. **GitHub Issues** - Reportar bugs o preguntas
3. **InterSystems Community** - [community.intersystems.com](https://community.intersystems.com)
4. **Documentación IRIS** - [docs.intersystems.com](https://docs.intersystems.com)

---

### ¿Hay una comunidad de usuarios?

InterSystems tiene una comunidad activa en:
- [community.intersystems.com](https://community.intersystems.com)
- Discord de InterSystems Developer Community
- Stack Overflow (tag: intersystems-iris)

---

### ¿Puedo contribuir al proyecto?

Este es un proyecto de demostración. Para contribuir:
1. Fork el repositorio
2. Crea una rama con tu feature
3. Haz pull request
4. Describe claramente los cambios

---

## 📚 Recursos Adicionales

### ¿Dónde aprendo más sobre IRIS?

- [InterSystems Learning](https://learning.intersystems.com/)
- [Developer Community](https://community.intersystems.com)
- [YouTube Channel](https://www.youtube.com/user/InterSystemsCorp)
- [Documentación Oficial](https://docs.intersystems.com)

---

### ¿Hay más ejemplos de IntegratedML?

Sí:
- [IntegratedML Samples](https://github.com/intersystems-community/iris-integratedml-samples)
- [Machine Learning Toolkit](https://github.com/intersystems/isc-dev-ml)
- Ejemplos en InterSystems Community

---

### ¿Dónde están las mejores prácticas?

En este proyecto:
- `BUENAS_PRACTICAS_IRIS_COMBINADAS.md`
- `INSTRUCTIONS.md`
- `CLAUDE.md`

También:
- [InterSystems Best Practices](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GBPN)

---

**¿No encontraste tu pregunta?**

- Ver [Troubleshooting](Troubleshooting) para problemas específicos
- Abrir un issue en GitHub
- Preguntar en InterSystems Community

