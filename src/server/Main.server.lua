-- 게임 전체 흐름을 담당하는 서버 스크립트예요.
-- 로비 → (혼자 시작) → 낮: 손님 체크인 → 밤: 결과 확인 → 다음 날 ...
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Animals = require(Shared:WaitForChild("Animals"))
local HotelBuilder = require(script.Parent:WaitForChild("HotelBuilder"))
local Npc = require(script.Parent:WaitForChild("Npc"))

local rgb = Color3.fromRGB

---------------------------------------------------------------- 원격 이벤트 (서버 ↔ 화면)
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
	return event
end
local StateEvent = remote("State") -- 서버 → 화면: 몇 일차, 낮/밤, 돈, 희생자
local GuestArrived = remote("GuestArrived") -- 서버 → 화면: 손님이 프론트에 도착
local Toast = remote("Toast") -- 서버 → 화면: 안내 메시지
local NightReport = remote("NightReport") -- 서버 → 화면: 밤 결과
local MorningReport = remote("MorningReport") -- 서버 → 화면: 어제 돌려보낸 손님의 정체
local StartSolo = remote("StartSolo") -- 화면 → 서버: 혼자 시작
local Decide = remote("Decide") -- 화면 → 서버: 예약 받기 / 셔터 닫기
local NextDay = remote("NextDay") -- 화면 → 서버: 다음 날로
local BackToLobby = remote("BackToLobby") -- 화면 → 서버: 로비로 돌아가기
local MorningOk = remote("MorningOk") -- 화면 → 서버: 아침 소식 확인
remotes.Parent = ReplicatedStorage

---------------------------------------------------------------- 월드 준비
local hotel = HotelBuilder.ensure()
local markers = hotel:WaitForChild("Markers")
local shutter = hotel:WaitForChild("Shutter")
local lobbySpawn = workspace:FindFirstChild("LobbySpawn", true)

local guestFolder = Instance.new("Folder")
guestFolder.Name = "Guests"
guestFolder.Parent = workspace
local corpseFolder = Instance.new("Folder")
corpseFolder.Name = "Corpses"
corpseFolder.Parent = workspace

-- 은은한 색감 보정 (살짝 바랜 색, 따뜻한 톤)
local grade = Lighting:FindFirstChild("HotelGrade") or Instance.new("ColorCorrectionEffect")
grade.Name = "HotelGrade"
grade.Saturation = -0.15
grade.Contrast = 0.12
grade.TintColor = rgb(255, 240, 225)
grade.Parent = Lighting

-- 근무 시간(isDay)도 해가 진 뒤라 로비는 어둑어둑해요.
-- 퇴근 후(밤)에는 손님 구역 불이 꺼지고, 촛불·깜빡이는 벽등·직원 구역 빨간 불만 남아요.
local function setDaylight(isDay)
	Lighting.ClockTime = isDay and 19.6 or 2
	Lighting.Brightness = isDay and 0.8 or 0.2
	Lighting.Ambient = isDay and rgb(48, 42, 38) or rgb(14, 13, 20)
	Lighting.OutdoorAmbient = isDay and rgb(60, 58, 75) or rgb(25, 25, 40)
	Lighting.FogColor = isDay and rgb(30, 28, 35) or rgb(8, 8, 15)
	Lighting.FogEnd = isDay and 400 or 160
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.3
	grade.Brightness = isDay and -0.02 or -0.06

	local lights = hotel:FindFirstChild("Lights")
	if not lights then
		return
	end
	for _, lamp in ipairs(lights:GetChildren()) do
		if lamp:IsA("BasePart") then
			if lamp:GetAttribute("Glow") == nil then
				lamp:SetAttribute("Glow", lamp.Material == Enum.Material.Neon)
			end
			local zone = lamp:GetAttribute("Zone")
			local on = isDay or zone == "Staff" or zone == "Flicker" or zone == "Candle" or zone == "Outside"
			if lamp:GetAttribute("Glow") then
				lamp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			end
			local light = lamp:FindFirstChildOfClass("PointLight")
			if light then
				if light:GetAttribute("BaseBrightness") == nil then
					light:SetAttribute("BaseBrightness", light.Brightness)
					light:SetAttribute("BaseColor", light.Color)
				end
				local base = light:GetAttribute("BaseBrightness")
				light.Enabled = on
				if not isDay and zone == "Staff" then
					light.Color = rgb(255, 80, 60)
					light.Brightness = base * 0.5
				else
					light.Color = light:GetAttribute("BaseColor")
					light.Brightness = isDay and base * 0.8 or base
				end
			end
		end
	end
