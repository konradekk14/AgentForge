---
name: new-project
description: Generate a complete multi-agent Claude Code scaffold for a new project
---

# /new-project

Trigger the full AgentForge pipeline to generate a new multi-agent project scaffold.

## Pipeline

Execute these phases in order. Each phase uses a subagent from `.claude/agents/`.

### Phase 1: Interview
Launch the **interviewer** agent. It asks 7 structured questions and writes `handoffs/brief.md`.

### Phase 2: Research
Launch the **researcher** agent. It analyzes templates and lessons, writes `handoffs/research.md`.

### Phase 3: Architecture
Launch the **architect** agent (uses Opus). It reads the brief and research, designs the agent topology, and writes `handoffs/ARCHITECTURE.md`.

Present the architecture to the user for approval. Do NOT proceed without explicit approval.

### Phase 4: Scaffold
After approval, launch the **scaffolder** agent. It writes the complete project to `output/[project-name]/`.

### Phase 5: Review
Launch the **reviewer** agent. It validates the scaffold for security, quality, and completeness. Writes `handoffs/review.md`.

- If PASS: Report success and show the user what was generated.
- If FAIL: Send failure details back to the scaffolder for remediation (max 3 retries). After 3 failures, escalate to the user.

## Error Handling
- If any phase fails, log the error and surface it to the user
- Never silently skip a phase
- All handoff files must exist before the next phase starts
