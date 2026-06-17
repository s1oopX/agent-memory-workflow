#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const repoRoot = path.resolve(__dirname, "..");
const packageJson = require("../package.json");

const managedRelativePaths = [
  "AGENT_BOOTSTRAP.md",
  "AGENT_MEMORY_IMPORT_PROMPT.md",
  "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
  "AGENT_MEMORY_WORKFLOW.md",
  "AGENT_MEMORY_WORKFLOW_CHANGELOG.md",
  "AGENT_MEMORY_WORKFLOW_MANIFEST.json",
  "AGENT_PLATFORM_ADAPTERS.md",
  "AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md",
  "AGENT_WORKFLOW_REPLICATION_STRATEGY.md",
  "AGENTS.md",
  "README.md",
  path.join("imports", "README.md"),
  path.join("imports", "IMPORT_REGISTRY.md"),
  path.join("machine", "MACHINE_ENVIRONMENT_MEMORY.md"),
  path.join("machine", "AGENT_EXECUTION_PLAYBOOK.md"),
  path.join("machine", "AGENT_ENVIRONMENT_QUICK_REFERENCE.md"),
  path.join("machine", "HOME_DIRECTORY_MAP.md"),
  path.join("machine", "MAINTENANCE_POLICY.md"),
  path.join("tools", "verify-agent-memory-workflow.ps1"),
  path.join("tools", "init-agent-memory-workflow.ps1"),
];

