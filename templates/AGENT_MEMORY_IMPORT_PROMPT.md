# Agent Memory Import Prompt

Version: `workflow-v3`

You are a local agent with access to the user's filesystem. Import the shared
agent memory workflow from:

```text
{{AGENTS_ROOT}}
```

## Required Reading Order

Read these files before claiming the import is complete:

```text
AGENT_BOOTSTRAP.md
machine\MACHINE_ENVIRONMENT_MEMORY.md
machine\AGENT_EXECUTION_PLAYBOOK.md
machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
machine\HOME_DIRECTORY_MAP.md
machine\MAINTENANCE_POLICY.md
AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
AGENT_PLATFORM_ADAPTERS.md
imports\IMPORT_REGISTRY.md
```

## What To Persist

Persist only durable, non-secret operating facts:

- canonical memory root and bootstrap path
- machine tool availability and known environment caveats
- preferred execution strategy for this machine
- maintenance policy for the memory directory
- local-only scope and secrets policy
- reimport rules from `imports\IMPORT_REGISTRY.md`

Do not persist chat-only notes as if they were durable memory. If you cannot
write to a durable memory or persistent instruction layer, say so and mark the
result as `manual_user_action_required` or `chat_local_only`.

## What Not To Persist

Do not persist:

- credentials, tokens, private keys, or service secrets
- private session logs
- temporary workspace facts
- machine facts that the source files do not actually state

## Required Receipt

After import, return a receipt using:

```text
AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
```

The receipt must state where the memory was stored, whether the storage is
durable, whether local filesystem access was available, and whether a fresh chat
test is still needed.
