<#
.SYNOPSIS
  Repack every <name>/SKILL.md under src/ into a distributable <name>.skill (zip).

.PARAMETER Verify
  After packing, SHA-256-compare the entry inside each .skill against
  src/<name>/SKILL.md and exit non-zero on any mismatch.

.EXAMPLE
  ./rebuild.ps1 -Verify
#>
[CmdletBinding()]
param(
  [switch]$Verify,
  [string]$Root = $null
)

if (-not $Root) { $Root = Split-Path -Parent $MyInvocation.MyCommand.Path }

$skills = Get-ChildItem -Directory -Path (Join-Path $Root 'src')
if (-not $skills) { throw "no skills under $($Root)\src" }

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Pack-One($skill) {
  $src = Join-Path $skill.FullName 'SKILL.md'
  if (-not (Test-Path $src)) { throw "missing $($src)" }
  $dest = Join-Path $Root "$($skill.Name).skill"
  $entryName = "$($skill.Name)/SKILL.md"
  if (Test-Path $dest) { Remove-Item $dest -Force }
  # Build the zip manually so entry names always use forward slashes.
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
    if (-not $entry) { Write-Host "FAIL $($skill.Name): entry $($skill.Name)/SKILL.md not found"; return $false }
    $ms = New-Object IO.MemoryStream
    $stream = $entry.Open()
    $stream.CopyTo($ms); $stream.Dispose()
    $a = [Security.Cryptography.SHA256]::Create().ComputeHash($ms.ToArray())
    $b = [Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($srcPath))
    $same = [BitConverter]::ToString($a) -eq [BitConverter]::ToString($b)
    if ($same) { Write-Host "ok   $($skill.Name)" } else { Write-Host "FAIL $($skill.Name): content differs" }
    return $same
  } finally { $zip.Dispose() }
}

foreach ($skill in $skills) { Pack-One $skill }

$bad = 0
foreach ($skill in $skills) {
  if (-not (Test-One $skill)) { $bad++ }
}
if ($bad) { exit 1 }
