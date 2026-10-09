-- 게임 전체 흐름을 담당하는 서버 스크립트예요.
-- 광장(로비) → 노란 네모에서 인원 정하기 → 밤 근무: 손님 체크인 → 근무 끝: 결과 확인 → 아침 보고서 → 다음 날 밤 ...
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Animals = require(Shared:WaitForChild("Animals"))
local HotelBuilder = require(script.Parent:WaitForChild("HotelBuilder"))
local Npc = require(script.Parent:WaitForChild("Npc"))
local StaffRoom = require(script.Parent:WaitForChild("StaffRoom"))
local Props = require(script.Parent:WaitForChild("Props"))
local Floors = require(script.Parent:WaitForChild("Floors"))
local Patrol = require(script.Parent:WaitForChild("Patrol"))

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
local StateEvent = remote("State") -- 서버 → 화면: 몇 일차, 근무 중/근무 끝, 돈, 희생자
local GuestArrived = remote("GuestArrived") -- 서버 → 화면: 손님이 프론트에 도착
local Toast = remote("Toast") -- 서버 → 화면: 안내 메시지
local NightReport = remote("NightReport") -- 서버 → 화면: 밤 결과
local MorningReport = remote("MorningReport") -- 서버 → 화면: 어제 돌려보낸 손님의 정체
local SanityEvent = remote("Sanity") -- 서버 → 화면: 내 정신력
local Scared = remote("Scared") -- 화면 → 서버: 도플갱어에게 놀랐어요
local KidEvent = remote("KidEvent") -- 서버 → 화면: 꼬마 손님의 부탁 (고르기)
local KidChoice = remote("KidChoice") -- 화면 → 서버: 꼬마 손님 부탁에 대한 대답
local PartyPrompt = remote("PartyPrompt") -- 서버 → 화면: 몇 명이서 할지 고르기
local PartySize = remote("PartySize") -- 화면 → 서버: 인원 선택
local PartyStatus = remote("PartyStatus") -- 서버 → 화면: 대기 인원
local PartyClosed = remote("PartyClosed") -- 서버 → 화면: 대기 창 닫기
local PartyStartNow = remote("PartyStartNow") -- 화면 → 서버: 지금 인원으로 바로 시작
local Decide = remote("Decide") -- 화면 → 서버: 예약 받기 / 셔터 닫기
local NextDay = remote("NextDay") -- 화면 → 서버: 다음 날로
local BackToLobby = remote("BackToLobby") -- 화면 → 서버: 로비로 돌아가기
local MorningOk = remote("MorningOk") -- 화면 → 서버: 아침 소식 확인
local PatrolState = remote("PatrolState") -- 서버 → 화면: 순찰 목록, 남은 시간, 룸서비스 주문
local Peephole = remote("Peephole") -- 서버 → 화면: 노크했더니 손님이 체인을 건 채 문을 빼꼼 열었어요
local PeepholeChoice = remote("PeepholeChoice") -- 화면 → 서버: 건네주기 / 문 앞에 두고 가기
local Inventory = remote("Inventory") -- 서버 → 화면: 가방 속 음료 개수
local UseDrink = remote("UseDrink") -- 화면 → 서버: 가방의 음료 마시기
local AskFloor = remote("AskFloor") -- 서버 → 화면: 엘리베이터에서 "이 층에 이상한 게 있었나요?"
local AskFloorAnswer = remote("AskFloorAnswer") -- 화면 → 서버: 있었다 / 없었다
local NightFx = remote("NightFx") -- 서버 → 화면: 순찰 중 공포 효과 (깜짝 놀람, 속삭임, 엘리베이터 암전)
remotes.Parent = ReplicatedStorage

---------------------------------------------------------------- 월드 준비
local hotel = HotelBuilder.ensure()
local markers = hotel:WaitForChild("Markers")
local shutter = hotel:WaitForChild("Shutter")
local lobbySpawn = workspace:FindFirstChild("LobbySpawn", true)
local floors = Floors.build(hotel) -- 2~4층 객실 복도

