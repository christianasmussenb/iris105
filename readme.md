# IRIS105 – SAP Facturación, Glosas, Cartera & RIPS (POC)

POC de analítica en **InterSystems IRIS** para integrar información de SAP (reportes `/SISS`) y exponer un cubo de gestión que cubre:

- Facturación
- Glosas (radicación, glosas iniciales, firmadas, en trámite, recuperadas)
- Cartera FI
- Futuro: alineamiento con el caso de uso RIPS (`docs/Caso de uso - Reporte de RIPS.docx`)

Diseñado para trabajar en el repo `IRIS105`, sobre el servidor IRIS `iriscnet` y con VS Code (extensión InterSystems).

---

## Objetivos

1. Definir un **modelo analítico** en IRIS que consolide datos de 4 reportes SAP:

   | Reporte SAP         | Descripción                              |
   | ------------------- | ---------------------------------------- |
   | `/SISS/ISHPA_R58`   | Gestión de facturas, radicación y glosas |
   | `/SISS/ISHPAG_R615` | Consulta de glosas (detalle)             |
   | `/SISS/ISHPA_R60`   | Resumen de facturación                   |
   | `/SISS/ISHPA_R82`   | Reporte de cartera FI                    |

2. Poblar el modelo con **datos mock** realistas para demo a negocio.
3. Exponer un **cubo IRIS Analytics** con métricas clave: facturado, radicado, glosado, rechazado, recuperado, cartera, días de mora y KPIs (% glosa, % rechazo, % cartera vencida).
4. Dejar listo el “hook” para que los datos provengan de SAP en una fase posterior (batch/ETL, BAPIs o reportes exportados).

---

## Arquitectura conceptual

### Componentes

- **IRIS Server**: `iriscnet`
  - Namespace sugerido: `SAPBI` (o `MLTEST` si ya existe).
  - BI / Analytics habilitado.

- **Modelo de datos** (namespace `SAPBI`)
  - Dimensiones: `IRIS105.BI.DimTiempo`, `IRIS105.BI.DimAseguradora`, `IRIS105.BI.DimCentro` (futuro: `DimPaciente`, `DimEpisodio`).
  - Hechos: `IRIS105.BI.FactFacturaGlosaCartera`.
  - Staging (opcional): `IRIS105.BI.Stg_ISHPA_R58`, `Stg_ISHPAG_R615`, `Stg_ISHPA_R60`, `Stg_ISHPA_R82`.

- **Cubo BI**: `IRIS105.BI.CuboFacturacionGlosasCartera` (fuente: `FactFacturaGlosaCartera`).

- **Mock / ETL**
  - Mock: `IRIS105.BI.MockDataGenerator`.
  - Futuro ETL SAP: `IRIS105.BI.ETL.SAPLoader` (lectura de reportes) + `IRIS105.BI.ETL.FactBuilder` (consolidación staging → fact).

### Flujo de datos

1. **Hoy (POC/mock)**: `MockDataGenerator` → dimensiones + fact → build cubo → dashboards/consultas.
2. **Futuro (SAP real)**: reportes `/SISS` → archivos/llamadas → staging → fact → refresh cubo.

---

## Estructura sugerida del repositorio

```text
IRIS105/
├─ README.md
├─ docs/
│  └─ Caso de uso - Reporte de RIPS.docx
├─ src/
│  └─ IRIS105/
│     └─ BI/
│        ├─ DimTiempo.cls
│        ├─ DimAseguradora.cls
│        ├─ DimCentro.cls
│        ├─ FactFacturaGlosaCartera.cls
│        ├─ CuboFacturacionGlosasCartera.cls
│        ├─ MockDataGenerator.cls
│        ├─ ETL/
│        │  ├─ SAPLoader.cls           # futuro
│        │  └─ FactBuilder.cls         # futuro
│        └─ Util/
│           └─ Log.cls                 # utilidades de logging
├─ sql/
│  ├─ create_tables.sql                # DDL (opcional)
│  └─ seed_mock_data.sql               # mock via SQL (opcional)
└─ .vscode/
   ├─ settings.json                    # Config VS Code IRIS
   └─ launch.json                      # Depuración IRIS
```

---

## Modelo de datos

### Fact `IRIS105.BI.FactFacturaGlosaCartera`

Nivel de detalle: Factura–Aseguradora–Centro–Fecha (extensible a línea).

- Identificadores: `FactID` (PK), `FacturaNum`, `AseguradoraID`, `CentroID`, `PacienteID` (futuro), `EpisodioID` (futuro).
- Fechas: `FechaFactura`, `FechaRadicacion`, `FechaGlosa`, `FechaVencimiento`, `FechaPago`.
- Medidas de facturación: `MontoFacturado`, `MontoRadicado`, `MontoAceptado`, `MontoRechazado`, `MontoRecuperado`.
- Medidas de glosa: `MontoGlosaInicial`, `MontoGlosaFirmada`, `MontoGlosaEnTramite`, `NumGlosas`.
- Medidas de cartera: `SaldoCartera`, `DiasMora`, `DiasDesdeRadicacion`.
- Atributos: `LineaNegocio`, `EstadoFactura`, `EstadoCartera` (corriente / vencida), `FuenteReporte` (R58, R60, R82, mixto).

