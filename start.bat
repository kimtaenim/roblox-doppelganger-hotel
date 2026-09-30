@echo off
rem Doppelganger Hotel - start (Marthadaram)
rem Korean messages live in start.ps1 (cmd can break on Korean text in .bat files).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
if errorlevel 1 pause
