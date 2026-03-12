---
name: new-project
description: Generate a complete multi-agent Claude Code scaffold for a new project
---

# /new-project

Trigger the full AgentForge pipeline to generate a new multi-agent project scaffold.

AgentForge's job is to **design and scaffold** — not to build. When it's done, you open the generated project in a new Claude Code session and work with the generated agents there.

## Pipeline

Execute these phases in order. Each phase uses a subagent from `.claude/agents/`.

### Phase 1: Interview
Launch the **interviewer** agent. It conducts a PRD-driven interview (minimum 7 questions, no ceiling) covering all requirements including UI/UX preferences and any specific skills or workflows requested. Writes `handoffs/brief.md`.

### Phase 2: Research
Launch the **researcher** agent. It analyzes templates, lessons, and external sources (best practices, library versions, CVEs) for the proposed stack. Writes `handoffs/research.md`.

### Phase 3: Architecture
Launch the **architect** agent (uses Opus). It reads the brief and research, designs the full agent topology using domain rules, and writes `handoffs/ARCHITECTURE.md`.

Present the architecture to the user for approval. Do NOT proceed without explicit approval.

### Phase 4: Scaffold
After approval, launch the **scaffolder** agent. It writes to `output/[project-name]/`:
- Agent definition files with full PRD context baked in
- Project structure stubs (not implementation code)
- Infrastructure files (Dockerfile, CI, Makefile with `make setup`)
- Test structure stubs and USER_TESTING.md
- Copies of brief.md and ARCHITECTURE.md so agents have full context
- Frontend agents include ui-ux-pro-max skill reference
- All agents include GSD working style and memory practices
- README includes claude-mem setup instructions

### Phase 5: Review
Launch the **reviewer** agent. It validates PRD fidelity, security, infrastructure, and testing completeness. Writes `handoffs/review.md`.

- If **PASS**: AgentForge is done. Tell the user:
  > "✓ Your project is ready at `output/[project-name]/`. Open that directory in a **new Claude Code session** — your agents have the full context and are ready to build. Run `make setup` first."
  Show the generated agent list. **Stop here — do not start building.**
- If **FAIL**: Send failure details back to the scaffolder for remediation (max 3 retries). After 3 failures, output the Escalation Protocol message defined in `CLAUDE.md ## Escalation Protocol` and stop. Do not retry without explicit user instruction.

## Boundary

AgentForge stops after Phase 5 PASS. It does not implement the project. The generated agents do that, in their own Claude Code session.

## Error Handling
- If any phase fails, log the error and surface it to the user
- Never silently skip a phase
- All handoff files must exist before the next phase starts