local guestFolder = Instance.new("Folder")
guestFolder.Name = "Guests"
guestFolder.Parent = workspace
local corpseFolder = Instance.new("Folder")
corpseFolder.Name = "Corpses"
corpseFolder.Parent = workspace

-- 후처리 효과: 불빛 번짐(Bloom), 먼 곳 흐림(DepthOfField), 공기 속 안개(Atmosphere)
local function effect(className, name, props)
	local inst = Lighting:FindFirstChild(name) or Instance.new(className)
	inst.Name = name
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = Lighting
	return inst
end
effect("BloomEffect", "HotelBloom", { Intensity = 0.7, Size = 28, Threshold = 1.1 })
effect("DepthOfFieldEffect", "HotelFocus", { FarIntensity = 0.3, FocusDistance = 25, InFocusRadius = 35, NearIntensity = 0 })
effect("Atmosphere", "HotelAir", {
	Density = 0.38,
	Offset = 0.1,
	Color = rgb(70, 60, 70),
	Decay = rgb(40, 30, 40),
	Glare = 0,
	Haze = 2,
})

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
	Lighting.Ambient = isDay and rgb(34, 29, 26) or rgb(12, 11, 18)
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
			local on = isDay or zone == "Staff" or zone == "Flicker" or zone == "Candle" or zone == "Outside" or zone == "Corridor"
			if lamp:GetAttribute("Glow") then
				lamp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
			end
			local light = lamp:FindFirstChildWhichIsA("Light") -- PointLight, SpotLight 모두
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

-- 여러 명이면 나란히 서요.
local DESK_OFFSETS = { 0, -4, 4, -8 }
local function deskCFrame(index)
	local p = markers.DeskSpawn.Position + Vector3.new(DESK_OFFSETS[index or 1] or 0, 0, 0)
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

---------------------------------------------------------------- 정신력
local function sendSanity(s, player)
	SanityEvent:FireClient(player, { value = s.sanity[player] or 0, max = Config.SanityMax })
end

local faint -- 아래에서 정의해요 (정신력이 0이 되면 쓰러짐)

local function changeSanity(s, player, amount)
	if not s.sanity[player] then
		return
	end
	s.sanity[player] = math.clamp(s.sanity[player] + amount, 0, Config.SanityMax)
	sendSanity(s, player)
	if s.sanity[player] <= 0 then
		faint(s, player)
	end
end

---------------------------------------------------------------- 음료 기계
-- 음료는 기계에서 챙겨서 가방에 넣고 다니다가, 아무 데서나 꺼내 마셔요. (가방엔 최대 Config.DrinkBagMax 개)
local function sendInventory(s, player)
	Inventory:FireClient(player, { drinks = s.drinks[player] or 0, max = Config.DrinkBagMax })
end

local staff = StaffRoom.setup(hotel, function(player, _machine, stock)
	local s = session
	if not s or not table.find(s.players, player) then
		Toast:FireClient(player, { text = "근무 중인 직원만 챙길 수 있어요.", kind = "info" })
		return false
	end
	if stock <= 0 then
		Toast:FireClient(player, { text = "🥤 음료가 다 떨어졌어요. 다음 밤 근무에 다시 채워져요.", kind = "info" })
		return false
	end
	local count = s.drinks[player] or 0
	if count >= Config.DrinkBagMax then
		Toast:FireClient(player, { text = "🎒 가방이 꽉 찼어요. 먼저 하나 마셔요. (1번 키)", kind = "info" })
		return false
	end
	s.drinks[player] = count + 1
	sendInventory(s, player)
	Toast:FireClient(player, { text = ("🥤 음료를 가방에 챙겼어요 (%d/%d). 1번 키나 가방 버튼으로 마셔요."):format(count + 1, Config.DrinkBagMax), kind = "accept" })
	return true
end)

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

