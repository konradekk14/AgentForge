# Data Pipeline Base Architecture

## Typical Agent Topology

| Agent | Role | Model |
|-------|------|-------|
| orchestrator | Pipeline sequencing and error handling | sonnet |
| ingestion | Data extraction from sources | sonnet |
| transform | Data cleaning, validation, transformation | sonnet |
| loader | Writing to destination stores | sonnet |
| reviewer | Data quality and security checks | sonnet |

## Common Patterns
- ETL/ELT pipeline stages
- Idempotent operations (safe to re-run)
- Schema validation at boundaries
- Checkpointing for long-running jobs
- Dead letter queues for failed records

## Destructive Operations
- Writing to production databases
- Deleting or overwriting source data
- Truncating tables before load
- Publishing to downstream consumers

## Typical File Structure
```
project/
├── CLAUDE.md
├── .claude/agents/
├── src/
│   ├── extractors/
│   ├── transformers/
│   ├── loaders/
│   └── schemas/
├── tests/
├── configs/
├── .env.example
└── README.md
```

## Security Considerations
- Database credentials in env vars only
- Validate schemas before loading
- Audit trail for data mutations
- Access controls on source and destination
- PII handling and masking
