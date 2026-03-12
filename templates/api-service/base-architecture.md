# API Service Base Architecture

Pure REST or GraphQL API with no frontend. Use this template when the deliverable is an API consumed by other clients (mobile apps, third-party integrations, other services).

## Agent Topology

| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| orchestrator | Routes work, manages phases, never writes app code | sonnet | Read |
| api | Route handlers, request validation, response shaping, OpenAPI spec | sonnet | Read, Write, Bash |
| data | Database schema, migrations, ORM models, query optimization | sonnet | Read, Write, Bash |
| infra | Dockerfile, docker-compose, CI/CD workflows, Makefile | sonnet | Read, Write, Bash |
| testing | Unit tests, integration tests, contract tests, fixtures | sonnet | Read, Write, Bash |
| reviewer | Quality, security, PRD fidelity gate — read-only | sonnet | Read, Glob, Grep, Bash |

## API Design Patterns

### OpenAPI Spec

Generate `openapi.yaml` or `openapi.json` as the source of truth for the API contract. All route implementations must match the spec.

Tools: swagger-codegen, fastapi (auto-generates), express-openapi-validator.

### Versioning

URL versioning: `/api/v1/`, `/api/v2/`
- Never break existing clients by removing/renaming fields
- Add new fields freely (backward compatible)
- Deprecation: add `Deprecation` header + docs update, then remove in next major version

### Pagination

All list endpoints must be paginated:
```json
GET /api/v1/resources?page=1&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

Use cursor-based pagination for large datasets or real-time data.

### Rate Limiting

```
Public endpoints:    100 req/15min per IP
Authenticated:       1000 req/15min per user
Write operations:    50 req/15min per user
Auth endpoints:      10 req/15min per IP (stricter)
```

Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

### Standard Response Shape

```json
Success:
{ "data": {...} | [...], "meta": {...} }

Error:
{ "error": "Human-readable message", "code": "MACHINE_CODE", "details": [...] }

Validation Error (422):
{ "error": "Validation failed", "details": [{ "field": "email", "message": "Invalid email" }] }
```

### Authentication Patterns

- API key (server-to-server): `Authorization: Bearer [api-key]`
- JWT (user auth): short-lived access token + refresh token rotation
- OAuth2 (third-party): authorization code flow for user-delegated access

Always validate tokens on every request — no session state.

## Middleware Stack (ordered)

1. `helmet` — security headers
2. `cors` — explicit origin allowlist
3. Request ID middleware — `X-Request-ID` header for tracing
4. `body-parser` — JSON + size limits
5. Rate limiter
6. Authentication middleware
7. Request logger (method, path, user, request_id)
8. Application routes
9. 404 handler
10. Centralized error handler (last)

## Error Handling Pattern

```
Validation errors → 422 with field details
Auth errors → 401 (not authenticated) or 403 (not authorized)
Not found → 404
Conflict (duplicate) → 409
Server error → 500, log full stack server-side, return opaque error to client
```

## Logging Pattern

Structured logger (pino, structlog, zap):
```json
{
  "level": "info",
  "timestamp": "ISO-8601",
  "request_id": "uuid",
  "method": "POST",
  "path": "/api/v1/users",
  "status": 201,
  "duration_ms": 45,
  "user_id": "uuid or null"
}
```

## Health Check Pattern

```
GET /health
→ { "status": "ok", "version": "1.2.0", "uptime": 3600, "dependencies": { "database": "ok" } }

GET /ready (for Kubernetes readiness probe)
→ 200 if DB connections available, 503 if not

GET /metrics (optional, for Prometheus)
→ Prometheus text format
```

## CI/CD Pattern

```yaml
on: pull_request
jobs:
  test:
    - lint + typecheck
    - unit tests
    - integration tests (real DB via testcontainers or in-memory)
    - contract tests (validate against OpenAPI spec)

on: push to main
jobs:
  build: docker build + push to registry
  deploy: (manual trigger — human gate)
```

## Docker Pattern

Multi-stage Dockerfile:
- `builder`: install all deps, compile TypeScript/run build step
- `production`: slim base, prod deps only, copy compiled output

docker-compose.yml services:
- `api`: the API server
- `db`: PostgreSQL with health check + persistent volume
- `redis`: (optional) for caching, rate limiting, or queues
- `docs`: serve OpenAPI docs (swagger-ui) in dev

## Testing Pattern

```
tests/
  unit/
    services/     ← business logic in isolation (mock DB)
    validators/   ← input validation rules
    utils/        ← utility functions
  integration/
    routes/       ← real HTTP calls via supertest/httpx, real test DB
    auth/         ← auth flow tests
  contract/
    openapi/      ← validate responses against openapi.yaml
  fixtures/
    users.fixture.ts
    [entity].fixture.ts
USER_TESTING.md   ← manual testing with curl/Postman examples
```

## Security Pattern

- Rate limiting (per tier, per endpoint sensitivity)
- CORS: explicit allowlist — never `*` in production
- Input validation at route level (zod, joi, pydantic)
- Parameterized queries only — never string concatenation
- API keys stored hashed in DB
- JWT: verify signature, expiry, and issuer on every request
- No sensitive data in logs or error responses
- HTTPS only in production

## Destructive Operations (require human gate)

- DB migrations that alter or drop columns
- Bulk data deletion
- API key revocation (user-visible effect)
- Deployment to production

## File Structure

```
project/
├── CLAUDE.md                    ← orchestrator
├── .claude/
│   ├── settings.json
│   └── agents/
│       ├── api.md
│       ├── data.md
│       ├── infra.md
│       ├── testing.md
│       └── reviewer.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── openapi.yaml                 ← API spec (source of truth)
├── src/
│   ├── routes/                  ← route handlers (thin — delegate to services)
│   │   └── v1/
│   ├── middleware/              ← ordered middleware stack
│   ├── services/                ← business logic (no HTTP knowledge)
│   ├── models/                  ← ORM models / DB schema types
│   ├── validators/              ← input validation schemas
│   └── utils/
│       ├── logger.ts
│       ├── errors.ts
│       └── db.ts               ← DB connection pool
├── migrations/
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/
│   └── fixtures/
├── USER_TESTING.md
├── tasks/
├── .env.example
├── .gitignore
└── README.md
```

## Environment Variables

```
# Server
PORT=3000
NODE_ENV=development
API_VERSION=v1

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
DATABASE_POOL_SIZE=10

# Auth
JWT_SECRET=
JWT_EXPIRY=15m
REFRESH_TOKEN_SECRET=
API_KEY_SALT=

# Rate limiting
REDIS_URL=redis://localhost:6379

# Monitoring
LOG_LEVEL=info
SENTRY_DSN=

# CORS
ALLOWED_ORIGINS=http://localhost:3000
```
