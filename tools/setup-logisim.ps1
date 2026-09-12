#Requires -Version 5.1
<#
.SYNOPSIS
    Unpack a portable (no-install) Logisim-evolution into tools/.

.DESCRIPTION
    The official Windows download of Logisim-evolution is a jpackage MSI that
    bundles the application, its jars and a private JRE.  Installing it system
    wide needs administrator rights, so this script instead unpacks the MSI
    payload and rebuilds the real directory layout inside tools/.  The result
    starts from a plain .exe and never touches Program Files or the registry.

    Input can be either the .zip published on the Logisim-evolution release
    page or the .msi it contains.  Both are searched in ./_local, the repo root
    and this folder when no explicit path is given.

.PARAMETER Msi
    Path to logisim-evolution-<version>-x86_64.msi.

.PARAMETER Zip
    Path to logisim-evolution-<version>-x86_64.zip (contains the MSI).

.PARAMETER Dest
    Target folder.  Defaults to tools/logisim-evolution-<version>.

.PARAMETER Force
    Overwrite an existing target folder.

.EXAMPLE
    pwsh -File tools/setup-logisim.ps1

.EXAMPLE
    pwsh -File tools/setup-logisim.ps1 -Zip _local/logisim-evolution-3.9.0-x86_64.zip -Force
#>
[CmdletBinding()]
param(
    [string]$Msi,
    [string]$Zip,
    [string]$Dest,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
$searchDirs = @((Join-Path $repoRoot '_local'), $repoRoot, $PSScriptRoot)

function Get-FirstFile {
    param([string]$Pattern)
    foreach ($dir in $searchDirs) {
        $hit = Get-ChildItem -Path (Join-Path $dir $Pattern) -File -ErrorAction SilentlyContinue |
               Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function New-TempDir {
    param([string]$Prefix)
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("$Prefix-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

# --- Windows Installer helpers -------------------------------------------------

function New-MsiDatabase {
    param([string]$Path)
    $installer = New-Object -ComObject WindowsInstaller.Installer
    return $installer.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $installer, @($Path, 0))
}

function Invoke-MsiQuery {
    param($Database, [string]$Sql)
    $view = $Database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $Database, @($Sql))
    [void]$view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null)
    $rows = New-Object System.Collections.ArrayList
    while ($true) {
        $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
        if ($null -eq $record) { break }
        $count = $record.GetType().InvokeMember('FieldCount', 'GetProperty', $null, $record, $null)
        $values = @()
        for ($i = 1; $i -le $count; $i++) {
            $values += [string]($record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, @($i)))
        }
        # One tab separated string per row: flat output survives PowerShell unrolling.
        [void]$rows.Add(($values -join "`t"))
    }
    [void]$view.GetType().InvokeMember('Close', 'InvokeMethod', $null, $view, $null)
    return $rows
}

function Get-MsiProperty {
    param($Database, [string]$Name)
    $rows = @(Invoke-MsiQuery -Database $Database -Sql "SELECT Value FROM Property WHERE Property='$Name'")
    if ($rows.Count -gt 0) { return (($rows[0] -split "`t")[0]) }
    return $null
}

# Logisim stores file names as "shortname|longname"; only the long name matters here.
function Resolve-MsiName {
    param([string]$Raw)
    if ([string]::IsNullOrEmpty($Raw) -or $Raw -eq '.') { return $null }
    $bar = $Raw.LastIndexOf('|')
    if ($bar -ge 0) { return $Raw.Substring($bar + 1) }
    return $Raw
}

# --- locate the package --------------------------------------------------------

if (-not $Msi) {
    if ($Zip) {
        $zipPath = (Resolve-Path -LiteralPath $Zip).Path
    } else {
        $zipPath = Get-FirstFile 'logisim-evolution-*-x86_64.zip'
    }

    if ($zipPath) {
        Write-Host "Using archive : $zipPath"
        $unzipDir = New-TempDir 'logisim-zip'
        Expand-Archive -LiteralPath $zipPath -DestinationPath $unzipDir -Force
        $Msi = (Get-ChildItem -Path $unzipDir -Filter '*.msi' -File | Select-Object -First 1).FullName
        if (-not $Msi) { throw "No .msi found inside $zipPath" }
    } else {
        $Msi = Get-FirstFile 'logisim-evolution-*-x86_64.msi'
    }
}

if (-not $Msi) {
    throw @"
Could not find a Logisim-evolution package.
Download logisim-evolution-<version>-x86_64.zip from
https://github.com/logisim-evolution/logisim-evolution/releases
and put it in ./_local, or pass -Zip / -Msi explicitly.
"@
}
$Msi = (Resolve-Path -LiteralPath $Msi).Path
Write-Host "MSI package  : $Msi"

$database = New-MsiDatabase -Path $Msi
$version = Get-MsiProperty -Database $database -Name 'ProductVersion'
if (-not $Dest) { $Dest = Join-Path $repoRoot "tools\logisim-evolution-$version" }
$Dest = [System.IO.Path]::GetFullPath($Dest)

if (Test-Path -LiteralPath $Dest) {
    if (-not $Force) { throw "Target already exists: $Dest  (pass -Force to overwrite)" }
    Remove-Item -LiteralPath $Dest -Recurse -Force
}

# --- unpack the cabinet into a staging folder ----------------------------------

$staging = New-TempDir 'logisim-payload'
Write-Host "Staging      : $staging"

$sevenZipCandidates = @()
# The literal paths matter: a 32 bit host process redirects %ProgramFiles%.
foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, 'C:\Program Files', 'C:\Program Files (x86)')) {
    if ($base) { $sevenZipCandidates += (Join-Path $base '7-Zip\7z.exe') }
}
$sevenZipCommand = Get-Command 7z.exe -ErrorAction SilentlyContinue
if ($sevenZipCommand) { $sevenZipCandidates += $sevenZipCommand.Source }
$sevenZip = $sevenZipCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if ($sevenZip) {
    Write-Host "Extracting   : via 7-Zip"
    & $sevenZip x $Msi "-o$staging" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "7-Zip failed with exit code $LASTEXITCODE" }
} else {
    # Fallback: dump the #Data.cab stream with Windows Installer, then expand it.
    Write-Host "Extracting   : via Windows Installer + expand.exe"
    $view = $database.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $database,
                @("SELECT Data FROM _Streams WHERE Name='Data.cab'"))
    [void]$view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null)
    $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
    if ($null -eq $record) { throw 'No #Data.cab stream inside the MSI' }
    $size = $record.GetType().InvokeMember('DataSize', 'GetProperty', $null, $record, @(1))
    # Format 1 = msiReadStreamBytes; anything else returns an empty buffer.
    $bytes = $record.GetType().InvokeMember('ReadStream', 'InvokeMethod', $null, $record, @(1, $size, 1))
    if (-not $bytes -or $bytes.Length -ne $size) { throw 'Could not read the #Data.cab stream from the MSI' }
    $cab = Join-Path $staging 'payload.cab'
    [System.IO.File]::WriteAllBytes($cab, $bytes)
    & expand.exe -F:* $cab $staging | Out-Null
}

