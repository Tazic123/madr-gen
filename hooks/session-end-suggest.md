---
description: Hook that triggers at session end to suggest mADR updates based on session activity
trigger: session-end
---

# Session End - mADR Suggestion Hook

This hook concept enables automatic mADR suggestions when a Claude Code session ends.

## How It Works

When a session is about to end (or when the user runs `/madr`), the plugin:

1. Scans the session's conversation history for architectural decisions
2. Cross-references with existing ADRs in `docs/decisions/`
3. Presents a quick summary of potential ADR updates

## Integration Point

Since Claude Code plugins currently support commands and agents rather than lifecycle hooks, the recommended integration is:

### Option A: Manual Trigger
User runs `/madr` at any point during or at the end of a session.

### Option B: CLAUDE.md Reminder
Add to the project's `CLAUDE.md`:

```markdown
## Session Workflow
Before ending a session with significant architectural changes, run `/madr` to check if any decisions should be documented.
```

### Option C: Compact Hook Integration
If using a compact/session-end hook system, add mADR analysis as a step:

```
After compaction, scan the session summary for architectural decisions and suggest ADR updates.
```

## Future: Native Hook Support

When Claude Code supports native session lifecycle hooks, this can be converted to an automatic trigger that runs on:
- `session-end`: Full analysis and interactive suggestion
- `pre-compact`: Quick scan and notepad reminder
- `post-commit`: Check if committed changes relate to documented decisions
