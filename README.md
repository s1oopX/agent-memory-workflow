# Agent Memory Workflow

Local-first file protocol for giving coding agents a shared, durable operating
memory without locking the memory into one agent product.

The workflow stores human-maintained guidance in a local `.agents` directory.
Local agents read the bootstrap and import prompt, then save the distilled
rules into their own persistent instruction or memory layer.

## Scope

This project is for local agents that can read local files. It does not try to
solve remote web-agent attachment flows, cloud sync, hosted memory, or a shared
database.

## Five-Minute Quickstart

Clone the repository and initialize a local `.agents` directory:

```powershell
git clone https://github.com/s1oopX/agent-memory-workflow.git
cd agent-memory-workflow
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\init-agent-memory-workflow.ps1 -TargetRoot "$HOME\.agents"
```

Verify the generated local workflow:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\tools\verify-agent-memory-workflow.ps1"
```

Then edit these two files for the machine:

```text
$HOME\.agents\machine\MACHINE_ENVIRONMENT_MEMORY.md
$HOME\.agents\machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md
```

Give a local agent this instruction:

```text
Read $HOME\.agents\AGENT_MEMORY_IMPORT_PROMPT.md and import it into your local durable memory or persistent instruction layer.
```

The agent should return a receipt based on:

```text
$HOME\.agents\AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md
```

## npx Usage

The repository includes a small Node wrapper so users can run it through a local
checkout or directly through GitHub:

```powershell
npx github:s1oopX/agent-memory-workflow init --target "$HOME\.agents"
npx github:s1oopX/agent-memory-workflow verify --root "$HOME\.agents"
```

The wrapper calls the PowerShell scripts in `tools\`. It requires PowerShell 7
(`pwsh`) on PATH.

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
  imports\
  machine\
```

`templates\` is the public source. `init-agent-memory-workflow.ps1` copies it to
the target root, replaces placeholders, installs the tools, and runs the
verifier.

## Design

- Canonical source: plain Markdown and JSON files under `.agents`.
- Import path: one bootstrap file and one import prompt.
- Persistence: handled by each agent's own local memory or instruction layer.
- Integrity: enforced by `verify-agent-memory-workflow.ps1`.
- Productization: thin CLI wrapper first; SDK only after a real integration
  boundary exists.

## Security

Do not store service credentials, tokens, passwords, private keys, or database
secrets in the shared memory files. Store only safe facts such as tool names,
paths, version notes, startup preferences, and non-secret usage policies.

## License

MIT
