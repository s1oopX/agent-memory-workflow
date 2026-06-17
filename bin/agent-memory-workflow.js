#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const repoRoot = path.resolve(__dirname, "..");
const packageJson = require("../package.json");

function usage() {
  console.log(`agent-memory-workflow

Usage:
  agent-memory-workflow init [--target <path>] [--force] [--dry-run] [--backup-root <path>] [--no-backup] [--overwrite-machine-facts] [--skip-verify]
  agent-memory-workflow verify [--root <path>]
  agent-memory-workflow status [--root <path>]
  agent-memory-workflow show-paths [--root <path>]
  agent-memory-workflow doctor [--root <path>]

Examples:
  agent-memory-workflow init --target "$HOME/.agents"
  agent-memory-workflow init --target "$HOME/.agents" --dry-run
  agent-memory-workflow verify --root "$HOME/.agents"
  agent-memory-workflow status --root "$HOME/.agents"
  agent-memory-workflow doctor --root "$HOME/.agents"
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

function workflowPaths(root) {
  return {
    root,
    bootstrap: path.join(root, "AGENT_BOOTSTRAP.md"),
    importPrompt: path.join(root, "AGENT_MEMORY_IMPORT_PROMPT.md"),
    receiptTemplate: path.join(root, "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md"),
    manifest: path.join(root, "AGENT_MEMORY_WORKFLOW_MANIFEST.json"),
    importRegistry: path.join(root, "imports", "IMPORT_REGISTRY.md"),
    machine: path.join(root, "machine"),
    machineMemory: path.join(root, "machine", "MACHINE_ENVIRONMENT_MEMORY.md"),
    quickReference: path.join(root, "machine", "AGENT_ENVIRONMENT_QUICK_REFERENCE.md"),
    homeMap: path.join(root, "machine", "HOME_DIRECTORY_MAP.md"),
    verifier: path.join(root, "tools", "verify-agent-memory-workflow.ps1"),
    initializer: path.join(root, "tools", "init-agent-memory-workflow.ps1"),
  };
}

function exists(filePath) {
  return fs.existsSync(filePath);
}

function readManifest(manifestPath) {
  if (!exists(manifestPath)) return undefined;
  try {
    return JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  } catch (error) {
    return { parseError: error.message };
  }
}

function formatPresent(filePath) {
  return exists(filePath) ? "present" : "missing";
}

function printStatus(root) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);
  const manifest = readManifest(paths.manifest);
  const machineFiles = [paths.machineMemory, paths.quickReference, paths.homeMap];
  const presentMachineFiles = machineFiles.filter(exists).length;

  console.log("Agent memory workflow status");
  console.log(`Root: ${resolvedRoot}`);
  console.log(`Root exists: ${exists(resolvedRoot) ? "yes" : "no"}`);
  console.log(`Manifest: ${formatPresent(paths.manifest)}`);
  if (manifest?.parseError) {
    console.log(`Manifest parse: failed (${manifest.parseError})`);
  } else if (manifest) {
    console.log(`Workflow version: ${manifest.version ?? "unknown"}`);
    console.log(`Owner user: ${manifest.owner_user ?? "unknown"}`);
    console.log(`OS: ${manifest.os_name ?? "unknown"}`);
  }
  console.log(`Bootstrap: ${formatPresent(paths.bootstrap)}`);
  console.log(`Import prompt: ${formatPresent(paths.importPrompt)}`);
  console.log(`Receipt template: ${formatPresent(paths.receiptTemplate)}`);
  console.log(`Machine facts: ${presentMachineFiles}/${machineFiles.length} key files present`);
  console.log(`Verifier: ${formatPresent(paths.verifier)}`);
  console.log(`Initializer: ${formatPresent(paths.initializer)}`);
  console.log("Run doctor: agent-memory-workflow doctor --root <path>");
}

function printPaths(root) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);
  console.log(`root=${paths.root}`);
  console.log(`bootstrap=${paths.bootstrap}`);
  console.log(`import_prompt=${paths.importPrompt}`);
  console.log(`receipt_template=${paths.receiptTemplate}`);
  console.log(`manifest=${paths.manifest}`);
  console.log(`import_registry=${paths.importRegistry}`);
  console.log(`machine=${paths.machine}`);
  console.log(`machine_memory=${paths.machineMemory}`);
  console.log(`quick_reference=${paths.quickReference}`);
  console.log(`home_map=${paths.homeMap}`);
  console.log(`verifier=${paths.verifier}`);
  console.log(`initializer=${paths.initializer}`);
}

function runDoctor(root) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);

  console.log(`Agent Memory Workflow ${packageJson.version}`);
  console.log(`Root: ${resolvedRoot}`);

  const pwshVersion = spawnSync("pwsh", ["--version"], { encoding: "utf8" });
  if (pwshVersion.error && pwshVersion.error.code === "ENOENT") {
    console.error("FAIL: PowerShell 7 executable `pwsh` was not found on PATH.");
    process.exit(127);
  }
  if (pwshVersion.error) {
    console.error(`FAIL: ${pwshVersion.error.message}`);
    process.exit(1);
  }
  console.log(`PowerShell: ${pwshVersion.stdout.trim() || "available"}`);

  if (!exists(resolvedRoot)) {
    console.error("FAIL: root does not exist.");
    process.exit(1);
  }
  if (!exists(paths.verifier)) {
    console.error(`FAIL: verifier is missing: ${paths.verifier}`);
    process.exit(1);
  }

  console.log("Running verifier...");
  const result = spawnSync(
    "pwsh",
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", paths.verifier, "-Root", resolvedRoot],
    { stdio: "inherit" }
  );
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

  if (command === "--version" || command === "-v" || command === "version") {
    console.log(packageJson.version);
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

  if (command === "status") {
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    printStatus(root);
    return;
  }

  if (command === "show-paths") {
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    printPaths(root);
    return;
  }

  if (command === "doctor") {
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    runDoctor(root);
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
