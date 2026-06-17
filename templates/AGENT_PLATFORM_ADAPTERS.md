# Agent Platform Adapters

This workflow is agent-neutral. Each local agent should map the file protocol
into its own durable memory or persistent instruction layer.

## Codex-Like Local Agents

Read `AGENT_BOOTSTRAP.md`, follow `AGENT_MEMORY_IMPORT_PROMPT.md`, and return a
receipt based on `AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md`.

Store durable facts in the local agent memory or persistent instruction layer
available to that tool. Do not rely on the current chat as durable storage.

## Local IDE Agents

Store the bootstrap path and stable machine facts in the IDE's persistent rules,
workspace instructions, or memory feature. Prefer pointing to files over copying
large blocks when the IDE can read local files.

## Local CLI Agents

Store the bootstrap path in the CLI's user config or startup instructions. Run
the verifier before importing and after upgrades.

## Local Desktop Agents

Store the bootstrap path in the desktop app's durable memory or settings. If the
app requires manual confirmation, return a receipt marked
`manual_user_action_required`.

## Unsupported Storage

If an agent cannot write durable memory, return a receipt marked
`chat_local_only` and tell the user what manual action is required.
