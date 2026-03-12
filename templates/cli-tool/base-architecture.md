# CLI Tool Base Architecture

## Agent Topology

| Agent | Role | Model | Tools |
|-------|------|-------|-------|
| orchestrator | Routes work, manages phases, never writes app code | sonnet | Read |
| builder | Command implementation, argument parsing, business logic | sonnet | Read, Write, Bash |
| reviewer | Quality gate — read-only, validates correctness and UX | sonnet | Read, Glob, Grep, Bash |

Note: CLI tools are simple-topology projects (3 agents). Add `infra` and `testing` agents only if the CLI has: a release pipeline, external service dependencies, or complex integration requirements.

## Command Structure Pattern

```
mycli [global-flags] <command> [command-flags] [args]

Commands:
  init        Initialize configuration
  run         Execute main operation
  status      Show current state
  config      Manage configuration

Global flags:
  --verbose   Enable debug output
  --json      Output as JSON (for scripting)
  --config    Path to config file (default: ~/.mycli/config.json)
```

## Argument Parsing

Use a proper parser (commander.js, yargs, argparse, cobra, click):
- Validate required args before running
- Show help on missing required args
- Return exit code 1 for user errors, 2 for internal errors
- Exit code 0 means success always

## Configuration Pattern

Priority order (highest to lowest):
1. Command-line flags
2. Environment variables (`MYCLI_*`)
3. Project-level config (`.myclirc` or `mycli.config.json`)
4. User-level config (`~/.config/mycli/config.json`)
5. Built-in defaults

Never store secrets in config files. Use env vars or system keychain.

## Output Pattern

- `stdout`: machine-readable output (data, results)
- `stderr`: human-readable status messages, progress, errors
- Support `--json` flag for structured output on stdout
- Show progress indicators for long-running operations
- Respect `NO_COLOR` and `TERM=dumb` environment variables

## Error Handling Pattern

```
User error (bad args, missing file):
  → clear message to stderr, suggest fix, exit 1

Internal error (unexpected failure):
  → "Error: [what failed]. Run with --verbose for details." to stderr
  → stack trace only with --verbose
  → exit 2

Network/external error:
  → retry with backoff (max 3 attempts)
  → clear message if still failing
  → exit 1
```

## Logging Pattern

No structured logger needed for simple CLIs. Rules:
- Use `--verbose` flag to gate debug output
- Debug messages → stderr only
- Progress messages → stderr only
- Data output → stdout only
- Never mix data and progress on stdout

For complex CLIs with audit needs, use a file logger (`~/.mycli/logs/`).

## Testing Pattern

```
tests/
  unit/          ← test each command handler in isolation, mock I/O
  integration/   ← spawn actual CLI binary, assert stdout/stderr/exit code
  fixtures/      ← sample input files, config files
USER_TESTING.md  ← manual walkthrough of all commands
```

Unit tests: mock filesystem, network, stdin
Integration tests: use a temp directory, real CLI invocations

## CI/CD Pattern (if release pipeline needed)

```yaml
on: [pull_request]
jobs:
  test: install → lint → unit tests → integration tests

on: push to main with version tag
jobs:
  release: build binaries → publish to npm/PyPI/GitHub Releases
```

## Security Pattern

- Never execute user-provided strings as shell commands (no `exec(userInput)`)
- Sanitize file paths (prevent directory traversal)
- Config files must not contain secrets
- Validate all file paths before operating on them
- Respect file permissions — don't create files as root

## Destructive Operations (require `--force` flag + confirmation prompt)

- Overwriting existing files
- Deleting user data
- Resetting configuration to defaults
- Any network call with side effects

Always: print what will happen, ask "Are you sure? [y/N]", default to No.

## File Structure

```
project/
├── CLAUDE.md                    ← orchestrator
├── .claude/
│   ├── settings.json
│   └── agents/
│       ├── builder.md
│       └── reviewer.md
├── src/
│   ├── cli.ts                   ← entry point, argument parsing
│   ├── commands/
│   │   ├── init.ts
│   │   ├── run.ts
│   │   └── config.ts
│   └── utils/
│       ├── output.ts            ← stdout/stderr helpers
│       └── config.ts           ← config loading
├── bin/
│   └── mycli                   ← executable entry point
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── USER_TESTING.md
├── tasks/
├── .env.example
├── .gitignore
└── README.md
```

## Environment Variables

```
# Optional overrides
MYCLI_CONFIG_PATH=
MYCLI_LOG_LEVEL=
MYCLI_[SERVICE]_API_KEY=
```
