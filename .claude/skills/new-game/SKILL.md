---
name: new-game
description: Generate a complete multi-agent Claude Code scaffold for a new Godot 4 game project
---

# /new-game

Trigger the full AgentForge pipeline to scaffold a Godot 4 game project. Optimized for game projects: supports PRD document input, uses the Godot 4 architecture template, and sequences agents in game-appropriate build order (simulation → core systems → content → UI/UX → testing → infra).

AgentForge's job is to **design and scaffold** — not to build. When it's done, you open the generated project in a new Claude Code session and work with the generated agents there.

## Pipeline

Execute these phases in order. Each phase uses a subagent from `.claude/agents/`.

### Phase 0: Setup

1. Ask the user: "Do you have a PRD or design document for this game? If yes, provide the absolute file path."
2. If the user provides a file path: write `handoffs/prd-source.md` with this exact content:
   ```
   PRD_FILE=/absolute/path/from/user
   ```
3. Clean `handoffs/` by deleting all other files (keep `prd-source.md` if just written, truncate `logs/audit.log`).
   **Do NOT delete `handoffs/prd-source.md`.**
4. If no PRD provided: clean `handoffs/` fully and proceed to Phase 1 (standard Q&A interview).

### Phase 1: Interview
Launch the **interviewer** agent with this instruction: "This is a Godot 4 game project. In the Overview section of brief.md, set `**Type**: godot-game` exactly — downstream agents depend on this exact string for project type detection." Before dispatching, it will automatically check for `handoffs/prd-source.md`. If present, it reads the PRD document directly and extracts all requirements — only asking questions for genuine gaps (batched in a single message). If absent, it conducts a standard Q&A interview (minimum 7 questions). Writes `handoffs/brief.md`.

### Phase 2: Research
Launch the **researcher** agent with this instruction: "This is a Godot 4 game project. Load `templates/godot-game/base-architecture.md` as your primary template reference before searching externally. Research current stable Godot 4.x version, current GUT testing framework version, and any relevant GDScript 2.0 patterns for the project's domain." Writes `handoffs/research.md`.

### Phase 3: Architecture
Launch the **architect** agent (uses Opus) with this instruction: "This is a Godot 4 game project. Apply the agent topology and build order from `templates/godot-game/base-architecture.md`. The build order is: simulation → core-systems → content → ui-ux → testing → infra → reviewer. Document scene and resource class dependencies explicitly — the content agent cannot create .tres data files before core-systems has defined their Resource class schemas." Writes `handoffs/ARCHITECTURE.md`.

Present the architecture to the user for approval. Do NOT proceed without explicit approval.

### Phase 4: Scaffold
After approval, launch the **scaffolder** agent. It writes to `output/[project-name]/`:
- Agent definition files with full PRD context baked in
- Project structure stubs (not implementation code)
- Infrastructure files (Makefile with Godot-specific targets)
- Test structure stubs and USER_TESTING.md
- Copies of brief.md and ARCHITECTURE.md so agents have full context
- All agents include GSD working style and memory practices
- README includes claude-mem setup instructions

### Phase 5: Review
Launch the **reviewer** agent. It validates PRD fidelity, security, infrastructure, and testing completeness. Writes `handoffs/review.md`.

- If **PASS**: AgentForge is done. Tell the user:
  > "Your project is ready at `output/[project-name]/`. Open that directory in a **new Claude Code session** — your agents have the full context and are ready to build. Run `make setup` first."
  Show the generated agent list. **Stop here — do not start building.**
- If **FAIL**: Send failure details back to the scaffolder for remediation (max 3 retries). After 3 failures, output the Escalation Protocol message defined in `CLAUDE.md ## Escalation Protocol` and stop. Do not retry without explicit user instruction.

## Boundary

AgentForge stops after Phase 5 PASS. It does not implement the project. The generated agents do that, in their own Claude Code session.

## Error Handling
- If any phase fails, log the error and surface it to the user
- Never silently skip a phase
- All handoff files must exist before the next phase starts
