<#
.SYNOPSIS
  Install the Venira skills into every client that can use them.

.DESCRIPTION
  Dry-run by default: prints exactly what would happen. Pass -Apply to make
  changes. Every file written is backed up first (<file>.bak). A marked block
  <!-- venira-skills:begin --> ... <!-- venira-skills:end --> is replaced or
  appended; content outside the markers is never touched.

.PARAMETER Client
  One of: opencode | codex | antigravity | claude-code | all. Default: all.
  opencode and codex share the same AGENTS.md (identical marker content).

.PARAMETER Path
  Target directory for AGENTS.md / GEMINI.md. Defaults to the current directory.
  Claude Code ignores -Path (it writes into ~/.claude/skills).

.PARAMETER Apply
  Actually write. Without it nothing is changed.

.EXAMPLE
  .\install.ps1 -Client opencode
  # dry-run; nothing is written

.EXAMPLE
  .\install.ps1 -Client all -Apply -Path G:\my-project
  # writes G:\my-project\AGENTS.md and GEMINI.md, and mirrors into ~/.claude/skills/
#>
param(
  [ValidateSet('opencode', 'codex', 'antigravity', 'claude-code', 'all')]
  [string]$Client = 'all',

  [string]$Path = (Get-Location).Path,

  [switch]$Apply
)

$skillsRoot = Split-Path -Parent $PSScriptRoot
if (-not $skillsRoot -or -not (Test-Path (Join-Path $skillsRoot 'clients'))) {
  $skillsRoot = $PWD.Path
}
if (-not (Test-Path (Join-Path $skillsRoot 'clients'))) { throw "run from the skills repo root" }
if (-not $Path) { $Path = $PWD.Path }
if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Force $Path | Out-Null }

$opencodeFile    = Join-Path $skillsRoot 'clients\opencode\AGENTS.md'    # opencode + codex share the same file (identical marker content)
$antigravityFile = Join-Path $skillsRoot 'clients\antigravity\GEMINI.md'

function Install-Block($target, $block) {
  $parent = Split-Path $target -Parent
  if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Force $parent | Out-Null }
  if (Test-Path $target) {
    Copy-Item $target "$target.bak" -Force
    Write-Host "  backed up -> $target.bak"
    $text = Get-Content -Raw $target
    $begin = $text.IndexOf('<!-- venira-skills:begin -->')
    $endMarker = '<!-- venira-skills:end -->'
    $end = $text.IndexOf($endMarker)
    if ($begin -ge 0 -and $end -ge 0) {
      $newText = $text.Substring(0, $begin) + $block + $text.Substring($end + $endMarker.Length)
      Set-Content -Path $target -Value $newText -Encoding utf8
      Write-Host "  replaced marked block in $target"
      return
    }
    Set-Content -Path $target -Value ($text.TrimEnd() + "`n`n" + $block + "`n") -Encoding utf8
    Write-Host "  appended marked block to $target"
    return
  }
  Set-Content -Path $target -Value ($block + "`n") -Encoding utf8
  Write-Host "  created $target"
}

$jobs = @(
  @{ Keys = @('opencode', 'codex');  Name = 'opencode / codex (AGENTS.md)'; Files = @($opencodeFile); Target = (Join-Path $Path 'AGENTS.md') }
  @{ Keys = @('antigravity');        Name = 'antigravity (GEMINI.md)';      Files = @($antigravityFile); Target = (Join-Path $Path 'GEMINI.md') }
)

$selected = if ($Client -eq 'all') { @('opencode', 'codex', 'antigravity', 'claude-code') } else { @($Client) }
$handled = @{}

Write-Host "Venira skills installer"
Write-Host ("Mode: " + $(if ($Apply) { 'APPLY' } else { 'DRY-RUN (use -Apply to write)' }))

foreach ($job in $jobs) {
  $relevant = $false
  foreach ($k in $job.Keys) { if ($selected -contains $k) { $relevant = $true } }
  if (-not $relevant) { continue }
  if ($handled.ContainsKey($job.Target)) { Write-Host "  $($job.Name): already handled ($($job.Target))"; continue }
  $handled[$job.Target] = $true
  $block = Get-Content -Raw $job.Files[0]
  if (Test-Path $job.Target) {
    Write-Host "  $($job.Name): would update marked block in $($job.Target) (backup .bak)"
  } else {
    Write-Host "  $($job.Name): would create $($job.Target)"
  }
  if ($Apply) { Install-Block $job.Target $block }
}

if ($selected -contains 'claude-code') {
  $dest = Join-Path $HOME '.claude\skills'
  if ($Apply) {
    New-Item -ItemType Directory -Force $dest | Out-Null
    foreach ($skill in (Get-ChildItem (Join-Path $skillsRoot 'skills') -Directory)) {
      $skillDest = Join-Path $dest $skill.Name
      if (Test-Path $skillDest) { Remove-Item $skillDest -Recurse -Force }
      New-Item -ItemType Directory -Force $skillDest | Out-Null
      Copy-Item (Join-Path $skill.FullName 'SKILL.md') (Join-Path $skillDest 'SKILL.md')
      Write-Host "  claude-code: installed $($skill.Name)"
    }
  } else {
    Write-Host "  claude-code: would mirror $skillsRoot\skills -> $dest (4 skills, overwriting)"
  }
}

Write-Host ""
Write-Host "claude-ai / claude-desktop: GUI upload only (Customize -> Skills -> upload .skill)."
Write-Host "Generic MCP / other models: paste clients/opencode/AGENTS.md into the system prompt or project instructions."
Write-Host "opencode / codex: the AGENTS.md in $Path is ready; commit it so teammates get the same behaviour."
