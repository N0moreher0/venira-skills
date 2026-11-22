<#
.SYNOPSIS
  Check the skills (and the plugin docs around them) against the venira-mcp
  source they describe, so a claim that drifted from the code fails loudly.

.DESCRIPTION
  Reads the server source, never runs it:
    tools/project-docs.ts       TOOL_DOCS keys = the tool names that exist
    tools/project-tool-mode.ts  CORE_TOOLS, SHIPPING_EXCLUDES, SETUP_TOOLS = tool count per mode
    tools/project-memory.ts     MEMORY_MAX_BYTES = the memory note cap
  Checks: skills/<name>/SKILL.md layout and frontmatter, names that no longer
  exist, tool counts per mode, the memory cap, a few must-mention facts, and
  that plugin.json and marketplace.json agree on the version.
  Exit code 1 when anything fails.

.PARAMETER ServerRoot
  Path of the venira-mcp repo. Default: a venira-mcp folder next to this repo.

.EXAMPLE
  .\check-skills.ps1
  .\check-skills.ps1 -ServerRoot G:\Venira\venira-mcp
#>
[CmdletBinding()]
param(
  [string]$Root = $null,
  [string]$ServerRoot = $null
)

$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path -Parent $PSCommandPath }
if (-not $Root) { $Root = $PWD.Path }
if (-not $ServerRoot) { $ServerRoot = Join-Path (Split-Path -Parent $Root) 'venira-mcp' }

$script:failures = 0
function Fail([string]$msg) { Write-Host "FAIL $msg"; $script:failures++ }
function Pass([string]$msg) { Write-Host "ok   $msg" }
function Read-Text([string]$path) { [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) }

# ---- server facts ------------------------------------------------------------
$docsPath = Join-Path $ServerRoot 'tools/project-docs.ts'
$modePath = Join-Path $ServerRoot 'tools/project-tool-mode.ts'
$memPath = Join-Path $ServerRoot 'tools/project-memory.ts'
foreach ($p in @($docsPath, $modePath, $memPath)) {
  if (-not (Test-Path $p)) { throw "not found: $p (pass -ServerRoot <path of the venira-mcp repo>)" }
}

$docs = Read-Text $docsPath
$start = $docs.IndexOf('export const TOOL_DOCS')
$end = $docs.IndexOf('type RegisterConfig')
if ($start -lt 0 -or $end -le $start) { throw 'cannot locate TOOL_DOCS in project-docs.ts' }
$block = $docs.Substring($start, $end - $start)
$tools = @([regex]::Matches($block, '(?m)^  ([a-z][a-z0-9_]*): \{') | ForEach-Object { $_.Groups[1].Value })
if ($tools.Count -lt 20) { throw "only $($tools.Count) tools found in TOOL_DOCS; the parser needs updating" }

$mode = Read-Text $modePath
function Get-List([string]$name) {
  $m = [regex]::Match($mode, '(?s)' + $name + '[^=]*=\s*\[(.*?)\];')
  if (-not $m.Success) { throw "cannot locate $name in project-tool-mode.ts" }
  @([regex]::Matches($m.Groups[1].Value, '"([a-z][a-z0-9_]*)"') | ForEach-Object { $_.Groups[1].Value })
}
$setup = Get-List 'SETUP_TOOLS'
$ship = Get-List 'SHIPPING_EXCLUDES'
$coreList = Get-List 'CORE_TOOLS'
$all = @($tools | Where-Object { $setup -notcontains $_ })
$counts = @{
  core = $coreList.Count
  default = @($all | Where-Object { $ship -notcontains $_ }).Count
  expert = $all.Count
}

$capText = [regex]::Match((Read-Text $memPath), 'MEMORY_MAX_BYTES\s*=\s*([0-9_]+)').Groups[1].Value
if (-not $capText) { throw 'cannot locate MEMORY_MAX_BYTES in project-memory.ts' }
$cap = [int]($capText -replace '_', '')

Write-Host "server: $($tools.Count) tools documented; core $($counts.core) / default $($counts.default) / expert $($counts.expert); memory cap $cap bytes"

# ---- layout and frontmatter --------------------------------------------------
$skillDirs = @(Get-ChildItem -Directory -Path (Join-Path $Root 'skills') | Sort-Object Name)
if ($skillDirs.Count -eq 0) { throw "no skills under $Root\skills" }
foreach ($d in $skillDirs) {
  $f = Join-Path $d.FullName 'SKILL.md'
  if (-not (Test-Path $f)) { Fail "$($d.Name): SKILL.md is missing"; continue }
  $stray = @(Get-ChildItem -File -Path $d.FullName | Where-Object { $_.Name -ne 'SKILL.md' })
  if ($stray.Count -gt 0) { Fail "$($d.Name): extra files next to SKILL.md ($(($stray | ForEach-Object { $_.Name }) -join ', '))" }
  $t = Read-Text $f
  $fm = [regex]::Match($t, '(?s)\A---\r?\n(.*?)\r?\n---')
  if (-not $fm.Success) { Fail "$($d.Name): no frontmatter"; continue }
  $name = [regex]::Match($fm.Groups[1].Value, '(?m)^name:\s*(.+?)\s*$').Groups[1].Value
  if ($name -ne $d.Name) { Fail "$($d.Name): frontmatter name is '$name'" }
  if (-not [regex]::IsMatch($fm.Groups[1].Value, '(?m)^description:\s*\S')) { Fail "$($d.Name): empty description" }
}
if ($script:failures -eq 0) { Pass "skills layout: $($skillDirs.Count) x SKILL.md with matching frontmatter" }

