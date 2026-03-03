---
description: Analyze the current session and suggest mADR (Architecture Decision Record) updates or new records
allowed-tools: Bash(git *), Bash(ls *), Bash(cat *), Bash(find *), Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
---

# mADR Generator (/madr)

Analyze the current Claude Code session to detect architectural decisions and suggest mADR document creation or updates.

## Usage

- `/madr` - Analyze current session and suggest ADR updates (interactive)
- `/madr scan` - Quick scan without interactive selection
- `/madr init` - Initialize docs/decisions/ directory with ADR index

## Execution

Follow the workflow defined in the **madr-gen** skill:

1. **Discover**: Find existing ADRs in `docs/decisions/`
2. **Analyze**: Run analysis agents in parallel to detect decisions from the current session
3. **Validate**: Check for duplicates against existing ADRs
4. **Present**: Show categorized suggestions to the user via interactive selection
5. **Execute**: Create or update selected mADR documents

Refer to `skills/madr-gen/SKILL.md` for detailed execution steps and agent configurations.
