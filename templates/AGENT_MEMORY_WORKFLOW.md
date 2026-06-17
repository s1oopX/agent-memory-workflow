# Agent Memory Workflow

Version: `workflow-v3`

This workflow gives local agents a shared file-based memory source that can be
imported into each agent's own persistent instruction or memory layer.

## Canonical Files

```text
AGENT_BOOTSTRAP.md
AGENT_MEMORY_IMPORT_PROMPT.md
AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
AGENT_MEMORY_WORKFLOW_MANIFEST.json
AGENT_MEMORY_WORKFLOW_CHANGELOG.md
AGENT_PLATFORM_ADAPTERS.md
AGENT_WORKFLOW_REPLICATION_STRATEGY.md
AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md
imports\IMPORT_REGISTRY.md
machine
```

## Flow

1. User initializes or updates `{{AGENTS_ROOT}}`.
2. User edits machine facts in `machine`.
3. Agent reads `AGENT_BOOTSTRAP.md`.
4. Agent follows `AGENT_MEMORY_IMPORT_PROMPT.md`.
5. Agent stores stable facts in its durable local memory or persistent rules.
6. Agent returns `AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md`.
7. User keeps receipts or notes in `imports\IMPORT_REGISTRY.md`.

## Reimport Triggers

Reimport when:

- `AGENT_MEMORY_IMPORT_PROMPT.md` changes
- `AGENT_MEMORY_WORKFLOW_MANIFEST.json` version changes
- machine facts under `machine` materially change
- `AGENT_PLATFORM_ADAPTERS.md` changes
- verifier rules change

## Local-Only Boundary

This is a local file protocol. It assumes the agent can read local files. It is
not a remote memory service and it does not synchronize memory between tools.