# --- rebuild the installed directory tree --------------------------------------

$dirTable = @{}
foreach ($line in @(Invoke-MsiQuery -Database $database -Sql 'SELECT Directory, Directory_Parent, DefaultDir FROM Directory')) {
    $field = $line -split "`t"
    $dirTable[$field[0]] = @{ Parent = $field[1]; DefaultDir = $field[2] }
}

$dirPathCache = @{}
# '.' marks the installation root itself; $null marks folders outside of it.
function Get-RelativeDir {
    param([string]$Key)
    if ([string]::IsNullOrEmpty($Key)) { return '.' }
    if ($dirPathCache.ContainsKey($Key)) { return $dirPathCache[$Key] }

    $entry = $dirTable[$Key]
    if (-not $entry) { $dirPathCache[$Key] = '.'; return '.' }

    # INSTALLDIR is the root; the well known folders live outside of it.
    if ($Key -eq 'INSTALLDIR') { $dirPathCache[$Key] = '.'; return '.' }
    if ($Key -in @('TARGETDIR', 'ProgramFiles64Folder', 'ProgramMenuFolder', 'DesktopFolder')) {
        $dirPathCache[$Key] = $null
        return $null
    }

    $parent = Get-RelativeDir $entry.Parent
    if ($null -eq $parent) { $dirPathCache[$Key] = $null; return $null }

    $name = Resolve-MsiName $entry.DefaultDir
    $result = if ($name) { if ($parent -eq '.') { $name } else { Join-Path $parent $name } } else { $parent }
    $dirPathCache[$Key] = $result
    return $result
}

$componentDir = @{}
foreach ($line in @(Invoke-MsiQuery -Database $database -Sql 'SELECT Component, ComponentId, Directory_ FROM Component')) {
    $field = $line -split "`t"
    $componentDir[$field[0]] = $field[2]
}

New-Item -ItemType Directory -Path $Dest -Force | Out-Null

$placed = 0
$missing = New-Object System.Collections.ArrayList
foreach ($line in @(Invoke-MsiQuery -Database $database -Sql 'SELECT File, Component_, FileName FROM File')) {
    $field = $line -split "`t"
    $key = $field[0]
    $component = $field[1]
    $fileName = Resolve-MsiName $field[2]
    if (-not $fileName) { continue }

    $source = Join-Path $staging $key
    if (-not (Test-Path -LiteralPath $source)) { [void]$missing.Add($key); continue }

    $relativeDir = '.'
    if ($componentDir.ContainsKey($component)) { $relativeDir = Get-RelativeDir $componentDir[$component] }
    if ($null -eq $relativeDir) { continue }   # start menu / desktop shortcuts

    $targetDir = if ($relativeDir -eq '.') { $Dest } else { Join-Path $Dest $relativeDir }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Move-Item -LiteralPath $source -Destination (Join-Path $targetDir $fileName) -Force
    $placed++
}

Remove-Item -LiteralPath $staging -Recurse -Force
if ($missing.Count -gt 0) { Write-Warning ("{0} file(s) listed in the MSI were missing from the cabinet." -f $missing.Count) }

# --- report --------------------------------------------------------------------

$exe = Get-ChildItem -Path $Dest -Filter '*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
$bundledJava = Join-Path $Dest 'runtime\bin\java.exe'

Write-Host ''
Write-Host "Logisim-evolution $version unpacked into:"
Write-Host "  $Dest"
Write-Host "  files placed : $placed"
if ($exe)         { Write-Host "  launcher     : $($exe.FullName)" }
if (Test-Path -LiteralPath $bundledJava) { Write-Host "  bundled JRE  : $bundledJava" }
Write-Host ''
Write-Host "Start it with: scripts\logisim.cmd  (or  scripts\logisim.cmd circuits\<file>.circ)"
