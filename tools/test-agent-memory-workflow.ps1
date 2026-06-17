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
$packageJson = Get-Content -LiteralPath (Join-Path $sourceRootPath "package.json") -Raw | ConvertFrom-Json

try {
    New-Item -ItemType Directory -Path $base -Force | Out-Null

    Invoke-Step "fresh init passes verifier" {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -TargetRoot $target -SourceRoot $sourceRootPath
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

        $verifier = Join-Path $target "tools\verify-agent-memory-workflow.ps1"
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $verifier -Root $target
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    Invoke-Step "dry run leaves target unchanged" {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript -TargetRoot $dryRunTarget -SourceRoot $sourceRootPath -DryRun
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (Test-Path -LiteralPath $dryRunTarget) {
            throw "Dry run created target path: $dryRunTarget"
        }
    }

    Invoke-Step "node wrapper preflights fresh target" {
        $preflightOutput = (& node $cliScript preflight --target $dryRunTarget) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $preflightOutput -Needle "Target exists: no" -Context "fresh preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Target mode: fresh install" -Context "fresh preflight output"
        Assert-TextContains -Text $preflightOutput -Needle "Result: PASS" -Context "fresh preflight output"
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
    }

    Invoke-Step "node wrapper prints workflow paths" {
        $pathsOutput = (& node $cliScript show-paths --root $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $pathsOutput -Needle "bootstrap=" -Context "show-paths output"
        Assert-TextContains -Text $pathsOutput -Needle "manifest=" -Context "show-paths output"
        Assert-TextContains -Text $pathsOutput -Needle "verifier=" -Context "show-paths output"
    }

    Invoke-Step "node wrapper doctor runs verifier" {
        $doctorOutput = (& node $cliScript doctor --root $target) -join "`n"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        Assert-TextContains -Text $doctorOutput -Needle "Running verifier..." -Context "doctor output"
        Assert-TextContains -Text $doctorOutput -Needle "Agent memory workflow check: PASS" -Context "doctor output"
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
