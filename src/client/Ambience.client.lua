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

---------------------------------------------------------------- 야간 순찰 배경음악
-- 순찰하는 동안 느릿느릿한 마림바로 "도 라 도 솔#" 을 계속 되풀이하고 (아래에 "파 파 미 미" 반주를 작게),
-- 낡은 무전기처럼 지직거리는 소리를 함께 깔아요. 순찰이 끝나면 멈춰요.
-- 마림바 소리는 "도" 한 음뿐이에요. 재생 빠르기를 바꿔서 다른 음을 만들어요. (반음 하나 = 2의 12제곱근 배)
local MELODY = { 0, -3, 0, -4 } -- 도에서 반음 몇 개 위(+)/아래(-)인지: 도, 라, 도, 솔#
local ACCOMPANY = { -7, -7, -8, -8 } -- 작은 소리 반주 (멜로디 아래): 파, 파, 미, 미
local MELODY_VOLUME = 0.35 -- 멜로디 소리 크기
local ACCOMPANY_VOLUME = 0.14 -- 반주 소리 크기 (멜로디보다 작게)
local BEAT = 0.9 -- 음과 음 사이 시간 (초). 크게 하면 더 느릿느릿해요.
local STATIC_MIN, STATIC_MAX = 0.06, 0.18 -- 지직 소리 크기가 오르내리는 범위

local marimba = loadSound("MarimbaNote", SoundService, { Volume = MELODY_VOLUME })
local radioStatic = loadSound("RadioStatic", SoundService, { Looped = true, Volume = STATIC_MIN })
if marimba then
	-- 텅 빈 복도에 울리는 느낌
	local echo = Instance.new("ReverbSoundEffect")
	echo.DecayTime = 2.5
	echo.WetLevel = -4
	echo.Parent = marimba
end

local patrolling = false

-- 마림바 한 음을 volume 크기로 친다. (겹쳐 울리도록 매번 복사해서 재생하고, 끝나면 지워요)
local function playNote(semitones, volume)
	local note = marimba:Clone()
	note.PlaybackSpeed = 2 ^ (semitones / 12)
	note.Volume = volume
	note.Parent = SoundService
	note:Play()
	note.Ended:Connect(function()
		note:Destroy()
	end)
end

-- 순찰 배경음악을 켜거나 끈다.
local function setPatrolMusic(on)
	if on == patrolling then
		return
	end
	patrolling = on
	if radioStatic then
		if on then
			radioStatic:Play()
		else
			radioStatic:Stop()
		end
	end
	if not on then
		return
	end
	task.spawn(function()
		local index = 0
		while patrolling do
			if marimba then
				playNote(MELODY[index % #MELODY + 1], MELODY_VOLUME)
				playNote(ACCOMPANY[index % #ACCOMPANY + 1], ACCOMPANY_VOLUME)
			end
			if radioStatic then
				-- 무전기 지직 소리가 커졌다 작아졌다 해요
				radioStatic.Volume = STATIC_MIN + math.random() * (STATIC_MAX - STATIC_MIN)
			end
			index += 1
			task.wait(BEAT)
		end
	end)
end

Remotes.State.OnClientEvent:Connect(function(state)
	setPatrolMusic(state.phase == "Patrol")
end)

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
