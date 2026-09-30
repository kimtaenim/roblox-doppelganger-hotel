@echo off
chcp 65001 >nul
title 도플갱어 호텔 시작 (Marthadaram)

rem 이 파일이 있는 폴더(저장소 폴더)로 이동해요. 어디에 clone해도 동작해요.
cd /d "%~dp0"

echo ============================================
echo   도플갱어 호텔 - 개발 시작 (Marthadaram)
echo ============================================
echo.

echo [1/4] 최신 코드 받아오는 중 (git pull)...
git pull
if errorlevel 1 (
    echo.
    echo  [!] git pull 에 실패했어요. 인터넷 연결이나 수정 중인 파일을 확인해 주세요.
    echo      그래도 계속 진행할게요.
)
echo.

echo [2/4] 도구 확인 중 (rokit install)...
rokit install
echo.

echo [3/4] Rojo 서버 켜는 중 (포트 34873)...
rem 새 창에서 rojo serve 를 켜요. 개발하는 동안 그 창은 닫지 마세요.
start "Rojo - 도플갱어 호텔 (34873)" cmd /k rojo serve default.project.json --port 34873
echo.

echo [4/4] Roblox Studio 여는 중...
if not exist "DoppelgangerHotel.rbxlx" (
    echo  처음 실행이라 place 파일을 만들어요...
    rojo build default.project.json -o DoppelgangerHotel.rbxlx
)
start "" "DoppelgangerHotel.rbxlx"
echo.

echo ============================================
echo  꼭 확인해 주세요!
echo.
echo  1. Studio 오른쪽 위 계정 이름이 "Marthadaram" 인지 확인하세요.
echo     다른 계정이면 로그아웃 후 Marthadaram 으로 다시 로그인하세요.
echo.
echo  2. Studio 위쪽 [플러그인] 탭 - Rojo 창에서
echo     포트를 34873 으로 바꾸고 [Connect] 를 누르세요.
echo     (34872 는 Stealth Animals 용이에요!)
echo.
echo  3. "Rojo - 도플갱어 호텔" 창은 개발이 끝날 때까지 닫지 마세요.
echo ============================================
echo.
pause
