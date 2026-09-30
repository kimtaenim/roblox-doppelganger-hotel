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

## 게임 방법

1. 로비에서 **[혼자 시작]** 을 누르면 호텔 프론트로 이동해요.
2. 손님(동물)이 프론트로 걸어오면 **예약 사진**과 **CCTV** 화면이 떠요.
3. 이상한 점이 없으면 **✅ 예약 받기**, 이상한 점이 있으면 **🛑 셔터 닫기**.
   - 이빨이 드러남 / 입이 쭉 찢어짐 / 눈이 검게 가려짐 / 몸이 이상함(긴 목, 긴 팔) / 사진이 움직임
4. 손님이 다 오면 밤이 돼요. 도플갱어를 받았다면 로비에 손님의 사체가 남고, 그 손님 돈은 못 받아요.
5. 첫날은 연습(도플갱어 없음), 둘째 날부터 도플갱어가 와요. 희생자가 3명이면 해고!

### 테스트하기

Studio에서 Rojo가 연결된 상태로 **플레이(▶ Play)** 를 누르세요.
호텔 건물은 플레이를 누를 때 스크립트가 자동으로 지어요. (편집 화면에는 안 보여요)

### 난이도 바꾸기

`src/shared/Config.lua` 에서 하루 손님 수, 도플갱어 확률, 방 값, 최대 희생자 수를 바꿀 수 있어요.

## 폴더 구조

| 폴더 | Studio에서 위치 | 설명 |
|---|---|---|
| `src/server` | ServerScriptService.Server | 서버 스크립트 |
| `src/client` | StarterPlayer.StarterPlayerScripts.Client | 플레이어 스크립트 |
| `src/shared` | ReplicatedStorage.Shared | 함께 쓰는 모듈 |

| 파일 | 하는 일 |
|---|---|
| `src/server/Main.server.lua` | 게임 흐름 (낮/밤, 손님, 돈, 희생자) |
| `src/server/HotelBuilder.lua` | 땅, 로비, 호텔 건물(아파트 모양) 짓기 |
| `src/server/Npc.lua` | 손님 걷기, 밤에 사체 놓기 |
| `src/shared/Animals.lua` | 동물 손님 모양과 도플갱어의 이상한 점 |
| `src/shared/Config.lua` | 난이도 설정 |
| `src/client/Main.client.lua` | 화면(로비, 체크인, CCTV, 밤 결과) |
