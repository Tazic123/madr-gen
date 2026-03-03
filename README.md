# madr-gen

A Claude Code plugin that automatically analyzes your session to detect architectural decisions and generates [mADR (Markdown Any Decision Records)](https://github.com/adr/madr) documents.

## What It Does

Every time you make a significant architectural decision in a Claude Code session — choosing a library, adopting a pattern, deciding on a structure — `madr-gen` finds it and asks if you want to document it. Documents are stored in `docs/decisions/` following the MADR 4.0 format.

## Installation

Claude Code plugins are installed by placing them in `~/.claude/plugins/`. You can install `madr-gen` in two ways:

**Option A — Clone directly into the plugins folder**

```bash
git clone https://github.com/JiHongKim98/madr-gen.git ~/.claude/plugins/madr-gen
```

**Option B — Symlink from a local clone**

```bash
git clone https://github.com/JiHongKim98/madr-gen.git ~/projects/madr-gen
ln -s ~/projects/madr-gen ~/.claude/plugins/madr-gen
```

After placing the folder, Claude Code will automatically discover the plugin on next launch (or reload).

> **Tip:** You can verify the plugin is recognized by running `/plugins` in Claude Code and checking that `madr-gen` appears in the list.

## Usage

Run the `/madr` command at any point during or at the end of a session:

```
/madr          # Interactive: analyze session and select which ADRs to create
/madr scan     # Quick scan: show detected decisions without writing files
/madr init     # Initialize docs/decisions/ directory in the current project
```

## How It Works

`madr-gen` runs a 4-phase pipeline:

```
Phase 1: Detection (parallel)
  └─ decision-detector (Sonnet)
     ├─ Reads JSONL session logs from ~/.claude/projects/<project>/
     ├─ Extracts User/Assistant conversation text
     └─ Cross-references with git diff/log

Phase 2: Validation (sequential)
  └─ duplicate-checker (Haiku)
     └─ Compares proposals against existing docs/decisions/*.md
        → classifies each as: new / update / supersede / duplicate

Phase 3: Selection (interactive)
  └─ AskUserQuestion (multi-select)
     └─ Lists detected decisions with category, action type, and confidence

Phase 4: Writing (parallel)
  └─ madr-writer (Sonnet) × N
     └─ Creates or updates NNNN-kebab-case-title.md in docs/decisions/
```

## Output Format

ADR files follow the [MADR 4.0](https://github.com/adr/madr) template:

```
docs/decisions/
├── 0001-use-react-for-frontend.md
├── 0002-adopt-repository-pattern.md
└── 0003-use-vitest-for-testing.md
```

Each file contains:

```markdown
---
status: accepted
date: 2026-03-04
decision-makers: kimjihong
---

# Use React for Frontend

## Context and Problem Statement
...

## Decision Drivers
* ...

## Considered Options
* React
* Vue
* Svelte

## Decision Outcome
Chosen option: "React", because ...

### Consequences
* Good, because ...
* Bad, because ...
```

## What Gets Detected

| Category | Examples |
|----------|---------|
| **Technology** | Library choices, framework selection, build tools |
| **Architecture** | Design patterns, module structure, API design |
| **Convention** | Naming rules, error handling, code style |
| **Infrastructure** | CI/CD, deployment, cloud services |
| **Refactoring** | Migration strategy, deprecation decisions |

## Configuration

Create `.madr-gen.json` in your project root to customize behavior:

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

| Option | Default | Description |
|--------|---------|-------------|
| `adrDirectory` | `docs/decisions` | Where ADR files are stored |
| `templateStyle` | `full` | `"full"` (all sections) or `"minimal"` (context, options, outcome only) |
| `language` | `auto` | `"auto"` matches session language, or force with `"en"`, `"ko"`, etc. |
| `autoSuggest` | `true` | Whether to suggest existing ADR updates alongside new ones |

## Helper Scripts

Two bash scripts are included for direct use or integration with other tools:

```bash
# Find session JSONL logs for any project
./scripts/find-session-logs.sh /path/to/project [max-age-hours]

# Extract conversation text from a session JSONL file
./scripts/extract-decisions.sh ~/.claude/projects/.../session.jsonl [max-lines]
```

## Recommended Workflow

Add this reminder to your project's `CLAUDE.md`:

```markdown
## Session Workflow
Before ending a session with significant changes, run `/madr` to document
any architectural decisions made during the session.
```

This keeps `docs/decisions/` up to date so future sessions (and teammates) understand why choices were made.

## Plugin Structure

```
madr-gen/
├── .claude-plugin/plugin.json    # Plugin manifest
├── commands/madr.md              # /madr command definition
├── agents/
│   ├── decision-detector.md      # Detects decisions from session + git
│   ├── duplicate-checker.md      # Prevents duplicate ADRs
│   └── madr-writer.md            # Writes MADR 4.0 formatted files
├── skills/madr-gen/SKILL.md      # Full workflow orchestration
├── scripts/
│   ├── find-session-logs.sh      # Session log discovery
│   └── extract-decisions.sh      # JSONL conversation extraction
└── .madr-gen.json                # Default configuration
```

## License

MIT
