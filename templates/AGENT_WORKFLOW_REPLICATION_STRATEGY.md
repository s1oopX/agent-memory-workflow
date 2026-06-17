# Agent Workflow Replication Strategy

The goal is to make local agent memory reproducible without binding it to one
agent vendor.

## Current Best Path

Use a plain file protocol under `{{AGENTS_ROOT}}`, backed by a verifier and a
small initializer.

This works because local agents can read Markdown and JSON files directly, and
humans can inspect or edit the source without a special database.

## npx / CLI

The first productization layer is an `npx` or local CLI wrapper. It should:

- initialize templates into a target `.agents` directory
- replace placeholders with local paths
- run `init-agent-memory-workflow.ps1`
- run `verify-agent-memory-workflow.ps1`
- show the import prompt path to give to local agents

The CLI should not hide the Markdown source files or become the canonical memory
store.

## Agent skill

An Agent skill can be useful as a thin adapter for a specific product. It should
read the file protocol and follow the same receipt rules. It should not become
the canonical source of truth.

## SDK

Defer an SDK until there is a stable app or integration boundary. An SDK is
useful only when multiple tools need programmatic access to the same verified
workflow state.

## Public Release Link

Use `AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md` before publishing or packaging the
workflow.
