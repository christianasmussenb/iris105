import httpx
import os

from dotenv import load_dotenv
load_dotenv()

IRIS_BASE_URL = os.getenv("IRIS_BASE_URL", "http://localhost:52773/csp/mltest")
IRIS_TOKEN    = os.getenv("IRIS_TOKEN", "demo-readonly-token")

# (method, path, query_param_keys)
ROUTE_MAP: dict[str, tuple[str, str, list[str] | None]] = {
    "health_check":        ("GET",  "/api/health",                              None),
    "stats_summary":       ("GET",  "/api/ml/stats/summary",                   None),
    "model_details":       ("GET",  "/api/ml/stats/model",                     ["modelName"]),
    "top_noshow":          ("GET",  "/api/ml/analytics/top-noshow",             ["by", "limit"]),
    "top_specialties":     ("GET",  "/api/ml/analytics/top-specialties",        ["limit"]),
    "top_physicians":      ("GET",  "/api/ml/analytics/top-physicians",         ["limit"]),
    "busiest_day":         ("GET",  "/api/ml/analytics/busiest-day",            ["startDate", "endDate"]),
    "occupancy_weekly":    ("GET",  "/api/ml/analytics/occupancy-weekly",       ["groupBy", "startDate", "endDate", "slotsPerDay"]),
    "occupancy_trend":     ("GET",  "/api/ml/analytics/occupancy-trend",        ["weeks", "groupBy"]),
    "scheduled_patients":  ("GET",  "/api/ml/analytics/scheduled-patients",     ["startDate", "endDate", "specialtyId", "patientName", "physicianName", "limit"]),
    "active_appointments": ("GET",  "/api/ml/appointments/active",              ["startDate", "endDate", "limit"]),
    "score_noshow":        ("POST", "/api/ml/noshow/score",                     None),
}

_headers = {
    "Authorization": f"Bearer {IRIS_TOKEN}",
    "Content-Type": "application/json",
}


async def dispatch(tool_name: str, tool_input: dict) -> dict:
    if tool_name not in ROUTE_MAP:
        return {"error": f"Tool desconocida: {tool_name}"}

    method, path, param_keys = ROUTE_MAP[tool_name]
    url = f"{IRIS_BASE_URL}{path}"

    params = {}
    body   = None

    if method == "GET" and param_keys:
        params = {k: tool_input[k] for k in param_keys if k in tool_input}
    elif method == "POST":
        body = tool_input

    async with httpx.AsyncClient(timeout=30.0) as client:
        if method == "GET":
            resp = await client.get(url, headers=_headers, params=params)
        else:
            resp = await client.post(url, headers=_headers, json=body)

    resp.raise_for_status()
    return resp.json()
