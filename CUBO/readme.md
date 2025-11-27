Tienes razón, quedó todo el README dentro de un bloque ```markdown, que no es lo ideal si lo vas a usar directo como `README.md` en el repo / con un Agent.

Te lo dejo de nuevo, **limpio**, listo para pegar como `README.md` en el repo `IRIS105` 👇

---

# IRIS105 – SAP Facturación, Glosas, Cartera & RIPS POC

POC de analítica en **InterSystems IRIS** para integrar información de SAP (reportes `/SISS`) en un **cubo de gestión** de:

* Facturación
* Glosas (radicación, glosas iniciales, firmadas, en trámite, recuperadas)
* Cartera FI
* Futuro: alineamiento con el caso de uso RIPS (documento `docs/Caso de uso - Reporte de RIPS.docx`)

El proyecto está pensado para ser usado con:

* **Repositorio GitHub**: `IRIS105`
* **Servidor IRIS**: `iriscnet`
* **Visual Studio Code**, extensión InterSystems, y un agente (Codex / Agent) trabajando sobre este repo.

---

## 1. Objetivos del proyecto

1. Diseñar y crear un **modelo analítico** en IRIS (tablas + cubo) que consolide datos provenientes de 4 reportes SAP:

   | Reporte SAP         | Descripción                              |
   | ------------------- | ---------------------------------------- |
   | `/SISS/ISHPA_R58`   | Gestión de facturas, radicación y glosas |
   | `/SISS/ISHPAG_R615` | Consulta de glosas (detalle)             |
   | `/SISS/ISHPA_R60`   | Resumen de facturación                   |
   | `/SISS/ISHPA_R82`   | Reporte de cartera FI                    |

2. Poblar el modelo con **datos mock** realistas, suficientes para hacer demo a negocio.

3. Exponer un **cubo IRIS Analytics** con métricas clave:

   * Total facturado, radicado, glosado, rechazado, recuperado.
   * Saldos de cartera y días de mora.
   * % de glosa, % de rechazo, % de cartera vencida.

4. Dejar preparado el “hook” para que, en una fase posterior, los datos vengan realmente desde SAP (vía BATCH/ETL, BAPIs o reportes exportados).

---

## 2. Arquitectura conceptual

### 2.1 Componentes

* **IRIS Server**: `iriscnet`

  * Namespace sugerido: `SAPBI` (o `MLTEST` si ya existe).
  * BI / Analytics habilitado.

* **Modelo de datos** (en namespace `SAPBI`):

  * Tablas de **dimensión**:

    * `IRIS105.BI.DimTiempo`
    * `IRIS105.BI.DimAseguradora`
    * `IRIS105.BI.DimCentro`
    * (Futuro) `IRIS105.BI.DimPaciente`, `IRIS105.BI.DimEpisodio`
  * Tabla de **hechos**:

    * `IRIS105.BI.FactFacturaGlosaCartera`
  * (Opcional) Tablas de **staging** por reporte SAP:

    * `IRIS105.BI.Stg_ISHPA_R58`
    * `IRIS105.BI.Stg_ISHPAG_R615`
    * `IRIS105.BI.Stg_ISHPA_R60`
    * `IRIS105.BI.Stg_ISHPA_R82`

* **Cubo BI**:

  * `IRIS105.BI.CuboFacturacionGlosasCartera`
  * Fuente: `FactFacturaGlosaCartera`.

* **Mock Data / ETL**:

  * Clase utilitaria:

    * `IRIS105.BI.MockDataGenerator`
  * (Futuro) Clases/procesos ETL SAP:

    * `IRIS105.BI.ETL.SAPLoader` (lectura de archivos/reportes SAP hacia staging)
    * `IRIS105.BI.ETL.FactBuilder` (consolidación staging → Fact).

### 2.2 Flujos de datos

1. **Hoy (POC con mock)**
   `MockDataGenerator` → Dimensiones + Fact → Build cubo → Dashboards/consultas.

2. **Futuro (con SAP)**
   SAP (reportes `/SISS`) → archivos/llamadas → `Staging` → `FactFacturaGlosaCartera` → Refresh cubo.

---

## 3. Estructura propuesta del repositorio

```text
IRIS105/
├─ README.md                          # Este documento
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
│  ├─ create_tables.sql                # DDL inicial (opcional)
│  └─ seed_mock_data.sql               # Ejemplos de mock via SQL (opcional)
└─ .vscode/
   ├─ settings.json                    # Config VS Code IRIS
   └─ launch.json                      # Config de depuración IRIS
