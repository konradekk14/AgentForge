# Data Pipeline Base Architecture

## Agent Topology

| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| orchestrator | Pipeline sequencing, error handling, retry logic | sonnet | Read |
| ingestion | Data extraction from sources, schema detection | sonnet | Read, Write, Bash |
| transform | Data cleaning, validation, transformation, enrichment | sonnet | Read, Write, Bash |
| loader | Writing to destination stores, idempotency checks | sonnet | Read, Write, Bash |
| infra | Dockerfile, CI/CD workflows, Makefile, orchestration config | sonnet | Read, Write, Bash |
| testing | Unit tests, integration tests, data quality tests, fixtures | sonnet | Read, Write, Bash |
| reviewer | Data quality, security, PRD fidelity gate — read-only | sonnet | Read, Glob, Grep, Bash |

## Pipeline Execution Pattern

```
Source → [Ingestion] → raw/ → [Transform] → clean/ → [Loader] → Destination
                ↓                    ↓                   ↓
           dead_letter/        checkpoints/         audit_log/
```

Every stage is idempotent: safe to re-run without duplicating data.

## Error Handling Pattern

```
Record-level errors:
  → log to dead_letter/ with: record, error, timestamp, stage
  → continue processing remaining records
  → report count at end

Stage-level errors:
  → checkpoint current progress
  → write to handoffs/pipeline-error.md
  → alert operator (log + optional webhook)
  → do NOT write partial data to destination

Schema errors:
  → hard fail — do not process
  → write schema diff to handoffs/schema-error.md
```

## Checkpointing Pattern

For long-running pipelines:
- Write checkpoint after every N records (configurable, default 1000)
- Checkpoint format: `{ last_processed_id, timestamp, records_processed, errors }`
- On restart: read checkpoint, skip already-processed records
- Checkpoint location: `checkpoints/[run-id].json`

## Logging Pattern

Use structured logger (pino, structlog, zap):
```json
{
  "level": "info",
  "timestamp": "2025-01-01T00:00:00Z",
  "run_id": "uuid",
  "stage": "transform",
  "records_processed": 1000,
  "records_failed": 2,
  "duration_ms": 450
}
```

Log at stage boundaries, not per-record (too noisy). Log errors per-record.

## Health Check / Monitoring Pattern

```
GET /health (if running as a service) → { status, last_run, next_run, records_processed }
Metrics: records_in, records_out, records_failed, duration, lag (if streaming)
Alerts: on >1% failure rate, on stale last_run, on schema drift
```

## Data Quality Pattern

Schema validation at every boundary:
- Input: validate against expected schema before processing
- Transform output: validate shape before passing to loader
- Load: check row counts match expectation (±5% tolerance)

Use: Great Expectations, pandera, dbt tests, or custom validators.

## CI/CD Pattern

```yaml
on: [pull_request]
jobs:
  test:
    - unit tests (transform functions, validators)
    - integration tests (with sample data files, in-memory DB)
    - data quality tests (schema validation)

on: push to main
jobs:
  build: docker build pipeline image
  deploy: (manual trigger only — human gate for production)
```

## Docker Pattern

Multi-stage Dockerfile:
- `builder`: install all deps, compile if needed
- `production`: slim image, prod deps only

docker-compose.yml:
- `pipeline`: the pipeline runner
- `db`: destination database (for local dev)
- `source-mock`: mock of source system (for integration tests)
- Volumes for checkpoints, dead_letter, logs

Makefile:
```
dev:     run pipeline locally with sample data
test:    run all tests
build:   docker build
migrate: run DB migrations
ingest:  trigger manual pipeline run
```

## Testing Pattern

```
tests/
  unit/
    test_transform.py      ← test each transform function in isolation
    test_validators.py     ← test schema validation rules
    test_loaders.py        ← test loader logic with mock DB
  integration/
    test_pipeline_e2e.py   ← sample input → assert output in test DB
    test_idempotency.py    ← run twice, assert same result
  fixtures/
    sample_input.json      ← representative input records
    expected_output.json   ← expected transformed output
    schema_v1.json         ← source schema definition
USER_TESTING.md            ← how to run manually, how to verify output
```

## Security Pattern

- Database credentials: env vars only, never in config files
- Validate all schemas before loading (prevent injection via data)
- Audit trail for every data mutation (who ran what, when, row counts)
- PII: mask/hash in logs and dead_letter
- Access controls: principle of least privilege on source and destination
- Encryption in transit (TLS) and at rest for sensitive data

## Destructive Operations (require human gate)

- Writing to production databases
- Truncating tables before load (use upsert instead when possible)
- Deleting or archiving source records
- Publishing to downstream consumers / message queues
- Running backfills on historical data

## File Structure

```
project/
├── CLAUDE.md                    ← orchestrator
├── .claude/
│   ├── settings.json
│   └── agents/
│       ├── ingestion.md
│       ├── transform.md
│       ├── loader.md
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
│   ├── extractors/              ← source connectors
│   ├── transformers/            ← transform functions (pure, testable)
│   ├── loaders/                 ← destination writers
│   ├── validators/              ← schema validation
│   └── utils/
│       ├── logger.py            ← structured logger
│       └── checkpoint.py       ← checkpointing logic
├── configs/
│   └── pipeline.yaml           ← pipeline configuration (no secrets)
├── migrations/
├── checkpoints/                 ← runtime, gitignored
├── dead_letter/                 ← runtime, gitignored
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── USER_TESTING.md
├── tasks/
├── .env.example
├── .gitignore
└── README.md
```

## Environment Variables

```
# Source
SOURCE_DB_URL=
SOURCE_API_KEY=
SOURCE_API_URL=

# Destination
DEST_DB_URL=
DEST_SCHEMA=

# Pipeline config
BATCH_SIZE=1000
CHECKPOINT_INTERVAL=1000
MAX_RETRIES=3
DEAD_LETTER_PATH=./dead_letter

# Monitoring
ALERT_WEBHOOK_URL=
```
