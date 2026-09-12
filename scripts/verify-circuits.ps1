#Requires -Version 5.1
<#
.SYNOPSIS
    Load every circuit in circuits/ headlessly and report whether it is healthy.

.DESCRIPTION
    Logisim-evolution can run without a GUI: the "-t stats" switch parses the
    project, builds every subcircuit and prints component statistics.  A clean
    exit code therefore proves that the file opens, and that no subcircuit is
    missing or malformed.  This is the check used before every commit.

.EXAMPLE
    pwsh -File scripts/verify-circuits.ps1

.EXAMPLE
    pwsh -File scripts/verify-circuits.ps1 -LogisimHome tools\logisim-evolution-3.9.0
#>
[CmdletBinding()]
param(
    [string]$LogisimHome,
    [string]$CircuitsDir,
    [string]$Java
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $CircuitsDir) { $CircuitsDir = Join-Path $repoRoot 'circuits' }
if (-not $LogisimHome) {
    $LogisimHome = Get-ChildItem -Path (Join-Path $repoRoot 'tools\logisim-evolution-*') -Directory -ErrorAction SilentlyContinue |
                   Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $LogisimHome) {
    throw "Logisim-evolution not found. Run  pwsh -File tools\setup-logisim.ps1  first."
}

$jar = Get-ChildItem -Path (Join-Path $LogisimHome 'app\*-all.jar') -File -ErrorAction SilentlyContinue |
       Select-Object -First 1 -ExpandProperty FullName
if (-not $jar) { throw "No logisim-evolution jar inside $LogisimHome\app" }

if (-not $Java) {
    $bundled = Join-Path $LogisimHome 'runtime\bin\java.exe'
    $Java = if (Test-Path -LiteralPath $bundled) { $bundled }
            else { (Get-Command java -ErrorAction SilentlyContinue).Source }
}
if (-not $Java) { throw 'No Java runtime found: install a JRE 17+ or point -Java at one.' }

$prefsDir = Join-Path ([System.IO.Path]::GetTempPath()) 'logisim-ci-prefs'
New-Item -ItemType Directory -Path $prefsDir -Force | Out-Null

Write-Host "Java      : $Java"
Write-Host "Logisim   : $jar"
Write-Host ''

$circuits = Get-ChildItem -Path (Join-Path $CircuitsDir '*.circ') | Sort-Object Name
if (-not $circuits) { throw "No .circ files in $CircuitsDir" }

$failed = 0
foreach ($file in $circuits) {
    $stdout = Join-Path ([System.IO.Path]::GetTempPath()) 'verify-stdout.txt'
    $stderr = Join-Path ([System.IO.Path]::GetTempPath()) 'verify-stderr.txt'
    & $Java '-Djava.awt.headless=true' "-Djava.util.prefs.userRoot=$prefsDir" `
            '-Dstdout.encoding=UTF-8' '-Dstderr.encoding=UTF-8' `
            -jar $jar -t stats $file.FullName > $stdout 2> $stderr
    $code = $LASTEXITCODE

    $errorText = (Get-Content -LiteralPath $stderr -ErrorAction SilentlyContinue) |
                 Where-Object { $_ -and $_ -notmatch 'WARNING|WindowsReg|prefs' }
    $parts = ((Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue) |
              Where-Object { $_ -match '\S' }).Count

    if ($code -eq 0 -and -not $errorText) {
        Write-Host ("  [ OK ]  {0,-24} {1,3} component rows" -f $file.Name, $parts)
    } else {
        $failed++
        Write-Host ("  [FAIL]  {0,-24} exit={1}" -f $file.Name, $code) -ForegroundColor Red
        $errorText | ForEach-Object { Write-Host "          $_" }
    }
}

Write-Host ''
if ($failed -gt 0) {
    Write-Host "$failed of $($circuits.Count) circuits failed to load." -ForegroundColor Red
    exit 1
}
Write-Host "All $($circuits.Count) circuits loaded successfully."
