# Decisions

Every non-obvious choice in AgentForge v2, documented.

---

## D1: Pure Claude Code Primitives

**Decision**: Use only `.claude/agents/`, `.claude/hooks/`, and `.claude/skills/` — no external servers, no custom Node apps.

**Why**: AgentForge should be a Claude Code project that generates Claude Code projects. Using external infrastructure would contradict the premise. Everything runs through Claude Code's native subagent and hook system.

---

## D2: 5 Agents, Not 6

**Decision**: Dropped the dedicated orchestrator agent. The root CLAUDE.md IS the orchestrator.

**Why**: In v1, `forge-orchestrator` was a separate agent that just routed work. But Claude Code's root CLAUDE.md already serves this role. Having a separate orchestrator agent was redundant — it added a hop without adding capability.

---

## D3: YAML Frontmatter in Agent Files

**Decision**: Agent `.md` files use YAML frontmatter for metadata (name, model, tools, output).

**Why**: Structured metadata makes agents machine-parseable while keeping them human-readable. The frontmatter declares capabilities; the markdown body explains behavior.

---

## D4: Hooks Over Agent-Level Enforcement

**Decision**: Security enforcement via `.claude/hooks/` shell scripts, not per-agent rules.

**Why**: Hooks run automatically on every tool use — they can't be bypassed by a misbehaving agent. Per-agent rules depend on the agent following instructions. Defense in depth: agents have rules AND hooks enforce them.

---

## D5: File-Based Handoffs

**Decision**: All agent communication via files in `handoffs/`.

**Why**: File-based handoffs are inspectable, debuggable, and survive context window resets. They create a natural audit trail. In-memory passing would be faster but opaque.

---

## D6: Human Gate at Architecture Phase

**Decision**: Single mandatory human approval after architecture design, before scaffolding.

**Why**: Interview is low-risk (gathering info). Research is read-only. Architecture is where consequential decisions are made. Scaffolding writes to disk. The gate sits right before the destructive step, after the user can see exactly what will be built.

---

## D7: Templates as Starting Points, Not Rigid Molds

**Decision**: Templates provide base patterns that the architect adapts, not copy-paste scaffolds.

**Why**: Every project is different. Templates give the architect a head start and surface common patterns, but the architect makes the final design decisions based on the specific brief.

---

## D8: Opus for Architecture, Sonnet for Everything Else

**Decision**: Only the architect agent uses Opus. All others use Sonnet.

**Why**: Architecture design requires the deepest reasoning — trade-off analysis, topology decisions, permission modeling. Other agents have focused, well-scoped tasks where Sonnet's speed wins. This balances quality with cost and latency.

---

## D9: Max 3 Retries Then Escalate

**Decision**: Failed review triggers retry (max 3), then escalates to user.

**Why**: 3 attempts handle transient issues and minor corrections. More than 3 suggests a systemic problem. Infinite retries waste compute and hide real issues.

---

## D10: Generated Scaffolds Must Be Immediately Runnable

**Decision**: Every scaffold in `output/` must work in Claude Code with zero manual setup.

**Why**: The whole point of AgentForge is to eliminate setup time. If output needs manual fixes, we've failed. This means complete CLAUDE.md, .env.example, .gitignore, tests, docs — everything.
