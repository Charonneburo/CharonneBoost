@echo off
setlocal
cd /d "%~dp0"

if not exist "%~dp0Purge.ps1" (
  echo ERREUR : Purge.ps1 introuvable dans %~dp0
  pause
  exit /b 1
)

:: Verifie si deja admin
net session >nul 2>&1
if %errorlevel%==0 goto RUN_ADMIN

:: Relance avec UAC Windows. ExecutionPolicy Bypass est limitee a CE lancement uniquement.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -WorkingDirectory '%~dp0' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0Purge.ps1\"'"
exit /b

:RUN_ADMIN
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Purge.ps1"
endlocal
