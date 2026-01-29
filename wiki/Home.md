# IRIS105 Wiki - Predicción de No-Show en Citas Médicas

Bienvenido al wiki del proyecto IRIS105, una prueba de concepto (POC) para predecir la inasistencia a citas médicas utilizando **InterSystems IRIS 2024.1** e **IntegratedML**.

## 🎯 Descripción del Proyecto

IRIS105 es un sistema de machine learning que predice la probabilidad de que un paciente no asista a su cita médica (No-Show). Utiliza IntegratedML con AutoML para entrenar modelos sobre datos históricos de citas y expone los resultados a través de una API REST.

### Características Principales

- ✅ **Modelo de ML**: IntegratedML con %AutoML para predicción de No-Show
- ✅ **API REST**: 15+ endpoints para scoring, estadísticas y analytics
- ✅ **Datos Sintéticos**: Generadores de datos mock para testing
- ✅ **UI Demo**: Página CSP básica para demostración
- ✅ **Autenticación**: Bearer token para proteger endpoints
- ✅ **Analytics**: Endpoints para análisis de ocupación y tendencias

## 📚 Documentación

### Primeros Pasos
- **[Getting Started](Getting-Started)** - Instalación y configuración rápida
- **[Architecture](Architecture)** - Arquitectura del sistema
- **[API Reference](API-Reference)** - Referencia completa de la API REST

### Desarrollo
- **[Development Guide](Development-Guide)** - Guía de desarrollo y buenas prácticas
- **[ML Model](ML-Model)** - Entrenamiento y uso del modelo IntegratedML

### Soporte
- **[Troubleshooting](Troubleshooting)** - Solución de problemas comunes
- **[FAQ](FAQ)** - Preguntas frecuentes

## 🚀 Quick Start

```bash
# 1. Crear namespace
iris session IRIS -U %SYS "Do ##class(%SYS.Namespace).Create(\"MLTEST\",\"USER\")"

# 2. Compilar el paquete
Do $system.OBJ.CompilePackage("IRIS105","ckr")

# 3. Configurar web apps
Do ##class(IRIS105.Util.WebAppSetup).ConfigureAll()

# 4. Generar datos de prueba
Do ##class(IRIS105.Util.MockData).Generate()

# 5. Entrenar el modelo
\i sql/NoShow_model.sql
```

## 📊 Estado del Proyecto

**Versión**: POC (Proof of Concept)  
**Namespace**: MLTEST  
**Modelo Principal**: NoShowModel2  
**Última Actualización**: Enero 2026

### Completado ✅
- Clases persistentes para el dominio médico
- Servicio REST con 15 endpoints
- Generadores de datos sintéticos
- Modelo IntegratedML con AutoML
- Página CSP para demo
- Documentación OpenAPI 3.1.0

### Pendiente 🔄
- Persistir resultados de scoring en `AppointmentRisk`
- Pruebas automatizadas y CI/CD
- Scripts de despliegue con Docker
- Mejorar autenticación (modo producción)
- Índices compuestos para mejor performance

## 🔗 Enlaces Importantes

- **Repositorio**: [github.com/christianasmussenb/iris105](https://github.com/christianasmussenb/iris105)
- **API Demo**: `http://localhost:52773/csp/mltest/api/health`
- **UI Demo**: `http://localhost:52773/csp/mltest/GCSP.Basic.cls`
- **OpenAPI Spec**: [docs/openapi.yaml](../docs/openapi.yaml)

## 💡 Contribuciones

Este es un proyecto de demostración. Para sugerencias o mejoras, por favor crea un issue en el repositorio.

## 📄 Licencia

Ver archivo LICENSE en el repositorio principal.

---

**Nota**: Esta es una prueba de concepto para fines educativos y de demostración. No está diseñada para uso en producción sin las debidas mejoras de seguridad y rendimiento.
