# AgentForge Architecture

## System Overview

AgentForge is a multi-agent system built on Claude Code. It generates fully configured agent scaffolds for new projects. The system uses 6 specialized agents coordinated by a lean orchestrator, with file-based handoffs and a human approval gate.

## Agent Topology

### forge-orchestrator
- **Role**: Routes and sequences all work. Never does domain work itself.
- **Context Budget**: <=15% (GSD lean orchestrator pattern)
- **Responsibilities**:
  - Sequence agent execution
  - Write timestamped audit log of every action to `logs/audit.log`
  - Own `tasks/todo.md` and `tasks/lessons.md`
  - Manage the human gate (architecture approval)
  - On 3rd agent failure: surface exactly what failed, ask human
- **CAN**: Route work, read handoff files, write audit logs, update task files
- **CANNOT**: Write project files to disk, execute code, make architecture decisions

### interview-agent
- **Role**: Structured project requirements gathering
- **Responsibilities**:
  - Ask 6-8 focused questions covering: project type, primary users, key integrations, destructive operations, stack preferences
  - Output structured `handoffs/brief.md`
- **CAN**: Ask questions, write `handoffs/brief.md`
- **CANNOT**: Make architecture decisions, access past project memory, write any file except brief.md

### research-agent
- **Role**: Pattern discovery from past projects
- **Responsibilities**:
  - Query claude-mem for patterns from past AgentForge-generated projects
  - Surface relevant lessons from `tasks/lessons.md`
  - Output `handoffs/research.md` summarizing applicable patterns
- **CAN**: Read `tasks/lessons.md`, query claude-mem, write `handoffs/research.md`
- **CANNOT**: Modify any existing files, make architecture decisions, write any file except research.md

### architect-agent
- **Role**: Design the full agent topology for the target project
- **Responsibilities**:
  - Consume `handoffs/brief.md` and `handoffs/research.md`
  - Design complete agent topology with personas and CAN/CANNOT constraints
  - Define handoff protocol between every agent pair
  - Specify directory structure, security posture
  - Document reasoning for every major decision
  - Output `handoffs/ARCHITECTURE.md`
- **CAN**: Read brief.md and research.md, write `handoffs/ARCHITECTURE.md`
- **CANNOT**: Write scaffold files, execute anything, write any file except ARCHITECTURE.md

### scaffolder-agent
- **Role**: Write the scaffold to disk
- **Trigger**: Runs ONLY after human approves `handoffs/ARCHITECTURE.md`
- **Responsibilities**:
  - Write all CLAUDE.md files, agent personas, directory structure
  - Write .env.example, tasks/todo.md, tasks/lessons.md, DECISIONS.md
  - Write logs/.gitkeep and any other structural files
  - Commit each logical unit atomically
- **CAN**: Create directories, write files in the target project directory, create git commits
- **CANNOT**: Write outside the target project directory, modify existing files not in scope, run without human approval

### reviewer-agent
- **Role**: Quality and security validation at every handoff
- **Trigger**: Runs after every agent handoff, not just at the end
- **Responsibilities**:
  - Check: no security issues, no hardcoded secrets, no over-permissioned agents, audit hooks present
  - On failure: return work to originating agent with specific failure reason
  - Do NOT pass failed work forward
  - Agents get 3 attempts before escalation
- **CAN**: Read any handoff file, write `handoffs/security.md`, flag failures
- **CANNOT**: Fix issues itself, approve its own output, write any file except security.md

## Execution Flow

```
User describes project
       |
       v
[interview-agent] --> handoffs/brief.md
       |
       v
[reviewer-agent validates brief.md]
       |
       v
[research-agent]  ──parallel──> handoffs/research.md
[architect-agent] ──parallel──> (waits for research.md) --> handoffs/ARCHITECTURE.md
       |
       v
[reviewer-agent validates ARCHITECTURE.md]
       |
       v
=== HUMAN GATE: User approves architecture ===
       |
       v
[scaffolder-agent] --> writes scaffold to target directory
       |
       v
[reviewer-agent validates scaffold]
       |
       v
Done. Scaffold ready to use.
```

## Handoff Protocol

All communication is file-based in `handoffs/`. Never in-memory.

| Source | Output File | Consumer |
|--------|------------|----------|
| interview-agent | `handoffs/brief.md` | orchestrator, architect-agent |
| research-agent | `handoffs/research.md` | architect-agent |
| architect-agent | `handoffs/ARCHITECTURE.md` | human (approval), scaffolder-agent |
| scaffolder-agent | `[target-dir]/` | reviewer-agent |
| reviewer-agent | `handoffs/security.md` | orchestrator, human |

## Self-Healing Loop

```
Agent produces output
  -> reviewer-agent checks it
  -> PASS: forward to next stage
  -> FAIL: return to originating agent with specific failure reason
     -> Agent retries (attempt logged to tasks/lessons.md)
     -> Max 3 attempts per stage
     -> 3rd failure: orchestrator surfaces what failed, asks human how to proceed
```

## Security Posture

### Rules (apply to AgentForge AND every scaffold it generates)
1. No secrets or API keys ever in any file
2. All credentials via environment variables only (`.env.example` provided, `.env` in `.gitignore`)
3. Every agent CLAUDE.md explicitly lists CAN and CANNOT
4. Audit log written for every agent action with timestamp
5. Human gate required before any destructive operation (write to disk, deploy, push)
6. Reviewer hard-fails on any API key pattern found in generated files

### Validation Checks (reviewer-agent)
- Regex scan for API key patterns (`sk-`, `key-`, `token=`, etc.)
- Verify every agent has CAN/CANNOT sections
- Verify .gitignore excludes .env
- Verify no agent has permissions beyond its stated scope
- Verify audit hooks are present in orchestrator

## Quality Contract (Non-Negotiable)

1. Tests must pass before any handoff
2. No known security issues before any handoff
3. Architecture decisions documented before any code is written

## Tool Integration

| Tool | Purpose |
|------|---------|
| GSD | Wave sequencing, fresh subagent contexts per phase, atomic commits |
| Ruflo | Parallel execution (research + architect), model routing (cheap for templates, Sonnet for architecture, Opus for complex topology) |
| claude-mem | Research agent queries it; reviewer writes security findings back; lessons.md updated after every run |

## Directory Structure

```
AgentForge/
├── CLAUDE.md                    # Root orchestrator instructions
├── ARCHITECTURE.md              # This file
├── DECISIONS.md                 # Design decisions and assumptions
├── README.md                    # How to run AgentForge
├── .env.example                 # Required env vars (no values)
├── .gitignore                   # .env, logs/, node_modules/, .planning/
├── agents/
│   ├── forge-orchestrator/CLAUDE.md
│   ├── interview-agent/CLAUDE.md
│   ├── research-agent/CLAUDE.md
│   ├── architect-agent/CLAUDE.md
│   ├── scaffolder-agent/CLAUDE.md
│   └── reviewer-agent/CLAUDE.md
├── handoffs/                    # File-based handoff artifacts
├── tasks/
│   ├── todo.md                  # Current work items
│   └── lessons.md               # Patterns and lessons learned
├── logs/                        # Audit logs (gitignored)
└── templates/                   # Scaffold templates (future)
```
