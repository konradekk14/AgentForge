# AgentForge

A meta-system that generates fully configured multi-agent Claude Code scaffolds for any project.

## What It Does

Describe a project. AgentForge interviews you, designs a multi-agent architecture, gets your approval, then writes a complete ready-to-run scaffold to disk.

## Quick Start

1. Clone this repo
2. Copy `.env.example` to `.env` and fill in your values
3. Open the project in Claude Code
4. Tell Claude: "I want to build [your project description]"
5. Answer the interview questions (6-8 focused questions)
6. Review the proposed architecture
7. Approve, and AgentForge writes your scaffold

## Project Structure

```
AgentForge/
├── CLAUDE.md              # Root orchestrator instructions
├── ARCHITECTURE.md        # System architecture
├── DECISIONS.md           # Design decisions and assumptions
├── agents/                # Agent personas (one CLAUDE.md each)
│   ├── forge-orchestrator/
│   ├── interview-agent/
│   ├── research-agent/
│   ├── architect-agent/
│   ├── scaffolder-agent/
│   └── reviewer-agent/
├── handoffs/              # File-based agent communication
├── tasks/                 # Task tracking and lessons learned
├── logs/                  # Audit logs
└── templates/             # Scaffold templates
```

## How It Works

1. **Interview**: Structured questions extract project type, users, integrations, stack, and destructive operations
2. **Research**: Queries past patterns from claude-mem and lessons learned
3. **Architecture**: Designs agent topology with CAN/CANNOT constraints, handoff protocols, security posture
4. **Human Gate**: You review and approve the architecture before anything is written
5. **Scaffold**: Writes all CLAUDE.md files, directory structure, configs, and docs
6. **Review**: Validates no secrets, no over-permissioned agents, audit hooks present

## Requirements

- Claude Code CLI
- Anthropic API key
- Optional: claude-mem for pattern memory across runs

## Security

- No secrets in any generated file (reviewer hard-fails on API key patterns)
- All credentials via environment variables
- Every agent has explicit CAN/CANNOT permissions
- Human approval required before writing to disk
- Full audit trail in `logs/audit.log`
