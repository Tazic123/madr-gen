#!/bin/bash
# extract-decisions.sh - Extract conversation from Claude Code session JSONL for decision analysis
# Usage: ./extract-decisions.sh <session-file> [max-lines]
#
# Claude Code JSONL structure:
#   .type = "user"|"assistant"|"progress"|"system"|"file-history-snapshot"
#   .message.role = "user"|"assistant"
#   .message.content = string (user) | array of {type,text}/{type,name,input} (assistant)

SESSION_FILE="$1"
MAX_LINES="${2:-500}"

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
  echo "Usage: $0 <session-file> [max-lines]" >&2
  exit 1
fi

if command -v jq &>/dev/null; then
  cat "$SESSION_FILE" | \
    jq -r '
      select(.type == "user" or .type == "assistant") |
      if .type == "user" then
        if (.message.content | type) == "string" then
          if (.message.content | length) > 0 then
            "## User\n" + .message.content + "\n"
          else empty end
        elif (.message.content | type) == "array" then
          ([ .message.content[] | select(.type == "text") | .text ] | join("\n")) as $text |
          if ($text | length) > 0 then "## User\n" + $text + "\n"
          else empty end
        else empty end
      elif .type == "assistant" then
        if (.message.content | type) == "string" then
          if (.message.content | length) > 0 then
            "## Assistant\n" + .message.content + "\n"
          else empty end
        elif (.message.content | type) == "array" then
          ([ .message.content[] | select(.type == "text") | .text ] | join("\n")) as $text |
          if ($text | length) > 0 then "## Assistant\n" + $text + "\n"
          else empty end
        else empty end
      else empty end
    ' 2>/dev/null | head -n "$MAX_LINES"
else
  # Fallback without jq: extract text content via grep
  grep -oP '"content"\s*:\s*"[^"]*"' "$SESSION_FILE" | sed 's/"content"\s*:\s*"//;s/"$//' | head -n "$MAX_LINES"
fi