```

---

## 4. Modelo de datos (detalle)

### 4.1. Tabla de hechos `FactFacturaGlosaCartera`

Clase persistente: `IRIS105.BI.FactFacturaGlosaCartera`
Nivel detalle: Factura–Aseguradora–Centro–Fecha (extensible a nivel línea).

Campos sugeridos:

**Identificadores**

* `FactID` (PK autoincremental)
* `FacturaNum`
* `AseguradoraID`
* `CentroID`
* `PacienteID` (futuro)
* `EpisodioID` (futuro)

**Fechas**

* `FechaFactura`
* `FechaRadicacion`
* `FechaGlosa`
* `FechaVencimiento`
* `FechaPago`

**Medidas de facturación**

* `MontoFacturado`
* `MontoRadicado`
* `MontoAceptado`
* `MontoRechazado`
* `MontoRecuperado`

**Medidas de glosa**

* `MontoGlosaInicial`
* `MontoGlosaFirmada`
* `MontoGlosaEnTramite`
* `NumGlosas`

**Medidas de cartera**

* `SaldoCartera`
* `DiasMora`
* `DiasDesdeRadicacion`

**Atributos adicionales**

* `LineaNegocio` (ambulatorio, hospitalización, urgencias, etc.)
* `EstadoFactura`
* `EstadoCartera` (corriente, 0–30, 31–60, 61–90, >90)
* `FuenteReporte` (R58, R60, R82, mixto)

### 4.2. Dimensiones

**`IRIS105.BI.DimTiempo`**

* `DateKey` (YYYYMMDD)
* `Fecha`
* `Dia`, `Mes`, `Año`, `Trimestre`, `Semana`

**`IRIS105.BI.DimAseguradora`**

* `AseguradoraID`
* `Nombre`
* `Tipo` (Fonasa, Isapre, EPS, etc.)
* `Segmento` (pública/privada)

**`IRIS105.BI.DimCentro`**

* `CentroID`
* `Nombre`
* `TipoCentro`
* `Ciudad`, `Region`

(Otras dimensiones se pueden agregar más adelante.)

---

## 5. Cubo IRIS

Clase: `IRIS105.BI.CuboFacturacionGlosasCartera`
Source: `IRIS105.BI.FactFacturaGlosaCartera`

**Dimensiones**

* `Tiempo` (basada en `FechaFactura`, jerarquía Año–Mes–Día)
* `Aseguradora`
* `Centro`
* `EstadoFactura`
* `EstadoCartera`

**Medidas**

* `TotalFacturado` = SUM(`MontoFacturado`)
* `TotalRadicado` = SUM(`MontoRadicado`)
* `TotalGlosado` = SUM(`MontoGlosaInicial`)
* `TotalRechazado` = SUM(`MontoRechazado`)
* `TotalRecuperado` = SUM(`MontoRecuperado`)
* `SaldoCartera` = SUM(`SaldoCartera`)
* `DiasMoraPromedio` = AVG(`DiasMora`)

**Medidas calculadas (KPIs)**

* `%GlosaSobreRadicado` = `TotalGlosado` / `TotalRadicado`
* `%RechazoFinal` = `TotalRechazado` / `TotalFacturado`
* `%CarteraVencida` = (Saldo en estados vencidos) / `SaldoCartera`

---

## 6. Mock Data – estrategia

Clase: `IRIS105.BI.MockDataGenerator`

Responsabilidades:

1. Poblar `DimTiempo` con un rango de fechas (ej. últimos 24 meses).

2. Poblar `DimAseguradora` con 6–8 aseguradoras típicas.

3. Poblar `DimCentro` con 3–5 centros.

4. Generar `FactFacturaGlosaCartera`:

   * Para cada combinación día–aseguradora–centro:

     * Generar N facturas (0–20/día).
     * Asignar:

       * `MontoFacturado` (100k–2M aprox).
       * `MontoRadicado` cercano al facturado.
       * `MontoGlosaInicial` como % aleatorio (0–20%).
       * `MontoRechazado` como % de glosa.
       * `SaldoCartera` y `DiasMora` en función del tiempo y probabilidad de pago.
       * `EstadoFactura` y `EstadoCartera` coherentes.

5. Ejecutar todo desde un método estático, por ejemplo:
   `Do ##class(IRIS105.BI.MockDataGenerator).RunAll()`

