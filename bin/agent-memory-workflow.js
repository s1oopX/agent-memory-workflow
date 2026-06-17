#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const path = require("node:path");
const os = require("node:os");

const repoRoot = path.resolve(__dirname, "..");

function usage() {
  console.log(`agent-memory-workflow

Usage:
  agent-memory-workflow init [--target <path>] [--force] [--dry-run] [--backup-root <path>] [--no-backup] [--overwrite-machine-facts] [--skip-verify]
  agent-memory-workflow verify [--root <path>]

Examples:
  agent-memory-workflow init --target "$HOME/.agents"
  agent-memory-workflow init --target "$HOME/.agents" --dry-run
  agent-memory-workflow verify --root "$HOME/.agents"
`);
}

function readOption(args, name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  const value = args[index + 1];
  if (!value || value.startsWith("--")) {
    throw new Error(`Missing value for ${name}`);
  }
  return value;
}

function runPwsh(script, args) {
  const result = spawnSync(
    "pwsh",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, ...args],
    { stdio: "inherit" }
  );

  if (result.error && result.error.code === "ENOENT") {
    console.error("PowerShell 7 executable `pwsh` was not found on PATH.");
    console.error("Install PowerShell 7, then rerun this command.");
    process.exit(127);
  }

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  process.exit(result.status ?? 1);
}

function main() {
  const [, , command, ...args] = process.argv;

  if (!command || command === "help" || command === "--help" || command === "-h") {
    usage();
    return;
  }

  if (command === "init") {
    const target = readOption(args, "--target", path.join(os.homedir(), ".agents"));
    const backupRoot = readOption(args, "--backup-root", undefined);
    const script = path.join(repoRoot, "tools", "init-agent-memory-workflow.ps1");
    const psArgs = ["-TargetRoot", target, "-SourceRoot", repoRoot];
    if (backupRoot) psArgs.push("-BackupRoot", backupRoot);
    if (args.includes("--force")) psArgs.push("-Force");
    if (args.includes("--dry-run")) psArgs.push("-DryRun");
    if (args.includes("--no-backup")) psArgs.push("-NoBackup");
    if (args.includes("--overwrite-machine-facts")) psArgs.push("-OverwriteMachineFacts");
    if (args.includes("--skip-verify")) psArgs.push("-SkipVerify");
    runPwsh(script, psArgs);
    return;
  }

  if (command === "verify") {
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    const script = path.join(repoRoot, "tools", "verify-agent-memory-workflow.ps1");
    runPwsh(script, ["-Root", root]);
    return;
  }

  console.error(`Unknown command: ${command}`);
  usage();
  process.exit(2);
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(2);
}
