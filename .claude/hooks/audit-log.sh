#!/usr/bin/env bash
# Audit log hook — reads JSON from stdin, appends to logs/audit.log
# Always exits 0 (never blocks execution)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_FILE="$REPO_ROOT/logs/audit.log"

mkdir -p "$(dirname "$LOG_FILE")"

INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "unknown")

echo "[$TIMESTAMP] tool=$TOOL input=$(echo "$INPUT" | tr '\n' ' ' | cut -c1-500)" >> "$LOG_FILE"

exit 0
