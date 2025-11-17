# Buenas prácticas para proyectos InterSystems IRIS + ObjectScript

Estado: versión consolidada que incluye extractos textuales desde iris102.  
Propósito: plantilla reutilizable para iniciar proyectos IRIS + ObjectScript con buenas prácticas, ejemplos operativos y una hoja de referencia rápida de ObjectScript.

---

## Índice
- 1. Alcance y objetivos
- 2. Requisitos y herramientas recomendadas
- 3. Estructura recomendada del repositorio
- 4. Git & packaging
- 5. Desarrollo local y CI
- 6. Convenciones de código ObjectScript
- 7. Transacciones y concurrencia
- 8. Acceso a datos y performance
- 9. REST / FHIR / Integraciones
- 10. Testing
- 11. Debugging y diagnóstico
- 12. Seguridad y configuración
- 13. Operación y despliegue
- 14. Recursos y enlaces útiles
- 15. Contenidos insertados desde iris102
  - A. @BUENAS_PRACTICAS_IRIS.md (insertado)
  - B. @objectscript-cheat-sheet.md (insertado)

---

## 1. Alcance y objetivos
- Establecer estructura de repositorio, convenciones de código y flujo de trabajo reproducible.
- Facilitar desarrollo local con Docker, despliegues controlados (ZPM / paquetes) y CI.
- Mantener código legible, modular y testeable en ObjectScript y componentes IRIS (clases persistentes, rutinas, servicios REST/ENS, colas).

## 2. Requisitos y herramientas recomendadas
- InterSystems IRIS (documentar versión objetivo).
- VS Code con extensión "InterSystems ObjectScript".
- ZPM para empaquetado y despliegue.
- Docker / docker-compose para entornos reproducibles.
- Git + GitHub y workflows CI.
- Postman / Insomnia para APIs; herramientas FHIR si aplica.

## 3. Estructura recomendada del repositorio
- /src
  - /src/classes
  - /src/routines
  - /src/sql
  - /src/web (si aplica)
- /deploy
- /docker
- /tests
- /docs
- /scripts
- .vscode
- runtime.config.json, env.example

(Adaptar convenciones a tu equipo.)

## 4. Git & packaging
- Versionar solo código y configuraciones exportables.
- Ignorar datos y bases IRIS en .gitignore.
- Empaquetar con ZPM; usar tags semánticos.
- Mantener CHANGELOG y README.

## 5. Desarrollo local y CI
- docker-compose con namespace precreado e import automático de fuentes.
- Scripts rebuild/import para facilitar desarrollo local.
- CI que arranque un contenedor IRIS, importe fuentes/paquete y ejecute tests.

## 6. Convenciones de código ObjectScript
- Nombres de clases siguiendo namespaces (MiOrg.Component.Clase).
- Metodología: separar acceso a datos de lógica de negocio.
- Manejo de errores con excepciones (%Exception) y logging estructurado.
- Evitar uso indiscriminado de globals; preferir %Persistent.

## 7. Transacciones y concurrencia
- Uso controlado de transacciones; evitar bloqueos largos.
- Jobs/asíncrono para procesos background.

## 8. Acceso a datos y performance
- Clases persistentes para datos estructurados.
- Indices en campos de filtro y joins.
- Operaciones bulk para masivos.

## 9. REST / FHIR / Integraciones
- Usar adaptadores nativos de IRIS para REST.
- En FHIR, respetar versiones y validaciones; incluir autenticación (OAuth2).
- Documentar endpoints y proveer colección Postman.

## 10. Testing (unitario e integración)
- Tests unitarios para lógica; tests de integración contra contenedor IRIS.
- Ejecutar tests en CI; mantener fixtures reproducibles.

## 11. Debugging y diagnóstico
- Uso de Management Portal, trace utilities y logging con request-id.
- Scripts para rebuild/import reproducible.

