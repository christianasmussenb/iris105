TOOLS = [
    {
        "name": "health_check",
        "description": "Verifica que el servicio IRIS esté disponible. Úsalo si el usuario pregunta si el sistema está activo o hay problemas de conexión.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "stats_summary",
        "description": "Devuelve totales generales: cuántos pacientes, citas, médicos hay, tasa global de no-show y estado del modelo ML. Úsalo siempre que pregunten totales, resumen general o estado del sistema.",
        "input_schema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "model_details",
        "description": "Devuelve información técnica del modelo IntegratedML: versión entrenada, métricas de validación, timestamp. Úsalo cuando pregunten sobre el modelo de predicción, su precisión o cuándo fue entrenado.",
        "input_schema": {
            "type": "object",
            "properties": {
                "modelName": {"type": "string", "description": "Nombre del modelo (default: NoShowModel2)"},
            },
            "required": [],
        },
    },
    {
        "name": "top_noshow",
        "description": "Ranking de quién falta más a las citas. Úsalo cuando pregunten quién falta más, qué especialidad o médico tiene más inasistencias, ranking de no-shows.",
        "input_schema": {
            "type": "object",
            "properties": {
                "by":    {"type": "string", "enum": ["specialty", "physician", "patient"], "description": "Agrupar por especialidad, médico o paciente"},
                "limit": {"type": "integer", "description": "Cuántos resultados devolver (default: 5)"},
            },
            "required": [],
        },
    },
    {
        "name": "top_specialties",
        "description": "Lista las especialidades con más citas y sus tasas de no-show. Úsalo cuando pregunten por especialidades, cuál tiene más actividad o más inasistencias.",
        "input_schema": {
            "type": "object",
            "properties": {
                "limit": {"type": "integer", "description": "Cuántas especialidades devolver"},
            },
            "required": [],
        },
    },
    {
        "name": "top_physicians",
        "description": "Lista los médicos con más citas y sus tasas de no-show. Úsalo cuando pregunten por médicos, cuál atiende más o tiene más inasistencias.",
        "input_schema": {
            "type": "object",
            "properties": {
                "limit": {"type": "integer", "description": "Cuántos médicos devolver"},
            },
            "required": [],
        },
    },
    {
        "name": "busiest_day",
        "description": "Devuelve el día más ocupado (más citas) en un rango de fechas. Úsalo cuando pregunten cuál fue el día con más pacientes o más actividad.",
        "input_schema": {
            "type": "object",
            "properties": {
                "startDate": {"type": "string", "description": "Fecha inicio YYYY-MM-DD"},
                "endDate":   {"type": "string", "description": "Fecha fin YYYY-MM-DD"},
            },
            "required": [],
        },
    },
    {
        "name": "occupancy_weekly",
        "description": "Ocupación semanal agrupada por especialidad, box o médico. Devuelve capacidad, citas realizadas y tasa de ocupación por semana. Úsalo cuando pregunten cómo va la ocupación por semana o comparar semanas.",
        "input_schema": {
            "type": "object",
            "properties": {
                "groupBy":    {"type": "string", "enum": ["specialty", "box", "physician"], "description": "Cómo agrupar los datos"},
                "startDate":  {"type": "string", "description": "Fecha inicio YYYY-MM-DD"},
                "endDate":    {"type": "string", "description": "Fecha fin YYYY-MM-DD"},
                "slotsPerDay":{"type": "integer", "description": "Slots disponibles por día (default: 8)"},
            },
            "required": [],
        },
    },
    {
        "name": "occupancy_trend",
        "description": "Tendencia de ocupación de las últimas N semanas. Úsalo para preguntas de tendencia, si la ocupación está subiendo o bajando, cómo fue la evolución reciente.",
        "input_schema": {
            "type": "object",
            "properties": {
                "weeks":   {"type": "integer", "description": "Número de semanas a analizar (default: 6)"},
                "groupBy": {"type": "string", "enum": ["specialty", "box", "physician"], "description": "Cómo agrupar"},
            },
            "required": [],
        },
    },
    {
        "name": "scheduled_patients",
        "description": "Busca citas agendadas por nombre de paciente, médico, especialidad o rango de fechas. Úsalo cuando busquen citas de un paciente específico, de un médico o en una fecha concreta.",
        "input_schema": {
            "type": "object",
            "properties": {
                "startDate":     {"type": "string", "description": "Fecha inicio YYYY-MM-DD"},
                "endDate":       {"type": "string", "description": "Fecha fin YYYY-MM-DD"},
                "specialtyId":   {"type": "string", "description": "ID de especialidad (ej: SPEC-1)"},
                "patientName":   {"type": "string", "description": "Nombre parcial del paciente"},
                "physicianName": {"type": "string", "description": "Nombre parcial del médico"},
                "limit":         {"type": "integer", "description": "Máximo de resultados"},
            },
            "required": [],
        },
    },
    {
        "name": "active_appointments",
        "description": "Lista las citas activas (pendientes) en un rango de fechas. Úsalo cuando pregunten qué citas hay próximamente o cuántos pacientes están agendados.",
        "input_schema": {
            "type": "object",
            "properties": {
                "startDate": {"type": "string", "description": "Fecha inicio YYYY-MM-DD"},
                "endDate":   {"type": "string", "description": "Fecha fin YYYY-MM-DD"},
                "limit":     {"type": "integer", "description": "Máximo de resultados"},
            },
            "required": [],
        },
    },
    {
        "name": "score_noshow",
        "description": "Predice la probabilidad de no-show para una cita. Úsalo cuando den un appointmentId específico (ej: APPT-1) o features de una cita para predecir si el paciente faltará.",
        "input_schema": {
            "type": "object",
            "properties": {
                "appointmentId": {"type": "string", "description": "ID de cita existente (ej: APPT-1)"},
                "features": {
                    "type": "object",
                    "description": "Features ad-hoc si no hay appointmentId",
                    "properties": {
                        "PatientId":            {"type": "integer"},
                        "PhysicianId":          {"type": "string"},
                        "BoxId":                {"type": "string"},
                        "SpecialtyId":          {"type": "string"},
                        "StartDateTime":        {"type": "string", "description": "YYYY-MM-DD HH:MM:SS"},
                        "BookingChannel":       {"type": "string", "enum": ["WEB", "PHONE", "PRESENCIAL"]},
                        "BookingDaysInAdvance": {"type": "integer"},
                        "HasSMSReminder":       {"type": "integer", "enum": [0, 1]},
                        "Reason":               {"type": "string"},
                    },
                },
                "modelName": {"type": "string", "description": "Modelo a usar (default: NoShowModel2)"},
            },
            "required": [],
        },
    },
]
