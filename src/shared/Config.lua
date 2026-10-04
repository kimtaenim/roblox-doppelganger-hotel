-- 서버와 클라이언트가 함께 쓰는 설정값이에요.
-- 숫자를 바꾸면 게임 난이도를 쉽게 조절할 수 있어요.
local Config = {
	GameName = "도플갱어 호텔",

	MaxPlayers = 4, -- 함께 근무할 수 있는 최대 인원

	GuestsPerDay = 5, -- 하루에 찾아오는 손님 수
	PracticeDays = 1, -- 이 날까지는 연습 (도플갱어 없음)

	-- 연습이 끝난 첫날의 도플갱어 확률, 하루마다 늘어나는 양, 최대 확률
	DoppelChanceStart = 0.3,
	DoppelChancePerDay = 0.1,
	DoppelChanceMax = 0.6,

	RoomPrice = 100, -- 평범한 손님을 받으면 버는 돈
	MaxDeaths = 3, -- 희생자가 이만큼 되면 해고 (게임 오버)

	WalkSpeed = 10, -- 손님이 걷는 속도

	-- 정신력: 근무하는 동안 조금씩 줄고, 다 떨어지면 쓰러져서 호텔 밖(로비)으로 나가요.
	SanityMax = 100,
	SanityDrainShift = 0.45, -- 밤 근무 중 1초에 줄어드는 양 (하루가 지날수록 조금씩 더 빨라져요)
	SanityDrainPerDay = 0.08, -- 하루마다 빨라지는 비율
	SanityDrainNight = 0.3, -- 근무가 끝난 뒤 1초에 줄어드는 양
	SanityScareLoss = 8, -- 도플갱어에게 놀랐을 때 줄어드는 양
	SanityCorpseLoss = 10, -- 밤에 사체를 봤을 때 줄어드는 양 (한 구마다)

	-- 음료 기계: 마시면 정신력이 채워져요. 기계마다 하룻밤에 몇 잔씩 나와요.
	DrinkRestore = 40,
	DrinksPerMachine = 2,

	-- 꼬마 손님: 이 날부터, 이 날마다 찾아와요. (3일차, 6일차, 9일차, ...)
	KidFirstDay = 3,
	KidEveryDays = 3,
}

return Config
