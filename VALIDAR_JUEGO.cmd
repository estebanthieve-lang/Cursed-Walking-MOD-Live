@echo off
chcp 65001 >nul
setlocal
title TikTok Live Games - Validar Minecraft
set "ROOT=%~dp0"
set "ROOT_ARG=%~dp0."

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\validar_juego.ps1" -Root "%ROOT_ARG%"
exit /b %ERRORLEVEL%
