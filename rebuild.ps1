<#
.SYNOPSIS
  Repack every <name>/SKILL.md under skills/ into a <name>.skill zip in the
  repo root.

.PARAMETER Verify
  After packing, SHA-256-compare the entry inside each .skill against
  skills/<name>/SKILL.md and exit non-zero on any mismatch.

.EXAMPLE
  .\rebuild.ps1 -Verify
#>
[CmdletBinding()]
param(
  [switch]$Verify,
  [string]$Root = $null
)

if (-not $Root) { $Root = Split-Path -Parent $PSCommandPath }
if (-not $Root) { $Root = $PWD.Path }

$skills = Get-ChildItem -Directory -Path (Join-Path $Root 'skills')
if (-not $skills) { throw "no skills under $($Root)\skills" }

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Pack-One($skill) {
  $src = Join-Path $skill.FullName 'SKILL.md'
  if (-not (Test-Path $src)) { throw "missing $($src)" }
  $dest = Join-Path $Root "$($skill.Name).skill"
  $entryName = "$($skill.Name)/SKILL.md"
  if (Test-Path $dest) { Remove-Item $dest -Force }
  $zip = [IO.Compression.ZipFile]::Open($dest, 'Create')
  try {
    $entry = $zip.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
    $bytes = [IO.File]::ReadAllBytes($src)
    $es = $entry.Open()
    $es.Write($bytes, 0, $bytes.Length)
    $es.Dispose()
    Write-Host "packed $($skill.Name).skill"
  } finally { $zip.Dispose() }
}

function Test-One($skill) {
  $srcPath = Join-Path $skill.FullName 'SKILL.md'
  $dest = Join-Path $Root "$($skill.Name).skill"
  if (-not (Test-Path $dest)) { Write-Host "FAIL $($skill.Name): missing $dest"; return $false }
  $zip = [IO.Compression.ZipFile]::OpenRead($dest)
  try {
    $entry = $zip.Entries | Where-Object { $_.FullName -eq "$($skill.Name)/SKILL.md" }
    if (-not $entry) { Write-Host "FAIL $($skill.Name): no $($skill.Name)/SKILL.md entry"; return $false }
    $ms = New-Object IO.MemoryStream
    $stream = $entry.Open()
    $stream.CopyTo($ms); $stream.Dispose()
    $a = [Security.Cryptography.SHA256]::Create().ComputeHash($ms.ToArray())
    $b = [Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($srcPath))
    if ([BitConverter]::ToString($a) -ne [BitConverter]::ToString($b)) { Write-Host "FAIL $($skill.Name): content differs"; return $false }
    Write-Host "ok   $($skill.Name)"
    return $true
  } finally { $zip.Dispose() }
}

foreach ($skill in $skills) { Pack-One $skill }

$bad = 0
if ($Verify) {
  foreach ($skill in $skills) {
    if (-not (Test-One $skill)) { $bad++ }
  }
  if ($bad) { exit 1 }
}
