# Agent Memory Workflow

[简体中文](README.md) | [English](README.en.md)

Agent Memory Workflow is a local-first file protocol for maintaining reusable
operating memory for coding agents. It provides a stable `.agents` directory,
generic templates, an initializer, and a verifier so local agents can share the
same machine guidance without depending on a hosted memory service or a specific
agent vendor.

## Overview

Modern coding agents often operate in separate sessions and products. Important
local context, such as tool availability, machine-specific paths, execution
policies, and maintenance rules, is repeatedly rediscovered or lost between
agents.

This project standardizes that context as local, inspectable files. A user
initializes a `.agents` directory, fills in non-secret machine facts, and gives
the import prompt to each local agent. The agent then imports the stable facts
into its own durable memory or persistent instruction layer and returns a
receipt.

## Scope

This project is designed for local agents with filesystem access.

It does not provide:

- cloud synchronization
- hosted memory storage
- remote web-agent attachment flows
- credential management
- a database-backed memory service

The source of truth remains the local `.agents` directory.

## Requirements

- Git
- PowerShell 7 or later, available as `pwsh`
- Node.js 18 or later, only when using the `npx` wrapper
- A local agent that can read files from the target machine

## Quick Start

Clone the repository and initialize a local `.agents` directory:

```powershell
git clone https://github.com/s1oopX/agent-memory-workflow.git
cd agent-memory-workflow
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\init-agent-memory-workflow.ps1 -TargetRoot "$HOME\.agents"
```

Verify the generated workflow:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\tools\verify-agent-memory-workflow.ps1"
```

Edit the generated machine reference files:

```text
$HOME\.agents\machine\MACHINE_ENVIRONMENT_MEMORY.md
$HOME\.agents\machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
$HOME\.agents\machine\HOME_DIRECTORY_MAP.md
```

Give a local agent this instruction:

```text
Read $HOME\.agents\AGENT_MEMORY_IMPORT_PROMPT.md and import it into your local durable memory or persistent instruction layer.
```

The agent should return an import receipt based on:

```text
$HOME\.agents\AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
```

## npx Usage

The repository includes a lightweight Node.js wrapper for initialization and
verification:

```powershell
npx github:s1oopX/agent-memory-workflow init --target "$HOME\.agents"
npx github:s1oopX/agent-memory-workflow verify --root "$HOME\.agents"
```

The wrapper delegates to the PowerShell scripts in `tools\`.

## Repository Layout

```text
bin\
  agent-memory-workflow.js
tools\
  init-agent-memory-workflow.ps1
  verify-agent-memory-workflow.ps1
templates\
  AGENT_BOOTSTRAP.md
  AGENT_MEMORY_IMPORT_PROMPT.md
  AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
  AGENT_MEMORY_WORKFLOW.md
  AGENT_MEMORY_WORKFLOW_MANIFEST.json
  AGENT_PLATFORM_ADAPTERS.md
  AGENT_WORKFLOW_REPLICATION_STRATEGY.md
  AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md
  imports\
  machine\
```

`templates\` is the public template source. The initializer copies these files
to the target root, replaces placeholders with local values, installs the tool
scripts, and runs the verifier.

## Workflow Model

1. Initialize a local `.agents` directory.
2. Fill in non-secret machine facts.
3. Run the verifier.
4. Ask a local agent to read `AGENT_MEMORY_IMPORT_PROMPT.md`.
5. Store the resulting durable memory inside the agent's own persistent layer.
6. Record or review the agent's import receipt.
7. Reimport when the workflow version, manifest, verifier, or machine facts
   materially change.

## Security Model

Shared memory files must not contain credentials, tokens, passwords, private
keys, cookies, service secrets, or private session logs.

Appropriate content includes:

- verified tool availability
- stable local paths
- non-secret environment notes
- startup and execution preferences
- maintenance policies
- local agent import status

The verifier scans for common secret patterns, but human review remains required
before publishing or sharing any machine-specific files.

## Versioning

The current workflow version is `workflow-v3`. Version markers are stored in the
manifest, import prompt, receipt template, workflow summary, and import
registry.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
