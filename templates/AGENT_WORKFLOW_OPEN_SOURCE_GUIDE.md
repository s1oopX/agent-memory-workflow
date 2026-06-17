# Agent Workflow Open Source Guide

This guide describes how to publish the local agent memory workflow so other
local-agent users can reproduce it easily.

## What To Open Source

Publish:

- protocol documentation
- generic templates
- `init-agent-memory-workflow.ps1`
- `verify-agent-memory-workflow.ps1`
- optional `npx` wrapper
- setup and verification instructions

## What Not To Open Source

Do not publish:

- credentials or service secrets
- private machine-specific memories
- private import receipts
- private session logs
- temporary workspace contents

## Reproducible User Flow

Users should be able to:

1. Clone the repository.
2. Run one init command.
3. Edit the generated machine fact files.
4. Run one verifier command.
5. Give `AGENT_MEMORY_IMPORT_PROMPT.md` to a local agent.
6. Receive an import receipt.

## Release Checklist

Before publishing:

1. Confirm templates use placeholders instead of personal paths.
2. Initialize into a clean temporary directory.
3. Run the verifier against that generated directory.
4. Scan for private paths and service secrets.
5. Confirm the README quickstart works.
6. Confirm local-only scope is explicit.

## Success Criteria

A new local user can reproduce the workflow without knowing the original
machine, original agent session, or any private local facts.
