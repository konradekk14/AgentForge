#!/usr/bin/env bash
# Require tests hook — checks that generated scaffolds include test files
# Exits 2 if no tests found in output directory, 0 if tests present

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT_DIR="$REPO_ROOT/output"

# Only check if output directory has content (skip if empty/nonexistent)
if [ ! -d "$OUTPUT_DIR" ] || [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null | grep -v .gitkeep)" ]; then
  exit 0
fi

# Look for test files in the generated scaffold
TEST_FILES=$(find "$OUTPUT_DIR" -type f \( \
  -name "*test*" -o \
  -name "*spec*" -o \
  -name "*.test.*" -o \
  -name "*.spec.*" -o \
  -path "*/tests/*" -o \
  -path "*/__tests__/*" -o \
  -path "*/test/*" \
\) 2>/dev/null | head -1)

if [ -z "$TEST_FILES" ]; then
  echo "BLOCKED: No test files found in output/. Every scaffold must include tests." >&2
  echo "Add test files before completing the scaffold." >&2
  exit 2
fi

exit 0
