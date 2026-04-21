# Plan: IRIS105 Chat App — NL Interface sobre IRIS

## Contexto

El proyecto IRIS105 ya tiene una API REST completa (15 endpoints, OpenAPI 3.1.0 documentado).
El objetivo es construir una **app web de chat en lenguaje natural** que permita a usuarios sin cuenta
de Claude ni Anthropic hacer preguntas en español sobre los datos de IRIS (inasistencias, ocupación,
médicos, etc.) y recibir respuestas interpretadas.

**Decisión de arquitectura**: App Python (FastAPI) desplegada en el mismo servidor que IRIS,
como un segundo servicio Docker. Las llamadas a IRIS van por `localhost` (interno, seguro, sin CORS).
Claude (Anthropic SDK) procesa el lenguaje natural con tool_use. Los usuarios acceden via URL pública
(Cloudflare Tunnel, puerto separado).

**Servidor activo**: `iris105m4.htc21.site` · Bearer token IRIS: `demo-readonly-token`

---

## Arquitectura final

```
Internet
    │ Cloudflare Tunnel  (nuevo: chat.iris105m4.htc21.site o /chat path)
    ▼
Python FastAPI · port 8000       (nuevo servicio Docker)
    ├── GET  /          → sirve index.html (chat UI)
    ├── POST /chat      → loop Claude tool_use → IRIS localhost
    └── GET  /health    → status check
              │
              │ http://iris:52773  (red Docker interna)
              ▼
         IRIS REST API  (existente, sin cambios)
```

---

## Archivos a crear

Directorio nuevo: `/iris105-chat/` en la raíz del repo

```
iris105-chat/
├── Dockerfile
├── requirements.txt
├── .env.example
├── main.py           ← FastAPI: endpoints /chat y GET /
├── tools.py          ← 12 tools definidas desde openapi.yaml
├── iris_client.py    ← httpx calls a IRIS por localhost
├── system_prompt.py  ← contexto del dominio para Claude
└── static/
    └── index.html    ← chat UI (vanilla JS, sin frameworks)
```

---

## Detalle de cada archivo

### `requirements.txt`
```
fastapi==0.115.0
uvicorn==0.30.0
httpx==0.27.0
anthropic==0.40.0
python-dotenv==1.0.0
```

### `.env.example`
```
ANTHROPIC_API_KEY=sk-ant-...
IRIS_BASE_URL=http://iris:52773/csp/mltest
IRIS_TOKEN=demo-readonly-token
```
En desarrollo local: `IRIS_BASE_URL=http://localhost:52773/csp/mltest`

---

### `iris_client.py` — Dispatcher de llamadas a IRIS

Mapea cada tool_name al endpoint correcto.

Tools a implementar (12):

| tool_name | método | path IRIS |
|---|---|---|
| `health_check` | GET | `/api/health` |
| `stats_summary` | GET | `/api/ml/stats/summary` |
| `model_details` | GET | `/api/ml/stats/model` |
| `top_noshow` | GET | `/api/ml/analytics/top-noshow` |
| `top_specialties` | GET | `/api/ml/analytics/top-specialties` |
| `top_physicians` | GET | `/api/ml/analytics/top-physicians` |
| `busiest_day` | GET | `/api/ml/analytics/busiest-day` |
| `occupancy_weekly` | GET | `/api/ml/analytics/occupancy-weekly` |
| `occupancy_trend` | GET | `/api/ml/analytics/occupancy-trend` |
| `scheduled_patients` | GET | `/api/ml/analytics/scheduled-patients` |
| `active_appointments` | GET | `/api/ml/appointments/active` |
| `score_noshow` | POST | `/api/ml/noshow/score` |

*Excluidas intencionalmente*: `generate_mock_data`, `capacity_config` (operaciones mutables,
no adecuadas para chat de consulta).

Patrón de implementación:
```python
ROUTE_MAP = {
    "stats_summary":       ("GET",  "/api/ml/stats/summary",                  None),
    "top_noshow":          ("GET",  "/api/ml/analytics/top-noshow",            ["by","limit"]),
    "scheduled_patients":  ("GET",  "/api/ml/analytics/scheduled-patients",    ["startDate","endDate","specialtyId","patientName","physicianName","limit"]),
    # ...
}

async def dispatch(tool_name: str, tool_input: dict) -> dict:
    method, path, param_keys = ROUTE_MAP[tool_name]
    params = {k: tool_input[k] for k in (param_keys or []) if k in tool_input}
    body   = tool_input if method == "POST" else None
    # llamar con httpx, devolver JSON
```

---

### `tools.py` — Definición de tools para Claude

Cada tool tiene `name`, `description` (clave para que Claude elija bien), y `input_schema`.

Notas importantes en los descriptions:
- `top_noshow`: "Úsalo cuando pregunten quién falta más, qué especialidad tiene más inasistencias, ranking de no-shows"
- `scheduled_patients`: "Úsalo para buscar citas por nombre de paciente, médico, especialidad o rango de fechas"
- `stats_summary`: "Úsalo siempre que pregunten totales, cuántos pacientes/citas hay, estado del modelo"
- `score_noshow`: "Úsalo cuando den un appointmentId específico (ej: APPT-1) o features para predecir"

IDs conocidos que Claude debe saber (incluir en system prompt, no en tools):
- SPEC-1 = Medicina Interna, SPEC-2 = Traumatología, SPEC-3 = Pediatría
- PHY-1..PHY-8, BOX-1..BOX-3

---

### `system_prompt.py` — Contexto del dominio

