param(
    [string]$Root,
    [switch]$TemplateMode
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
    $scriptDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($PSCommandPath))
    $Root = [System.IO.Path]::GetFullPath((Join-Path $scriptDirectory ".."))
}

$rootPath = [System.IO.Path]::GetFullPath($Root)
$currentVersion = "workflow-v3"
$requiredFiles = @(
    "AGENT_BOOTSTRAP.md",
    "AGENT_MEMORY_IMPORT_PROMPT.md",
    "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
    "AGENT_MEMORY_WORKFLOW.md",
    "AGENT_MEMORY_WORKFLOW_CHANGELOG.md",
    "AGENT_MEMORY_WORKFLOW_MANIFEST.json",
    "AGENT_PLATFORM_ADAPTERS.md",
    "AGENT_WORKFLOW_REPLICATION_STRATEGY.md",
    "AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md",
    "AGENTS.md",
    "README.md",
    "imports\README.md",
    "imports\IMPORT_REGISTRY.md",
    "machine\MACHINE_ENVIRONMENT_MEMORY.md",
    "machine\AGENT_EXECUTION_PLAYBOOK.md",
    "machine\AGENT_ENVIRONMENT_QUICK_REFERENCE.md",
    "machine\HOME_DIRECTORY_MAP.md",
    "machine\MAINTENANCE_POLICY.md"
)

if (-not $TemplateMode) {
    $requiredFiles += @(
    "tools\verify-agent-memory-workflow.ps1",
    "tools\init-agent-memory-workflow.ps1"
    )
}

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message) | Out-Null
}

function Read-Text {
    param([string]$RelativePath)
    $path = Join-Path $rootPath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing file: $RelativePath"
        return ""
    }
    return Get-Content -LiteralPath $path -Raw
}

function Expected-Path {
    param([string]$RelativePath)
    return [System.IO.Path]::GetFullPath((Join-Path $rootPath $RelativePath))
}

foreach ($file in $requiredFiles) {
    $path = Join-Path $rootPath $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required file: $file"
    }
}

