# Changelog

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
