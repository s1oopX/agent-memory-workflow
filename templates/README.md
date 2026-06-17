# Local Agent Memory

This directory is the local shared memory source for agents on this machine.
It is intended for local agents with filesystem access.

## Start Here

Use this file as the universal bootstrap:

```text
{{AGENTS_ROOT}}\AGENT_BOOTSTRAP.md
```

Use this file when importing the memory into a new local agent:

```text
{{AGENTS_ROOT}}\AGENT_MEMORY_IMPORT_PROMPT.md
```

After importing, the agent should return a receipt using:

```text
{{AGENTS_ROOT}}\AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
```

## Machine Facts

Edit these files after initialization:

```text
{{AGENTS_ROOT}}\machine\MACHINE_ENVIRONMENT_MEMORY.md
{{AGENTS_ROOT}}\machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
{{AGENTS_ROOT}}\machine\HOME_DIRECTORY_MAP.md
```

Do not store service credentials, tokens, private keys, or private session logs
in these shared files.

## Verification

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "{{AGENTS_ROOT}}\tools\verify-agent-memory-workflow.ps1"
```