## 12. Seguridad y configuración
- No versionar secretos; usar vault/CI secrets/.env local.
- Configurar TLS en producción; revisar permisos de namespaces.

## 13. Operación y despliegue
- Documentar backups/restore y plan de rollback.
- Automatizar despliegues con ZPM o scripts; documentar pasos manuales.

## 14. Recursos y enlaces útiles
- Documentación oficial InterSystems IRIS (por versión).
- Guía ZPM, extensión ObjectScript para VS Code, recursos FHIR.
- Enlaces a los archivos fuente originales:
  - @BUENAS_PRACTICAS_IRIS.md: https://github.com/christianasmussenb/iris102/blob/main/@BUENAS_PRACTICAS_IRIS.md
  - @objectscript-cheat-sheet.md: https://github.com/christianasmussenb/iris102/blob/main/@objectscript-cheat-sheet.md

---

## 15. Contenidos insertados desde iris102

### A) Contenido completo de @BUENAS_PRACTICAS_IRIS.md (insertado)

# Buenas Prácticas para Desarrollo en InterSystems IRIS

## Guía de Desarrollo Basada en Experiencia del Proyecto iris102

**Fecha:** 17 de octubre de 2025  
**Proyecto Base:** iris102 - Integración CSV a MySQL/PostgreSQL vía ODBC  
**Autor:** Documentación basada en experiencia real de desarrollo

---

## 📋 Índice

1. [Estructura de Proyecto](#estructura-de-proyecto)
2. [Gestión de Código Fuente](#gestión-de-código-fuente)
3. [Compilación y Despliegue](#compilación-y-despliegue)
4. [Conectividad de Bases de Datos](#conectividad-de-bases-de-datos)
5. [Arquitectura de Interoperability](#arquitectura-de-interoperability)
6. [Debugging y Troubleshooting](#debugging-y-troubleshooting)
7. [Docker y Entorno de Desarrollo](#docker-y-entorno-de-desarrollo)
8. [Testing y Validación](#testing-y-validación)
9. [Errores Comunes y Soluciones](#errores-comunes-y-soluciones)

---

## 1. Estructura de Proyecto

### 1.1 Organización Recomendada de Directorios

proyecto-iris/
├── iris/
│   ├── Dockerfile                    # Construcción del contenedor IRIS
│   ├── Installer.cls                 # Clase de instalación/setup
│   ├── iris.script                   # Script de inicialización
│   ├── src/
│   │   └── <namespace>/              # Código fuente por namespace
│   │       └── prod/                 # Clases de producción
│   │           ├── *.cls             # Clases de negocio
│   │           └── Msg/              # Clases de mensajes
│   └── odbc/                         # Configuración ODBC si aplica
│       ├── odbc.ini
│       └── odbcinst.ini
├── data/
│   ├── IN/                           # Entrada de datos
│   ├── OUT/                          # Salida procesada
│   ├── LOG/                          # Logs de procesamiento
│   └── WIP/                          # Work in progress
├── sql/                              # Scripts SQL externos
│   ├── mysql_init.sql
│   └── postgres_init.sql
├── docker-compose.yml                # Orquestación de servicios
└── README.md                         # Documentación principal

### 1.2 Convenciones de Nombres

**Packages (Namespaces):**
- Usar PascalCase: `Demo`, `MyApp`, `CompanyName`
- Evitar guiones bajos o caracteres especiales

**Clases:**
- Business Services: `<Nombre>Service` → `Demo.FileService`
- Business Processes: `<Nombre>Process` → `Demo.Process`
- Business Operations: `<Nombre>Operation` → `Demo.MySQL.Operation`
- Messages: `Demo.Msg.<TipoMensaje>` → `Demo.Msg.FileProcessRequest`

**Properties:**
- PascalCase: `TargetConfigName`, `FilePath`, `CSVContent`
- Boolean: Usar `Is` o `Has` como prefijo → `IsValid`, `HasHeader`

---