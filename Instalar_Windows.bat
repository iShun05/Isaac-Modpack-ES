@echo off
chcp 65001 >nul
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0windows\instalar_gui.ps1"
