@echo off
setlocal
cd /d "%~dp0."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\actualizar_juego.ps1" -InstallRoot "%~dp0."
pause
