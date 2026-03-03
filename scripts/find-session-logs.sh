#!/bin/bash
# find-session-logs.sh - Find Claude Code session JSONL files for the current project
# Usage: ./find-session-logs.sh [project-dir] [max-age-hours]

PROJECT_DIR="${1:-$(pwd)}"
MAX_AGE_HOURS="${2:-24}"

# Encode the project directory path (replace / with -)
# Claude Code stores sessions at ~/.claude/projects/<encoded-cwd>/
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's|^/||' | sed 's|/|-|g')
SESSION_DIR="$HOME/.claude/projects/-${ENCODED_PATH}"

if [ ! -d "$SESSION_DIR" ]; then
  echo "No session directory found at: $SESSION_DIR" >&2
  exit 1
fi

# Find JSONL files, optionally filtered by age
if [ "$MAX_AGE_HOURS" -gt 0 ] 2>/dev/null; then
  find "$SESSION_DIR" -name "*.jsonl" -mmin "-$((MAX_AGE_HOURS * 60))" -type f 2>/dev/null | sort -t/ -k1 -r
else
  find "$SESSION_DIR" -name "*.jsonl" -type f 2>/dev/null | sort -t/ -k1 -r
fi
