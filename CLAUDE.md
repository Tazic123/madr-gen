# madr-gen Plugin

Claude Code plugin that automatically detects architectural decisions from sessions and generates mADR documents.

## Plugin Usage

- `/madr` - Analyze current session and suggest ADR creation/updates
- `/madr scan` - Quick scan without interactive selection
- `/madr init` - Initialize `docs/decisions/` directory

## Architecture

```
Phase 1 (Parallel):  decision-detector (sonnet) → detect decisions from session
Phase 2 (Sequential): duplicate-checker (haiku)  → validate against existing ADRs
Phase 3 (Interactive): AskUserQuestion            → user selects which to create
Phase 4 (Parallel):  madr-writer (sonnet)        → write selected ADR files
```

## Session Workflow Reminder

Before ending a session with significant architectural changes, consider running `/madr` to document decisions made during this session. This keeps the `docs/decisions/` directory up to date and helps future sessions (and team members) understand why certain choices were made.

## mADR Format

This plugin follows [MADR 4.0](https://github.com/adr/madr) format:
- Files stored in `docs/decisions/`
- Named as `NNNN-kebab-case-title.md` (e.g., `0001-use-react-for-frontend.md`)
- Contains: Context, Decision Drivers, Considered Options, Decision Outcome, Consequences

## Configuration

Edit `.madr-gen.json` in the project root to customize:
- `adrDirectory`: Where ADRs are stored (default: `docs/decisions`)
- `templateStyle`: `"full"` or `"minimal"`
- `language`: `"auto"` (matches session language), `"en"`, `"ko"`, etc.
