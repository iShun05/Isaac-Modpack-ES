@echo off
chcp 65001 >nul
title Isaac Pack ES - instalador (consola)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\instalar_windows.ps1"
if errorlevel 1 (
  echo.
  echo [ERROR] La instalacion no se completo. Lee el mensaje de arriba.
)
echo.
pause
