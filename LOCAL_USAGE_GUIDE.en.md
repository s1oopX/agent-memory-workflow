# Local-First Usage Guide

[Simplified Chinese](LOCAL_USAGE_GUIDE.md) | [English](LOCAL_USAGE_GUIDE.en.md)

This guide condenses the local-agent usage model of Agent Memory Workflow into a
single path. It is not meant to repeat every template. It answers four
practical questions:

- which installation and operating path a local user should choose
- which files should be filled in first
- what should be handed to a new local agent
- how to tell whether the import is truly durable instead of living only in the
  current chat

## Scope

This guide is only for agents that can read the local filesystem, such as:

- local Codex-like coding agents
- local IDE agents
- local CLI agents
- local desktop agents

It does not cover remote web agents, attachment handoff flows, multi-device
synchronization, or hosted cloud memory.

## Recommended Default Path

For most local users, the recommended default combination is:

- keep the shared directory at `$HOME\.agents`
- initialize the workflow with `npx` or a fixed release tag
- use `AGENT_BOOTSTRAP.md` as the durable entrypoint anchor
- use `AGENT_MEMORY_IMPORT_PROMPT.md` as the import protocol
- use the import receipt and `imports\IMPORT_REGISTRY.md` as proof of completion

The shortest working path is:

1. Run `preflight` to check the runtime and target directory.
2. Run `init` to generate `$HOME\.agents`.
3. Fill in the durable machine facts under `machine\`.
4. Run `verify` to confirm structure, references, and sensitive-pattern checks.
5. Give `AGENT_MEMORY_IMPORT_PROMPT.md` to the new local agent.
6. Require the agent to return a structured import receipt.
7. In later tasks, have the agent read `AGENT_BOOTSTRAP.md` first instead of
   rescanning the whole machine.

## Which Local Path To Choose

| Your goal | Recommended path | Why |
| --- | --- | --- |
| Start using it immediately | `npx -y github:s1oopX/agent-memory-workflow ...` | Lowest setup cost; best for most local users |
| Reproduce an exact version | `npx -y github:s1oopX/agent-memory-workflow#v0.1.20 ...` | Fixed version; good for team reproducibility and documentation alignment |
| Audit templates, read offline, contribute | Clone the repo and run `tools\*.ps1` | Full visibility into templates, scripts, and changes |

The practical rule is simple:

- use `npx` by default
- switch to a fixed tag when exact reproducibility matters
- clone the repo only when you need to inspect or change the templates

## Recommended Stack Order

If you are designing your own local agent memory workflow, use this order:

1. **File protocol**: keep shared facts in user-reviewable Markdown and JSON.
2. **npx / local CLI**: provide initialization, upgrade, verification, and
   import-prompt commands.
3. **Agent-specific skill or adapter**: keep it thin; it should read the file
   protocol, not replace it.
4. **SDK**: add it only when multiple local tools need programmatic access to
   the same verified state.

This is also the order used by this repository. The point is not "never use a
skill or SDK"; the point is that they should not become the source of truth
before the local file protocol exists.

## Which Files To Fill In First

The initialized templates are only the frame. The valuable part is the durable
machine context you add. Fill these first:

| File | Role |
| --- | --- |
| `machine\MACHINE_ENVIRONMENT_MEMORY.md` | full machine fact library with stable environment conclusions |
| `machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md` | short summary for fast agent reads |
| `machine\AGENT_EXECUTION_PLAYBOOK.md` | shell and command-routing strategy for this machine |
| `machine\HOME_DIRECTORY_MAP.md` | boundary map for user, workspace, config, and temporary directories |
| `machine\MAINTENANCE_POLICY.md` | what counts as live data and which cleanup actions are unsafe by default |

Writing rules:

- record only durable, non-secret, reusable machine facts
- do not store passwords, tokens, private keys, or session logs
- do not promote one-off task conclusions into long-term rules

## What To Hand To A New Agent

The minimum input for a new local agent is not a large handwritten prompt. It is
this instruction:

```text
Read $HOME\.agents\AGENT_MEMORY_IMPORT_PROMPT.md and import it into your local durable memory or persistent instruction layer.
```

If the agent can read local files directly, that instruction is enough. It
should then follow the import prompt and read the required files, not only the
README.

## Durable Storage Targets By Local Agent Type

| Agent type | Recommended storage target | Minimum requirement |
| --- | --- | --- |
| Codex-like local agent | durable memory, persistent instruction layer, or user-level rules | must not stop at the current chat |
| Local IDE agent | global IDE rules, user instructions, or a persistent memory feature | must at least keep the bootstrap path and stable machine summary |
| Local CLI agent | user config, startup instructions, or global rule files | new sessions must still read the bootstrap first |
| Local desktop agent | durable settings, memory page, or persistent instructions area | if manual confirmation is needed, the receipt must say so |

The key question is not the product name. It is:

- where does the agent write long-lived rules
- can it still read `AGENT_BOOTSTRAP.md` first after a restart or fresh session

## How To Tell Whether Import Succeeded

Import should count as successful only if all of the following are true:

1. The agent read the required files from the import prompt, not only a summary.
2. The agent wrote a durable memory record that includes at least the bootstrap
   path and a stable machine-facts summary.
3. The agent stated where it wrote that durable state, such as persistent
   memory, a rules page, user config, or startup instructions.
4. The agent returned a structured receipt based on
   `AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md`.
5. If durable storage was not actually completed, the receipt says
   `chat_local_only` or `manual_user_action_required` instead of pretending the
   import is done.

The short rule is: **it is only a successful import if it survives a fresh
session and has receipt evidence.**

## Local Maintenance Loop

A good local maintenance loop is:

1. Edit the machine facts or policy files under `machine\`.
2. Run `verify`.
3. If the workflow version or managed templates changed, run `upgrade`.
4. Give the new `import-prompt` to agents that already imported the workflow.
5. Update `imports\IMPORT_REGISTRY.md` or at least retain the new import
   receipts.

These changes usually require reimport:

- material changes to machine facts
- changes to `AGENT_MEMORY_IMPORT_PROMPT.md`
- changes to `AGENT_PLATFORM_ADAPTERS.md`
- changes to `AGENT_MEMORY_WORKFLOW_MANIFEST.json`
- changes to verifier or maintenance policy behavior

## What Not To Do

- do not store credentials in `.agents`
- do not treat the current chat as durable memory
- do not make every new agent re-audit the whole machine
- do not keep facts only inside one product's private memory without preserving
  the bootstrap path
- do not mix remote web-agent workflows into this local-first protocol

## One-Sentence Workflow

If you want the shortest possible version, use this:

**Generate `$HOME\.agents` with `npx` or a fixed tag, fill the `machine\`
facts, run `verify`, then hand `AGENT_MEMORY_IMPORT_PROMPT.md` to every new
local agent and require an auditable import receipt.**
