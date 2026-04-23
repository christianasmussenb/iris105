# Estado del sprint – IRIS105 No-Show

## Sprint actual — Chat App desplegada (2026-04-23)

### Completado

**iris105-chat**: app web de chat en lenguaje natural sobre los datos de IRIS.

Archivos creados en `iris105-chat/`:
- `wsgi.py` — entry point WSGI para IRIS Web Gateway (wrappea FastAPI con `a2wsgi`)
- `main.py` — FastAPI con endpoints `GET /`, `GET /health`, `POST /chat` (loop tool_use)
- `iris_client.py` — dispatcher de 12 tools hacia IRIS REST API
- `tools.py` — definiciones de tools para Claude con descriptions optimizadas
- `system_prompt.py` — contexto del dominio en español
- `static/index.html` — chat UI vanilla JS con markdown rendering, historial en sessionStorage
- `requirements.txt`, `Dockerfile`, `.env.example`

**Decisión de arquitectura**: app deployada dentro del IRIS Web Gateway usando WSGI Experimental.
- Elimina necesidad de segundo contenedor, segundo puerto y gestión de CORS
- Archivos en `/opt/iris105-chat/` dentro del contenedor Docker
- Web App en `/csp/mlchat` (NameSpace MLTEST, sin auth, WSGI invocable: `wsgi.app`)

**Despliegue productivo (2026-04-23)**:
- `.env` creado en el contenedor vía `docker cp` (el directorio pertenece al usuario 501 del host, no a `irisowner` — `docker exec bash -c` falla con Permission denied; usar `docker cp` desde el host)
- `flask` instalado con irispython: IRIS WSGI Experimental valida la presencia de un framework conocido (flask/django) antes de activar la Web App; sin él muestra "Unable to find a WSGI framework"
- Web App `/csp/mlchat` configurada en Management Portal con WSGI Experimental activo
- Chat accesible en `https://iris105m4.htc21.site/csp/mlchat/` — el tunnel `iris105-mltest` ya cubre el puerto 52773 completo, no requiere entrada adicional en config

**Fixes aplicados durante implementación**:
1. `load_dotenv()` usa `Path(__file__).parent / ".env"` — funciona bajo IRIS WSGI donde el working dir no es el directorio de la app
2. `StaticFiles` y `FileResponse` usan paths absolutos (`_BASE_DIR = Path(__file__).parent`)
3. `load_dotenv()` se llama antes de `import iris_client` — las constantes de módulo se evalúan al importar
4. `fetch('/chat')` en UI cambiado a path relativo detectado por `window.location.pathname` — funciona bajo cualquier path prefix de IRIS
5. Serialización del historial: `response.content` del SDK Anthropic se convierte con `block.model_dump()` antes de devolver al cliente (evita error `MockValSer` de Pydantic)

**Rendering de tablas**: `marked.js` (CDN) renderiza markdown a HTML en respuestas del bot. Tablas con estilo oscuro, filas alternadas, cabeceras en azul.

### Probado y funcionando

- Preguntas simples: "¿cuántos pacientes hay?" → tool `stats_summary` → respuesta con tabla
- Preguntas analíticas: "¿qué especialidad tiene más inasistencias?" → tool `top_noshow` → ranking
- Conversación con contexto: segunda pregunta referencia la primera correctamente
- Historial persiste durante la sesión (sessionStorage)
- Funcionamiento en modo standalone (uvicorn local) y bajo IRIS WSGI
- Chat accesible públicamente vía Cloudflare Tunnel: `https://iris105m4.htc21.site/csp/mlchat/`

---

## Actualizacion 2026-02-27 (despliegue de agenda + mock con restricciones)

- Agenda `GCSP.Agenda`: render por celdas `(dia,hora)`, color de fondo segun tasa `NoShow`, leyenda visual.
- Mock data: restricciones horarias L-V `08:00-18:00`, S `09:00-14:00`, sin domingos; duración 60 min; tasa NoShow por especialidad.
- API/UI: `POST /api/ml/mock/generate` acepta `clearBeforeGenerate`, `defaultNoShowRate`, `specialtyNoShowRates`.
- Corrección: `IRIS105.Util.MockData.%ExecNonQuery` — `QUIT` con argumento inválido removido.

### Pruebas ejecutadas (2026-02-27)
- Mock: `5379` citas (`months=3, occupancy=0.85, patients=200`).
- Validación horaria: `SundayRows=0`, `SaturdayOut=0`, `WeekdayOut=0`, `MinuteOut=0`, `DurationOut=0`.
- NoShow real: SPEC-1 `0.1174` (obj `0.12`), SPEC-2 `0.1909` (obj `0.20`), SPEC-3 `0.0782` (obj `0.08`).

---

## Avance previo

- Endpoints analytics: `occupancy-weekly`, `scheduled-patients`, `occupancy-trend`, `appointments/active`, `config/capacity`.
- `docs/openapi.yaml` v1.0.1 (OpenAPI 3.1.0) completo; excluye `model/step/execute` del Custom GPT.
- `IRIS105.Util.ProjectSetup`: inicializa globals de tokens y capacidad.
- `POST /api/ml/model/step/execute`: flujo SQL guiado steps 1-6.
- `GCSP.Agenda`: agenda visual con filtros.
- Fix: `/csp/mltest2` sin `DispatchClass`.
- Fix: `INFORMATION_SCHEMA.ML_MODELS` — usar `CREATE_TIMESTAMP`, no `STATUS`.

---

## Pendientes

1. **Capacidad realista**: persistir configuración de slots por box/especialidad.
2. **Índices**: compuestos en `IRIS105.Appointment` sobre `StartDateTime + SpecialtyId/BoxId/PhysicianId`.
3. **Tests**: scripts curl para endpoints nuevos; validar errores por rangos inválidos.
4. **Seguridad**: endurecer autenticación del chat para producción (actualmente sin auth).
5. **Scoring masivo**: ejecutar `score_noshow` sobre citas activas (`scoredAppointments` actual: 0).
