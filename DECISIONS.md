# Decisions and Assumptions

Every non-obvious choice made during AgentForge's design, documented here.

---

## D1: File-Based Handoffs Over In-Memory

**Decision**: All agent communication happens via files in `handoffs/`, never in-memory.

**Reasoning**: File-based handoffs are inspectable, debuggable, and survive context window resets. They create a natural audit trail and allow humans to review intermediate artifacts. In-memory passing would be faster but opaque.

**Trade-off**: Slightly slower (disk I/O) but dramatically more transparent and debuggable.

---

## D2: Six Agents, Not Fewer

**Decision**: Six specialized agents rather than collapsing roles.

**Reasoning**: Each agent has a clearly bounded responsibility with explicit CAN/CANNOT constraints. Merging agents (e.g., research + architect) would blur permission boundaries and make the reviewer's job harder. The orchestrator stays lean by delegating everything.

**Trade-off**: More CLAUDE.md files to maintain, but cleaner separation of concerns.

---

## D3: Human Gate at Architecture, Not Earlier

**Decision**: The single human approval gate is after architecture design, before scaffolding.

**Reasoning**: The interview is low-risk (just gathering info). Research is read-only. Architecture is where consequential decisions happen. Scaffolding writes to disk — that's the destructive operation. So the gate sits right before the destructive step, after the human can see exactly what will be built.

**Trade-off**: No human approval on interview questions (assumed low-risk).

---

## D4: Reviewer Runs After Every Handoff

**Decision**: The reviewer validates every agent's output, not just the final scaffold.

**Reasoning**: Catching issues early is cheaper than catching them late. A bad brief leads to a bad architecture leads to a bad scaffold. The reviewer acts as a quality gate at every stage.

**Trade-off**: Adds latency to each stage but prevents error cascading.

---

## D5: Max 3 Retries Before Human Escalation

**Decision**: Agents get 3 attempts to pass review, then the orchestrator escalates to the human.

**Reasoning**: 3 is enough to handle transient issues and minor corrections. More than 3 suggests a systemic problem that the agent can't self-correct. At that point, human judgment is needed.

**Trade-off**: Could be too conservative for some failures, but errs on the side of human involvement.

---

## D6: Orchestrator Cannot Write Files or Make Decisions

**Decision**: The forge-orchestrator routes work but never does domain work itself.

**Reasoning**: GSD lean orchestrator pattern — keeps the orchestrator's context window clean (target: <=15% budget). If the orchestrator starts doing work, it becomes a bottleneck and its context fills up. Delegation is the whole point.

**Trade-off**: Requires more agent hops for simple tasks.

---

## D7: Scaffold Output is a Complete, Runnable Project

**Decision**: Every generated scaffold must be immediately usable in Claude Code with zero manual setup.

**Reasoning**: The whole point of AgentForge is to eliminate scaffold setup time. If the output needs manual fixes, we've failed. This means: all CLAUDE.md files, .env.example, .gitignore, tasks/, logs/, DECISIONS.md, ARCHITECTURE.md — everything.

**Trade-off**: Scaffolder is more complex, but the output is more valuable.

---

## D8: Audit Log for Every Agent Action

**Decision**: Every agent action is logged with a timestamp to `logs/audit.log`.

**Reasoning**: Debugging multi-agent systems is hard without observability. The audit log creates a timeline of what happened, when, and which agent did it. Essential for post-mortem analysis.

**Trade-off**: Log file grows with usage; needs rotation strategy eventually.

---

## D9: Templates Directory Reserved for Future Use

**Decision**: `templates/` exists but is empty (just .gitkeep).

**Reasoning**: As AgentForge generates more scaffolds, common patterns will emerge. The templates directory is reserved for extracting these patterns into reusable templates. Not implemented yet because we need real data first.

**Trade-off**: Empty directory now, but avoids a structural change later.

---

## D10: No External Dependencies

**Decision**: AgentForge is a pure scaffold — no npm packages, no build tools, no runtime dependencies.

**Reasoning**: This is a Claude Code project driven entirely by CLAUDE.md instructions and file-based workflows. Adding dependencies would mean package management, version pinning, and a build step — none of which serve the core purpose. If we need tooling later (e.g., for template rendering), we'll add it then.

**Trade-off**: No programmatic template engine; scaffolder writes files directly.

---

## D11: Research and Architect Run in Parallel

**Decision**: research-agent and architect-agent can run concurrently (via Ruflo).

**Reasoning**: Research doesn't depend on architecture, and the architect consumes research output. By running them in parallel, we cut wall-clock time. The architect waits for research.md before finalizing, but can start preliminary work.

**Trade-off**: Architect may need to re-evaluate if research surfaces unexpected patterns.

---

## D12: Security Rules Apply Recursively

**Decision**: Security rules apply to AgentForge itself AND every scaffold it generates.

**Reasoning**: AgentForge should exemplify what it produces. If we don't follow our own security rules, generated scaffolds won't either. This is a credibility and correctness issue.

**Trade-off**: More validation work, but ensures consistency.
