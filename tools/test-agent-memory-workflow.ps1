param(
    [string]$SourceRoot
)

$ErrorActionPreference = "Stop"

$scriptPath = [System.IO.Path]::GetFullPath($PSCommandPath)
if (-not $SourceRoot) {
    $SourceRoot = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $scriptPath) ".."))
}
$sourceRootPath = [System.IO.Path]::GetFullPath($SourceRoot)
$initScript = Join-Path $sourceRootPath "tools\init-agent-memory-workflow.ps1"
$cliScript = Join-Path $sourceRootPath "bin\agent-memory-workflow.js"

function Invoke-Step {
    param(
        [string]$Name,
        [scriptblock]$Script
    )

    Write-Host "TEST: $Name"
    & $Script
    Write-Host "PASS: $Name"
}

function Assert-FileContains {
    param(
        [string]$Path,
        [string]$Needle
    )

    $content = Get-Content -LiteralPath $Path -Raw
    if (-not $content.Contains($Needle)) {
        throw "Expected file to contain '$Needle': $Path"
    }
}

function Assert-FileDoesNotContain {
    param(
        [string]$Path,
        [string]$Needle
    )

    $content = Get-Content -LiteralPath $Path -Raw
    if ($content.Contains($Needle)) {
        throw "Expected file not to contain '$Needle': $Path"
    }
}

function Assert-TextContains {
    param(
        [string]$Text,
        [string]$Needle,
        [string]$Context
    )

    if (-not $Text.Contains($Needle)) {
        throw "Expected $Context to contain '$Needle'. Actual output: $Text"
    }
}

$base = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-memory-workflow-test-" + [guid]::NewGuid().ToString())
$target = Join-Path $base "install"
$dryRunTarget = Join-Path $base "dry-run"
$dryRunConflictTarget = Join-Path $base "dry-run-conflict"
$conflictTarget = Join-Path $base "conflict"
$sourceCopy = Join-Path $base "source-copy"
$packageJson = Get-Content -LiteralPath (Join-Path $sourceRootPath "package.json") -Raw | ConvertFrom-Json

