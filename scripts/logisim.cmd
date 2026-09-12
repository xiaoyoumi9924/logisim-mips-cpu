@echo off
rem ---------------------------------------------------------------
rem  Launch the portable Logisim-evolution that lives in tools\.
rem  Usage:  scripts\logisim.cmd                          (empty window)
rem          scripts\logisim.cmd circuits\4.2-流水线CPU.circ
rem ---------------------------------------------------------------
setlocal
set "REPO=%~dp0.."
set "LSE="
for /d %%D in ("%REPO%\tools\logisim-evolution-*") do set "LSE=%%~fD\logisim-evolution.exe"

if not defined LSE goto missing
if not exist "%LSE%" goto missing

start "" "%LSE%" %*
exit /b 0

:missing
echo.
echo   Portable Logisim-evolution was not found under  tools\
echo   Unpack it first (needs the official .zip or .msi in _local\):
echo.
echo       pwsh -File tools\setup-logisim.ps1
echo.
pause
exit /b 1
