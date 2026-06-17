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

## Minimum Durable Memory Record

Store a compact pointer record rather than copying every source file into memory:

```text
Agent Memory Workflow root: {{AGENTS_ROOT}}
Bootstrap: {{AGENTS_ROOT}}\AGENT_BOOTSTRAP.md
Machine facts: {{AGENTS_ROOT}}\machine
Verifier: {{AGENTS_ROOT}}\tools\verify-agent-memory-workflow.ps1
Scope: local filesystem agents only
Secrets policy: never store credentials, tokens, private keys, cookies, service secrets, or database passwords
Default behavior: use the bootstrap path as the first machine-context source; do not re-audit the whole environment for ordinary tasks
```

You may summarize stable machine facts into your durable memory, but keep the
bootstrap path as the canonical source so future updates can be reimported.

## Persistence Requirements

Do not claim the import is durable unless you wrote the record to a memory,
rules, settings, profile, or startup-instruction layer that survives a new
conversation or process restart.

If the current agent only has project-local rules, store the bootstrap pointer
there and mark the receipt as `project_rules`. If no durable storage is
available, mark the receipt as `manual_user_action_required` or
`chat_local_only`.

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

## Fresh Session Verification

If the agent platform supports it, verify the import in a fresh conversation or
new process by confirming that the bootstrap path is available without the user
repeating it. If this cannot be tested immediately, set `fresh_chat_test` to
`needed` in the receipt.
