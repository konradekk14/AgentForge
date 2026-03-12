# Agent Pipeline Base Architecture

## Agent Topology

| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| orchestrator | Sequences agents, manages handoffs, self-healing retry loop | sonnet | Read |
| specialist-1..N | Domain-specific task execution (one agent per concern) | sonnet/opus | [task-specific] |
| infra | Hooks, settings.json, CI/CD, audit infrastructure | sonnet | Read, Write, Bash |
| testing | Test suites for agent behavior, fixture data | sonnet | Read, Write, Bash |
| reviewer | Quality, security, PRD fidelity gate — read-only | sonnet | Read, Glob, Grep, Bash |

## Handoff Protocol

All agent communication is file-based — no in-memory state passing:

```
handoffs/
  brief.md          ← project requirements (input)
  research.md       ← research findings
  ARCHITECTURE.md   ← approved architecture
  [phase]-output.md ← each agent writes its output here
  review.md         ← reviewer's verdict
  errors/           ← error artifacts for retry context
```

Agent reads its input file → does work → writes output file → next agent reads that file.
Never call another agent directly. Always go through the orchestrator.

## Self-Healing Retry Loop

```
Agent produces output
  → reviewer checks it
  → PASS: orchestrator routes to next phase
  → FAIL: orchestrator routes back to agent with failure context
  → agent retries (max 3 per phase)
  → 3rd failure: surface to user with full context + lessons learned
  → log failure pattern to tasks/lessons.md
```

## Logging / Audit Pattern

Every tool use is logged via hooks:
```
logs/
  audit/
    [timestamp]-[agent]-[tool].log   ← every tool call recorded
  errors/
    [timestamp]-[agent]-error.log    ← every failure with context
```

Structured log format:
```json
{
  "timestamp": "ISO-8601",
  "agent": "researcher",
  "tool": "Read",
  "input": "handoffs/brief.md",
  "result": "success",
  "duration_ms": 120
}
```

## Observability Pattern

For agent pipelines that run as a service:
```
GET /health → { status, current_phase, phases_complete, agents_dispatched }
GET /status → { run_id, started_at, current_agent, retry_count }
POST /retry → trigger retry of failed phase
```

For batch pipelines: write `logs/run-summary.json` at completion.

## CI/CD Pattern

```yaml
on: [pull_request]
jobs:
  test:
    - lint agent definition files (yaml frontmatter validation)
    - unit tests for any utility code
    - integration tests: run pipeline with mock inputs, assert output shape

on: push to main
jobs:
  build: validate all agent definitions
  smoke-test: run pipeline with sample brief, assert review PASS
```

## Docker Pattern

Agent pipelines are typically not containerized unless:
- They run as a scheduled service
- They have external service dependencies (databases, APIs)
- They need reproducible environments

If containerized:
- Dockerfile: single stage (Claude Code runs inside container)
- docker-compose: mount `handoffs/` and `output/` as volumes for persistence
- Health check: verify Claude Code is available

## Testing Pattern

```
tests/
  unit/
    test_[agent-name].md     ← test agent behavior with mock inputs
    test_handoffs.py         ← validate handoff file formats
  integration/
    test_pipeline.py         ← run full pipeline with sample brief
    test_retry_loop.py       ← simulate failures, verify retry behavior
  fixtures/
    sample_brief.md          ← representative project brief
    expected_research.md     ← expected research output shape
    expected_architecture.md ← expected ARCHITECTURE.md structure
USER_TESTING.md              ← how to run /new-project manually, what to verify
```

## Security Pattern

- No agent has more permissions than its tool list allows
- Reviewer validates every handoff — never skipped
- Audit log captures every tool use
- Secrets: env vars only, never in handoff files or agent definitions
- Block-secrets hook fires before any write
- Agent definitions: reviewer is always read-only (no Write/Bash in tools)

## Middleware / Hook Stack (ordered)

Applied to every tool call via `.claude/settings.json`:
1. `audit-log.sh` — log tool call and agent
2. `block-secrets.sh` — scan write content for credential patterns
3. `require-tests.sh` — warn if scaffold skips tests
4. Tool executes
5. Output logged

## Destructive Operations (require human gate)

- Writing to `output/` (generates real files)
- External API calls with side effects
- Sending notifications or messages
- Modifying shared state outside the pipeline
- Deleting any file (reviewer never does this)

## CAN/CANNOT Model

Every agent definition MUST have:
```markdown
## Rules
- CAN: [explicit list of what this agent is allowed to do]
- CANNOT: [explicit list of what this agent must never do]
```

Reviewer is always: CAN read, CANNOT write (except review.md).
Orchestrator is always: CAN route, CANNOT write domain code.

## File Structure

```
project/
├── CLAUDE.md                    ← orchestrator
├── .claude/
│   ├── settings.json           ← hooks configuration
│   ├── agents/
│   │   ├── [specialist-1].md
│   │   ├── [specialist-N].md
│   │   ├── infra.md
│   │   ├── testing.md
│   │   └── reviewer.md
│   ├── hooks/
│   │   ├── audit-log.sh
│   │   ├── block-secrets.sh
│   │   └── require-tests.sh
│   └── skills/
├── handoffs/
├── logs/
│   └── audit/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── USER_TESTING.md
├── tasks/
│   ├── todo.md
│   └── lessons.md
├── .env.example
├── .gitignore
└── README.md
```

## Environment Variables

```
# Claude API (if agents call API directly)
ANTHROPIC_API_KEY=

# Audit / monitoring
AUDIT_LOG_PATH=./logs/audit
MAX_RETRIES=3

# External integrations (if any)
[SERVICE]_API_KEY=
[SERVICE]_WEBHOOK_URL=
```
