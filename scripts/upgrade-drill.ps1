<#
.SYNOPSIS
  Upgrade drill: take real published Windows packages, upgrade each to a candidate build with the product's own
  updater, and report which prior versions still upgrade cleanly.

.DESCRIPTION
  Runs scripts/smoke-windows-version-upgrade.mjs (the CI "running published release upgrade" check) once per prior
  release instead of only against the newest one. Each run starts the prior package with a hidden window, seeds user
  data, applies the candidate through the prior shell's updater and asserts that credentials, sessions and plugins
  survive and that the new runtime layout is in place. Nothing is shown on screen and the downloaded packages are
  removed afterwards.

  Use it before and after touching updater code (launcher/update-core.mjs, DSH-FullUpdater, the shell contract): the
  same drill must pass before and after.

.PARAMETER Artifacts
  Directory holding the candidate's DSH-Portable-windows-x64-offline.zip, DSH-Portable-update-windows-x64.zip,
  portable-manifest.json and portable-update-windows-x64.json (the CI "windows-x64-build" artifact).

.PARAMETER Priors
  Release tags to upgrade from. Default: the newest stable 0.x releases other than the candidate itself.

.PARAMETER Count
  How many prior releases to take when -Priors is not given. Default 3.

.EXAMPLE
  gh run download <run-id> -n windows-x64-build -D artifacts
  ./scripts/upgrade-drill.ps1 -Artifacts artifacts
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $Artifacts,
  [string[]] $Priors,
  [int] $Count = 3,
  [string] $Repository = 'WSL043/DSH-Portable',
  [switch] $KeepDownloads
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Artifacts = (Resolve-Path -LiteralPath $Artifacts).Path
foreach ($name in 'DSH-Portable-windows-x64-offline.zip', 'DSH-Portable-update-windows-x64.zip', 'portable-manifest.json', 'portable-update-windows-x64.json') {
  if (-not (Test-Path -LiteralPath (Join-Path $Artifacts $name))) { throw "Candidate artifact is missing: $name" }
}
$Candidate = [string](Get-Content -LiteralPath (Join-Path $Artifacts 'portable-manifest.json') -Raw | ConvertFrom-Json).version

if (-not $Priors) {
  $Releases = gh release list --repo $Repository --exclude-drafts --limit 60 --json tagName,isPrerelease,publishedAt | ConvertFrom-Json
  $Priors = @($Releases | Where-Object { -not $_.isPrerelease -and $_.tagName -match '^v0\.\d+\.\d+$' -and $_.tagName -ne "v$Candidate" } |
    Sort-Object publishedAt -Descending | Select-Object -First $Count | ForEach-Object { $_.tagName })
}
if ($Priors.Count -eq 0) { throw 'No prior release to drill against.' }

$Work = Join-Path ([IO.Path]::GetTempPath()) ('upgrade-drill-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $Work | Out-Null
$Results = @()
try {
  foreach ($Tag in $Priors) {
    $Dir = Join-Path $Work $Tag.TrimStart('v')
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    $Started = Get-Date
    Write-Host "== $Tag -> $Candidate"
    gh release download $Tag --repo $Repository --pattern 'DSH-Portable-windows-x64-offline.zip' --dir $Dir
    if ($LASTEXITCODE -ne 0) {
      $Results += [pscustomobject]@{ From = $Tag; To = $Candidate; Result = 'DOWNLOAD FAILED'; Seconds = 0 }
      continue
    }
    $Zip = Join-Path $Dir 'DSH-Portable-windows-x64-offline.zip'
    Push-Location $Root
    try {
      node scripts/smoke-windows-version-upgrade.mjs $Zip $Artifacts --running-host --simulate-webview-busy
      $Code = $LASTEXITCODE
    } finally { Pop-Location }
    $Results += [pscustomobject]@{
      From = $Tag; To = $Candidate; Result = $(if ($Code -eq 0) { 'PASS' } else { "FAIL (exit $Code)" })
      Seconds = [int]((Get-Date) - $Started).TotalSeconds
    }
    if (-not $KeepDownloads) { Remove-Item -LiteralPath $Dir -Recurse -Force -ErrorAction SilentlyContinue }
  }
} finally {
  if (-not $KeepDownloads) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
}
Write-Host ''
$Results | Format-Table -AutoSize | Out-String | Write-Host
if ($Results | Where-Object { $_.Result -ne 'PASS' }) { exit 1 }
