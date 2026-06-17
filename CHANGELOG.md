# Changelog

## 0.1.11 - 2026-06-17

- Added `agent-memory-workflow import-prompt` to print the exact instruction to
  give to a new local agent.
- Added `agent-memory-workflow import-prompt --json` for scripts that need the
  import prompt, bootstrap, receipt template, and registry paths.
- Added smoke coverage for the new import prompt command.

## 0.1.10 - 2026-06-17

- Added `agent-memory-workflow doctor --json` for machine-readable diagnostics.
- The doctor JSON report includes PowerShell availability, root/verifier checks,
  verifier JSON results, and top-level failures.
- Added smoke coverage that parses `doctor --json`.

## 0.1.9 - 2026-06-17

- Added JSON output to `verify-agent-memory-workflow.ps1` with `-Json`.
- Added `agent-memory-workflow verify --json`.
- Added smoke tests that parse verifier JSON from both PowerShell and the Node
  wrapper.

## 0.1.8 - 2026-06-17

- Added `--json` output for `preflight`, `status`, and `show-paths`.
- Added smoke tests that parse JSON output with PowerShell.
- Documented machine-readable CLI output in the Chinese and English READMEs.

## 0.1.7 - 2026-06-17

- Added a read-only CLI `preflight` command that checks runtime prerequisites,
  packaged source files, and target directory state before initialization.
- Documented the preflight command in the Chinese and English READMEs.
- Added smoke coverage for fresh and existing target preflight results.

## 0.1.6 - 2026-06-17

- Added a Node wrapper `upgrade` command for safe template upgrades of existing
  `.agents` directories.
- Documented the upgrade command in the Chinese and English READMEs.
- Added smoke coverage proving CLI upgrade preserves existing machine facts.

## 0.1.5 - 2026-06-17

- Strengthened the import prompt with a minimum durable memory record,
  persistence requirements, and fresh-session verification guidance.
- Added a receipt field for whether the durable bootstrap pointer was actually
  written.
- Extended verifier checks to require the new durable-import guidance.

## 0.1.4 - 2026-06-17

- Changed the CLI wrapper to reject unknown options and unexpected positional
  arguments instead of silently falling back to defaults.
- Added smoke tests for CLI argument validation failures.

## 0.1.3 - 2026-06-17

- Added CLI diagnostics: `status`, `show-paths`, `doctor`, and `--version`.
- Extended smoke tests to cover the new Node wrapper diagnostic commands.
- Documented diagnostic commands in the Chinese and English READMEs.

## 0.1.2 - 2026-06-17

- Added issue templates, a pull request template, `CONTRIBUTING.md`, and
  `SECURITY.md`.

## 0.1.1 - 2026-06-17

- Added GitHub Actions CI for pull requests and pushes to `main`.
- Added local smoke tests covering fresh installs, dry runs, forced upgrades,
  machine-fact preservation, explicit machine-fact overwrite, and CLI verify.
- Added safer initialization options: `-DryRun`, `-BackupRoot`, `-NoBackup`, and
  `-OverwriteMachineFacts`.
- Changed forced initialization to preserve existing `machine\` facts by default
  and back up overwritten files automatically.
- Added npm scripts for `check`, `test`, `pack:dry-run`, and `ci`.

## 0.1.0

- Initial public release of the local agent memory workflow.
- Added generic templates for `.agents`.
- Added PowerShell init and verification scripts.
- Added a minimal `npx` wrapper for local setup and verification.
