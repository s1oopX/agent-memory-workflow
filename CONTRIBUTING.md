# Contributing

Thanks for improving Agent Memory Workflow.

This project is intentionally local-first and file-based. Contributions should
preserve the following constraints:

- The canonical source remains the local `.agents` directory.
- Shared memory files must not store credentials or private session data.
- Templates must use placeholders instead of personal paths.
- Initializer changes must avoid overwriting user machine facts by default.
- Verifier changes should produce actionable failure messages.

## Development Setup

```powershell
git clone https://github.com/s1oopX/agent-memory-workflow.git
cd agent-memory-workflow
npm run ci
```

The project has no runtime npm dependencies. PowerShell 7 (`pwsh`) is required.

## Before Opening a Pull Request

Run:

```powershell
npm run ci
```

Check that:

- no secrets or private paths were added
- README and templates are updated when behavior changes
- new initializer or verifier behavior is covered by `tools\test-agent-memory-workflow.ps1`
- package contents still look correct through `npm pack --dry-run`

## Documentation Style

Keep documentation explicit and operational. A new local user should be able to
reproduce the workflow from the README without needing hidden context from the
maintainer's machine.
