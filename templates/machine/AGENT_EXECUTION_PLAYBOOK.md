# Agent Execution Playbook

This playbook tells local agents how to work efficiently on this machine.

## Defaults

- Read `{{AGENTS_ROOT}}\AGENT_BOOTSTRAP.md` before relying on local memory.
- Do not perform a full environment audit for ordinary tasks.
- Prefer existing verified tools from
  `{{AGENTS_ROOT}}\machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md`.
- Use task-specific checks instead of broad rescans.
- Run the verifier after changing workflow files.

## Editing This Memory

When updating this directory:

1. Read `{{AGENTS_ROOT}}\machine\MAINTENANCE_POLICY.md`.
2. Make focused edits.
3. Avoid storing secrets or temporary session details.
4. Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "{{AGENTS_ROOT}}\tools\verify-agent-memory-workflow.ps1"
```

## Importing Into A New Agent

Give the agent:

```text
Read {{AGENTS_ROOT}}\AGENT_MEMORY_IMPORT_PROMPT.md and import it into your local durable memory or persistent instruction layer.
```

Require a receipt before assuming the import is durable.
