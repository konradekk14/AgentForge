# Web App Base Architecture

## Agent Topology

| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| orchestrator | Routes work, manages phases, never writes app code | sonnet | Read |
| frontend | UI components, state management, routing, client-side logic | sonnet | Read, Write, Bash |
| backend | API routes, business logic, database schema, auth | sonnet | Read, Write, Bash |
| infra | Dockerfile, docker-compose, CI/CD workflows, Makefile | sonnet | Read, Write, Bash |
| testing | Unit tests, integration tests, USER_TESTING.md, fixtures | sonnet | Read, Write, Bash |
| reviewer | Quality, security, PRD fidelity gate — read-only | sonnet | Read, Glob, Grep, Bash |

## Middleware Stack (ordered)

Apply in this order — do not reorder:
1. `helmet` — security headers
2. `cors` — cross-origin policy
3. `body-parser` / `express.json()` — request body parsing
4. `express-session` / JWT middleware — session/token management
5. `auth middleware` — verify identity
6. `csrf protection` — anti-CSRF tokens (stateful sessions only)
7. Application routes
8. Static file serving
9. 404 fallback handler
10. Centralized error handler (last)

## Error Handling Pattern

Centralized error handler — all errors flow here:
```
{ error: string, details?: string[], code?: string }
```
- Domain errors throw structured error objects (not strings)
- HTTP layer catches and formats them
- Never leak stack traces to clients in production

## Logging Pattern

Use structured logger (pino for Node, structlog for Python):
- Log levels: debug (dev only), info, warn, error
- Every request: method, path, status, duration, request_id
- Every error: message, stack (server-side only), context
- Never use `console.log` in production code

## Health Check Pattern

```
GET /health → 200 OK
{
  "status": "ok",
  "version": "1.0.0",
  "uptime": 1234,
  "dependencies": {
    "database": "ok" | "degraded" | "down"
  }
}
```

## CI/CD Pattern

```yaml
# .github/workflows/ci.yml
on: [pull_request]  # test + lint
on: push to main    # build Docker image

jobs:
  test: install → lint → unit tests → integration tests
  build: docker build (only after test passes)
```

## Docker Pattern

Multi-stage Dockerfile:
- `builder` stage: full dev deps, compile/transpile
- `production` stage: slim base, prod deps only, no source maps, no dev tools

docker-compose.yml services:
- `app`: the web server
- `db`: PostgreSQL/MySQL/MongoDB with health check
- `redis`: (if sessions/cache needed)
- Volumes for persistent data
- `env_file: .env` for secrets

## Testing Pattern

```
tests/
  unit/          ← pure functions, no I/O, <100ms total
  integration/   ← real in-memory DB (sqlite/testcontainers), real HTTP via supertest
  fixtures/      ← factories for test data
USER_TESTING.md  ← step-by-step manual scenarios for every FR
```

## Security Pattern

- Rate limiting: 100 req/15min per IP on public routes, stricter on auth routes
- CORS: explicit allowlist, not `*`
- Input validation: validate at API boundary (zod, joi, pydantic)
- Auth: JWT with short expiry + refresh tokens, or session with secure/httpOnly cookies
- SQL: parameterized queries only — never string concatenation
- Secrets: env vars via `.env` (never committed)

## Common Patterns
- REST or GraphQL API layer
- Database with migrations (not raw schema drops)
- OAuth or email/password auth
- Frontend framework (React, Svelte, Vue, Next.js)
- Environment-based configuration (dev/test/prod)

## Destructive Operations (require human gate)
- Database migrations that drop/alter columns
- User data deletion
- Deployment to production
- Payment processing
- Bulk data operations

## File Structure

```
project/
├── CLAUDE.md                    ← orchestrator
├── .claude/
│   ├── settings.json
│   └── agents/
│       ├── frontend.md
│       ├── backend.md
│       ├── infra.md
│       ├── testing.md
│       └── reviewer.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── src/
│   ├── api/                     ← route handlers
│   ├── middleware/              ← ordered middleware stack
│   ├── models/                  ← DB schema/ORM models
│   ├── services/                ← business logic
│   ├── utils/
│   │   ├── logger.ts            ← structured logger
│   │   └── errors.ts           ← error types
│   └── ui/                     ← frontend components
├── migrations/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── USER_TESTING.md
├── handoffs/
├── tasks/
├── .env.example
├── .gitignore
└── README.md
```

## Environment Variables (required)

```
# App
PORT=
NODE_ENV=
APP_SECRET=

# Database
DATABASE_URL=

# Auth
JWT_SECRET=
SESSION_SECRET=

# External services
[SERVICE]_API_KEY=
```
