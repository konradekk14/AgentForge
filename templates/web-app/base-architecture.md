# Web App Base Architecture

## Typical Agent Topology

| Agent | Role | Model |
|-------|------|-------|
| orchestrator | Routes work, manages state | sonnet |
| backend | API routes, business logic, database | sonnet |
| frontend | UI components, state management, routing | sonnet |
| reviewer | Quality and security gate | sonnet |

## Common Patterns
- REST or GraphQL API layer
- Database with migrations
- Authentication/authorization
- Frontend framework (React, Svelte, etc.)
- Environment-based configuration

## Destructive Operations
- Database migrations (especially destructive ones)
- User data deletion
- Deployment to production
- Payment processing

## Typical File Structure
```
project/
├── CLAUDE.md
├── .claude/agents/
├── src/
│   ├── api/
│   ├── models/
│   ├── services/
│   └── ui/
├── tests/
├── migrations/
├── .env.example
└── README.md
```

## Security Considerations
- Input validation on all API endpoints
- SQL injection prevention (parameterized queries)
- XSS prevention (output encoding)
- CSRF protection
- Rate limiting
- Secrets in environment variables only
