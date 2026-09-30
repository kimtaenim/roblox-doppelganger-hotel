# 도플갱어 호텔 개발 시작 스크립트 (start.bat 이 이 파일을 실행해요)
# git pull → rokit install → rojo serve (포트 34873) → Roblox Studio 열기
$Port = 34873
$PlaceFile = 'DoppelgangerHotel.rbxlx'

Set-Location $PSScriptRoot
$Host.UI.RawUI.WindowTitle = '도플갱어 호텔 시작 (Marthadaram)'

function Step($text) { Write-Host ''; Write-Host $text -ForegroundColor Cyan }
function Problem($text) { Write-Host "  [!] $text" -ForegroundColor Red }

Write-Host '============================================'
Write-Host '  도플갱어 호텔 - 개발 시작 (Marthadaram)'
Write-Host '============================================'
Write-Host "  폴더: $PSScriptRoot"

Step '[1/4] 최신 코드 받아오는 중 (git pull)...'
git pull
if ($LASTEXITCODE -ne 0) { Problem 'git pull 에 실패했어요. 인터넷 연결을 확인해 주세요. 그래도 계속 진행할게요.' }

Step '[2/4] 도구 확인 중 (rokit install)...'
rokit install
if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
    Problem 'rojo 를 찾을 수 없어요. Rokit 설치 후 컴퓨터를 한 번 다시 켜 보세요.'
    Read-Host '엔터를 누르면 닫혀요'
    exit 1
}

Step "[3/4] Rojo 서버 켜는 중 (포트 $Port)..."
$already = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($already) {
    Write-Host "  이미 포트 $Port 에서 Rojo 가 켜져 있어요."
} else {
    # 새 창에서 rojo serve 를 켜요. 개발하는 동안 그 창은 닫지 마세요.
    Start-Process cmd -WorkingDirectory $PSScriptRoot -ArgumentList '/k', "title Rojo - Doppelganger Hotel ($Port) && rojo serve default.project.json --port $Port"
    $ok = $false
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 500
        if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { $ok = $true; break }
    }
    if ($ok) {
        Write-Host "  Rojo 서버가 켜졌어요! (포트 $Port)" -ForegroundColor Green
    } else {
        Problem 'Rojo 서버가 아직 안 켜졌어요. "Rojo - Doppelganger Hotel" 창의 메시지를 확인해 주세요.'
    }
}

Step '[4/4] Roblox Studio 여는 중...'
if (-not (Test-Path $PlaceFile)) {
    Write-Host '  처음 실행이라 place 파일을 만들어요...'
    rojo build default.project.json -o $PlaceFile
}
try {
    Start-Process (Join-Path $PSScriptRoot $PlaceFile) -ErrorAction Stop
} catch {
    Problem 'place 파일을 Studio로 열지 못했어요. Studio를 직접 켜서 아무 place 나 열어 주세요.'
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Yellow
Write-Host '  꼭 확인해 주세요!' -ForegroundColor Yellow
Write-Host ''
Write-Host '  1. Studio 오른쪽 위 계정 이름이 "Marthadaram" 인지 확인하세요.'
Write-Host '     다른 계정이면 로그아웃 후 Marthadaram 으로 다시 로그인하세요.'
Write-Host ''
Write-Host "  2. Studio [플러그인] 탭 - Rojo 창에서 포트를 $Port 로 바꾸고"
Write-Host '     [Connect] 를 누르세요. (34872 는 Stealth Animals 용이에요!)'
Write-Host ''
Write-Host '  3. "Rojo - Doppelganger Hotel" 창은 개발이 끝날 때까지 닫지 마세요.'
Write-Host '============================================' -ForegroundColor Yellow
Write-Host ''
Read-Host '엔터를 누르면 이 창이 닫혀요'
