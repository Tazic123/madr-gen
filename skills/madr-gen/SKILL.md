---
description: Analyze current session for architectural decisions and generate/update mADR documents
triggers:
  - "madr"
  - "architecture decision"
  - "decision record"
  - "document decisions"
  - "adr"
allowed-tools: Bash(git *), Bash(ls *), Bash(find *), Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
---

# mADR Generator Skill

Generate and update Markdown Architecture Decision Records (mADR) by analyzing the current Claude Code session.

## Overview

This skill implements a 3-phase pipeline:
1. **Phase 1 - Detection** (Parallel): Analyze session context to detect architectural decisions
2. **Phase 2 - Validation** (Sequential): Check proposals against existing ADRs
3. **Phase 3 - Execution** (Interactive): Present options and write selected ADRs

## Step-by-Step Workflow

### Step 0: Initialize

Ensure the `docs/decisions/` directory exists in the project root. If not, create it.

```
mkdir -p docs/decisions
```

Check for existing ADRs:
```
ls docs/decisions/*.md 2>/dev/null
```

### Step 1: Gather Session Context

Collect information from multiple sources in parallel:

#### 1a. Git Changes (run in parallel)
```bash
git diff --stat
git log --oneline -20
```

#### 1b. Existing ADRs (run in parallel)
```bash
ls docs/decisions/*.md 2>/dev/null
```
Read each existing ADR to understand what's already documented.

#### 1c. Session JSONL Logs (run in parallel)
Claude Code stores session histories as JSONL at `~/.claude/projects/<encoded-cwd>/`.

```bash
# Encode current directory path
PROJECT_DIR=$(pwd)
ENCODED=$(echo "$PROJECT_DIR" | sed 's|^/||' | sed 's|/|-|g')
SESSION_DIR="$HOME/.claude/projects/-${ENCODED}"

# Find recent session files (last 24h)
find "$SESSION_DIR" -name "*.jsonl" -mmin -1440 -type f 2>/dev/null | sort -r | head -5
```

For each session file, extract the user/assistant conversation text.
Use the helper script (handles edge cases, empty filtering, jq fallback):

```bash
bash scripts/extract-decisions.sh <session-file> 500
```

Or inline with jq (note: `.type` is `"user"`/`"assistant"`, user content is a string, assistant content is an array):
```bash
cat <session-file> | jq -r '
  select(.type == "user" or .type == "assistant") |
  if .type == "user" then
    if (.message.content | type) == "string" then
      if (.message.content | length) > 0 then "## User\n" + .message.content + "\n" else empty end
    else empty end
  elif .type == "assistant" then
    ([ .message.content[] | select(.type == "text") | .text ] | join("\n")) as $text |
    if ($text | length) > 0 then "## Assistant\n" + $text + "\n" else empty end
  else empty end
' 2>/dev/null | head -500
```

**Processing strategy:**
- 1-3 JSONL files: Read each directly
- 4+ files: Focus on the most recent file only
- If `jq` unavailable: script falls back to grep-based extraction

#### 1d. Config (run in parallel)
```bash
cat .madr-gen.json 2>/dev/null  # Check for project-level config overrides
```

### Step 2: Phase 1 - Decision Detection (Parallel)

Launch the `decision-detector` agent with all gathered context:

```
Agent(
  subagent_type="decision-detector",
  model="sonnet",
  prompt="Analyze the current session to detect architectural decisions.

  Session conversation (from JSONL):
  {extracted_conversation}

  Git changes summary: {git_diff_stat}
  Recent commits: {git_log}

  Existing ADR titles: {existing_adr_list}

  Return decisions as a JSON array following the output format in your instructions.
  Only include decisions with medium or high confidence."
)
```

The agent will return a JSON array of detected decisions with:
- Title, category, context, drivers
- Considered options and chosen option
- Rationale and consequences
- Confidence level

### Step 3: Phase 2 - Duplicate Validation (Sequential)

Launch the `duplicate-checker` agent with the detected decisions and existing ADR list:

```
Agent(
  subagent_type="duplicate-checker",
  model="haiku",
  prompt="Check these proposed decisions against existing ADRs in docs/decisions/.

  Proposed decisions: {decisions_json}
  Existing ADR files: {existing_files_list}

  Classify each as new/update/supersede/duplicate."
)
```

### Step 4: Present Suggestions to User

After filtering out duplicates, present the remaining suggestions to the user using `AskUserQuestion`.

Format the suggestions as a numbered list with:
- Decision title
- Category badge
- Action type (NEW / UPDATE / SUPERSEDE)
- Brief context (1-2 sentences)
- Confidence indicator

Example presentation:

```
## Detected Architectural Decisions

Based on this session, I found the following decisions that could be documented:

1. **[NEW] Use Zustand for State Management** (Technology, High confidence)
   > Chose Zustand over Redux for client-side state due to simpler API and smaller bundle size.

2. **[UPDATE] API Authentication Strategy** (Architecture, Medium confidence)
   > Updated from JWT-only to JWT + refresh token rotation. Existing: 0003-api-auth-strategy.md

3. **[NEW] Adopt Vitest for Unit Testing** (Technology, High confidence)
   > Switched from Jest to Vitest for better ESM support and faster execution.
```

Use `AskUserQuestion` with multiSelect to let the user pick which ones to create/update.

### Step 5: Phase 3 - Write ADRs

For each selected decision, launch the `madr-writer` agent:

```
Agent(
  subagent_type="madr-writer",
  model="sonnet",
  prompt="Create/update the following ADR in docs/decisions/:

  Action: {new|update|supersede}
  Decision data: {decision_json}
  Existing file (if update/supersede): {file_path}
  Next sequence number (if new): {next_number}
  Today's date: {YYYY-MM-DD}

  Write the mADR file following the MADR 4.0 template."
)
```

For multiple selections, run writers in parallel since they write to different files.

### Step 6: Summary

After all writes complete, present a summary:
- List of created/updated files with paths
- Quick view of each ADR title and status

## Configuration

### ADR Directory
Default: `docs/decisions/`
Can be overridden by setting `adrDirectory` in the project's `.madr-gen.json` config file.

### Template Style
Default: Full template (all sections)
Alternative: Minimal template (context, options, outcome only)
Set via `templateStyle: "full" | "minimal"` in `.madr-gen.json`.

### Language
By default, ADRs are written in the language the user uses in the session.
Can be forced via `language: "en" | "ko" | ...` in `.madr-gen.json`.

## Example Config (.madr-gen.json)

```json
{
  "adrDirectory": "docs/decisions",
  "templateStyle": "full",
  "language": "auto",
  "autoSuggest": true,
  "categories": [
    "technology",
    "architecture",
    "convention",
    "infrastructure",
    "refactoring"
  ]
}
```
