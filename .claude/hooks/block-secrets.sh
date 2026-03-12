#!/usr/bin/env bash
# Block secrets hook — scans tool output for credential patterns
# Exits 2 if secrets detected, 0 if clean

set -euo pipefail

INPUT=$(cat)

# Patterns that indicate leaked secrets
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
  'password[[:space:]]*[:=][[:space:]]*[^[:space:]"'"'"'$\{][^[:space:]]{7,}'
  'postgres(ql)?://[^:]+:[^@]+@'
)

for pattern in "${PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qE -- "$pattern"; then
    echo "BLOCKED: Credential pattern detected matching: $pattern" >&2
    echo "Remove all secrets before proceeding. Use environment variables instead." >&2
    exit 2
  fi
done

exit 0
