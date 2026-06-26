@echo off
chcp 65001 >nul
setlocal
title Preparar Cursed Walking MOD Live
set "ROOT=%~dp0"
set "ROOT_ARG=%~dp0."
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\preparar_cliente.ps1" -Root "%ROOT_ARG%"
exit /b %ERRORLEVEL%