---------------------------------------------------------------- 야간 순찰 + 룸서비스 준비
-- 프런트 전화기: 순찰 중에 울리면 받아요.
local phone = hotel:FindFirstChild("PhoneBase", true)
local phonePrompt = Instance.new("ProximityPrompt")
phonePrompt.ActionText = "전화 받기"
phonePrompt.ObjectText = "프런트 전화"
phonePrompt.HoldDuration = 0
phonePrompt.MaxActivationDistance = 8
phonePrompt.RequiresLineOfSight = false
phonePrompt.Enabled = false
phonePrompt.Parent = phone or markers.DeskSpawn
local ringSound = Instance.new("Sound")
ringSound.Name = "PhoneRing"
ringSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
ringSound.Looped = true
ringSound.Volume = 0.7
ringSound.PlaybackSpeed = 1.3
ringSound.RollOffMaxDistance = 120
ringSound.Parent = phone or markers.DeskSpawn

-- 프런트 종: 순찰 일을 다 마치면 여기서 퇴근해요.
local bell = hotel:FindFirstChild("Bell", true)
local leavePrompt = Instance.new("ProximityPrompt")
leavePrompt.ActionText = "퇴근하기"
leavePrompt.ObjectText = "프런트 종"
leavePrompt.KeyboardKeyCode = Enum.KeyCode.Q
leavePrompt.HoldDuration = 0.5
leavePrompt.MaxActivationDistance = 8
leavePrompt.RequiresLineOfSight = false
leavePrompt.Enabled = false
leavePrompt.Parent = bell or markers.DeskSpawn

Patrol.init({
	leavePrompt = leavePrompt,
	floors = floors,
	Animals = Animals,
	Config = Config,
	phonePrompt = phonePrompt,
	ringSound = ringSound,
	remotes = {
		Toast = Toast,
		PatrolState = PatrolState,
		Peephole = Peephole,
		PeepholeChoice = PeepholeChoice,
		NightFx = NightFx,
		AskFloor = AskFloor,
		AskFloorAnswer = AskFloorAnswer,
	},
	fire = function(s, event, payload)
		fire(s, event, payload)
	end,
	fireTo = function(player, event, payload)
		if player.Parent then
			event:FireClient(player, payload)
		end
	end,
	changeSanity = function(s, player, amount)
		changeSanity(s, player, amount)
	end,
	teleport = teleport,
})

-- 조건이 참이 될 때까지 기다려요. 도중에 게임이 끝나면 false 를 돌려줘요.
local function waitUntil(s, check)
	while s.active and not check() do
		task.wait(0.1)
	end
	return s.active
end

-- 오늘 아직 아무도 묵지 않는 방 (2~4층, 01~12호)
local function freeRoom(used)
	for _ = 1, 100 do
		local room = math.random(2, 4) * 100 + math.random(1, 12)
		if not used[room] then
			used[room] = true
			return room
		end
	end
	return 201
end

