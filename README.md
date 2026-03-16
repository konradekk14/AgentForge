# AgentForge

A meta-system that generates fully configured multi-agent Claude Code projects. Describe what you want to build, and AgentForge interviews you, designs the architecture, and writes a complete runnable scaffold — ready to open in a new Claude Code session.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Anthropic API key (set as `ANTHROPIC_API_KEY` environment variable)

## Quick Start

1. Clone this repo and `cd AgentForge`
2. Open with Claude Code: `claude`
3. Run `/new-project` or just describe what you want to build
4. Answer interview questions covering 11 PRD sections (minimum 7, no ceiling)
5. Review the proposed architecture
6. Approve — AgentForge writes your scaffold to `output/[project-name]/`
7. `cd output/[project-name]` and open a new Claude Code session

## How It Works

AgentForge runs a 6-phase pipeline using Claude Code subagents:

**Phase 0 — Clean Slate**
Wipes `handoffs/` and truncates the audit log before each run.

**Phase 1 — Interview** *(Sonnet)*
Conducts a structured interview covering 11 PRD sections: overview, problem & users, user stories, functional requirements, non-functional requirements, data model, integrations, error states, deployment, out-of-scope, and UI/UX. Asks follow-up questions until every section has real answers. Outputs `handoffs/brief.md`.

**Phase 2 — Research** *(Sonnet)*
Scans templates and past lessons, analyzes previous output scaffolds, and conducts web research for best practices, current CVEs, and library versions. Outputs `handoffs/research.md`.

**Phase 3 — Architecture** *(Opus)*
Designs agent topology using domain-based rules, defines all inter-agent contracts, documents the execution flow, security posture, data model, and infra requirements. Outputs `handoffs/ARCHITECTURE.md`.

> **Human gate** — you must explicitly approve the architecture before scaffolding begins.

**Phase 4 — Scaffold** *(Sonnet)*
Writes the complete project to `output/[project-name]/`: all agent definitions, root `CLAUDE.md`, stub source files (TODOs only — no working logic), hooks, `README.md`, `DECISIONS.md`, `.env.example`, `.gitignore`, `Makefile`, and CI workflow. Conditionally generates Dockerfile/docker-compose, test stubs, and copies the `ui-ux-pro-max` skill for frontend agents.

**Phase 5 — Review** *(Sonnet)*
Validates the scaffold across 6 hard checks: FR coverage, agent quality, topology correctness, no implementation leaks, security, and structure. On failure, emits a structured `## Remediation List`. The scaffolder re-runs in surgical patch mode — touching only the named files — up to 3 retries before escalating.

## Project Structure

```
AgentForge/
├── CLAUDE.md                    # Orchestrator (root CLAUDE.md IS the orchestrator)
├── DECISIONS.md                 # 10 architectural decisions
├── .claude/
│   ├── settings.json            # Hook configuration
│   ├── agents/                  # 5 pipeline agents
│   │   ├── interviewer.md
│   │   ├── researcher.md
│   │   ├── architect.md         # Uses Opus
│   │   ├── scaffolder.md
│   │   └── reviewer.md
│   ├── hooks/                   # Security and audit hooks
│   │   ├── audit-log.sh
│   │   ├── block-secrets.sh
│   │   └── require-tests.sh
│   └── skills/new-project/      # /new-project entry point
├── templates/                   # Base architecture templates
├── handoffs/                    # Agent communication artifacts
├── output/                      # Generated scaffolds
├── tasks/                       # Tracking and lessons
└── logs/                        # Audit trail
```

## What Gets Generated

Every scaffold is immediately runnable in Claude Code with zero manual setup:

- `CLAUDE.md` — orchestrator with full agent instructions
- `.claude/agents/*.md` — scoped agent definitions with CAN/CANNOT constraints, inter-agent contracts, and handoff protocol
- `.claude/hooks/` — security hooks copied from AgentForge
- `.claude/settings.json` — hooks wired
- Stub source files — `TODO` comments only, no working logic
- `README.md`, `DECISIONS.md`, `.env.example`, `.gitignore`
- `tasks/todo.md` seeded from PRD functional requirements
- If infra agent: `Dockerfile` (multi-stage), `docker-compose.yml`, `Makefile`, `.github/workflows/ci.yml`
- If testing agent: test stubs in `tests/unit/`, `tests/integration/`, `USER_TESTING.md`
- If frontend agent: `ui-ux-pro-max` skill copied into the project
- `handoffs/brief.md` and `handoffs/ARCHITECTURE.md` copied for agent context

## Security Model

- **No secrets in files** — `block-secrets.sh` hook scans 11 credential patterns and blocks writes
- **Audit trail** — `audit-log.sh` logs every tool use to `logs/audit.log`
- **Test enforcement** — `require-tests.sh` warns if generated scaffolds have no tests
- **Human gate** — architecture must be approved before any files are written
- **Scoped agents** — every generated agent has explicit CAN/CANNOT constraints and owns specific files only

## Templates

AgentForge ships with 6 base architecture templates:

- `web-app` — full-stack web applications (6-agent topology)
- `api-service` — REST/OpenAPI services with versioning and rate limiting
- `agent-pipeline` — multi-agent AI systems with self-healing patterns
- `cli-tool` — command-line tools (3-agent topology)
- `data-pipeline` — ETL/data processing with idempotency
- `microservices` — per-service agents with gateway pattern

Templates are starting points — the architect adapts them to the specific project.

## License

MIT — Copyright (c) 2026 Konrad Kapusta
