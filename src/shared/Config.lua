-- 서버와 클라이언트가 함께 쓰는 설정값이에요.
-- 숫자를 바꾸면 게임 난이도를 쉽게 조절할 수 있어요.
local Config = {
	GameName = "도플갱어 호텔",

	MaxPlayers = 4, -- 나중에 친구와 함께하기에서 쓸 최대 인원

	GuestsPerDay = 5, -- 하루에 찾아오는 손님 수
	PracticeDays = 1, -- 이 날까지는 연습 (도플갱어 없음)

	-- 연습이 끝난 첫날의 도플갱어 확률, 하루마다 늘어나는 양, 최대 확률
	DoppelChanceStart = 0.3,
	DoppelChancePerDay = 0.1,
	DoppelChanceMax = 0.6,

	RoomPrice = 100, -- 평범한 손님을 받으면 버는 돈
	MaxDeaths = 3, -- 희생자가 이만큼 되면 해고 (게임 오버)

	WalkSpeed = 10, -- 손님이 걷는 속도
}

return Config