local function makeGuestData(isDoppel, usedRooms)
	nextGuestId += 1
	local animal = Animals.List[math.random(#Animals.List)]
	local def = Animals.Types[animal]
	local data = {
		id = nextGuestId,
		name = NAMES[math.random(#NAMES)],
		animal = animal,
		animalName = def.name,
		room = freeRoom(usedRooms or {}),
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
		table.insert(s.accepted, data) -- 밤 순찰 때 이 방을 확인해요
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

---------------------------------------------------------------- 꼬마 손님 "도토리"
-- 3일차: 음료를 달라고 해요 / 6일차: 책가방을 맡아 달라고 해요 /
-- 9일차: 그 책가방을 숨겨 달라고 해요 (숨겨 주면 보답으로 음료 기계가 하나 더 생겨요) / 그 뒤로는 다시 음료
local KID = { id = 777, name = "도토리", animal = "rabbit", fur = rgb(205, 165, 125), cloth = rgb(240, 200, 60) }

local function askKid(s, line, choices)
	s.kidChoice = nil
	s.kidAskId = (s.kidAskId or 0) + 1
	fire(s, KidEvent, { id = s.kidAskId, speaker = "꼬마 손님 도토리", line = line, choices = choices })
	if not waitUntil(s, function()
		return s.kidChoice ~= nil
	end) then
		return nil
	end
	return s.kidChoice
end

local function runKid(s)
	local kid = Animals.build(KID, nil)
	-- 어린이라서 어른보다 머리 하나만큼 작아요.
	pcall(function()
		kid:ScaleTo(0.8 * 0.6) -- 어른(0.8) 키의 60%
	end)
	local stage = "drink"
	if s.day == Config.KidFirstDay + Config.KidEveryDays then
		stage = "bag"
	elseif s.day == Config.KidFirstDay + Config.KidEveryDays * 2 then
		stage = s.keptBag and "hide" or "sad"
	end
	if stage == "bag" then
		-- 등에 노란 책가방을 메고 와요.
		local bag = Props.backpack(kid, CFrame.new())
		pcall(function()
			bag:ScaleTo(0.6)
		end)
		bag:PivotTo(kid:GetPivot() * CFrame.new(0, 1.9, 0.95))
	end
	kid.Parent = guestFolder
	s.guestModel = kid
	kid:PivotTo(CFrame.new(markers.GuestSpawn.Position))
	Npc.walkTo(kid, markers.Door.Position, Config.WalkSpeed * 0.8)
	Npc.walkTo(kid, markers.Counter.Position, Config.WalkSpeed * 0.8)
	if not s.active then
		return
	end
	-- 키가 작아서 낮은 받침대 위에 올라서요.
	local stool = Props.solid(guestFolder, "Stool", Vector3.new(1.8, 0.9, 1.8), CFrame.new(markers.Counter.Position + Vector3.new(0, 0.35, 0)), rgb(110, 70, 45), Enum.Material.Wood)
	kid:PivotTo(CFrame.new(markers.Counter.Position + Vector3.new(0, 0.9, 0)))
	Npc.face(kid, markers.DeskSpawn.Position)

	local function say(line)
		Npc.say(kid, line, 5)
	end

	if stage == "drink" then
		local line = "저기요... 목이 너무 말라요. 음료 하나만 주실 수 있어요?"
		say(line)
		local choice = askKid(s, line, { "음료 주기", "거절하기" })
		if choice == 1 then
			if staff.takeDrink() then
				s.kidFriend = (s.kidFriend or 0) + 1
				say("와아, 고마워요! 이 은혜 꼭 갚을게요!")
				fire(s, Toast, { text = "🥤 도토리에게 음료를 한 잔 줬어요.", kind = "accept" })
			else
				say("...음료가 없구나. 괜찮아요.")
				fire(s, Toast, { text = "음료 기계가 비어 있어요.", kind = "info" })
			end
		elseif choice == 2 then
			say("...네. 알겠어요.")
		end
	elseif stage == "bag" then
		local line = "이 책가방 좀 맡아 주실래요? 꼭... 꼭 다시 찾으러 올게요."
		say(line)
		local choice = askKid(s, line, { "맡아 주기", "거절하기" })
		if choice == 1 then
			s.keptBag = true
			local bag = kid:FindFirstChild("Backpack")
			if bag then
				bag:Destroy()
			end
			staff.setBag(true)
			say("고마워요! 아무한테도 주면 안 돼요!")
			fire(s, Toast, { text = "🎒 도토리의 책가방을 맡았어요. 직원 책상 위에 있어요.", kind = "accept" })
		elseif choice == 2 then
			say("...그렇구나.")
		end
	elseif stage == "hide" then
		local line = "누가 저를 쫓아와요...! 그 책가방, 아무도 못 찾게 숨겨 주세요!"
		say(line)
		local choice = askKid(s, line, { "숨기러 가기", "거절하기" })
		if choice == 1 then
			say("고마워요...! 빨리요!")
			fire(s, Toast, { text = "🎒 오른쪽 벽의 반짝이는 직원 사물함에 책가방을 숨기세요!", kind = "warn" })
			s.bagHidden = false
			staff.enableHide(true)
			local deadline = os.clock() + 45
			waitUntil(s, function()
				return s.bagHidden or os.clock() > deadline
			end)
			staff.enableHide(false)
			if s.bagHidden then
				staff.setBag(false)
				s.keptBag = false
				task.wait(1)
				staff.addMachine(Config.DrinksPerMachine)
				fire(s, Toast, {
					text = "🎁 사물함 안에 쪽지가 있어요: \"고마워요. 선물이에요.\" 음료 기계가 하나 더 생겼어요!",
					kind = "accept",
				})
			elseif s.active then
				fire(s, Toast, { text = "...시간이 지나 버렸어요. 도토리는 어디로 갔을까요.", kind = "info" })
			end
		elseif choice == 2 then
			say("......")
		end
	else -- sad
		local line = "...제 책가방, 아무도 안 맡아 줬어요. 이제 어떡하죠."
		say(line)
		askKid(s, line, { "미안해", "모른 척하기" })
	end

	if s.active and kid.Parent then
		task.wait(1.5)
		kid:PivotTo(CFrame.new(markers.Counter.Position))
		stool:Destroy()
		Npc.walkTo(kid, markers.Door.Position, Config.WalkSpeed)
		Npc.walkTo(kid, markers.GuestSpawn.Position, Config.WalkSpeed)
	end
	stool:Destroy()
	kid:Destroy()
	s.guestModel = nil
	task.wait(1)
end

local function runDay(s)
	s.phase = "Day"
	s.earned = 0
	s.victims = {}
	s.accepted = {}
	s.usedRooms = {}
	-- 며칠째 묵고 있는 다른 투숙객들: 몇 명은 체크아웃하고, 새 손님이 들어와 방을 채워요.
	-- (오늘 내가 받는 손님은 남은 빈방에 들어가요)
	s.residents = s.residents or {}
	local staying = {}
	for _, resident in ipairs(s.residents) do
		if math.random() < 0.7 then
			table.insert(staying, resident)
			s.usedRooms[resident.room] = true
		end
	end
	local target = math.random(12, 16)
	while #staying < target do
		local resident = makeGuestData(false, s.usedRooms)
		resident.resident = true
		table.insert(staying, resident)
	end
	s.residents = staying
	s.guestsTotal = Config.GuestsPerDay
	s.guestIndex = 0

	corpseFolder:ClearAllChildren() -- 밤사이 청소 완료
	staff.refill(Config.DrinksPerMachine) -- 음료 기계 채우기
	setDaylight(true)
	-- 모두 프런트 자리로
	for i, player in ipairs(s.players) do
		teleport(player, deskCFrame(i))
	end
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
			patrol = s.yesterdayPatrol,
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
		fire(s, Toast, { text = ("🌙 %d일차 밤 근무 시작! 첫날은 연습이에요. 도플갱어는 오지 않아요."):format(s.day), kind = "info" })
	else
		fire(s, Toast, {
			text = ("🌙 %d일차 밤 근무... 오늘은 도플갱어가 찾아올 거예요. 사진과 CCTV를 꼼꼼히 보세요!"):format(s.day),
			kind = "warn",
		})
	end
	task.wait(3)

	-- 꼬마 손님 (3일차부터 3일마다)
	if s.day >= Config.KidFirstDay and (s.day - Config.KidFirstDay) % Config.KidEveryDays == 0 then
		runKid(s)
		if not s.active then
			return
		end
	end

	local plan = planDoppels(s.day, s.guestsTotal)
	for i = 1, s.guestsTotal do
		if not s.active then
			return
		end
		s.guestIndex = i
		sendState(s)
		runGuest(s, makeGuestData(plan[i], s.usedRooms))
		task.wait(1)
	end
end

-- 손님을 다 받은 뒤: 야간 순찰 + 룸서비스. 찾아낸 도플갱어 방은 봉쇄돼서 희생자가 생기지 않아요.
local function runPatrol(s)
	s.phase = "Patrol"
	setDaylight(false)
	moveShutter(true) -- 정문 셔터를 내리고 순찰을 돌아요
	sendState(s)
	local result = Patrol.run(s)
	if not s.active then
		return
	end
	s.patrol = result
	-- 봉쇄한 방의 도플갱어는 오늘 밤 아무도 해치지 못해요.
	local remaining = {}
	for _, victim in ipairs(s.victims) do
		if not result.isolated[victim.id] then
			table.insert(remaining, victim)
		end
	end
	s.victims = remaining
	s.earned += result.tips + result.bonus - result.penalty
	for i, player in ipairs(s.players) do
		teleport(player, deskCFrame(i))
	end
	moveShutter(false)
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
	s.yesterdayPatrol = s.patrol
	if #s.victims > 0 then
		for _, player in ipairs(s.players) do
			changeSanity(s, player, -Config.SanityCorpseLoss * #s.victims)
		end
	end
	sendState(s)
	local gameOver = s.deaths >= Config.MaxDeaths
	fire(s, NightReport, {
		day = s.day,
		earned = s.earned,
		victims = victimNames,
		patrol = s.patrol,
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
	staff.reset()
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

-- 정신력이 0이 되면 쓰러져서 호텔 밖 광장으로 나가요.
faint = function(s, player)
	local index = table.find(s.players, player)
	if not index then
		return
	end
	table.remove(s.players, index)
	s.sanity[player] = nil
	if player.Parent then
		teleport(player, lobbyCFrame())
		StateEvent:FireClient(player, { phase = "Lobby" })
		Toast:FireClient(player, { text = "😵 정신을 잃고 쓰러졌어요... 눈을 떠 보니 호텔 밖이에요.", kind = "warn" })
	end
	if #s.players == 0 then
		endSession(s)
	else
		fire(s, Toast, { text = ("😵 %s 님이 정신을 잃고 쓰러졌어요..."):format(player.DisplayName), kind = "warn" })
	end
end

local function runGame(s)
	while s.active do
		runDay(s)
		if not s.active then
			break
		end
		s.patrol = nil
		runPatrol(s)
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

-- 근무 시작: 고른 인원으로 세션을 만들고 모두 프런트로 보내요.
local function startSession(players)
	local s = {
		active = true,
		players = {},
		sanity = {},
		phase = "Day",
		day = 1,
		money = 0,
		deaths = 0,
		guestIndex = 0,
		guestsTotal = 0,
		victims = {},
		refused = {},
		drinks = {},
		accepted = {},
		usedRooms = {},
	}
	for i, player in ipairs(players) do
		table.insert(s.players, player)
		s.sanity[player] = Config.SanityMax
		teleport(player, deskCFrame(i))
		PartyClosed:FireClient(player)
		sendSanity(s, player)
		sendInventory(s, player)
	end
	session = s
	task.spawn(runGame, s)

	-- 정신력이 1초마다 조금씩 줄어요. (날이 갈수록 빨라져요)
	task.spawn(function()
		while s.active do
			task.wait(1)
			if not s.active then
				break
			end
			local drain = Config.SanityDrainNight
			if s.phase == "Day" then
				drain = Config.SanityDrainShift * (1 + (s.day - 1) * Config.SanityDrainPerDay)
			elseif s.phase == "Patrol" then
				drain = Config.SanityDrainPatrol
			end
			for _, player in ipairs(table.clone(s.players)) do
				changeSanity(s, player, -drain)
			end
		end
	end)
end

---------------------------------------------------------------- 노란 네모: 인원 정하고 출근하기
local startZone = workspace:FindFirstChild("StartZone", true)
local party = nil -- { host, size, members = { ... } }
local inZone = {} -- [player] = true
local busyNotified = {} -- [player] = true (근무 중이라는 안내를 한 번만)

local function isInside(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not startZone then
		return false
	end
	local localPos = startZone.CFrame:PointToObjectSpace(root.Position)
	local half = startZone.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Z) <= half.Z and math.abs(localPos.Y) <= half.Y + 2
end

local function partyMembers()
	local members = {}
	if not party then
		return members
	end
	table.insert(members, party.host)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= party.host and inZone[player] and #members < party.size then
			table.insert(members, player)
		end
	end
	return members
end

local function closeParty()
	if not party then
		return
	end
	for player in pairs(inZone) do
		PartyClosed:FireClient(player)
	end
	party = nil
end

local function updateParty()
	if not party then
		return
	end
	local members = partyMembers()
	for player in pairs(inZone) do
		PartyStatus:FireClient(player, {
			size = party.size,
			count = #members,
			hostName = party.host.DisplayName,
			isHost = player == party.host,
			joined = table.find(members, player) ~= nil,
		})
	end
	if #members >= party.size then
		closeParty()
		startSession(members)
	end
end

task.spawn(function()
	while true do
		task.wait(0.25)
		local changed = false
		for _, player in ipairs(Players:GetPlayers()) do
			local inside = not sessionOf(player) and isInside(player)
			if inside and not inZone[player] then
				inZone[player] = true
				changed = true
				if session then
					if not busyNotified[player] then
						busyNotified[player] = true
						Toast:FireClient(player, { text = "지금은 다른 팀이 근무 중이에요. 잠시 후 다시 와 주세요.", kind = "info" })
					end
				elseif not party then
					PartyPrompt:FireClient(player, { max = Config.MaxPlayers })
				end
			elseif not inside and inZone[player] then
				inZone[player] = nil
				busyNotified[player] = nil
				changed = true
				PartyClosed:FireClient(player)
				if party and party.host == player then
					closeParty()
				end
			end
		end
		if changed then
			updateParty()
		end
	end
end)

PartySize.OnServerEvent:Connect(function(player, size)
	if session or party or not inZone[player] or typeof(size) ~= "number" then
		return
	end
	size = math.clamp(math.floor(size), 1, Config.MaxPlayers)
	party = { host = player, size = size }
	-- 다른 사람에게 떠 있던 인원 고르기 창은 대기 화면으로 바뀌어요.
	updateParty()
end)

PartyStartNow.OnServerEvent:Connect(function(player)
	if party and party.host == player and not session then
		local members = partyMembers()
		closeParty()
		startSession(members)
	end
end)

UseDrink.OnServerEvent:Connect(function(player)
	local s = sessionOf(player)
	if not s or (s.drinks[player] or 0) <= 0 then
		return
	end
	s.drinks[player] -= 1
	changeSanity(s, player, Config.DrinkRestore)
	sendInventory(s, player)
	Toast:FireClient(player, { text = ("🥤 시원한 음료를 마셨어요. 정신력 +%d"):format(Config.DrinkRestore), kind = "accept" })
end)

Scared.OnServerEvent:Connect(function(player)
	local s = sessionOf(player)
	if s and s.currentGuest and s.lastScare ~= s.currentGuest.id .. player.UserId then
		s.lastScare = s.currentGuest.id .. player.UserId
		changeSanity(s, player, -Config.SanityScareLoss)
	end
end)

KidChoice.OnServerEvent:Connect(function(player, askId, index)
	local s = sessionOf(player)
	if s and s.kidAskId == askId and not s.kidChoice and (index == 1 or index == 2) then
		s.kidChoice = index
	end
end)

staff.hidePrompt.Triggered:Connect(function(player)
	local s = sessionOf(player)
	if s and s.keptBag and not s.bagHidden then
		s.bagHidden = true
		fire(s, Toast, { text = "🎒 책가방을 사물함 깊숙이 숨겼어요.", kind = "accept" })
	end
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
			local s = sessionOf(player)
			character:PivotTo(deskCFrame(s and table.find(s.players, player) or 1))
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	inZone[player] = nil
	busyNotified[player] = nil
	if party and party.host == player then
		closeParty()
	end
	local s = sessionOf(player)
	if not s then
		return
	end
	table.remove(s.players, table.find(s.players, player))
	s.sanity[player] = nil
	if #s.players == 0 then
		endSession(s)
	end
end)

print("[도플갱어 호텔] 서버 준비 완료!")
