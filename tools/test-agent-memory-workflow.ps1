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

$base = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-memory-workflow-test-" + [guid]::NewGuid().ToString())
$target = Join-Path $base "install"
$dryRunTarget = Join-Path $base "dry-run"

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

    Write-Host "Agent memory workflow smoke tests: PASS"
}
finally {
    $basePath = [System.IO.Path]::GetFullPath($base)
    $tempPath = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($basePath.StartsWith($tempPath, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $basePath)) {
        Remove-Item -LiteralPath $basePath -Recurse -Force
    }
}
