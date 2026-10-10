@echo off
chcp 65001 >nul
title Isaac Pack ES - aplicar seleccion del panel
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\instalar_windows.ps1" -Rapido
if errorlevel 1 (
  echo.
  echo [ERROR] No se pudo aplicar la seleccion. Lee el mensaje de arriba.
)
echo.
pause
