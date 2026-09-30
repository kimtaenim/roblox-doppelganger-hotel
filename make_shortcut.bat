@echo off
rem Creates the desktop shortcut. Run this once.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0make_shortcut.ps1"
pause
