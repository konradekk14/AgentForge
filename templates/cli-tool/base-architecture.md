# CLI Tool Base Architecture

## Typical Agent Topology

| Agent | Role | Model |
|-------|------|-------|
| orchestrator | Manages CLI flow and delegation | sonnet |
| core | Command implementation and business logic | sonnet |
| reviewer | Quality gate, tests, and validation | sonnet |

## Common Patterns
- Command/subcommand structure
- Argument parsing and validation
- Configuration file support (~/.config or .rc files)
- Stdout/stderr separation
- Exit codes for scripting

## Destructive Operations
- File system writes/deletions
- Overwriting existing configs
- Network requests with side effects

## Typical File Structure
```
project/
├── CLAUDE.md
├── .claude/agents/
├── src/
│   ├── cli.ts (or main entry)
│   ├── commands/
│   └── utils/
├── tests/
├── bin/
├── .env.example
└── README.md
```

## Security Considerations
- Sanitize all user input from arguments
- Don't execute user-provided strings as commands
- Config files should not contain secrets
- Respect file permissions
