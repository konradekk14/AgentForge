# Fix: Medium Issues + Bloat (AgentForge)

Self-contained execution plan. All changes are in-place edits to existing files — no new files needed.

---

## Checklist

- [x] 1. block-secrets.sh — tighten patterns
- [x] 2. CLAUDE.md — add handoff validation rule
- [x] 3. CLAUDE.md — merge Quality Contract + Security into one section
- [x] 4. scaffolder.md — partial failure reporting in retry mode
- [x] 5. scaffolder.md — collision detection before output directory creation
- [x] 6. scaffolder.md — fix YAML tools placeholder syntax
- [x] 7. reviewer.md — add YAML frontmatter array check to Structure Check

---

## 1. block-secrets.sh — tighten patterns

**File:** `.claude/hooks/block-secrets.sh`

Replace the entire `PATTERNS=(...)` array (currently lines 10–20):

**Old:**
```bash
PATTERNS=(
  'sk-ant-[a-zA-Z0-9]'
  'sk-[a-zA-Z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'ghp_[a-zA-Z0-9]{36}'
  'glpat-[a-zA-Z0-9\-]{20}'
  'xoxb-[0-9]'
  'xoxp-[0-9]'
  '-----BEGIN (RSA |EC )?PRIVATE KEY-----'
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
)
```

**New:**
```bash
PATTERNS=(
  'sk-ant-[a-zA-Z0-9\-]{95,}'
  'sk-[a-zA-Z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'ghp_[a-zA-Z0-9]{36}'
  'glpat-[a-zA-Z0-9\-]{20}'
  'xoxb-[0-9]+-[0-9]+-[a-zA-Z0-9]+'
  'xoxp-[0-9]+-[0-9]+-[0-9]+-[a-zA-Z0-9]+'
  '-----BEGIN (RSA |EC )?PRIVATE KEY-----'
  'password\s*[:=]\s*["\x27][^"\x27]{8,}'
  "password\\s*[:=]\\s*[^\\s\"'\\$\\{][^\\s]{7,}"
  'postgres(ql)?://[^:]+:[^@]+@'
)
```

**Why each change:**
- `sk-ant-`: now requires 95+ chars (real Anthropic keys are ~100 chars; old pattern matched 9 chars)
- Slack `xoxb-`/`xoxp-`: now match full token structure instead of single digit
- New unquoted password pattern (double-quoted entry to allow backslash escaping)
- New postgres connection string pattern

---

## 2. CLAUDE.md — handoff validation rule

**File:** `CLAUDE.md`

In `## Orchestrator Rules`, after the line:
```
- If a handoff file is missing, STOP and investigate.
```

Insert:
```
- Before dispatching each phase, read the required handoff file and verify it contains no `[placeholder]` or `TBD` text in key sections. If found: re-dispatch the previous phase with the instruction "Handoff file [filename] contains unfilled placeholders — regenerate it completely." If re-dispatch has already been attempted once for this phase, report to the user and stop.
```

---

## 3. CLAUDE.md — merge Quality Contract + Security

**File:** `CLAUDE.md`

Replace both sections:
```
## Quality Contract

1. No secrets in any generated file (enforced by hooks)
2. Every agent has CAN/CANNOT constraints
3. Tests exist in every generated scaffold
4. Architecture decisions documented before code is written
5. Human gate before any destructive operation

## Security (Non-Negotiable)

- No API keys, tokens, or credentials in any file — ever
- All secrets via environment variables
- Hooks enforce this automatically (`.claude/hooks/block-secrets.sh`)
- Audit log for every tool use (`.claude/hooks/audit-log.sh`)
- Reviewer hard-fails on any credential pattern
```

With:
```
## Quality & Security Contract

1. No secrets, API keys, tokens, or credentials in any generated file — ever. All secrets via environment variables. Enforced by `.claude/hooks/block-secrets.sh`. Reviewer hard-fails on any credential pattern.
2. Every agent has CAN/CANNOT constraints
3. Tests exist in every generated scaffold
4. Architecture decisions documented before code is written
5. Human gate before any destructive operation
6. Audit log for every tool use (`.claude/hooks/audit-log.sh`)
```

---

## 4. scaffolder.md — partial failure reporting

**File:** `.claude/agents/scaffolder.md`

In the retry mode block (step 0), replace:
```
   - Do NOT re-run the full scaffold. Only touch files named in the Remediation List.
   - Done when all items are addressed.
```

With:
```
   - Do NOT re-run the full scaffold. Only touch files named in the Remediation List.
   - When all items have been attempted: if any item could not be addressed (file not found, ambiguous instruction, unexpected state), write `handoffs/scaffold-error.md` listing each unresolved item and the specific reason it was skipped. Continue with all other items regardless — do not abort the full run. The reviewer's next run will surface remaining unresolved items.
```

---

## 5. scaffolder.md — collision detection

**File:** `.claude/agents/scaffolder.md`

In `## Process`, between step 2 and step 3, insert:

```
2b. Check whether `output/[project-name]/` already exists (`test -d output/[project-name]`). If it exists: write to `handoffs/scaffold-error.md`:
    "Directory output/[project-name]/ already exists. Delete it first or rename the project in handoffs/brief.md."
    Then stop. Do not overwrite.
```

---

## 6. scaffolder.md — YAML tools placeholder

**File:** `.claude/agents/scaffolder.md`

In the `## Agent File Format` block, change:
```
tools: [list]
```

To:
```
tools: [Read, Write]  # replace with actual tools from ARCHITECTURE.md — must be a YAML array
```

---

## 7. reviewer.md — YAML frontmatter check

**File:** `.claude/agents/reviewer.md`

In `### 6. Structure Check`, under the **Hard fail** list, add after the existing 3 bullets:
```
- Each `.claude/agents/*.md` has a valid YAML frontmatter `tools:` value that is a YAML array (value starts with `[`). A comma-separated string like `tools: Read, Write, Bash` is invalid — FAIL with file citation. Tag as `[TOPOLOGY]` in Remediation List.
```

---

## Verification

After all edits:

```bash
# Should exit 2 (blocked)
echo 'password: hardcodedvalue' | bash .claude/hooks/block-secrets.sh

# Should exit 2 (blocked)
echo 'postgres://user:pass@localhost/db' | bash .claude/hooks/block-secrets.sh

# Should exit 0 (clean)
echo 'password: ${DB_PASS}' | bash .claude/hooks/block-secrets.sh

# Should exit 0 (clean — no real secret)
echo 'password: ' | bash .claude/hooks/block-secrets.sh
```

Read each modified file to confirm edits landed in the right place.

---

## Intentionally skipped

- **Template tree+prose redundancy** — templates are reference docs for the researcher; both formats add value
- **Hooks documented in 4 places** — each location serves a distinct purpose (config, inline comments, high-level ref, execution order)
