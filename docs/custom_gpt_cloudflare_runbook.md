# Runbook: localhost -> Cloudflare Tunnel -> Custom GPT Actions

Este documento describe el flujo operativo para publicar el servicio REST de IRIS105 desde local y consumirlo desde un Custom GPT usando `docs/openapi.yaml`.

## Alcance

- Publicar `http://localhost:52773/csp/mltest` por HTTPS con Cloudflare Tunnel.
- Validar salud y autenticación antes de integrar.
- Cargar/reimportar `docs/openapi.yaml` en Actions.
- Mantener fuera del Custom GPT el endpoint `POST /api/ml/model/step/execute`.

## Flujo resumido

1. Verificar servicio local y token.
2. Levantar túnel Cloudflare.
3. Validar endpoint público.
4. Ajustar `servers.url` en `docs/openapi.yaml` si cambia el host.
5. Importar schema en Custom GPT (Actions) y probar.

## 1) Verificación local

Probar salud (sin token):

```bash
curl -i --max-time 10 http://localhost:52773/csp/mltest/api/health
```

Probar endpoint autenticado:

```bash
curl -i --max-time 20 http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"
```

Si responde `401`, inicializa token:

```objectscript
Set ^IRIS105("API","Tokens","demo-readonly-token")=1
```

## 2) Publicación por Cloudflare Tunnel

### Opción A (recomendada): túnel con hostname estable

Ejemplo de `~/.cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL-UUID>
credentials-file: /Users/<usuario>/.cloudflared/<TUNNEL-UUID>.json
ingress:
  - hostname: iris105m4.htc21.site
    service: http://localhost:52773
  - service: http_status:404
```

Levantar túnel:

```bash
cloudflared tunnel --config /Users/<usuario>/vscode/iris105/docs/config.yml run <NOMBRE-O-UUID-DEL-TUNNEL>
```

Importante:
- `cloudflared tunnel run <nombre>` solo toma `~/.cloudflared/config.yml` por defecto.
- Si tu config vive en otro path (por ejemplo `docs/config.yml`), debes pasar `--config ...` o copiar el archivo a `~/.cloudflared/config.yml`.

### Opción B: quick tunnel (URL efímera)

```bash
cloudflared tunnel --url http://localhost:52773
```

Si usas URL efímera, actualiza `servers.url` en `docs/openapi.yaml` antes de importar al GPT.

## 3) Validación del endpoint público

Con túnel activo:

```bash
curl -i --max-time 10 https://iris105m4.htc21.site/csp/mltest/api/health
curl -i --max-time 20 https://iris105m4.htc21.site/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"
```

Esperado:

- `/api/health` -> `200`
- endpoint autenticado -> `200` con JSON

## 4) Revisión de OpenAPI antes de cargar al GPT

Archivo fuente:

- `docs/openapi.yaml` (OpenAPI `3.1.0`, versión de API `1.0.1`)

Puntos obligatorios:

- `servers.url` debe apuntar al host público correcto, incluyendo `/csp/mltest`.
- El endpoint `POST /api/ml/model/step/execute` debe permanecer excluido del schema.
- La exclusión está documentada en `info.description`.

Checks rápidos:

```bash
rg -n "servers:|url:|model/step/execute|excluye intencionalmente" docs/openapi.yaml
```

## 5) Carga/reimportación en Custom GPT (Actions)

1. Abrir ChatGPT -> `GPTs` -> editar tu GPT.
2. Ir a `Configure` -> `Actions`.
3. Importar schema desde `docs/openapi.yaml` (pegar contenido o cargar archivo).
4. Configurar autenticación en la Action:
   - Tipo: `API Key` (header)
   - Header: `Authorization`
   - Valor: `Bearer <token>` (ejemplo: `Bearer demo-readonly-token`)
5. Guardar y publicar cambios del GPT.
6. Probar primero `GET /api/health`, luego `GET /api/ml/stats/summary`.

## 6) Smoke tests recomendados en el GPT

- `GET /api/health`
- `GET /api/ml/stats/summary`
- `GET /api/ml/analytics/top-noshow?by=specialty&limit=5`
- `GET /api/ml/analytics/scheduled-patients?limit=20&debug=1`

## 7) Seguridad y alcance recomendado

- Mantener token de solo lectura para uso general del GPT.
- Si se habilitan endpoints de escritura (`mock/generate`, `config/capacity`), usar token separado y controlado.
- No exponer por Actions el endpoint de entrenamiento SQL `POST /api/ml/model/step/execute`.

## Troubleshooting rápido

- `401 Missing/Invalid bearer token`: revisar header y existencia en `^IRIS105("API","Tokens",token)`.
- `404`: revisar prefijo `/csp/mltest` en URL pública.
- `503` en host Cloudflare con túnel "up": revisar que `cloudflared` esté corriendo con el `config.yml` correcto (si no, el ingress no apunta a `localhost:52773`).
- `502/5xx` en host Cloudflare: túnel caído o IRIS local no disponible.
- Warnings al importar OpenAPI: reimportar schema completo y validar indentación YAML.
- `GCSP.Agenda.cls` muestra `GCSP.Basic`: revisar web app `/csp/mltest2`; debe tener `DispatchClass` vacío (si apunta a `GCSP.Basic`, intercepta todas las rutas).
