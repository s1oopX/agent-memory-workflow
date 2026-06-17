param(
    [string]$TargetRoot = (Join-Path $HOME ".agents"),
    [string]$SourceRoot,
    [switch]$Force,
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

$homeDir = [Environment]::GetFolderPath("UserProfile")
$userId = [Environment]::UserName
$osName = if ($IsWindows) { "Windows" } elseif ($IsMacOS) { "macOS" } else { "Linux" }

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
    if ((Test-Path -LiteralPath $targetPath -PathType Leaf) -and -not $Force) {
        throw "Target file already exists: $targetPath. Re-run with -Force to overwrite."
    }

    $targetDirectory = Split-Path -Parent $targetPath
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null

    $content = Get-Content -LiteralPath $sourcePath -Raw
    foreach ($entry in $replacements.GetEnumerator()) {
        $content = $content.Replace($entry.Key, $entry.Value)
    }

    Set-Content -LiteralPath $targetPath -Value $content -Encoding UTF8
}

if (-not $SkipVerify) {
    $verifier = Join-Path $targetRootPath "tools\verify-agent-memory-workflow.ps1"
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $verifier -Root $targetRootPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "Agent memory workflow initialized: $targetRootPath"
