# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

IRIS105 is a POC for predicting medical appointment no-shows using InterSystems IRIS 2024.1 and IntegratedML. The project combines persistent data models, ML model training/scoring, and a REST API for integration.

**Deployment Target**: Namespace `MLTEST` on IRIS 2024.1
**Primary Language**: ObjectScript
**ML Framework**: IntegratedML with %AutoML

## Architecture

### Three-Layer Architecture

1. **Domain Layer** (`src/IRIS105/Domain/`): Persistent classes extending `%Persistent`
   - Core entity: `Appointment` (links Patient, Physician, Box, Specialty)
   - `AppointmentRisk` table exists but not actively used for storing scoring results
   - All relationships mapped via foreign keys

2. **Business Logic Layer** (`src/IRIS105/Util/`):
   - **ML Scoring**: `NoShowPredictor.cls` wraps IntegratedML SQL scoring
   - **Mock Data**: 8 generator classes for synthetic data (patients, physicians, appointments, etc.)
   - **Setup**: `ProjectSetup.cls` initializes globals for tokens and capacity config
   - **WebAppSetup**: Creates REST and CSP web applications

3. **API Layer** (`src/IRIS105/REST/`):
   - `NoShowService.cls` (1099 lines): Single comprehensive REST service with 15 endpoints
   - Extends `%CSP.REST`
   - Bearer token auth via global: `^IRIS105("API","Tokens",token)`
   - URL routing defined in XData `UrlMap`

### Data Flow

```
Mock Data Generation
  → Patient/Physician/Appointment tables
    → IntegratedML Model Training (NoShowModel2)
      → REST API Scoring Endpoints
        → CSP UI (Basic.cls) or external clients
```

## Common Development Commands

### Building and Compilation

```bash
# Compile entire package (from Docker container)
./scripts/compile_package.sh iris MLTEST

# Or directly in IRIS session
Do $system.OBJ.CompilePackage("IRIS105","ckr")

# Compile single class
Do $system.OBJ.Compile("IRIS105.REST.NoShowService","ck")

# Purge SQL query cache after changes
Do $SYSTEM.SQL.Purge()
```

### Setup and Initialization

```objectscript
# Create namespace (run in %SYS)
Do ##class(%SYS.Namespace).Create("MLTEST","USER")
Do ##class(%EnsembleMgr).EnableNamespace("MLTEST",1)

# Create web applications
Do ##class(IRIS105.Util.WebAppSetup).ConfigureAll()

# Initialize project globals (tokens, capacity)
Do ##class(IRIS105.Util.ProjectSetup).Init()

# Generate mock data (3 months, 85% occupancy, 8 physicians, 100 patients)
Do ##class(IRIS105.Util.MockData).Generate()
```

### Testing ML Model

```sql
-- Train model (run in MLTEST namespace)
\i sql/NoShow_model.sql

-- Or manually:
CREATE MODEL NoShowModel2 PREDICTING (NoShow) WITH (...) FROM IRIS105.Appointment;
TRAIN MODEL NoShowModel2 USING {"seed": 42, "TrainMode": "BALANCE", "MaxTime": 60};
VALIDATE MODEL NoShowModel2;

-- Test scoring
SELECT A.AppointmentId,
       PREDICT(NoShowModel2) AS PredictedLabel,
       PROBABILITY(NoShowModel2 FOR 1) AS NoShowProb
FROM IRIS105.Appointment AS A
WHERE A.AppointmentId = 'APPT-1';
```

### Testing REST API

```bash
# Health check (no auth required)
curl http://localhost:52773/csp/mltest/api/health

# Score by appointment ID (requires Bearer token)
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId":"APPT-1"}'

# Score with ad-hoc features
curl -X POST http://localhost:52773/csp/mltest/api/ml/noshow/score \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"features":{"PatientId":10,"PhysicianId":3,"BoxId":2,"SpecialtyId":1,"StartDateTime":"2025-11-18 10:30:00","BookingChannel":"WEB","BookingDaysInAdvance":5,"HasSMSReminder":1,"Reason":"Control"}}'

# Get statistics
curl http://localhost:52773/csp/mltest/api/ml/stats/summary \
  -H "Authorization: Bearer demo-readonly-token"

# Generate additional mock data
curl -X POST http://localhost:52773/csp/mltest/api/ml/mock/generate \
  -H "Authorization: Bearer demo-readonly-token" \
  -H "Content-Type: application/json" \
  -d '{"months":3,"targetOccupancy":0.85,"patients":200}'
```

