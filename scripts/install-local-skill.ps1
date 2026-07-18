# Purpose: Install this repository into a local pmm skill directory without maintainer sync.
# Read when: Installing pmm on Windows or any environment that can run PowerShell.
# Skip when: Maintainers need checked public-repository sync; use sync-local-skill.sh instead.

param(
  [Parameter(Mandatory = $true)]
  [string] $SkillsRoot,

  [string] $SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,

  [switch] $Force
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  throw $Message
}

if ([string]::IsNullOrWhiteSpace($SkillsRoot)) {
  Fail "SkillsRoot must not be empty."
}

$pathTrimChars = [char[]]@('\', '/')
$trimmedSkillsRoot = $SkillsRoot.TrimEnd($pathTrimChars)
if ([IO.Path]::GetFileName($trimmedSkillsRoot) -ieq "pmm") {
  Fail "Pass the skills root, not the pmm directory itself. The installer creates <SKILLS_ROOT>/pmm."
}

$source = (Resolve-Path $SourceRoot).Path
$destination = Join-Path $SkillsRoot "pmm"

if (-not (Test-Path (Join-Path $source "SKILL.md"))) {
  Fail "SourceRoot does not look like the pmm repository: $source"
}

if ((Test-Path $destination) -and -not $Force) {
  Fail "Destination already exists: $destination. Re-run with -Force to replace managed pmm docs/templates and helper files."
}

if (Test-Path $destination) {
  $destinationItem = Get-Item $destination
  if (($destinationItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    Fail "Destination must not be a symlink or reparse point: $destination"
  }
}

New-Item -ItemType Directory -Force -Path $destination | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $destination "scripts") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path (Join-Path $destination "scripts") "lib") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $destination "tests") | Out-Null

$topLevelFiles = @(
  "SKILL.md",
  "VERSION",
  "CHANGELOG.md",
  "CHANGELOG.en.md",
  "LICENSE"
)

foreach ($file in $topLevelFiles) {
  Copy-Item -Force -Path (Join-Path $source $file) -Destination (Join-Path $destination $file)
}

foreach ($dir in @("docs", "templates")) {
  $sourceDir = Join-Path $source $dir
  $destDir = Join-Path $destination $dir
  if (Test-Path $destDir) {
    Remove-Item -Recurse -Force $destDir
  }
  Copy-Item -Recurse -Force -Path $sourceDir -Destination $destDir
}

foreach ($script in @("recovery-status.sh", "pmm-doctor.sh", "pmm-task.sh")) {
  $sourceScript = Join-Path (Join-Path $source "scripts") $script
  $destScript = Join-Path (Join-Path $destination "scripts") $script
  Copy-Item -Force -Path $sourceScript -Destination $destScript
}

$sourceStateLibrary = Join-Path (Join-Path (Join-Path $source "scripts") "lib") "pmm-state.sh"
$destStateLibrary = Join-Path (Join-Path (Join-Path $destination "scripts") "lib") "pmm-state.sh"
Copy-Item -Force -Path $sourceStateLibrary -Destination $destStateLibrary

$sourceRuntimeTest = Join-Path (Join-Path $source "tests") "pmm-runtime-contract.sh"
$destRuntimeTest = Join-Path (Join-Path $destination "tests") "pmm-runtime-contract.sh"
Copy-Item -Force -Path $sourceRuntimeTest -Destination $destRuntimeTest

Write-Output "Installed pmm to $destination"