# ---- names that no longer exist ----------------------------------------------
$removed = @('change_impact', 'read_batch', 'edit_batch', 'git_status', 'git_diff', 'git_log', 'git_branch', 'git_commit', 'git_stash', 'approval_wait_ms', 'VENIRA_WORKSPACE_ROOTS')
$scan = @(Get-ChildItem -Recurse -File -Path (Join-Path $Root 'skills') -Filter 'SKILL.md')
foreach ($rel in @('.claude-plugin/plugin.json', '.claude-plugin/marketplace.json', '.mcp.json', 'local-mcp/README.md')) {
  $p = Join-Path $Root $rel
  if (Test-Path $p) { $scan += Get-Item $p }
}
$before = $script:failures
foreach ($f in $scan) {
  $t = Read-Text $f.FullName
  $label = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
  foreach ($tok in $removed) {
    if ([regex]::IsMatch($t, '(?<![A-Za-z0-9_])' + [regex]::Escape($tok) + '(?![A-Za-z0-9_])')) { Fail "${label}: mentions removed name '$tok'" }
  }
  if ([regex]::IsMatch($t, '(?<![A-Za-z0-9_])project_[a-z]')) { Fail "${label}: uses the old project_ tool prefix" }
  if ([regex]::IsMatch($t, 'background=[01](?![0-9])')) { Fail "${label}: background is a boolean, write background=true or false" }
}
if ($script:failures -eq $before) { Pass "no removed names in $($scan.Count) files" }

# ---- numbers -----------------------------------------------------------------
$before = $script:failures
$cwPath = Join-Path $Root 'skills/venira-coding-workflow/SKILL.md'
if (Test-Path $cwPath) {
  $cw = Read-Text $cwPath
  foreach ($m in @('core', 'default', 'expert')) {
    $g = [regex]::Match($cw, ('`' + $m + '` \((\d+) tools'))
    if (-not $g.Success) { Fail "venira-coding-workflow: no '$m (N tools)' claim"; continue }
    if ([int]$g.Groups[1].Value -ne $counts[$m]) { Fail "venira-coding-workflow: $m is $($g.Groups[1].Value) tools, server has $($counts[$m])" }
  }
}
$readmePath = Join-Path $Root 'README.md'
if (Test-Path $readmePath) {
  $rd = Read-Text $readmePath
  $g = [regex]::Match($rd, '`core` (\d+), `default` (\d+) or `expert` (\d+) tools')
  if (-not $g.Success) { Fail 'README.md: no "core N, default N or expert N tools" claim' }
  else {
    $i = 1
    foreach ($m in @('core', 'default', 'expert')) {
      if ([int]$g.Groups[$i].Value -ne $counts[$m]) { Fail "README.md: $m is $($g.Groups[$i].Value) tools, server has $($counts[$m])" }
      $i++
    }
  }
  if ($rd -match '38 tools') { Fail 'README.md: still says 38 tools' }
}
$memSkill = Join-Path $Root 'skills/venira-memory/SKILL.md'
foreach ($p in @($memSkill, $cwPath)) {
  if (-not (Test-Path $p)) { continue }
  $label = $p.Substring($Root.Length).TrimStart('\', '/')
  $nums = @([regex]::Matches((Read-Text $p), '(\d{4,6}) bytes?') | ForEach-Object { [int]$_.Groups[1].Value })
  if ($nums.Count -eq 0) { Fail "${label}: no memory cap stated" }
  foreach ($n in $nums) { if ($n -ne $cap) { Fail "${label}: memory cap $n bytes, server has $cap" } }
}
if ($script:failures -eq $before) { Pass "tool counts per mode and memory cap match the server" }

# ---- facts a skill must carry ------------------------------------------------
$before = $script:failures
$must = @(
  @{ file = 'skills/venira-memory/SKILL.md'; token = 'if_version' },
  @{ file = 'skills/venira-memory/SKILL.md'; token = 'conflict' },
  @{ file = 'skills/venira-git-pr/SKILL.md'; token = 'git action=push' },
  @{ file = 'skills/venira-git-pr/SKILL.md'; token = 'expert' },
  @{ file = 'skills/venira-debug-ci/SKILL.md'; token = 'expert' }
)
foreach ($c in $must) {
  $p = Join-Path $Root $c.file
  if (-not (Test-Path $p)) { continue }
  if (-not (Read-Text $p).Contains($c.token)) { Fail "$($c.file): should mention '$($c.token)'" }
}
if ($script:failures -eq $before) { Pass 'required facts present' }

# ---- plugin manifest ---------------------------------------------------------
$pj = Join-Path $Root '.claude-plugin/plugin.json'
$mj = Join-Path $Root '.claude-plugin/marketplace.json'
if ((Test-Path $pj) -and (Test-Path $mj)) {
  $pv = (Read-Text $pj | ConvertFrom-Json).version
  $mv = (Read-Text $mj | ConvertFrom-Json).plugins[0].version
  if ($pv -ne $mv) { Fail "plugin.json version $pv, marketplace.json version $mv" } else { Pass "plugin version $pv in both manifests" }
}

if ($script:failures -gt 0) { Write-Host "$($script:failures) check(s) failed"; exit 1 }
Write-Host 'all checks passed'
