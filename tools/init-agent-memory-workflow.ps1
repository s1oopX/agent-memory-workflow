param(
    [string]$TargetRoot = (Join-Path $HOME ".agents"),
    [string]$SourceRoot,
    [string]$BackupRoot,
    [switch]$Force,
    [switch]$DryRun,
    [switch]$NoBackup,
    [switch]$OverwriteMachineFacts,
    [switch]$SkipVerify
)

$ErrorActionPreference = "Stop"

$scriptPath = [System.IO.Path]::GetFullPath($PSCommandPath)
$defaultSourceRoot = [System.IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $scriptPath) ".."))
if (-not $SourceRoot) {
    $SourceRoot = $defaultSourceRoot
}

$sourceRootPath = [System.IO.Path]::GetFullPath($SourceRoot)
$targetRootPath = [System.IO.Path]::GetFullPath($TargetRoot)
$backupRootPath = $null
if ($BackupRoot) {
    $backupRootPath = [System.IO.Path]::GetFullPath($BackupRoot)
}
$templateRootPath = Join-Path $sourceRootPath "templates"
if (-not (Test-Path -LiteralPath $templateRootPath -PathType Container)) {
    throw "Template directory not found: $templateRootPath"
}

$managedFiles = @(
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
    "imports\README.md",
    "imports\IMPORT_REGISTRY.md",
    "machine\MACHINE_ENVIRONMENT_MEMORY.md",
    "machine\AGENT_EXECUTION_PLAYBOOK.md",
    "machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md",
    "machine\HOME_DIRECTORY_MAP.md",
    "machine\MAINTENANCE_POLICY.md",
    "tools\verify-agent-memory-workflow.ps1",
    "tools\init-agent-memory-workflow.ps1"
)

function ConvertTo-JsonStringContent {
    param([string]$Value)
    return ($Value | ConvertTo-Json -Compress).Trim('"')
}

function Get-SourcePath {
    param([string]$RelativePath)

    if ($RelativePath.StartsWith("tools\")) {
        return (Join-Path $sourceRootPath $RelativePath)
    }

    return (Join-Path $templateRootPath $RelativePath)
}

function Test-IsMachineFact {
    param([string]$RelativePath)
    return $RelativePath.StartsWith("machine\", [System.StringComparison]::OrdinalIgnoreCase)
}

function Add-Action {
    param([string]$Message)
    $script:actions.Add($Message) | Out-Null
}

function Get-BackupRoot {
    if (-not $script:backupRootPath) {
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
        $script:backupRootPath = Join-Path $targetRootPath ".backups\agent-memory-workflow-$timestamp"
    }
    return $script:backupRootPath
}

function Backup-TargetFile {
    param(
        [string]$TargetPath,
        [string]$RelativePath
    )

    if ($NoBackup) {
        if ($DryRun) {
            Add-Action "Would skip backup for existing file: $RelativePath"
        }
        else {
            Add-Action "Skipping backup for existing file: $RelativePath"
        }
        return
    }

    $root = Get-BackupRoot
    $backupPath = Join-Path $root $RelativePath
    if ($DryRun) {
        Add-Action "Would back up existing file: $RelativePath"
        return
    }

    Add-Action "Backing up existing file: $RelativePath"
    New-Item -ItemType Directory -Path (Split-Path -Parent $backupPath) -Force | Out-Null
    Copy-Item -LiteralPath $TargetPath -Destination $backupPath -Force
}

$homeDir = [Environment]::GetFolderPath("UserProfile")
$userId = [Environment]::UserName
$osName = if ($IsWindows) { "Windows" } elseif ($IsMacOS) { "macOS" } else { "Linux" }
$actions = New-Object System.Collections.Generic.List[string]
$dryRunFailures = New-Object System.Collections.Generic.List[string]

$replacements = [ordered]@{}
$replacements["{{AGENTS_ROOT_JSON}}"] = ConvertTo-JsonStringContent $targetRootPath
$replacements["{{HOME_DIR_JSON}}"] = ConvertTo-JsonStringContent $homeDir
$replacements["{{AGENTS_ROOT}}"] = $targetRootPath
$replacements["{{HOME_DIR}}"] = $homeDir
$replacements["{{USER_ID}}"] = $userId
$replacements["{{OS_NAME}}"] = $osName
$replacements["{{GENERATED_UTC}}"] = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

foreach ($relativePath in $managedFiles) {
    $sourcePath = Get-SourcePath $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing source file: $sourcePath"
    }

    $targetPath = Join-Path $targetRootPath $relativePath
    $targetExists = Test-Path -LiteralPath $targetPath -PathType Leaf

    if ($targetExists) {
        if (-not $Force) {
            if ($DryRun) {
                $message = "Would fail because target exists without -Force: $relativePath"
                Add-Action $message
                $dryRunFailures.Add($message) | Out-Null
                continue
            }
            throw "Target file already exists: $targetPath. Re-run with -Force to overwrite."
        }

        if ((Test-IsMachineFact $relativePath) -and -not $OverwriteMachineFacts) {
            Add-Action "Preserving existing machine fact: $relativePath"
            continue
        }

        Backup-TargetFile -TargetPath $targetPath -RelativePath $relativePath
        if ($DryRun) {
            Add-Action "Would overwrite file: $relativePath"
        }
        else {
            Add-Action "Overwriting file: $relativePath"
        }
    }
    else {
        if ($DryRun) {
            Add-Action "Would create file: $relativePath"
        }
        else {
            Add-Action "Creating file: $relativePath"
        }
    }

    $targetDirectory = Split-Path -Parent $targetPath
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    $content = Get-Content -LiteralPath $sourcePath -Raw
    foreach ($entry in $replacements.GetEnumerator()) {
        $content = $content.Replace($entry.Key, $entry.Value)
    }

    if (-not $DryRun) {
        Set-Content -LiteralPath $targetPath -Value $content -Encoding UTF8
    }
}

if ($DryRun) {
    Write-Host "Agent memory workflow dry run: $targetRootPath"
    foreach ($action in $actions) {
        Write-Host "- $action"
    }
    Write-Host "No files changed."
    if ($dryRunFailures.Count -gt 0) {
        Write-Host "Result: FAIL"
        exit 1
    }
    Write-Host "Result: PASS"
    exit 0
}

if (-not $SkipVerify) {
    $verifier = Join-Path $targetRootPath "tools\verify-agent-memory-workflow.ps1"
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $verifier -Root $targetRootPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "Agent memory workflow initialized: $targetRootPath"
foreach ($action in $actions) {
    Write-Host "- $action"
}
if ($backupRootPath -and (Test-Path -LiteralPath $backupRootPath -PathType Container)) {
    Write-Host "Backup written: $backupRootPath"
}
