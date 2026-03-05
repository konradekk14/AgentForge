# AgentForge Tasks

## Phase 1: Core Pipeline
- [ ] Implement interview-agent conversation flow (6-8 questions, structured brief.md output)
- [ ] Implement research-agent claude-mem query integration
- [ ] Implement architect-agent topology design logic
- [ ] Build forge-orchestrator routing and sequencing
- [ ] Implement scaffolder-agent file generation from ARCHITECTURE.md
- [ ] Implement reviewer-agent validation checks (secrets, permissions, tests)
- [ ] Wire up file-based handoff protocol between all agents

## Phase 2: Quality & Security
- [ ] Add audit logging to forge-orchestrator (timestamped, every action)
- [ ] Implement self-healing loop (retry up to 3, then escalate)
- [ ] Add API key pattern detection to reviewer-agent
- [ ] Implement human gate for architecture approval
- [ ] Add CAN/CANNOT enforcement validation

## Phase 3: Integration
- [ ] GSD wave sequencing integration
- [ ] Ruflo parallel execution (research + architect)
- [ ] claude-mem read/write integration
- [ ] Template system for common scaffold patterns

## Phase 4: Polish
- [ ] End-to-end test: describe a project, get a working scaffold
- [ ] Error messages and failure reporting
- [ ] Documentation review and update
- [ ] Lessons.md auto-update after each run

---

## Completed
<!-- Move items here when done -->