$scannedFiles = @(
    foreach ($file in $requiredFiles) {
        $path = Join-Path $rootPath $file
        if (
            (Test-Path -LiteralPath $path -PathType Leaf) -and
            ([System.IO.Path]::GetExtension($path) -in @(".md", ".json", ".ps1")) -and
            ($path -ne $PSCommandPath)
        ) {
            Get-Item -LiteralPath $path
        }
    }
)
$allText = ($scannedFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"

$secretPatterns = @(
    ("12" + "3456"),
    "password\s*:",
    ("require" + "pass\s+\S+"),
    ("REDISCLI" + "_AUTH\s*="),
    ("MYSQL" + "_PWD\s*="),
    ("root\s+" + "12" + "3456")
)

foreach ($pattern in $secretPatterns) {
    if ($allText -match $pattern) {
        Add-Failure "Potential secret pattern found: $pattern"
    }
}

$versionFiles = @(
    "AGENT_MEMORY_IMPORT_PROMPT.md",
    "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
    "AGENT_MEMORY_WORKFLOW.md",
    "imports\IMPORT_REGISTRY.md"
)

foreach ($file in $versionFiles) {
    $text = Read-Text $file
    if ($text -notmatch [regex]::Escape($currentVersion)) {
        Add-Failure "Missing $currentVersion marker: $file"
    }
}

$referenceChecks = @{
    "AGENT_BOOTSTRAP.md" = @(
        "AGENT_MEMORY_IMPORT_PROMPT.md",
        "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
        "AGENT_MEMORY_WORKFLOW.md",
        "imports",
        "machine\MACHINE_ENVIRONMENT_MEMORY.md"
    )
    "AGENT_MEMORY_IMPORT_PROMPT.md" = @(
        "AGENT_BOOTSTRAP.md",
        "Minimum Durable Memory Record",
        "Persistence Requirements",
        "Fresh Session Verification",
        "MACHINE_ENVIRONMENT_MEMORY.md",
        "AGENT_EXECUTION_PLAYBOOK.md",
        "AGENT_ENVIRONMENT_QUICK_REFERENCE.md",
        "HOME_DIRECTORY_MAP.md",
        "MAINTENANCE_POLICY.md",
        "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
        "AGENT_PLATFORM_ADAPTERS.md",
        "imports\IMPORT_REGISTRY.md"
    )
    "AGENT_MEMORY_WORKFLOW.md" = @(
        "AGENT_MEMORY_IMPORT_PROMPT.md",
        "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
        "AGENT_MEMORY_WORKFLOW_MANIFEST.json",
        "AGENT_MEMORY_WORKFLOW_CHANGELOG.md",
        "AGENT_PLATFORM_ADAPTERS.md",
        "AGENT_WORKFLOW_REPLICATION_STRATEGY.md",
        "AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md",
        "imports\IMPORT_REGISTRY.md",
        "AGENT_BOOTSTRAP.md",
        "machine"
    )
    "imports\README.md" = @(
        "AGENT_MEMORY_IMPORT_PROMPT.md",
        "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
        "IMPORT_REGISTRY.md"
    )
    "imports\IMPORT_REGISTRY.md" = @(
        "AGENT_MEMORY_IMPORT_PROMPT.md",
        "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md",
        $currentVersion
    )
    "AGENT_MEMORY_WORKFLOW_CHANGELOG.md" = @(
        $currentVersion,
        "Reimport Policy",
        "AGENT_MEMORY_WORKFLOW_MANIFEST.json",
        "verify-agent-memory-workflow.ps1"
    )
    "AGENT_PLATFORM_ADAPTERS.md" = @(
        "Codex-Like Local Agents",
        "Local IDE Agents",
        "Local CLI Agents",
        "Local Desktop Agents",
        "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md"
    )
    "AGENT_WORKFLOW_REPLICATION_STRATEGY.md" = @(
        "file protocol",
        "npx / CLI",
        "Agent skill",
        "SDK",
        "Current Best Path",
        "init-agent-memory-workflow.ps1",
        "AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md"
    )
    "AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md" = @(
        "What To Open Source",
        "What Not To Open Source",
        "Reproducible User Flow",
        "Release Checklist",
        "Success Criteria"
    )
}

foreach ($entry in $referenceChecks.GetEnumerator()) {
    $text = Read-Text $entry.Key
    foreach ($needle in $entry.Value) {
        if (-not $text.Contains($needle)) {
            Add-Failure "Missing reference in $($entry.Key): $needle"
        }
    }
}

$receiptText = Read-Text "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md"
$receiptFields = @(
    "persistent_storage:",
    "durable_memory_record:",
    "chat_local_only",
    "manual_user_action_required",
    "fresh_chat_test:",
    "canonical_shared_source:",
    "secrets_policy:",
    "local_filesystem_access:"
)

foreach ($field in $receiptFields) {
    if (-not $receiptText.Contains($field)) {
        Add-Failure "Receipt template missing field: $field"
    }
}

$manifestPath = Join-Path $rootPath "AGENT_MEMORY_WORKFLOW_MANIFEST.json"
try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.version -ne $currentVersion) {
        Add-Failure "Manifest version is not $currentVersion"
    }

    if (-not $TemplateMode) {
        $manifestPathChecks = @{
            "universal_bootstrap" = "AGENT_BOOTSTRAP.md"
            "import_prompt" = "AGENT_MEMORY_IMPORT_PROMPT.md"
            "receipt_template" = "AGENT_MEMORY_IMPORT_RECEIPT_TEMPLATE.md"
            "workflow_summary" = "AGENT_MEMORY_WORKFLOW.md"
            "import_registry" = "imports\IMPORT_REGISTRY.md"
            "imports_directory" = "imports"
            "initializer" = "tools\init-agent-memory-workflow.ps1"
            "verifier" = "tools\verify-agent-memory-workflow.ps1"
        }
        foreach ($entry in $manifestPathChecks.GetEnumerator()) {
            $actual = $manifest.($entry.Key)
            $expected = Expected-Path $entry.Value
            if (-not $actual -or $actual -ne $expected) {
                Add-Failure "Manifest $($entry.Key) path is missing or incorrect"
            }
        }
        if ($manifest.canonical_shared_source -ne (Expected-Path "machine")) {
            Add-Failure "Manifest canonical_shared_source is incorrect"
        }
        if (-not $manifest.changelog -or $manifest.changelog -ne (Expected-Path "AGENT_MEMORY_WORKFLOW_CHANGELOG.md")) {
            Add-Failure "Manifest changelog path is missing or incorrect"
        }
        if (-not $manifest.platform_adapters -or $manifest.platform_adapters -ne (Expected-Path "AGENT_PLATFORM_ADAPTERS.md")) {
            Add-Failure "Manifest platform_adapters path is missing or incorrect"
        }
        if (-not $manifest.replication_strategy -or $manifest.replication_strategy -ne (Expected-Path "AGENT_WORKFLOW_REPLICATION_STRATEGY.md")) {
            Add-Failure "Manifest replication_strategy path is missing or incorrect"
        }
        if (-not $manifest.open_source_guide -or $manifest.open_source_guide -ne (Expected-Path "AGENT_WORKFLOW_OPEN_SOURCE_GUIDE.md")) {
            Add-Failure "Manifest open_source_guide path is missing or incorrect"
        }
    }

    if (-not $manifest.source_files -or $manifest.source_files.Count -lt 6) {
        Add-Failure "Manifest source_files is missing or too short"
    }
    if (-not $manifest.stable_policies.secrets) {
        Add-Failure "Manifest stable_policies.secrets is missing"
    }
    if (-not $manifest.reimport_required_when -or $manifest.reimport_required_when.Count -lt 4) {
        Add-Failure "Manifest reimport_required_when is missing or too short"
    }
    if (-not $manifest.replication_recommendation -or $manifest.replication_recommendation.next_productization_step -ne "npx/local CLI wrapper") {
        Add-Failure "Manifest replication_recommendation is missing or incorrect"
    }
    if (-not $manifest.open_source_recommendation -or $manifest.open_source_recommendation.first_release -ne "templates plus PowerShell init/verifier") {
        Add-Failure "Manifest open_source_recommendation is missing or incorrect"
    }
    if (-not $manifest.adapter_categories -or $manifest.adapter_categories.Count -lt 4) {
        Add-Failure "Manifest adapter_categories is missing or too short"
    }
    foreach ($category in $manifest.adapter_categories) {
        if ($category -notmatch "^local_") {
            Add-Failure "Manifest adapter category is not local-only: $category"
        }
    }
}
catch {
    Add-Failure "Manifest JSON parse failed: $($_.Exception.Message)"
}

if ($failures.Count -gt 0) {
    Write-Host "Agent memory workflow check: FAIL"
    foreach ($failure in $failures) {
        Write-Host "- $failure"
    }
    exit 1
}

Write-Host "Agent memory workflow check: PASS"
Write-Host "Checked root: $rootPath"
Write-Host "Required files: $($requiredFiles.Count)"
Write-Host "Files scanned: $($scannedFiles.Count)"