```
Eres un asistente clínico del sistema IRIS105, especializado en análisis de
inasistencias (no-shows) a citas médicas.

DATOS DEL SISTEMA:
- ~100 pacientes, ~5.373 citas registradas
- 8 médicos (PHY-1 a PHY-8), 3 boxes (BOX-1 a BOX-3)
- 3 especialidades: SPEC-1 Medicina Interna, SPEC-2 Traumatología, SPEC-3 Pediatría
- Tasa global de no-show: ~12.7%
- Modelo ML: NoShowModel2 (IntegratedML, estado: entrenado)

HORARIOS: Lunes–Viernes 08:00–18:00, Sábado 09:00–14:00, sin domingos.

INSTRUCCIONES:
- Responde siempre en español, de forma clara y concisa
- Formatea porcentajes con 1 decimal (ej: 18.3%)
- Usa las tools para obtener datos reales — no inventes cifras
- Si la pregunta es ambigua, elige la tool más probable e indica qué consultaste
- Si el usuario menciona una especialidad por nombre, mapea al ID correcto
- Para preguntas sobre tendencias, usa occupancy_trend con weeks=6 por defecto
- El historial de conversación está disponible — puedes referenciar respuestas anteriores
```

---

### `main.py` — FastAPI con loop tool_use

```python
@app.post("/chat")
async def chat(req: ChatRequest):
    # req.message: str, req.history: list[dict]
    messages = req.history + [{"role": "user", "content": req.message}]

    # loop: Claude puede pedir múltiples tools antes de responder
    for _ in range(10):  # máximo 10 rondas de tool_use
        response = anthropic_client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            system=SYSTEM_PROMPT,
            tools=TOOLS,
            messages=messages
        )

        if response.stop_reason == "end_turn":
            return {"reply": extract_text(response), "history": messages}

        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    data = await iris_client.dispatch(block.name, block.input)
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": json.dumps(data, ensure_ascii=False)
                    })
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user",      "content": tool_results})

    return {"reply": "No pude obtener una respuesta. Intenta reformular.", "history": messages}
```

Modelo a usar: `claude-sonnet-4-6` (balance costo/capacidad).
El historial (`req.history`) se mantiene en el frontend (sessionStorage) — el backend es stateless.

---

### `static/index.html` — Chat UI

UI minimalista, vanilla JS, sin dependencias externas:
- Header: "IRIS105 · Asistente de Agenda"
- Área de mensajes con burbujas (usuario / asistente)
- Input + botón Enviar (también Enter)
- Estado "pensando..." mientras espera respuesta
- sessionStorage para mantener historial durante la sesión
- Responsive (funciona en móvil)
- Sugerencias de preguntas iniciales como chips clickeables:
  - "¿Cuál es la tasa de no-show actual?"
  - "¿Qué especialidad tiene más inasistencias?"
  - "¿Cómo va la ocupación esta semana?"
  - "¿Cuál fue el día más ocupado?"

---

### `Dockerfile`

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Cambio en docker-compose.yml (existente)

Agregar servicio `chat` al docker-compose del proyecto:

```yaml
  chat:
    build: ./iris105-chat
    ports:
      - "8000:8000"
    env_file:
      - ./iris105-chat/.env
    depends_on:
      - iris
```

IRIS_BASE_URL en .env debe usar el nombre del servicio Docker: `http://iris:52773/csp/mltest`

Si no hay docker-compose existente, correr directo:
```bash
cd iris105-chat
IRIS_BASE_URL=http://localhost:52773/csp/mltest \
IRIS_TOKEN=demo-readonly-token \
ANTHROPIC_API_KEY=sk-ant-... \
uvicorn main:app --port 8000
```

---

## Cloudflare Tunnel

Dos opciones para exponer el chat:

**Opción A** — Nuevo subdominio:
`chat.iris105m4.htc21.site` → `localhost:8000`

**Opción B** — Path en el mismo dominio:
`iris105m4.htc21.site/chat/*` → `localhost:8000`
Requiere configurar path routing en el tunnel (más complejo).

Recomendado: **Opción A** (subdominio nuevo, configuración más simple).

---

## Orden de implementación

1. `requirements.txt` + `Dockerfile`
2. `.env.example`
3. `iris_client.py` — dispatch + ROUTE_MAP
4. `tools.py` — 12 definiciones con descriptions cuidadosas
5. `system_prompt.py`
6. `main.py` — FastAPI, endpoint /chat con loop tool_use
7. `static/index.html` — chat UI
8. Probar local: `uvicorn main:app` + curl /chat
9. Agregar a docker-compose
10. Configurar Cloudflare Tunnel (subdominio chat.)

---

## Verificación final

```bash
# 1. Health check del chat
curl http://localhost:8000/health

# 2. Pregunta de prueba
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "¿cuántos pacientes hay y cuál es la tasa de no-show?", "history": []}'

# 3. Pregunta con contexto (historial)
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "¿y cuál especialidad falla más?", "history": [...]}'

# 4. Verificar que IRIS se llama por interno (no por internet)
# El log de FastAPI debe mostrar calls a http://iris:52773 o http://localhost:52773
```

---

## Notas para retomar

- El servidor IRIS está activo en `iris105m4.htc21.site` (no `iris105.htc21.site` que está caído)
- Bearer token confirmado funcionando: `demo-readonly-token`
- No hay docker-compose.yml en el repo aún — verificar antes de agregar el servicio `chat`
- El openapi.yaml excluye `POST /api/ml/model/step/execute` intencionalmente — mantener esa decisión
- Anthropic API key necesaria: el usuario debe proveerla antes de implementar
