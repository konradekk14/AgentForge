# Microservices Base Architecture

Multi-service architecture where each service is independently deployable. Use this template when the project has distinct bounded contexts that need to scale, deploy, or evolve independently.

## Agent Topology

| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| orchestrator | Routes work, manages phases, never writes app code | sonnet | Read |
| [service-N] | One agent per service — owns that service's code entirely | sonnet | Read, Write, Bash |
| gateway | API gateway config, routing rules, rate limiting, auth | sonnet | Read, Write, Bash |
| infra | Docker compose, CI/CD per-service, Makefile, shared infra | sonnet | Read, Write, Bash |
| testing | Per-service unit/integration tests, contract tests, e2e | sonnet | Read, Write, Bash |
| reviewer | Quality, security, PRD fidelity gate — read-only | sonnet | Read, Glob, Grep, Bash |

One agent per service. Do NOT collapse multiple services into one agent.

## Service Discovery

Use simple approaches first:
- **Docker Compose** (local/small): service name DNS (`http://auth-service:3001`)
- **Environment variables** (small production): `AUTH_SERVICE_URL=http://auth-service:3001`
- **Service mesh** (large production): Consul, Istio — only if you actually need it

Each service must expose: `GET /health`, `GET /ready`

## Inter-Service Authentication

Service-to-service calls use shared secrets or mTLS:
```
Option A: Shared secret
  Service A sets: Authorization: Bearer [SERVICE_SECRET]
  Service B validates the secret

Option B: JWT with service identity
  Each service has its own signing key
  Include: { iss: "service-a", aud: "service-b", iat, exp }
```

Never use user JWT tokens for service-to-service calls.

## API Gateway Pattern

All external traffic enters through the gateway:
```
Client → Gateway → [auth check] → Service A
                                → Service B
                                → Service C

Gateway responsibilities:
- TLS termination
- Authentication (validate JWT, inject user context)
- Rate limiting (per user, per IP)
- Request ID injection
- Response aggregation (BFF pattern if needed)
- Circuit breaking (fail fast if service is down)
```

Tools: nginx, Kong, Traefik, AWS API Gateway, or a lightweight custom proxy.

## Shared Error Handling

Every service must use the same error response shape:
```json
{ "error": "Human message", "code": "MACHINE_CODE", "service": "auth", "request_id": "uuid" }
```

The gateway adds `service` and `request_id` fields if services omit them.

## Distributed Tracing

Inject `X-Request-ID` at gateway. Every service:
1. Reads `X-Request-ID` from incoming request headers
2. Logs it with every log line
3. Passes it to downstream service calls

Minimal tracing without a full tracing backend. Upgrade to OpenTelemetry when needed.

## Logging Pattern

Structured logger in every service:
```json
{
  "service": "auth-service",
  "level": "info",
  "timestamp": "ISO-8601",
  "request_id": "uuid",
  "method": "POST",
  "path": "/auth/login",
  "status": 200,
  "duration_ms": 45
}
```

Centralize logs: ship to a single sink (CloudWatch, Datadog, ELK) from all services.

## Health Check Pattern

Every service exposes:
```
GET /health → { status, version, uptime }            ← liveness probe
GET /ready  → { status, dependencies: {db: "ok"} }  ← readiness probe
```

Gateway aggregates: `GET /health/all` → check all service /health endpoints.

## CI/CD Pattern

Per-service CI (run only when service directory changes):
```yaml
on:
  pull_request:
    paths: ['services/[service-name]/**']

jobs:
  test-[service]:
    - lint + typecheck
    - unit tests
    - integration tests
    - docker build (validate image builds)

on: push to main (service path changed)
jobs:
  deploy-[service]: (manual trigger or auto depending on environment)
```

Never redeploy all services when only one changed.

## Docker Pattern

Each service has its own Dockerfile (multi-stage):
```
services/
  auth-service/
    Dockerfile
  user-service/
    Dockerfile
  [service-N]/
    Dockerfile
```

Root docker-compose.yml for local development:
```yaml
services:
  gateway:
    image: nginx:alpine
    ports: ["80:80"]
    volumes: ["./gateway/nginx.conf:/etc/nginx/nginx.conf"]

  auth-service:
    build: services/auth-service
    env_file: services/auth-service/.env

  user-service:
    build: services/user-service
    env_file: services/user-service/.env

  db:
    image: postgres:16-alpine
    volumes: [db-data:/var/lib/postgresql/data]
    healthcheck: ...

  redis:
    image: redis:7-alpine
```

## Testing Pattern

```
tests/
  unit/
    [service-name]/       ← per-service unit tests
  integration/
    [service-name]/       ← per-service integration tests (real DB)
  contract/
    auth-to-user/         ← consumer-driven contract tests between services
    [service-a]-to-[b]/
  e2e/
    [user-flow].test.ts   ← full flow through gateway → services
  fixtures/
    [entity].fixture.ts
USER_TESTING.md           ← manual e2e scenarios through the gateway
```

Contract tests (Pact or similar) are the most important for microservices — they catch breaking API changes between services before deployment.

## Security Pattern

- Every service validates auth independently (don't trust gateway alone)
- Service-to-service: shared secrets or mTLS, never user tokens
- Each service has its own database — no cross-service DB access
- Secrets: per-service env files, never shared
- Network: services only reachable via gateway externally; internal Docker network for inter-service
- Rate limiting: at gateway (per user) AND at service level (per service)

## Destructive Operations (require human gate)

- Deploying a breaking API change (coordinate with all consumers first)
- Database migrations (per-service, never cross-service)
- Retiring a service (ensure all consumers are updated first)
- Bulk data operations
- Any production deployment

## File Structure

```
project/
├── CLAUDE.md                    ← orchestrator
├── .claude/
│   ├── settings.json
│   └── agents/
│       ├── [service-1].md       ← one agent per service
│       ├── [service-N].md
│       ├── gateway.md
│       ├── infra.md
│       ├── testing.md
│       └── reviewer.md
├── .github/
│   └── workflows/
│       ├── ci-[service-1].yml   ← per-service CI
│       ├── ci-[service-N].yml
│       └── ci-shared.yml        ← shared infra changes
├── docker-compose.yml           ← local dev: all services together
├── Makefile                     ← dev, test-all, build-all, logs
├── gateway/
│   └── nginx.conf               ← or Kong/Traefik config
├── services/
│   ├── [service-1]/
│   │   ├── Dockerfile
│   │   ├── src/
│   │   ├── tests/
│   │   ├── .env.example
│   │   └── package.json
│   └── [service-N]/
│       └── ...
├── shared/
│   ├── types/                   ← shared TypeScript types
│   └── errors/                  ← shared error codes
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── contract/
│   └── e2e/
├── USER_TESTING.md
├── tasks/
├── .env.example                 ← gateway-level env vars
├── .gitignore
└── README.md
```

## Environment Variables

Per-service `.env.example` in `services/[service]/`:
```
# Service identity
SERVICE_NAME=[service-name]
PORT=300N

# Database (each service has its own DB)
DATABASE_URL=postgresql://user:pass@localhost:5432/[service]_db

# Auth
JWT_SECRET=
SERVICE_SECRET=   ← for inter-service auth

# Dependencies (other services)
AUTH_SERVICE_URL=http://localhost:3001
[DEPENDENCY]_SERVICE_URL=
```

Root `.env.example` (gateway/shared):
```
# Gateway
GATEWAY_PORT=80

# Shared secrets
INTER_SERVICE_SECRET=

# Monitoring
LOG_AGGREGATOR_URL=
TRACING_ENDPOINT=
```