end

local function moveShutter(closed)
	local target = markers:FindFirstChild(closed and "ShutterClosed" or "ShutterOpen")
	local tween = TweenService:Create(
		shutter,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = target.CFrame, Size = target.Size }
	)
	tween:Play()
	tween.Completed:Wait()
end

local function deskCFrame()
	local p = markers.DeskSpawn.Position
	return CFrame.lookAt(p, p + Vector3.new(0, 0, -1))
end

local function lobbyCFrame()
	return lobbySpawn.CFrame + Vector3.new(0, 4, 0)
end

local function teleport(player, cf)
	local character = player.Character
	if character then
		character:PivotTo(cf)
	end
end

local function randomPointIn(area)
	local half = area.Size / 2
	return area.Position + Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1) * Vector3.new(half.X, 0, half.Z)
end

setDaylight(true)

---------------------------------------------------------------- 게임 진행 (세션)
-- 지금은 서버에 게임 하나만 진행돼요. (players 목록은 나중에 4명 함께하기용)
local session = nil
local nextGuestId = 0

local NAMES = {
	"민준", "서연", "도윤", "하은", "지호", "수아", "예준", "지우",
	"시우", "하린", "주원", "채원", "건우", "유나", "우진", "다은",
}

-- 손님 대사 (도플갱어도 똑같이 말해서 대사로는 구별할 수 없어요)
local GREETINGS = {
	"안녕하세요! 예약자 %s입니다. 체크인 부탁해요.",
	"오늘 하룻밤 묵으려고요. 예약한 %s입니다.",
	"먼 길 오느라 힘들었어요... 예약자 %s입니다.",
	"방 준비됐나요? %s 이름으로 예약했어요.",
	"안녕하세요~ 창가 쪽 방이면 좋겠어요. 예약자는 %s입니다.",
}
local THANKS = {
	"감사합니다! 좋은 하루 되세요.",
	"와, 로비 예쁘다! 올라가 볼게요.",
	"고마워요. 엘리베이터는 저쪽이죠?",
	"푹 쉬다 갈게요~",
}
local PROTESTS = {
	"어? 왜 닫아요?!",
	"저기요! 예약했다니까요!",
	"잠깐만요... 문 좀 열어 주세요.",
	"......",
	"이런 호텔은 처음이네요!",
}

