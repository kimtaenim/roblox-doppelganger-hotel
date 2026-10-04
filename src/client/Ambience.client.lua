-- 호텔 배경 소리예요. (각 플레이어의 컴퓨터에서만 재생돼요)
-- 괘종시계 째깍 소리는 계속, 부엉이·박쥐·엘리베이터 소리는 가끔, 경찰차 소리는 아주 멀리서 가끔 들려요.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local hotel = workspace:WaitForChild("Hotel")

---------------------------------------------------------------- 지금 호텔 안인지, 밤인지 (소리를 불러오는 동안에도 기억해요)
local inHotel = false
local isNight = false
local clockTick = nil

local function updateClock()
	if not clockTick then
		return
	end
	if inHotel and not clockTick.IsPlaying then
		clockTick:Play()
	elseif not inHotel then
		clockTick:Stop()
	end
end

Remotes.State.OnClientEvent:Connect(function(state)
	inHotel = state.phase ~= "Lobby"
	isNight = state.phase == "Night"
	updateClock()
end)

-- 후보 번호를 하나씩 불러 보고, 성공한 첫 번째 소리를 돌려줘요.
local function loadSound(name, parent, props)
	for _, id in ipairs(Sounds[name] or {}) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		for key, value in pairs(props or {}) do
			sound[key] = value
		end
		sound.Parent = parent

		local ok = false
		pcall(function()
			ContentProvider:PreloadAsync({ sound }, function(_, status)
				ok = status == Enum.AssetFetchStatus.Success
			end)
		end)
		if ok then
			return sound
		end
		sound:Destroy()
	end
	warn(("[도플갱어 호텔] '%s' 소리를 불러오지 못했어요. src/shared/Sounds.lua 의 번호를 바꿔 주세요."):format(name))
	return nil
end

local function findPart(name)
	return hotel:FindFirstChild(name, true)
end

-- 소리가 나는 위치 (가까이 가면 크게, 멀어지면 작게 들려요)
local clockPart = findPart("ClockBody") or hotel
local elevatorPart = findPart("ElevatorDoor") or hotel
local windowPart = findPart("WindowPane") or hotel

clockTick = loadSound("ClockTick", clockPart, {
	Looped = true,
	Volume = 0.35,
	RollOffMinDistance = 8,
	RollOffMaxDistance = 70,
})
updateClock()
local owl = loadSound("Owl", windowPart, { Volume = 0.5, RollOffMinDistance = 15, RollOffMaxDistance = 150 })
local bat = loadSound("Bat", windowPart, { Volume = 0.35, RollOffMinDistance = 10, RollOffMaxDistance = 120 })
local ding = loadSound("ElevatorDing", elevatorPart, { Volume = 0.5, RollOffMinDistance = 10, RollOffMaxDistance = 90 })

-- 경찰차: 위치 없이 아주 작게, 높은 소리를 깎고 울림을 더해서 먼 곳처럼 들리게 해요.
local siren = loadSound("PoliceSiren", SoundService, { Volume = 0.12 })
if siren then
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain = -30
	eq.MidGain = -8
	eq.LowGain = 0
	eq.Parent = siren
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 3
	reverb.WetLevel = 0
	reverb.DryLevel = -6
	reverb.Parent = siren
end

---------------------------------------------------------------- 가끔 나는 소리
-- 소리 하나를 min~max 초마다 가끔 재생해요. (밤에는 더 자주)
local function sometimes(sound, minSeconds, maxSeconds, onPlay)
	if not sound then
		return
	end
	task.spawn(function()
		while true do
			local wait = minSeconds + math.random() * (maxSeconds - minSeconds)
			task.wait(isNight and wait * 0.6 or wait)
			if inHotel then
				sound.PlaybackSpeed = 0.9 + math.random() * 0.2
				if onPlay then
					onPlay(sound)
				end
				sound:Play()
			end
		end
	end)
end

sometimes(owl, 35, 80)
sometimes(bat, 50, 110)
sometimes(ding, 45, 100)
sometimes(siren, 120, 240, function(sound)
	-- 다가왔다 멀어지는 느낌으로 아주 작게 커졌다 작아져요.
	sound.Volume = 0.03
	task.spawn(function()
		for i = 1, 40 do
			sound.Volume = 0.03 + math.sin(i / 40 * math.pi) * 0.1
			task.wait(0.25)
		end
	end)
end)
