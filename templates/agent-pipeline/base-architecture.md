# Agent Pipeline Base Architecture

## Typical Agent Topology

| Agent | Role | Model |
|-------|------|-------|
| orchestrator | Sequences agents, manages handoffs | sonnet |
| specialist-1..N | Domain-specific task execution | sonnet/opus |
| reviewer | Quality and security gate | sonnet |

## Common Patterns
- File-based handoffs between agents
- Human gates before destructive operations
- Self-healing retry loop (max 3 attempts)
- Audit logging for every agent action
- CAN/CANNOT permission model per agent

## Destructive Operations
- Writing files to disk
- External API calls with side effects
- Sending notifications or messages
- Modifying shared state

## Typical File Structure
```
project/
├── CLAUDE.md
├── .claude/
│   ├── agents/
│   ├── hooks/
│   └── settings.json
├── handoffs/
├── tasks/
├── logs/
├── .env.example
└── README.md
```

## Security Considerations
- No agent should have more permissions than needed
- Reviewer validates every handoff
- Audit trail for debugging and accountability
- Secrets never in files, always env vars
