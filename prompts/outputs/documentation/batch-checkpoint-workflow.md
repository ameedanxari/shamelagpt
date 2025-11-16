# Batch Checkpoint Workflow

**Date**: 2026-02-17

## Checkpoint Record Schema
- `timestamp`
- `task_id`
- `batch_id`
- `platform`
- `command`
- `status` (`PASS`, `FAIL`, `BLOCKED`, `PARTIAL`)
- `result_summary`
- `artifacts`
- `next_action`
- `blockers`

## Storage
- Canonical checkpoint log file:
  - `prompts/outputs/documentation/batch-checkpoints.md`
- Append one record per executed batch.
- Do not overwrite prior records.

## Record Template
Use this exact section format for each batch:

```md
### <timestamp> | <task_id> | <batch_id>
- platform: <ios|android|cross-platform>
- command: `<full command>`
- status: <PASS|FAIL|BLOCKED|PARTIAL>
- result_summary: <short factual outcome>
- artifacts:
  - `<artifact path>`
- next_action: <single concrete next step>
- blockers: <none|short blocker detail>
```

## Execution Rules
1. Run one bounded batch.
2. Persist checkpoint record in `batch-checkpoints.md`.
3. Ensure command, status, artifacts, and next action are always present.
4. If `FAIL` or `BLOCKED`, stop and triage only that batch.
5. Resume from latest incomplete batch.