## Key Technical Details

### IntegratedML Integration

- Model name: `NoShowModel2` (default model used throughout)
- Scoring uses SQL functions: `PREDICT(NoShowModel2)` and `PROBABILITY(NoShowModel2 FOR 1)`
- Features: PatientId, PhysicianId, BoxId, SpecialtyId, StartDateTime, BookingChannel, BookingDaysInAdvance, HasSMSReminder, Reason
- Training mode: BALANCE (handles class imbalance)
- Target: NoShow field (0 or 1)

### Authentication

- REST endpoints (except `/api/health`) require Bearer token
- Token validation: checks `^IRIS105("API","Tokens",token)` global
- To add token: `Set ^IRIS105("API","Tokens","your-token-here")=1`
- Web apps created with no auth for demo (harden for production)

### SQL Query Patterns

- Use `%SQL.Statement` for dynamic queries (never concatenate user input)
- Avoid `TOP ?` parameterization (some IRIS versions don't support it; concatenate limit instead)
- Analytics endpoints include `debug` traces in responses for troubleshooting
- Capacity calculations use heuristics: `slotsPerDay × 3 patients/hour × factor`

### REST API Structure

All endpoints in `IRIS105.REST.NoShowService`:
- **Scoring**: `/api/ml/noshow/score` (POST)
- **Stats**: `/api/ml/stats/summary`, `/api/ml/stats/model`, `/api/ml/stats/lastAppointmentByPatient`
- **Analytics**: `/api/ml/analytics/busiest-day`, `/api/ml/analytics/top-specialties`, `/api/ml/analytics/top-physicians`, `/api/ml/analytics/top-noshow`, `/api/ml/analytics/occupancy-weekly`, `/api/ml/analytics/scheduled-patients`, `/api/ml/analytics/occupancy-trend`
- **Appointments**: `/api/ml/appointments/active`
- **Config**: `/api/ml/config/capacity` (GET/POST)
- **Mock**: `/api/ml/mock/generate` (POST)
- **Health**: `/api/health` (GET)

Responses include:
- `success` (boolean)
- `data` (object with results)
- `debug` (array of trace steps for analytics endpoints)
- `error` (string, when success=false)

## Important Standards (from INSTRUCTIONS.md)

When reviewing or modifying code:

- **Transactions**: ALWAYS use TSTART/TCOMMIT for write operations
- **SQL Safety**: ALWAYS use `%SQL.Statement` for dynamic queries (prevent SQL injection)
- **Input Validation**: ALWAYS validate inputs in setters
- **Error Handling**: ALWAYS use Try/Catch blocks
- **Storage Definitions**: ALWAYS define custom storage layouts for persistent classes
- **Documentation**: ALWAYS document public methods

## Known Limitations and Pending Work

- Scoring results not persisted to `AppointmentRisk` table (only returned in API response)
- No automated tests or CI/CD pipeline
- Authentication is demo-mode (not hardened for production)
- Capacity calculations use heuristics (need realistic persistent configuration)
- Performance: Consider adding composite indices on `Appointment` for common queries
- Docker deployment scripts not finalized

## VS Code Configuration

- Extension: InterSystems ObjectScript
- Connection: `localhost:52773` or tunnel `iris105.htc21.site`
- Namespace: `MLTEST`
- Workspace file: `iris105.code-workspace`

## Related Documentation

- `readme.md`: Main project documentation with setup and API examples
- `docs/arquitectura.md`: Functional architecture overview
- `docs/sprint_status.md`: Current sprint progress
- `docs/sprint1_setup.md`: Initial setup guide
- `docs/demo_script.md`: Quick demo walkthrough
- `docs/openapi.yaml`: Complete OpenAPI 3.1.0 specification
- `BUENAS_PRACTICAS_IRIS_COMBINADAS.md`: IRIS project best practices guide
- `INSTRUCTIONS.md`: Code review guidelines
