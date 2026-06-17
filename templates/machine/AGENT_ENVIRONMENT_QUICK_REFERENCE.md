# Agent Environment Quick Reference

This file should become the quick operational reference for local agents on this
machine.

## Machine

```text
user: {{USER_ID}}
home: {{HOME_DIR}}
agents_root: {{AGENTS_ROOT}}
os: {{OS_NAME}}
```

## Tool Inventory

Fill in verified tools:

```text
shells:
  - pending
languages:
  - pending
package_managers:
  - pending
databases:
  - pending
browsers:
  - pending
build_tools:
  - pending
```

## Known Caveats

Record durable caveats only. Examples:

- tool exists but requires a developer shell
- a service is intentionally not auto-started
- a command name differs between shells
- PATH is intentionally managed by a profile script

## Agent Rule

Use this file as a shortcut after it has been verified. Do not rescan the whole
machine unless the user asks for an audit or the reference appears stale.
