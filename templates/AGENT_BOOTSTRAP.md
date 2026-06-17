# Agent Bootstrap

This is the stable entry point for local agents.

Canonical root:

```text
{{AGENTS_ROOT}}
```

Read these files before relying on local machine memory:

```text
{{AGENTS_ROOT}}\AGENT_MEMORY_IMPORT_PROMPT.md
{{AGENTS_ROOT}}\AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
{{AGENTS_ROOT}}\AGENT_MEMORY_WORKFLOW.md
{{AGENTS_ROOT}}\imports
{{AGENTS_ROOT}}\machine\MACHINE_ENVIRONMENT_MEMORY.md
```

The import prompt is the operational instruction. The workflow summary explains
the protocol and reimport rules. The `machine` directory contains facts that are
local to this computer and should be edited by the user or a trusted local
agent.

Do not infer secrets from this directory. If a task needs credentials, ask the
user or use an approved local credential mechanism.
