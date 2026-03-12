# Lessons Learned

Patterns, mistakes, and insights captured during AgentForge runs.

---

## Format

### [DATE] - [Short title]
- **Context**: What was happening
- **Issue**: What went wrong or what was learned
- **Resolution**: How it was fixed
- **Rule**: Preventive rule for future runs

---

<!-- Entries below this line -->

### 2026-03-11 — Scaffolder generated implementation code instead of stubs

- **Context**: Running /new-project for PolishPal (Polish language learning app, Node/Express/SQLite)
- **Issue**: Scaffolder wrote a complete working server.js, API routes, DB models, and frontend — full implementation instead of agent stubs. The generated project had node_modules, working migrations, and actual business logic. This is the opposite of what AgentForge should produce.
- **Root cause**: Old scaffolder.md lacked a clear "stubs only" boundary. The prompt said "write every file needed to run the project" which Claude interpreted as: write the actual project.
- **Resolution**: Scaffolder now has explicit YOU GENERATE / YOU DO NOT GENERATE split at the top. "Stubs and TODOs only in src/" is a hard rule. Implementation is the job of the generated agents, not AgentForge.
- **Rule**: If scaffolder output contains working business logic, routes, or DB queries — it has overstepped. Stubs only. The generated agents build the project.
