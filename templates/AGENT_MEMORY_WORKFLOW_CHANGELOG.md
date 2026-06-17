# Agent Memory Workflow Changelog

## workflow-v3

- Added a manifest-backed workflow definition in
  `AGENT_MEMORY_WORKFLOW_MANIFEST.json`.
- Added `AGENT_PLATFORM_ADAPTERS.md` for local agent categories.
- Added `AGENT_WORKFLOW_REPLICATION_STRATEGY.md` for file protocol, CLI, skill,
  and SDK decisions.
- Added `AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md` for public release hygiene.
- Added `verify-agent-memory-workflow.ps1` as the local integrity check.

## Reimport Policy

Agents should reimport when the workflow version changes, the manifest changes,
machine facts materially change, or the verifier policy changes.
