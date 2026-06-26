@echo off
chcp 65001 >nul
setlocal
title TikTok Live Games - Cursed Walking MOD Live
set "ROOT=%~dp0"
set "ROOT_ARG=%~dp0."
set "JAVA_HOME=%ROOT%tools\java"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo Preparando cliente Cursed Walking...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\preparar_cliente.ps1" -Root "%ROOT_ARG%"
if errorlevel 1 exit /b %ERRORLEVEL%

echo Preparando servidor local Forge/RCON...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\preparar_servidor.ps1" -Root "%ROOT_ARG%"
if errorlevel 1 exit /b %ERRORLEVEL%

echo Iniciando EventBus oculto...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\iniciar_event_bus.ps1" -Root "%ROOT_ARG%"
if errorlevel 1 exit /b %ERRORLEVEL%

echo Iniciando servidor Minecraft local...
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\iniciar_servidor.ps1" -Root "%ROOT_ARG%"
exit /b %ERRORLEVEL%
