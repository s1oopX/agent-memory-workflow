# Agent Directory Rules

This directory is the local agent memory and workflow directory for
`{{USER_ID}}` on `{{OS_NAME}}`.

Treat it as durable local agent configuration, not as a normal project
workspace.

Universal bootstrap:

```text
{{AGENTS_ROOT}}\AGENT_BOOTSTRAP.md
```

Full machine environment reference:

```text
{{AGENTS_ROOT}}\machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
```

Execution strategy:

```text
{{AGENTS_ROOT}}\machine\AGENT_EXECUTION_PLAYBOOK.md
```

## Safe Defaults

- Do not re-audit the whole environment for ordinary tasks.
- Do not move or delete auth, config, database, session, plugin, cache, runtime,
  or sandbox files unless the user explicitly asks for that exact cleanup.
- Do not write credentials or service secrets into docs or logs.
- Keep machine-level reference material under `{{AGENTS_ROOT}}\machine`.

## Before Changing This Directory

Read:

```text
{{AGENTS_ROOT}}\machine\MAINTENANCE_POLICY.md
```

Follow the verifier after material changes:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "{{AGENTS_ROOT}}\tools\verify-agent-memory-workflow.ps1"
```
