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

1. 호텔 길 건너편 **광장**에서 시작해요. 바닥의 **노란 네모** 안으로 들어가면 몇 명이서 근무할지(1~4명) 고를 수 있어요.
   - 2명 이상을 고르면 친구들이 노란 네모 안으로 들어올 때까지 기다려요. 방장은 **[지금 인원으로 시작]** 도 할 수 있어요.
2. 손님(동물)이 프런트로 걸어오면 **예약 확인서**가 뜨고, **[CCTV 보기]** 버튼으로 CCTV를 볼 수 있어요.
3. 이상한 점이 없으면 **예약 받기**, 이상한 점이 있으면 **셔터 닫기**.
   - 이빨이 드러남 / 입이 쭉 찢어짐 / 눈이 검게 가려짐 / 몸이 이상함(긴 목, 긴 팔) / 사진이 움직임
4. 셔터로 돌려보낸 손님이 도플갱어였는지는 **다음 날 아침 보고서**에서 알려줘요.
5. 손님이 다 오면 근무가 끝나요. 도플갱어를 받았다면 로비에 손님의 사체가 남고, 그 손님 돈은 못 받아요.
6. 첫날은 연습(도플갱어 없음), 둘째 날부터 도플갱어가 와요. 희생자가 3명이면 해고!
7. **정신력**은 시간이 지나면 줄고, 놀라거나 사체를 보면 크게 줄어요. 다 떨어지면 쓰러져서 광장으로 나가요.
   - 직원 공간 왼쪽의 **음료 기계**에서 음료를 마시면 채워져요. (기계마다 하룻밤에 2잔)
8. **꼬마 손님 도토리**가 3일차부터 3일마다 찾아와요.
   - 3일차: 음료를 달라고 해요 · 6일차: 책가방을 맡아 달라고 해요 · 9일차: 그 책가방을 숨겨 달라고 해요
   - 오른쪽 벽의 **직원 사물함**에 숨겨 주면 보답으로 **음료 기계가 하나 더** 생겨요.
9. 프런트 오른쪽 **STAFF ONLY** 문으로 로비에 나갈 수 있어요.

### 테스트하기

Studio에서 Rojo가 연결된 상태로 **플레이(▶ Play)** 를 누르세요.
호텔 건물은 플레이를 누를 때 스크립트가 자동으로 지어요. (편집 화면에는 안 보여요)

### 조명이 밋밋하게 보이면

이 게임은 **Future** 조명(실시간 그림자, 불빛 번짐)을 써요. Rojo가 자동으로 켜 주지만,
안 바뀌어 있으면 Studio 탐색기에서 **Lighting** 을 누르고 속성 창의 **Technology** 를 **Future** 로 바꿔 주세요.

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
| `src/server/LobbyDecor.lua` | 호텔 1층 로비 꾸미기 (프론트, 가구, 오싹한 소품, 움직이는 소품) |
| `src/server/StaffRoom.lua` | 프런트 뒤 직원 공간 (음료 기계, 사물함, 열쇠 걸이, 책상, 화분 등) |
| `src/server/Props.lua` | 꽃, 화분, 책가방 같은 소품 만들기 도우미 |
| `src/server/Npc.lua` | 손님 걷기, 밤에 사체 놓기 |
| `src/shared/Animals.lua` | 동물 손님 모양과 도플갱어의 이상한 점 |
| `src/shared/Config.lua` | 난이도 설정 |
| `src/shared/Sounds.lua` | 배경 소리 번호 목록 (바꾸고 싶으면 여기) |
| `src/client/Ambience.client.lua` | 시계·부엉이·박쥐·엘리베이터·먼 경찰차 소리 |
| `src/client/Main.client.lua` | 화면(로비, 체크인, CCTV, 밤 결과) |