---

## 7. Integración futura con SAP

No se implementa en esta fase, pero el diseño ya lo considera:

* `IRIS105.BI.ETL.SAPLoader`

  * Lectura de archivos (CSV/XML) exportados desde los reportes `/SISS/ISHPA_R58`, `/SISS/ISHPAG_R615`, `/SISS/ISHPA_R60`, `/SISS/ISHPA_R82`.
  * Carga a tablas de staging `Stg_*`.

* `IRIS105.BI.ETL.FactBuilder`

  * Lógica de consolidación desde staging → `FactFacturaGlosaCartera`.
  * Reglas de reconciliación con R60 (resumen de facturación).

---

## 8. Configuración de entorno (VS Code + IRIS `iriscnet`)

### 8.1. Requisitos

* Visual Studio Code
* Extensión **InterSystems ObjectScript**
* Acceso a servidor IRIS `iriscnet` (host, puerto, credenciales)
* Git instalado y configurado

### 8.2. Pasos iniciales

1. Clonar el repo:

   ```bash
   git clone https://github.com/<tu-org>/IRIS105.git
   cd IRIS105
   ```

2. Abrir en VS Code:

   ```bash
   code .
   ```

3. Configurar conexión a IRIS `iriscnet` en `.vscode/settings.json` (ejemplo):

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

4. Crear el namespace `SAPBI` en `iriscnet` (si no existe) con soporte de BI/Analytics.

5. Sincronizar clases del repositorio a IRIS y compilar desde VS Code.

---

## 9. Tareas sugeridas para el Agent/Codex

1. Crear las clases de dimensiones y fact en `src/IRIS105/BI/*.cls` según este diseño.
2. Implementar `IRIS105.BI.MockDataGenerator` con métodos para poblar:

   * `DimTiempo`
   * `DimAseguradora`
   * `DimCentro`
   * `FactFacturaGlosaCartera`
3. Definir el cubo `CuboFacturacionGlosasCartera` en ObjectScript apuntando a la tabla de hechos.
4. (Opcional) Crear scripts SQL en `sql/` para recrear tablas o cargar datos de ejemplo.
5. Construir el cubo y ejecutar consultas (Analyzer/MDX) para validar:

   * Monto facturado por aseguradora y mes.
   * % de glosa por aseguradora.
   * Cartera vencida por aseguradora.

---

## 10. Próximos pasos

1. Implementar y probar `MockDataGenerator` hasta tener:

   * 12–24 meses de datos simulados.
   * 5–10 aseguradoras.
   * 3–5 centros.
2. Validar con negocio que los KPIs reflejan el caso de uso RIPS.
3. Preparar una demo (dashboards o consultas) sobre el cubo.
4. Diseñar el layout de salida de los reportes SAP `/SISS` para conectar el ETL real.

---

Si quieres, después armamos la clase `MockDataGenerator` completa en ObjectScript para pegarla directa en `src/IRIS105/BI/MockDataGenerator.cls`.
