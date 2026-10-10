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
	MaxDeaths = 3, -- 실종자가 이만큼 되면 해고 (게임 오버)

	WalkSpeed = 10, -- 손님이 걷는 속도

	-- 정신력: 근무하는 동안 조금씩 줄고, 다 떨어지면 쓰러져서 호텔 밖(로비)으로 나가요.
	SanityMax = 100,
	SanityDrainShift = 0.08, -- 손님 받는 동안 1초에 줄어드는 양 (하루가 지날수록 조금씩 더 빨라져요)
	SanityDrainPerDay = 0.03, -- 하루마다 빨라지는 비율
	SanityDrainPatrol = 0.06, -- 야간 순찰 중 1초에 줄어드는 양
	SanityDrainNight = 0.04, -- 근무가 끝난 뒤 1초에 줄어드는 양
	SanityScareLoss = 6, -- 도플갱어에게 놀랐을 때 줄어드는 양
	SanityCorpseLoss = 8, -- 밤에 실종된 손님의 소지품을 봤을 때 줄어드는 양 (한 명마다)

	-- 음료 기계: 마시면 정신력이 채워져요. 기계마다 하룻밤에 몇 잔씩 나와요.
	DrinkRestore = 40,
	DrinksPerMachine = 2,
	DrinkBagMax = 3, -- 가방에 넣고 다닐 수 있는 음료 개수

	-- 꼬마 손님: 이 날부터, 이 날마다 찾아와요. (3일차, 6일차, 9일차, ...)
	KidFirstDay = 3,
	KidEveryDays = 3,

	-- 야간 순찰 + 룸서비스
	PatrolTime = 300, -- 순찰 제한 시간 (초)

	-- 날짜마다 새로 나타나는 도플갱어 모습과 복도 이상 (그날부터 계속 나올 수 있어요)
	-- doppel: 손님 도플갱어의 모습 / floor: 순찰 복도에 생기는 층 전체 이상
	Unlocks = {
		{ day = 2, doppel = { "teeth", "mouth", "eyes" }, floor = { "eyes", "red", "blood" } },
		{ day = 3, doppel = { "moving" }, floor = { "doors" } },
		{ day = 4, doppel = { "body" }, floor = { "balloons" } },
		{ day = 5, doppel = { "noface" }, floor = { "flip" } },
		{ day = 6, doppel = { "manyeyes" }, floor = { "crowd" } },
		{ day = 7, doppel = { "upside" }, floor = { "giant" } },
		{ day = 8, doppel = {}, floor = { "flood" } },
	},
	RoomServiceTip = 30, -- 진짜 손님에게 배달하면 받는 팁
	RoomServiceScareLoss = 15, -- 도플갱어·빈방에 들어갔을 때 줄어드는 정신력
	CallRingTime = 40, -- 전화가 울리는 시간 (안 받으면 끊겨요)
	FloorReportBonus = 20, -- 이상한 게 있는 층을 "있다"고 맞히면 받는 수당
	FloorFalsePenalty = 15, -- 아무 이상 없는 층을 "있다"고 했을 때 벌금
	FloorMissLoss = 6, -- 이상한 게 있었는데 "없다"고 했을 때, 놓친 것 하나마다 줄어드는 정신력
}

-- 오늘(day)까지 나타난 도플갱어 모습 / 복도 이상 목록
function Config.unlocked(kindName, day)
	local list = {}
	for _, step in ipairs(Config.Unlocks) do
		if step.day <= day then
			for _, kind in ipairs(step[kindName]) do
				table.insert(list, kind)
			end
		end
	end
	return list
end

-- 딱 오늘(day) 처음 나타나는 것들
function Config.newOn(day)
	for _, step in ipairs(Config.Unlocks) do
		if step.day == day then
			return step
		end
	end
	return nil
end

return Config