function usage() {
  console.log(`agent-memory-workflow

Usage:
  agent-memory-workflow init [--target <path>] [--force] [--dry-run] [--backup-root <path>] [--no-backup] [--overwrite-machine-facts] [--skip-verify]
  agent-memory-workflow upgrade [--target <path>] [--dry-run] [--backup-root <path>] [--no-backup] [--overwrite-machine-facts] [--skip-verify]
  agent-memory-workflow preflight [--target <path>] [--json]
  agent-memory-workflow verify [--root <path>] [--json]
  agent-memory-workflow status [--root <path>] [--json]
  agent-memory-workflow show-paths [--root <path>] [--json]
  agent-memory-workflow import-prompt [--root <path>] [--json]
  agent-memory-workflow doctor [--root <path>] [--json]

Examples:
  agent-memory-workflow init --target "$HOME/.agents"
  agent-memory-workflow init --target "$HOME/.agents" --dry-run
  agent-memory-workflow preflight --target "$HOME/.agents"
  agent-memory-workflow upgrade --target "$HOME/.agents"
  agent-memory-workflow verify --root "$HOME/.agents"
  agent-memory-workflow status --root "$HOME/.agents"
  agent-memory-workflow import-prompt --root "$HOME/.agents"
  agent-memory-workflow doctor --root "$HOME/.agents"
  agent-memory-workflow doctor --root "$HOME/.agents" --json
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

function validateOptions(args, { valueOptions = [], flagOptions = [] }) {
  const optionsWithValues = new Set(valueOptions);
  const flags = new Set(flagOptions);

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (!arg.startsWith("--")) {
      throw new Error(`Unexpected argument: ${arg}`);
    }

    if (optionsWithValues.has(arg)) {
      const value = args[index + 1];
      if (!value || value.startsWith("--")) {
        throw new Error(`Missing value for ${arg}`);
      }
      index += 1;
      continue;
    }

    if (flags.has(arg)) {
      continue;
    }

    throw new Error(`Unknown option: ${arg}`);
  }
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

function fileStatus(filePath) {
  return {
    path: filePath,
    status: formatPresent(filePath),
  };
}

function managedFileStatus(root, relativePath) {
  const filePath = path.join(root, relativePath);
  return {
    relative_path: relativePath,
    path: filePath,
    status: formatPresent(filePath),
  };
}

function printJson(value) {
  console.log(JSON.stringify(value, null, 2));
}

function buildStatus(root) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);
  const manifest = readManifest(paths.manifest);
  const machineFiles = [paths.machineMemory, paths.quickReference, paths.homeMap];
  const presentMachineFiles = machineFiles.filter(exists).length;

  return {
    command: "status",
    ok: exists(resolvedRoot) && Boolean(manifest) && !manifest?.parseError,
    root: resolvedRoot,
    root_exists: exists(resolvedRoot),
    manifest: {
      path: paths.manifest,
      status: formatPresent(paths.manifest),
      parse_error: manifest?.parseError ?? null,
      version: manifest && !manifest.parseError ? manifest.version ?? null : null,
      owner_user: manifest && !manifest.parseError ? manifest.owner_user ?? null : null,
      os_name: manifest && !manifest.parseError ? manifest.os_name ?? null : null,
    },
    files: {
      bootstrap: fileStatus(paths.bootstrap),
      import_prompt: fileStatus(paths.importPrompt),
      receipt_template: fileStatus(paths.receiptTemplate),
      verifier: fileStatus(paths.verifier),
      initializer: fileStatus(paths.initializer),
    },
    machine_facts: {
      present: presentMachineFiles,
      total: machineFiles.length,
      files: machineFiles.map(fileStatus),
    },
    next_command: "agent-memory-workflow doctor --root <path>",
  };
}

function printStatus(root, { json = false } = {}) {
  const status = buildStatus(root);
  if (json) {
    printJson(status);
    return;
  }

  console.log("Agent memory workflow status");
  console.log(`Root: ${status.root}`);
  console.log(`Root exists: ${status.root_exists ? "yes" : "no"}`);
  console.log(`Manifest: ${status.manifest.status}`);
  if (status.manifest.parse_error) {
    console.log(`Manifest parse: failed (${status.manifest.parse_error})`);
  } else if (status.manifest.status === "present") {
    console.log(`Workflow version: ${status.manifest.version ?? "unknown"}`);
    console.log(`Owner user: ${status.manifest.owner_user ?? "unknown"}`);
    console.log(`OS: ${status.manifest.os_name ?? "unknown"}`);
  }
  console.log(`Bootstrap: ${status.files.bootstrap.status}`);
  console.log(`Import prompt: ${status.files.import_prompt.status}`);
  console.log(`Receipt template: ${status.files.receipt_template.status}`);
  console.log(`Machine facts: ${status.machine_facts.present}/${status.machine_facts.total} key files present`);
  console.log(`Verifier: ${status.files.verifier.status}`);
  console.log(`Initializer: ${status.files.initializer.status}`);
  console.log(`Run doctor: ${status.next_command}`);
}

function buildPaths(root) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);
  return {
    command: "show-paths",
    paths: {
      root: paths.root,
      bootstrap: paths.bootstrap,
      import_prompt: paths.importPrompt,
      receipt_template: paths.receiptTemplate,
      manifest: paths.manifest,
      import_registry: paths.importRegistry,
      machine: paths.machine,
      machine_memory: paths.machineMemory,
      quick_reference: paths.quickReference,
      home_map: paths.homeMap,
      verifier: paths.verifier,
      initializer: paths.initializer,
    },
  };
}

function printPaths(root, { json = false } = {}) {
  const result = buildPaths(root);
  if (json) {
    printJson(result);
    return;
  }

  for (const [key, value] of Object.entries(result.paths)) {
    console.log(`${key}=${value}`);
  }
}

function buildImportPrompt(root) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);
  const failures = [];
  const checks = {
    root_exists: exists(resolvedRoot),
    import_prompt_exists: exists(paths.importPrompt),
    bootstrap_exists: exists(paths.bootstrap),
    receipt_template_exists: exists(paths.receiptTemplate),
    import_registry_exists: exists(paths.importRegistry),
  };

  if (!checks.root_exists) failures.push("Root does not exist.");
  if (!checks.import_prompt_exists) failures.push(`Import prompt is missing: ${paths.importPrompt}`);
  if (!checks.bootstrap_exists) failures.push(`Bootstrap is missing: ${paths.bootstrap}`);
  if (!checks.receipt_template_exists) {
    failures.push(`Receipt template is missing: ${paths.receiptTemplate}`);
  }
  if (!checks.import_registry_exists) failures.push(`Import registry is missing: ${paths.importRegistry}`);

  return {
    command: "import-prompt",
    ok: failures.length === 0,
    root: resolvedRoot,
    instruction: `Read ${paths.importPrompt} and import it into your local durable memory or persistent instruction layer.`,
    paths: {
      import_prompt: paths.importPrompt,
      bootstrap: paths.bootstrap,
      receipt_template: paths.receiptTemplate,
      import_registry: paths.importRegistry,
    },
    checks,
    failures,
  };
}

function printImportPrompt(root, { json = false } = {}) {
  const result = buildImportPrompt(root);
  if (json) {
    printJson(result);
    if (!result.ok) process.exit(1);
    return;
  }

  console.log("Agent memory workflow import prompt");
  console.log(`Root: ${result.root}`);
  console.log(`Import prompt: ${result.checks.import_prompt_exists ? "present" : "missing"}`);
  console.log(`Bootstrap: ${result.checks.bootstrap_exists ? "present" : "missing"}`);
  console.log(`Receipt template: ${result.checks.receipt_template_exists ? "present" : "missing"}`);
  console.log(`Import registry: ${result.checks.import_registry_exists ? "present" : "missing"}`);

  if (!result.ok) {
    console.log("Result: FAIL");
    for (const failure of result.failures) {
      console.log(`- ${failure}`);
    }
    process.exit(1);
  }

  console.log("Give this instruction to a local agent:");
  console.log(result.instruction);
}

function sourcePaths() {
  return {
    templates: path.join(repoRoot, "templates"),
    bootstrapTemplate: path.join(repoRoot, "templates", "AGENT_BOOTSTRAP.md"),
    initializer: path.join(repoRoot, "tools", "init-agent-memory-workflow.ps1"),
    verifier: path.join(repoRoot, "tools", "verify-agent-memory-workflow.ps1"),
  };
}

function buildPreflight(target) {
  const resolvedTarget = path.resolve(target);
  const paths = workflowPaths(resolvedTarget);
  const sources = sourcePaths();
  const failures = [];
  let powershell = { status: "available", version: null, error: null };

  const pwshVersion = spawnSync("pwsh", ["--version"], { encoding: "utf8" });
  if (pwshVersion.error && pwshVersion.error.code === "ENOENT") {
    failures.push("PowerShell 7 executable `pwsh` was not found on PATH.");
    powershell = { status: "missing", version: null, error: failures[failures.length - 1] };
  } else if (pwshVersion.error) {
    failures.push(pwshVersion.error.message);
    powershell = { status: "error", version: null, error: pwshVersion.error.message };
  } else {
    powershell = { status: "available", version: pwshVersion.stdout.trim() || null, error: null };
  }

  if (!exists(sources.templates)) failures.push(`Missing source templates: ${sources.templates}`);
  if (!exists(sources.bootstrapTemplate)) failures.push(`Missing bootstrap template: ${sources.bootstrapTemplate}`);
  if (!exists(sources.initializer)) failures.push(`Missing source initializer: ${sources.initializer}`);
  if (!exists(sources.verifier)) failures.push(`Missing source verifier: ${sources.verifier}`);

  const manifest = readManifest(paths.manifest);
  const targetExists = exists(resolvedTarget);
  let targetMode = "fresh install";
  if (targetExists && manifest && !manifest.parseError) {
    targetMode = "existing workflow";
  } else if (targetExists) {
    targetMode = "existing non-workflow directory";
  }
  const managedFiles = managedRelativePaths.map((relativePath) => managedFileStatus(resolvedTarget, relativePath));
  const presentManagedFiles = managedFiles.filter((file) => file.status === "present");
  const hasNonWorkflowManagedFileConflicts =
    targetMode === "existing non-workflow directory" && presentManagedFiles.length > 0;
  if (hasNonWorkflowManagedFileConflicts) {
    failures.push(
      "Existing non-workflow target contains workflow-managed files. Choose a different target, remove the conflicts, or review and rerun init with --force."
    );
  }

  return {
    command: "preflight",
    ok: failures.length === 0,
    cli_version: packageJson.version,
    node: process.version,
    powershell,
    sources: {
      templates: fileStatus(sources.templates),
      bootstrap_template: fileStatus(sources.bootstrapTemplate),
      initializer: fileStatus(sources.initializer),
      verifier: fileStatus(sources.verifier),
    },
    target: {
      path: resolvedTarget,
      exists: targetExists,
      mode: targetMode,
      managed_files: {
        present: presentManagedFiles.length,
        total: managedFiles.length,
        conflicts: hasNonWorkflowManagedFileConflicts ? presentManagedFiles : [],
      },
      manifest: {
        path: paths.manifest,
        status: formatPresent(paths.manifest),
        parse_error: manifest?.parseError ?? null,
        version: manifest && !manifest.parseError ? manifest.version ?? null : null,
      },
    },
    failures,
  };
}

function runPreflight(target, { json = false } = {}) {
  const result = buildPreflight(target);
  if (json) {
    printJson(result);
    if (!result.ok) process.exit(1);
    return;
  }

  console.log("Agent memory workflow preflight");
  console.log(`CLI version: ${result.cli_version}`);
  console.log(`Node: ${result.node}`);
  if (result.powershell.status === "available") {
    console.log(`PowerShell: ${result.powershell.version ?? "available"}`);
  } else {
    console.log(`PowerShell: ${result.powershell.status}`);
  }
  console.log(`Source templates: ${result.sources.templates.status}`);
  console.log(`Bootstrap template: ${result.sources.bootstrap_template.status}`);
  console.log(`Source initializer: ${result.sources.initializer.status}`);
  console.log(`Source verifier: ${result.sources.verifier.status}`);
  console.log(`Target: ${result.target.path}`);
  console.log(`Target exists: ${result.target.exists ? "yes" : "no"}`);
  console.log(`Target manifest: ${result.target.manifest.status}`);
  console.log(`Managed file conflicts: ${result.target.managed_files.conflicts.length}`);
  if (result.target.manifest.parse_error) {
    console.log(`Target manifest parse: failed (${result.target.manifest.parse_error})`);
  } else if (result.target.manifest.version) {
    console.log(`Target workflow version: ${result.target.manifest.version}`);
  }
  console.log(`Target mode: ${result.target.mode}`);

  if (!result.ok) {
    console.log("Result: FAIL");
    for (const failure of result.failures) {
      console.log(`- ${failure}`);
    }
    process.exit(1);
  }

  console.log("Result: PASS");
}

function runDoctor(root, { json = false } = {}) {
  const resolvedRoot = path.resolve(root);
  const paths = workflowPaths(resolvedRoot);
  const failures = [];
  let powershell = { status: "available", version: null, error: null };

  const pwshVersion = spawnSync("pwsh", ["--version"], { encoding: "utf8" });
  if (pwshVersion.error && pwshVersion.error.code === "ENOENT") {
    const message = "PowerShell 7 executable `pwsh` was not found on PATH.";
    powershell = { status: "missing", version: null, error: message };
    failures.push(message);
  } else if (pwshVersion.error) {
    powershell = { status: "error", version: null, error: pwshVersion.error.message };
    failures.push(pwshVersion.error.message);
  } else {
    powershell = { status: "available", version: pwshVersion.stdout.trim() || null, error: null };
  }

  const checks = {
    root_exists: exists(resolvedRoot),
    verifier_exists: exists(paths.verifier),
  };

  if (!checks.root_exists) failures.push("Root does not exist.");
  if (!checks.verifier_exists) failures.push(`Verifier is missing: ${paths.verifier}`);

  if (json) {
    let verifier = null;
    let verifierExitCode = null;
    let verifierParseError = null;
    let verifierStdout = null;
    let verifierStderr = null;

    if (failures.length === 0) {
      const result = spawnSync(
        "pwsh",
        [
          "-NoProfile",
          "-ExecutionPolicy",
          "Bypass",
          "-File",
          paths.verifier,
          "-Root",
          resolvedRoot,
          "-Json",
        ],
        { encoding: "utf8" }
      );

      verifierExitCode = result.status ?? null;
      verifierStderr = result.stderr?.trim() || null;

      if (result.error) {
        failures.push(result.error.message);
      } else {
        const stdout = result.stdout?.trim() || "";
        if (stdout) {
          try {
            verifier = JSON.parse(stdout);
          } catch (error) {
            verifierParseError = error.message;
            verifierStdout = stdout;
            failures.push(`Verifier JSON parse failed: ${error.message}`);
          }
        } else {
          verifierParseError = "Verifier produced no stdout.";
          failures.push(verifierParseError);
        }

        if (result.status !== 0) failures.push("Verifier failed.");
        if (verifier && verifier.ok !== true) failures.push("Verifier reported failures.");
      }
    }

    const report = {
      command: "doctor",
      ok: failures.length === 0,
      cli_version: packageJson.version,
      root: resolvedRoot,
      powershell,
      checks,
      verifier,
      verifier_exit_code: verifierExitCode,
      verifier_parse_error: verifierParseError,
      verifier_stdout: verifierStdout,
      verifier_stderr: verifierStderr,
      failures,
    };

    printJson(report);
    if (!report.ok) process.exit(powershell.status === "missing" ? 127 : 1);
    return;
  }

  console.log(`Agent Memory Workflow ${packageJson.version}`);
  console.log(`Root: ${resolvedRoot}`);

  if (powershell.status === "missing") {
    console.error("FAIL: PowerShell 7 executable `pwsh` was not found on PATH.");
    process.exit(127);
  }
  if (powershell.status === "error") {
    console.error(`FAIL: ${powershell.error}`);
    process.exit(1);
  }
  console.log(`PowerShell: ${powershell.version ?? "available"}`);

  if (!checks.root_exists) {
    console.error("FAIL: root does not exist.");
    process.exit(1);
  }
  if (!checks.verifier_exists) {
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

function runInit(args, { force = false } = {}) {
  validateOptions(args, {
    valueOptions: ["--target", "--backup-root"],
    flagOptions: ["--force", "--dry-run", "--no-backup", "--overwrite-machine-facts", "--skip-verify"],
  });
  const target = readOption(args, "--target", path.join(os.homedir(), ".agents"));
  const backupRoot = readOption(args, "--backup-root", undefined);
  const script = path.join(repoRoot, "tools", "init-agent-memory-workflow.ps1");
  const psArgs = ["-TargetRoot", target, "-SourceRoot", repoRoot];
  if (backupRoot) psArgs.push("-BackupRoot", backupRoot);
  if (force || args.includes("--force")) psArgs.push("-Force");
  if (args.includes("--dry-run")) psArgs.push("-DryRun");
  if (args.includes("--no-backup")) psArgs.push("-NoBackup");
  if (args.includes("--overwrite-machine-facts")) psArgs.push("-OverwriteMachineFacts");
  if (args.includes("--skip-verify")) psArgs.push("-SkipVerify");
  runPwsh(script, psArgs);
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
    runInit(args);
    return;
  }

  if (command === "preflight") {
    validateOptions(args, { valueOptions: ["--target"], flagOptions: ["--json"] });
    const target = readOption(args, "--target", path.join(os.homedir(), ".agents"));
    runPreflight(target, { json: args.includes("--json") });
    return;
  }

  if (command === "upgrade") {
    runInit(args, { force: true });
    return;
  }

  if (command === "verify") {
    validateOptions(args, { valueOptions: ["--root"], flagOptions: ["--json"] });
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    const script = path.join(repoRoot, "tools", "verify-agent-memory-workflow.ps1");
    const psArgs = ["-Root", root];
    if (args.includes("--json")) psArgs.push("-Json");
    runPwsh(script, psArgs);
    return;
  }

  if (command === "status") {
    validateOptions(args, { valueOptions: ["--root"], flagOptions: ["--json"] });
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    printStatus(root, { json: args.includes("--json") });
    return;
  }

  if (command === "show-paths") {
    validateOptions(args, { valueOptions: ["--root"], flagOptions: ["--json"] });
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    printPaths(root, { json: args.includes("--json") });
    return;
  }

  if (command === "import-prompt") {
    validateOptions(args, { valueOptions: ["--root"], flagOptions: ["--json"] });
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    printImportPrompt(root, { json: args.includes("--json") });
    return;
  }

  if (command === "doctor") {
    validateOptions(args, { valueOptions: ["--root"], flagOptions: ["--json"] });
    const root = readOption(args, "--root", path.join(os.homedir(), ".agents"));
    runDoctor(root, { json: args.includes("--json") });
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
