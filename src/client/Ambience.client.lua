-- 호텔 배경 소리예요. (각 플레이어의 컴퓨터에서만 재생돼요)
-- 로비(대기실)와 호텔 어디서나 들려요.
-- 괘종시계 째깍 소리는 계속, 부엉이·박쥐·엘리베이터 소리는 가끔, 경찰차 소리는 아주 멀리서 가끔 들려요.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local hotel = workspace:WaitForChild("Hotel")
local lobby = workspace:WaitForChild("Lobby")
local lobbySpot = lobby:FindFirstChild("Sign") or lobby:FindFirstChildWhichIsA("BasePart")

---------------------------------------------------------------- 지금 밤인지 (밤에는 소리가 더 자주 나요)
local isNight = false

Remotes.State.OnClientEvent:Connect(function(state)
	isNight = state.phase == "Night" or state.phase == "Patrol"
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

-- 위치가 있는 소리는 로비에도 똑같은 소리를 하나 더 둬요. (둘 다 재생해요)
local function withLobbyCopy(sound)
	if not sound or not lobbySpot then
		return { sound }
	end
	local copy = sound:Clone()
	copy.Parent = lobbySpot
	return { sound, copy }
end

local clockTicks = withLobbyCopy(loadSound("ClockTick", clockPart, {
	Looped = true,
	Volume = 0.35,
	RollOffMinDistance = 8,
	RollOffMaxDistance = 70,
}))
for _, sound in ipairs(clockTicks) do
	sound:Play()
end
-- 부엉이와 박쥐는 바깥 소리라서 어디서나 똑같이 들려요.
local owl = { loadSound("Owl", SoundService, { Volume = 0.3 }) }
local bat = { loadSound("Bat", SoundService, { Volume = 0.22 }) }
local ding = withLobbyCopy(loadSound("ElevatorDing", elevatorPart, { Volume = 0.5, RollOffMinDistance = 10, RollOffMaxDistance = 90 }))

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
-- sounds 는 같은 소리 묶음이에요. (호텔용 + 로비용)
local function sometimes(sounds, minSeconds, maxSeconds, onPlay)
	if #sounds == 0 then
		return
	end
	task.spawn(function()
		while true do
			local wait = minSeconds + math.random() * (maxSeconds - minSeconds)
			task.wait(isNight and wait * 0.6 or wait)
			local speed = 0.9 + math.random() * 0.2
			for _, sound in ipairs(sounds) do
				sound.PlaybackSpeed = speed
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
sometimes({ siren }, 120, 240, function(sound)
	-- 다가왔다 멀어지는 느낌으로 아주 작게 커졌다 작아져요.
	sound.Volume = 0.03
	task.spawn(function()
		for i = 1, 40 do
			sound.Volume = 0.03 + math.sin(i / 40 * math.pi) * 0.1
			task.wait(0.25)
		end
	end)
end)
