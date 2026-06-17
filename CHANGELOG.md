# Changelog

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
