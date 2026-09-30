# 바탕화면에 "도플갱어 호텔 시작 (Marthadaram)" 바로가기를 만들어요.
$desktop = [Environment]::GetFolderPath('Desktop')
$link = Join-Path $desktop '도플갱어 호텔 시작 (Marthadaram).lnk'
$shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($link)
$shortcut.TargetPath = Join-Path $PSScriptRoot 'start.bat'
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Save()
Write-Host "바로가기를 만들었어요: $link" -ForegroundColor Green
