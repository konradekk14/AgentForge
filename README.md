# AgentForge

A meta-system that generates fully configured multi-agent Claude Code projects. Describe what you want to build, and AgentForge interviews you, designs the architecture, and writes a complete runnable scaffold.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Anthropic API key (set as `ANTHROPIC_API_KEY` environment variable)

## Quick Start

1. Clone this repo and `cd AgentForge`
2. Open with Claude Code: `claude`
3. Run `/new-project` or describe what you want to build
4. Answer 7 interview questions
5. Review the proposed architecture
6. Approve, and AgentForge writes your scaffold to `output/`

## How It Works

AgentForge runs a 5-phase pipeline using Claude Code subagents:

1. **Interview** — Structured questions extract project requirements
2. **Research** — Scans templates and past lessons for relevant patterns
3. **Architecture** — Designs agent topology, permissions, and handoff protocol (uses Opus)
4. **Scaffold** — Writes the complete project after your approval
5. **Review** — Validates security, quality, and completeness

Every phase produces a file in `handoffs/`. Nothing proceeds past architecture without your explicit approval.

## Project Structure

```
AgentForge/
├── CLAUDE.md                    # Orchestrator brain
├── .claude/
│   ├── settings.json            # Hook configuration
│   ├── agents/                  # 5 subagent definitions
│   ├── hooks/                   # Security and audit hooks
│   └── skills/new-project/      # /new-project command
├── templates/                   # Base architecture templates
├── handoffs/                    # Agent communication artifacts
├── output/                      # Generated scaffolds
├── tasks/                       # Tracking and lessons
└── logs/                        # Audit trail
```

## Security Model

- **No secrets in files**: `block-secrets.sh` hook scans for credential patterns and blocks writes
- **Audit trail**: `audit-log.sh` logs every tool use to `logs/audit.log`
- **Test enforcement**: `require-tests.sh` ensures generated scaffolds include tests
- **Human gate**: Architecture must be approved before scaffolding begins
- **Permission model**: Every generated agent has explicit CAN/CANNOT constraints

## Templates

AgentForge includes base architecture templates for common project types:

- `web-app` — Full-stack web applications
- `agent-pipeline` — Multi-agent AI systems
- `cli-tool` — Command-line tools
- `data-pipeline` — ETL/data processing systems

## What Gets Generated

A complete, runnable Claude Code project including:

- `CLAUDE.md` with full agent instructions
- Agent definitions with scoped permissions
- Hook configurations for security
- `.env.example`, `.gitignore`, `README.md`
- `DECISIONS.md` documenting architectural choices
- Test files for every agent
- Task tracking files

## License

MIT
