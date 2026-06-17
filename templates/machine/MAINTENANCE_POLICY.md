# Maintenance Policy

This policy applies to `{{AGENTS_ROOT}}`.

## Allowed Routine Edits

- update verified tool facts
- update stable path references
- update import registry rows
- update workflow docs through the public template protocol

## Require Explicit User Approval

- deleting files
- moving files out of this directory
- changing secrets handling policy
- replacing the whole workflow version
- publishing private machine facts

## Verification

Run after material edits:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "{{AGENTS_ROOT}}\tools\verify-agent-memory-workflow.ps1"
```

The verifier is the authority for structural integrity. Human review remains
the authority for whether machine facts are accurate.