try {
    New-Item -ItemType Directory -Path $base -Force | Out-Null

    Invoke-Step "fresh init passes verifier" {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -TargetRoot $target -SourceRoot $sourceRootPath
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        $verifier = Join-Path $target "tools\verify-agent-memory-workflow.ps1"
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $verifier -Root $target
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        $verifyJsonText = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $verifier -Root $target -Json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $verifyJson = $verifyJsonText | ConvertFrom-Json
        if (-not $verifyJson.ok -or $verifyJson.workflow_version -ne "workflow-v3") {
            throw "Unexpected verifier JSON: $verifyJsonText"
        }
    }

    Invoke-Step "dry run leaves target unchanged" {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -TargetRoot $dryRunTarget -SourceRoot $sourceRootPath -DryRun
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (Test-Path -LiteralPath $dryRunTarget) {
            throw "Dry run created target path: $dryRunTarget"
        }
    }

    Invoke-Step "dry run reports simulated conflicts as failure" {
        New-Item -ItemType Directory -Path $dryRunConflictTarget -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $dryRunConflictTarget "AGENT_BOOTSTRAP.md") -Value "# Existing unrelated file" -Encoding UTF8

        $dryRunOutput = (& node $cliScript init --target $dryRunConflictTarget --dry-run 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 1) {
            throw "Expected conflicting dry run to exit 1, got $LASTEXITCODE. Output: $dryRunOutput"
        }
        Assert-TextContains -Text $dryRunOutput -Needle "Would fail because target exists without -Force: AGENT_BOOTSTRAP.md" -Context "conflicting dry-run output"
        Assert-TextContains -Text $dryRunOutput -Needle "No files changed." -Context "conflicting dry-run output"
        Assert-TextContains -Text $dryRunOutput -Needle "Result: FAIL" -Context "conflicting dry-run output"
        if (Test-Path -LiteralPath (Join-Path $dryRunConflictTarget "AGENT_MEMORY_IMPORT_PROMPT.md")) {
            throw "Conflicting dry run wrote a new managed file."
        }
    }

    Invoke-Step "node wrapper preflights fresh target" {
        $preflightOutput = (& node $cliScript preflight --target $dryRunTarget) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $preflightOutput -Needle "Target exists: no" -Context "fresh preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Target mode: fresh install" -Context "fresh preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Result: PASS" -Context "fresh preflight output"

        $preflightJsonText = (& node $cliScript preflight --target $dryRunTarget --json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $preflightJson = $preflightJsonText | ConvertFrom-Json
        if (-not $preflightJson.ok -or $preflightJson.target.mode -ne "fresh install") {
            throw "Unexpected fresh preflight JSON: $preflightJsonText"
        }
    }

    Invoke-Step "node wrapper preflight catches non-workflow conflicts" {
        New-Item -ItemType Directory -Path $conflictTarget -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $conflictTarget "AGENT_BOOTSTRAP.md") -Value "# Existing unrelated file" -Encoding UTF8

        $preflightOutput = (& node $cliScript preflight --target $conflictTarget 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 1) {
            throw "Expected conflicting preflight to exit 1, got $LASTEXITCODE. Output: $preflightOutput"
        }
        Assert-TextContains -Text $preflightOutput -Needle "Target mode: existing non-workflow directory" -Context "conflicting preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Managed file conflicts: 1" -Context "conflicting preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Result: FAIL" -Context "conflicting preflight output"

        $preflightJsonText = (& node $cliScript preflight --target $conflictTarget --json 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 1) {
            throw "Expected conflicting preflight JSON to exit 1, got $LASTEXITCODE. Output: $preflightJsonText"
        }
        $preflightJson = $preflightJsonText | ConvertFrom-Json
        if ($preflightJson.ok -or $preflightJson.target.managed_files.present -ne 1) {
            throw "Unexpected conflicting preflight JSON: $preflightJsonText"
        }
        if ($preflightJson.target.managed_files.conflicts[0].relative_path -ne "AGENT_BOOTSTRAP.md") {
            throw "Unexpected conflicting managed file JSON: $preflightJsonText"
        }
    }

    Invoke-Step "node wrapper preflight catches missing managed source files" {
        Copy-Item -LiteralPath $sourceRootPath -Destination $sourceCopy -Recurse -Force
        $missingSourceFile = Join-Path $sourceCopy "templates\AGENT_MEMORY_WORKFLOW.md"
        Remove-Item -LiteralPath $missingSourceFile -Force

        $copiedCliScript = Join-Path $sourceCopy "bin\agent-memory-workflow.js"
        $preflightOutput = (& node $copiedCliScript preflight --target $dryRunTarget 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 1) {
            throw "Expected missing-source preflight to exit 1, got $LASTEXITCODE. Output: $preflightOutput"
        }
        Assert-TextContains -Text $preflightOutput -Needle "Managed source files: 19/20 present" -Context "missing-source preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Missing managed source file:" -Context "missing-source preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "AGENT_MEMORY_WORKFLOW.md" -Context "missing-source preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Result: FAIL" -Context "missing-source preflight output"

        $preflightJsonText = (& node $copiedCliScript preflight --target $dryRunTarget --json 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 1) {
            throw "Expected missing-source preflight JSON to exit 1, got $LASTEXITCODE. Output: $preflightJsonText"
        }
        $preflightJson = $preflightJsonText | ConvertFrom-Json
        if ($preflightJson.ok) {
            throw "Expected missing-source preflight JSON to fail: $preflightJsonText"
        }
        if ($preflightJson.sources.managed_files.present -ne 19 -or $preflightJson.sources.managed_files.total -ne 20) {
            throw "Unexpected managed source counts: $preflightJsonText"
        }
        if ($preflightJson.sources.managed_files.missing[0].relative_path -ne "AGENT_MEMORY_WORKFLOW.md") {
            throw "Unexpected missing managed source JSON: $preflightJsonText"
        }
    }

    Invoke-Step "force preserves machine facts by default" {
        $machineFile = Join-Path $target "machine\MACHINE_ENVIRONMENT_MEMORY.md"
        $sentinel = "LOCAL_SENTINEL_MACHINE_FACT"
        Set-Content -LiteralPath $machineFile -Value "# Local Machine Facts`n`n$sentinel" -Encoding UTF8

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -TargetRoot $target -SourceRoot $sourceRootPath -Force
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        Assert-FileContains -Path $machineFile -Needle $sentinel
        $backups = @(Get-ChildItem -LiteralPath (Join-Path $target ".backups") -Directory -ErrorAction SilentlyContinue)
        if ($backups.Count -lt 1) {
            throw "Expected at least one backup directory after force update."
        }
    }

    Invoke-Step "explicit machine overwrite works" {
        $machineFile = Join-Path $target "machine\MACHINE_ENVIRONMENT_MEMORY.md"
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -TargetRoot $target -SourceRoot $sourceRootPath -Force -OverwriteMachineFacts
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-FileDoesNotContain -Path $machineFile -Needle "LOCAL_SENTINEL_MACHINE_FACT"
    }

    Invoke-Step "node wrapper verifies installed target" {
        & node $cliScript verify --root $target
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        $verifyJsonText = (& node $cliScript verify --root $target --json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $verifyJson = $verifyJsonText | ConvertFrom-Json
        if (-not $verifyJson.ok -or $verifyJson.workflow_version -ne "workflow-v3") {
            throw "Unexpected node verify JSON: $verifyJsonText"
        }
    }

    Invoke-Step "node wrapper upgrades installed target" {
        $machineFile = Join-Path $target "machine\MACHINE_ENVIRONMENT_MEMORY.md"
        $sentinel = "LOCAL_SENTINEL_CLI_UPGRADE"
        Set-Content -LiteralPath $machineFile -Value "# Local Machine Facts`n`n$sentinel" -Encoding UTF8

        $upgradeOutput = (& node $cliScript upgrade --target $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        Assert-TextContains -Text $upgradeOutput -Needle "Preserving existing machine fact:" -Context "upgrade output"
        Assert-FileContains -Path $machineFile -Needle $sentinel
    }

    Invoke-Step "node wrapper preflights existing target" {
        $preflightOutput = (& node $cliScript preflight --target $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $preflightOutput -Needle "Target exists: yes" -Context "existing preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Target mode: existing workflow" -Context "existing preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Result: PASS" -Context "existing preflight output"
    }

    Invoke-Step "node wrapper prints package version" {
        $versionOutput = ((& node $cliScript --version) -join "`n").Trim()
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if ($versionOutput -ne $packageJson.version) {
            throw "Expected CLI version '$($packageJson.version)', got '$versionOutput'."
        }
    }

    Invoke-Step "node wrapper reports installed status" {
        $statusOutput = (& node $cliScript status --root $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $statusOutput -Needle "Workflow version: workflow-v3" -Context "status output"
        Assert-TextContains -Text $statusOutput -Needle "Bootstrap: present" -Context "status output"
        Assert-TextContains -Text $statusOutput -Needle "Verifier: present" -Context "status output"

        $statusJsonText = (& node $cliScript status --root $target --json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $statusJson = $statusJsonText | ConvertFrom-Json
        if (-not $statusJson.ok -or $statusJson.manifest.version -ne "workflow-v3") {
            throw "Unexpected status JSON: $statusJsonText"
        }
    }

    Invoke-Step "node wrapper prints workflow paths" {
        $pathsOutput = (& node $cliScript show-paths --root $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $pathsOutput -Needle "bootstrap=" -Context "show-paths output"
        Assert-TextContains -Text $pathsOutput -Needle "manifest=" -Context "show-paths output"
        Assert-TextContains -Text $pathsOutput -Needle "verifier=" -Context "show-paths output"

        $pathsJsonText = (& node $cliScript show-paths --root $target --json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $pathsJson = $pathsJsonText | ConvertFrom-Json
        if (-not $pathsJson.paths.bootstrap -or -not $pathsJson.paths.verifier) {
            throw "Unexpected show-paths JSON: $pathsJsonText"
        }
    }

    Invoke-Step "node wrapper prints import prompt instruction" {
        $importPromptOutput = (& node $cliScript import-prompt --root $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $importPromptOutput -Needle "Give this instruction to a local agent:" -Context "import-prompt output"
        Assert-TextContains -Text $importPromptOutput -Needle "Import registry: present" -Context "import-prompt output"
        Assert-TextContains -Text $importPromptOutput -Needle "AGENT_MEMORY_IMPORT_PROMPT.md" -Context "import-prompt output"
        Assert-TextContains -Text $importPromptOutput -Needle "local durable memory or persistent instruction layer" -Context "import-prompt output"

        $importPromptJsonText = (& node $cliScript import-prompt --root $target --json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $importPromptJson = $importPromptJsonText | ConvertFrom-Json
        if (
            -not $importPromptJson.ok -or
            -not $importPromptJson.paths.import_prompt -or
            -not $importPromptJson.paths.bootstrap -or
            -not $importPromptJson.checks.import_registry_exists
        ) {
            throw "Unexpected import-prompt JSON: $importPromptJsonText"
        }
        if (-not $importPromptJson.instruction.Contains("AGENT_MEMORY_IMPORT_PROMPT.md")) {
            throw "Import prompt instruction missing prompt path: $importPromptJsonText"
        }
    }

    Invoke-Step "node wrapper doctor runs verifier" {
        $doctorOutput = (& node $cliScript doctor --root $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $doctorOutput -Needle "Running verifier..." -Context "doctor output"
        Assert-TextContains -Text $doctorOutput -Needle "Agent memory workflow check: PASS" -Context "doctor output"

        $doctorJsonText = (& node $cliScript doctor --root $target --json) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if ($doctorJsonText.Contains("Running verifier...")) {
            throw "Expected doctor JSON output to exclude human text. Actual output: $doctorJsonText"
        }
        $doctorJson = $doctorJsonText | ConvertFrom-Json
        if (-not $doctorJson.ok -or -not $doctorJson.checks.root_exists -or -not $doctorJson.checks.verifier_exists) {
            throw "Unexpected doctor JSON checks: $doctorJsonText"
        }
        if (-not $doctorJson.verifier.ok -or $doctorJson.verifier.workflow_version -ne "workflow-v3") {
            throw "Unexpected doctor verifier JSON: $doctorJsonText"
        }
    }

    Invoke-Step "node wrapper rejects unknown options" {
        $unknownOutput = (& node $cliScript status --rooot $target 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 2) {
            throw "Expected unknown option to exit 2, got $LASTEXITCODE. Output: $unknownOutput"
        }
        Assert-TextContains -Text $unknownOutput -Needle "Unknown option: --rooot" -Context "unknown option output"

        $unexpectedOutput = (& node $cliScript status $target 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 2) {
            throw "Expected unexpected argument to exit 2, got $LASTEXITCODE. Output: $unexpectedOutput"
        }
        Assert-TextContains -Text $unexpectedOutput -Needle "Unexpected argument:" -Context "unexpected argument output"
    }

    Write-Host "Agent memory workflow smoke tests: PASS"
}
finally {
    $basePath = [System.IO.Path]::GetFullPath($base)
    $tempPath = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($basePath.StartsWith($tempPath, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $basePath)) {
        Remove-Item -LiteralPath $basePath -Recurse -Force
    }
}