local function pick(list)
	return list[math.random(#list)]
end

local function fire(s, event, payload)
	for _, player in ipairs(s.players) do
		if player.Parent then
			event:FireClient(player, payload)
		end
	end
end

local function sendState(s)
	fire(s, StateEvent, {
		phase = s.phase,
		day = s.day,
		money = s.money,
		deaths = s.deaths,
		maxDeaths = Config.MaxDeaths,
		guestIndex = s.guestIndex,
		guestsTotal = s.guestsTotal,
	})
end

-- 조건이 참이 될 때까지 기다려요. 도중에 게임이 끝나면 false 를 돌려줘요.
local function waitUntil(s, check)
	while s.active and not check() do
		task.wait(0.1)
	end
	return s.active
end

local function makeGuestData(isDoppel)
	nextGuestId += 1
	local animal = Animals.List[math.random(#Animals.List)]
	local def = Animals.Types[animal]
	local data = {
		id = nextGuestId,
		name = NAMES[math.random(#NAMES)],
		animal = animal,
		animalName = def.name,
		room = math.random(2, 4) * 100 + math.random(1, 12),
		fur = def.furs[math.random(#def.furs)],
		cloth = Animals.Clothes[math.random(#Animals.Clothes)],
		isDoppel = isDoppel,
	}
	if isDoppel then
		local kind = Animals.AnomalyKinds[math.random(#Animals.AnomalyKinds)]
		local where = (kind == "moving" or math.random() < 0.5) and "photo" or "cctv"
		data.anomaly = { kind = kind, where = where }
	end
	return data
end

-- 오늘 몇 번째 손님이 도플갱어인지 정해요.
local function planDoppels(day, count)
	local plan = {}
	for i = 1, count do
		plan[i] = false
	end
	if day <= Config.PracticeDays then
		return plan
	end
	local chance = math.min(
		Config.DoppelChanceMax,
		Config.DoppelChanceStart + (day - Config.PracticeDays - 1) * Config.DoppelChancePerDay
	)
	local any = false
	for i = 1, count do
		plan[i] = math.random() < chance
		any = any or plan[i]
	end
	if not any then
		plan[math.random(count)] = true -- 하루에 최소 한 명은 와요
	end
	return plan
end

local function runGuest(s, data)
	local model = Animals.build(data, nil) -- 직접 보면 멀쩡해 보여요!
	model.Parent = guestFolder
	s.guestModel = model
	model:PivotTo(CFrame.new(markers.GuestSpawn.Position))

	Npc.walkTo(model, markers.Door.Position, Config.WalkSpeed)
	Npc.walkTo(model, markers.Counter.Position, Config.WalkSpeed)
	if not s.active then
		return
	end
	Npc.face(model, markers.DeskSpawn.Position)

	s.currentGuest = data
	s.decision = nil
	local anomaly = data.anomaly
	local greeting = pick(GREETINGS):format(data.name)
	Npc.say(model, greeting, 6)
	fire(s, GuestArrived, {
		line = greeting,
		id = data.id,
		name = data.name,
		animal = data.animal,
		animalName = data.animalName,
		room = data.room,
		fur = data.fur,
		cloth = data.cloth,
		photoAnomaly = anomaly and anomaly.where == "photo" and anomaly.kind or nil,
		cctvAnomaly = anomaly and anomaly.where == "cctv" and anomaly.kind or nil,
		index = s.guestIndex,
		total = s.guestsTotal,
		day = s.day,
	})

	if not waitUntil(s, function()
		return s.decision ~= nil
	end) then
		return
	end
	local choice = s.decision
	s.currentGuest = nil

	if choice == "accept" then
		-- 도플갱어를 받아도 지금은 티가 안 나요. 밤이 되면 알게 돼요...
		if data.isDoppel then
			table.insert(s.victims, data)
		else
			s.earned += Config.RoomPrice
		end
		Npc.say(model, pick(THANKS), 3)
		fire(s, Toast, { text = "✅ 체크인 완료! " .. data.name .. " 님이 방으로 올라갔어요.", kind = "accept" })
		Npc.walkTo(model, markers.Elevator.Position, Config.WalkSpeed)
	else
		-- 셔터로 돌려보낸 손님이 도플갱어였는지는 다음 날 아침에 알려줘요.
		table.insert(s.refused, { name = data.name, animalName = data.animalName, isDoppel = data.isDoppel })
		Npc.say(model, pick(PROTESTS), 3)
		task.wait(0.8)
		moveShutter(true)
		fire(s, Toast, { text = "🛑 셔터를 내렸어요. 누구였는지는 내일 아침에 알 수 있어요.", kind = "info" })
		task.wait(2.5)
		if s.active then
			moveShutter(false)
		end
	end

	model:Destroy()
	s.guestModel = nil
end

local function runDay(s)
	s.phase = "Day"
	s.earned = 0
	s.victims = {}
	s.guestsTotal = Config.GuestsPerDay
	s.guestIndex = 0

	corpseFolder:ClearAllChildren() -- 밤사이 청소 완료
	setDaylight(true)
	moveShutter(false)
	sendState(s)

	-- 아침 보고서: 어젯밤 피해와 어제 셔터로 돌려보낸 손님의 정체
	if s.day > 1 then
		s.request = nil
		fire(s, MorningReport, {
			day = s.day,
			refused = s.refused,
			victims = s.yesterdayVictims or {},
			earned = s.yesterdayEarned or 0,
			money = s.money,
			deaths = s.deaths,
			maxDeaths = Config.MaxDeaths,
		})
		if not waitUntil(s, function()
			return s.request == "morning"
		end) then
			return
		end
	end
	s.refused = {}

	if s.day <= Config.PracticeDays then
		fire(s, Toast, { text = ("☀️ %d일차 아침! 첫날은 연습이에요. 도플갱어는 오지 않아요."):format(s.day), kind = "info" })
	else
		fire(s, Toast, {
			text = ("☀️ %d일차 아침... 오늘은 도플갱어가 찾아올 거예요. 사진과 CCTV를 꼼꼼히 보세요!"):format(s.day),
			kind = "warn",
		})
	end
	task.wait(3)

	local plan = planDoppels(s.day, s.guestsTotal)
	for i = 1, s.guestsTotal do
		if not s.active then
			return
		end
		s.guestIndex = i
		sendState(s)
		runGuest(s, makeGuestData(plan[i]))
		task.wait(1)
	end
end

-- 밤: 직원이 퇴근하고, 도플갱어가 있었다면 사체가 남아요. 게임 오버면 true.
local function runNight(s)
	s.phase = "Night"
	s.money += s.earned
	s.deaths += #s.victims
	setDaylight(false)

	local area = markers.CorpseArea
	local victimNames = {}
	for _, victim in ipairs(s.victims) do
		Npc.spawnCorpse(victim, randomPointIn(area), corpseFolder)
		table.insert(victimNames, ("%s(%s)"):format(victim.name, victim.animalName))
	end

	s.yesterdayVictims = victimNames
	s.yesterdayEarned = s.earned
	sendState(s)
	local gameOver = s.deaths >= Config.MaxDeaths
	fire(s, NightReport, {
		day = s.day,
		earned = s.earned,
		victims = victimNames,
		refused = gameOver and s.refused or nil, -- 게임이 끝나면 바로 정체를 알려줘요
		money = s.money,
		deaths = s.deaths,
		maxDeaths = Config.MaxDeaths,
		gameOver = gameOver,
	})
	return gameOver
end

local function endSession(s)
	if not s.active then
		return
	end
	s.active = false
	guestFolder:ClearAllChildren()
	corpseFolder:ClearAllChildren()
	setDaylight(true)
	task.spawn(moveShutter, false)
	for _, player in ipairs(s.players) do
		if player.Parent then
			teleport(player, lobbyCFrame())
			StateEvent:FireClient(player, { phase = "Lobby" })
		end
	end
	if session == s then
		session = nil
	end
end

local function runGame(s)
	while s.active do
		runDay(s)
		if not s.active then
			break
		end
		local gameOver = runNight(s)
		s.request = nil
		if not waitUntil(s, function()
			return s.request ~= nil
		end) then
			break
		end
		if gameOver or s.request == "lobby" then
			endSession(s)
			break
		end
		s.day += 1
	end
end

---------------------------------------------------------------- 화면에서 온 요청 처리
local function sessionOf(player)
	if session and table.find(session.players, player) then
		return session
	end
	return nil
end

StartSolo.OnServerEvent:Connect(function(player)
	if session then
		Toast:FireClient(player, {
			text = "지금은 다른 사람이 호텔에서 일하고 있어요. 잠시 후 다시 눌러 주세요.",
			kind = "info",
		})
		return
	end
	local s = {
		active = true,
		players = { player },
		phase = "Day",
		day = 1,
		money = 0,
		deaths = 0,
		guestIndex = 0,
		guestsTotal = 0,
		victims = {},
		refused = {},
	}
	session = s
	teleport(player, deskCFrame())
	task.spawn(runGame, s)
end)

Decide.OnServerEvent:Connect(function(player, guestId, choice)
	local s = sessionOf(player)
	if not s or not s.currentGuest or s.currentGuest.id ~= guestId or s.decision then
		return
	end
	if choice == "accept" or choice == "shutter" then
		s.decision = choice
	end
end)

NextDay.OnServerEvent:Connect(function(player)
	local s = sessionOf(player)
	if s and s.phase == "Night" and not s.request then
		s.request = "next"
	end
end)

MorningOk.OnServerEvent:Connect(function(player)
	local s = sessionOf(player)
	if s and s.phase == "Day" and not s.request then
		s.request = "morning"
	end
end)

BackToLobby.OnServerEvent:Connect(function(player)
	local s = sessionOf(player)
	if s and s.phase == "Night" and not s.request then
		s.request = "lobby"
	end
end)

---------------------------------------------------------------- 플레이어 입장/퇴장
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		-- 게임 중에 캐릭터가 다시 생기면 프론트로 돌려보내요.
		if sessionOf(player) then
			character:WaitForChild("HumanoidRootPart")
			task.wait(0.1)
			character:PivotTo(deskCFrame())
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	local s = sessionOf(player)
	if not s then
		return
	end
	table.remove(s.players, table.find(s.players, player))
	if #s.players == 0 then
		endSession(s)
	end
end)

print("[도플갱어 호텔] 서버 준비 완료!")