### Dimensiones clave

- `IRIS105.BI.DimTiempo`: `DateKey` (YYYYMMDD), `Fecha`, `Dia`, `Mes`, `Año`, `Trimestre`, `Semana`.
- `IRIS105.BI.DimAseguradora`: `AseguradoraID`, `Nombre`, `Tipo` (Fonasa/Isapre/EPS), `Segmento` (pública/privada).
- `IRIS105.BI.DimCentro`: `CentroID`, `Nombre`, `TipoCentro`, `Ciudad`, `Region`.
- Futuro: `DimPaciente`, `DimEpisodio`.

---

## Cubo IRIS `IRIS105.BI.CuboFacturacionGlosasCartera`

- Dimensiones: `Tiempo` (basada en `FechaFactura`, jerarquía Año–Mes–Día), `Aseguradora`, `Centro`, `EstadoFactura`, `EstadoCartera`.
- Medidas: `TotalFacturado`, `TotalRadicado`, `TotalGlosado`, `TotalRechazado`, `TotalRecuperado`, `SaldoCartera`, `DiasMoraPromedio`.
- KPIs: `%GlosaSobreRadicado`, `%RechazoFinal`, `%CarteraVencida`.

---

## Estrategia de datos mock

Clase: `IRIS105.BI.MockDataGenerator`

1. Poblar `DimTiempo` con rango de fechas (ej. últimos 24 meses).
2. Poblar `DimAseguradora` (6–8 aseguradoras) y `DimCentro` (3–5 centros).
3. Generar `FactFacturaGlosaCartera` por combinación día–aseguradora–centro:
   - N facturas/día (0–20).
   - `MontoFacturado` 100k–2M aprox; `MontoRadicado` cercano al facturado.
   - `MontoGlosaInicial` 0–20% del radicado; `MontoRechazado` como % de glosa.
   - `SaldoCartera` y `DiasMora` en función de tiempo y probabilidad de pago.
   - `EstadoFactura` y `EstadoCartera` coherentes.
4. Ejecutable con: `Do ##class(IRIS105.BI.MockDataGenerator).RunAll()`.

---

## Integración futura con SAP

- `IRIS105.BI.ETL.SAPLoader`: lectura de archivos CSV/XML exportados desde `/SISS/ISHPA_R58`, `/SISS/ISHPAG_R615`, `/SISS/ISHPA_R60`, `/SISS/ISHPA_R82` hacia staging.
- `IRIS105.BI.ETL.FactBuilder`: consolidación staging → `FactFacturaGlosaCartera`, con reglas de reconciliación vs. R60.

---

## Entorno (VS Code + IRIS `iriscnet`)

### Requisitos

- VS Code + extensión **InterSystems ObjectScript**
- Acceso a IRIS `iriscnet` (host, puerto, credenciales)
- Git instalado

### Pasos

1. Clonar:
   ```bash
   git clone https://github.com/<tu-org>/IRIS105.git
   cd IRIS105
   ```
2. Abrir en VS Code:
   ```bash
   code .
   ```
3. Configurar `.vscode/settings.json` (ejemplo):
   ```json
   {
     "objectscript.conn": {
       "active": true,
       "host": "iriscnet",
       "port": 1972,
       "ns": "SAPBI",
       "username": "_SYSTEM",
       "password": "SYS",
       "https": false
     }
   }
   ```
4. Crear namespace `SAPBI` en `iriscnet` (si no existe) con BI/Analytics.
5. Sincronizar clases y compilar desde VS Code.

---

## Tareas sugeridas (Agent/Codex)

1. Crear clases de dimensiones y fact en `src/IRIS105/BI/*.cls`.
2. Implementar `IRIS105.BI.MockDataGenerator` (DimTiempo, DimAseguradora, DimCentro, Fact).
3. Definir el cubo `CuboFacturacionGlosasCartera` apuntando a la tabla de hechos.
4. (Opcional) Scripts SQL en `sql/` para recrear tablas o cargar datos de ejemplo.
5. Construir el cubo y validar con consultas (Analyzer/MDX):
   - Monto facturado por aseguradora y mes.
   - % de glosa por aseguradora.
   - Cartera vencida por aseguradora.

---

## Próximos pasos

1. Completar y probar `MockDataGenerator` con 12–24 meses, 5–10 aseguradoras, 3–5 centros.
2. Validar KPIs con negocio (caso de uso RIPS).
3. Preparar demo (dashboards o consultas) sobre el cubo.
4. Diseñar layout de salida de los reportes SAP `/SISS` para conectar el ETL real.
