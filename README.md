# roblox-doppelganger-hotel

Roblox 게임 **도플갱어 호텔** (계정: Marthadaram)

## 처음 한 번만 하기

1. 문서 폴더에서 이 저장소를 clone 해요.
   ```
   cd %USERPROFILE%\Documents
   git clone https://github.com/kimtaenim/roblox-doppelganger-hotel.git
   ```
2. 폴더 안의 `make_shortcut.bat` 을 더블클릭해요.
   → 바탕화면에 **"도플갱어 호텔 시작 (Marthadaram)"** 바로가기가 생겨요.

## 매일 개발 시작하기

바탕화면의 **"도플갱어 호텔 시작 (Marthadaram)"** 을 더블클릭하면 자동으로:

1. `git pull` — 최신 코드 받기
2. `rokit install` — Rojo 7.4.4 확인
3. `rojo serve --port 34873` — 새 창에서 Rojo 서버 켜기
4. Roblox Studio 열기

그다음 Studio에서:

- 오른쪽 위 계정이 **Marthadaram** 인지 확인하기
- [플러그인] 탭 → Rojo → 포트를 **34873** 으로 바꾸고 **Connect**

> Stealth Animals는 34872 포트, 이 게임은 34873 포트라서 두 게임을 동시에 켜도 부딪히지 않아요.

## 폴더 구조

| 폴더 | Studio에서 위치 | 설명 |
|---|---|---|
| `src/server` | ServerScriptService.Server | 서버 스크립트 |
| `src/client` | StarterPlayer.StarterPlayerScripts.Client | 플레이어 스크립트 |
| `src/shared` | ReplicatedStorage.Shared | 함께 쓰는 모듈 |
