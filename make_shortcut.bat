@echo off
chcp 65001 >nul
rem 바탕화면에 "도플갱어 호텔 시작 (Marthadaram)" 바로가기를 만들어요.
rem 처음에 딱 한 번만 더블클릭하면 돼요.
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$desk = [Environment]::GetFolderPath('Desktop');" ^
  "$lnk = Join-Path $desk '도플갱어 호텔 시작 (Marthadaram).lnk';" ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk);" ^
  "$s.TargetPath = '%~dp0start.bat';" ^
  "$s.WorkingDirectory = '%~dp0';" ^
  "$s.Save();" ^
  "Write-Host ('바로가기를 만들었어요: ' + $lnk)"

echo.
pause
