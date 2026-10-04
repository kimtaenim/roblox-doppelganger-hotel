-- 각 플레이어의 화면(UI)을 담당하는 스크립트예요.
-- 로비 화면, 위쪽 상태 표시, 체크인 창(예약 확인서 / CCTV / 손님 응대), 밤 결과, 아침 보고서가 있어요.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Animals = require(Shared:WaitForChild("Animals"))
local Sounds = require(Shared:WaitForChild("Sounds"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local WHITE = rgb(255, 255, 255)

-- 고급 호텔 톤: 에스프레소 갈색 바탕, 놋쇠 테두리, 크림색 글자
local ESPRESSO = rgb(24, 17, 13)
local BRASS = rgb(196, 156, 84)
local CREAM = rgb(236, 222, 192)
local OXBLOOD = rgb(112, 24, 24)
local BOTTLE = rgb(38, 72, 52)
local SERIF = Enum.Font.Garamond

---------------------------------------------------------------- UI 도우미
local function make(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function round(inst, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, inst)
end

local function maxSize(inst, width, height)
	make("UISizeConstraint", { MaxSize = Vector2.new(width, height) }, inst)
end

local function label(parent, props, maxText)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = WHITE,
		TextScaled = true,
		TextWrapped = true,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	local inst = make("TextLabel", defaults, parent)
	make("UITextSizeConstraint", { MaxTextSize = maxText or 28 }, inst)
	return inst
end

local function button(parent, text, color, props, maxText)
	local defaults = {
		Text = text,
		BackgroundColor3 = color,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		AutoButtonColor = true,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	local inst = make("TextButton", defaults, parent)
	round(inst, 10)
	make("UITextSizeConstraint", { MaxTextSize = maxText or 26 }, inst)
	return inst
end

local gui = make("ScreenGui", {
	Name = "HotelGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

-- 비네트: 화면 가장자리를 어둡게 해서 음산한 느낌을 줘요.
do
	local vignette = make("Frame", {
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 0,
	}, gui)
	local edges = {
		{ UDim2.fromScale(0.22, 1), UDim2.fromScale(0, 0), 0 },
		{ UDim2.fromScale(0.22, 1), UDim2.fromScale(0.78, 0), 180 },
		{ UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0), 90 },
		{ UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0.75), 270 },
	}
	for _, edge in ipairs(edges) do
		local frame = make("Frame", {
			Size = edge[1],
			Position = edge[2],
			BackgroundColor3 = rgb(0, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 0,
		}, vignette)
		make("UIGradient", {
			Rotation = edge[3],
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, frame)
	end
end

local function brassFrame(inst, thickness)
	make("UIStroke", { Color = BRASS, Thickness = thickness or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, inst)
end

---------------------------------------------------------------- 로비 화면
local lobbyFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.7),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.04,
}, gui)
round(lobbyFrame, 6)
maxSize(lobbyFrame, 560, 470)
brassFrame(lobbyFrame, 2)

label(lobbyFrame, {
	Text = "DOPPELGANGER HOTEL",
	Font = SERIF,
	TextColor3 = BRASS,
	Position = UDim2.fromScale(0.05, 0.04),
	Size = UDim2.fromScale(0.9, 0.1),
}, 36)
label(lobbyFrame, {
	Text = "— 도플갱어 호텔 · 야간 프론트 —",
	Font = SERIF,
	TextColor3 = rgb(170, 60, 55),
	Position = UDim2.fromScale(0.05, 0.135),
	Size = UDim2.fromScale(0.9, 0.06),
}, 18)

label(lobbyFrame, {
	Text = "당신은 호텔 프론트 직원이에요.\n\n"
		.. "• 손님이 오면 예약 사진과 CCTV를 확인해요\n"
		.. "• 이빨이 보이거나, 입이 찢어졌거나, 눈이 검게 가려졌거나, "
		.. "몸이 이상하거나, 사진이 움직이면... 셔터를 닫아요!\n"
		.. "• 첫날은 연습이에요. 둘째 날부터 도플갱어가 와요\n"
		.. "• 희생자가 3명이 되면 해고돼요",
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.07, 0.21),
	Size = UDim2.fromScale(0.86, 0.43),
}, 18)

local soloButton = button(lobbyFrame, "혼자 시작", BRASS, {
	Position = UDim2.fromScale(0.1, 0.67),
	Size = UDim2.fromScale(0.8, 0.14),
	TextColor3 = ESPRESSO,
}, 28)

local partyButton = button(lobbyFrame, "친구와 함께 (최대 4명) · 준비 중", rgb(45, 36, 30), {
	Position = UDim2.fromScale(0.1, 0.84),
	Size = UDim2.fromScale(0.8, 0.1),
	AutoButtonColor = false,
	TextColor3 = rgb(140, 125, 105),
}, 16)
brassFrame(partyButton, 1)

---------------------------------------------------------------- 위쪽 상태 표시
local hud = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.new(0.62, 0, 0, 26),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.2,
	Visible = false,
}, gui)
round(hud, 4)
maxSize(hud, 860, 26)
brassFrame(hud, 1)
-- 가로로 긴 한 줄 (줄바꿈 없이)
local hudText = label(hud, {
	Position = UDim2.new(0, 12, 0, 3),
	Size = UDim2.new(1, -24, 1, -6),
	TextColor3 = CREAM,
	Font = SERIF,
	TextWrapped = false,
}, 16)

---------------------------------------------------------------- 안내 메시지 (토스트)
local toast = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 48),
	Size = UDim2.new(0.62, 0, 0, 34),
	BackgroundTransparency = 0.12,
	BackgroundColor3 = ESPRESSO,
	Visible = false,
}, 16)
round(toast, 4)
maxSize(toast, 760, 34)
brassFrame(toast, 1)

local TOAST_COLORS = {
	accept = rgb(170, 220, 170),
	caught = rgb(230, 170, 90),
	missed = rgb(190, 180, 165),
	warn = rgb(220, 110, 100),
	info = CREAM,
}
local toastToken = 0
local function showToast(text, kind)
	toastToken += 1
	local myToken = toastToken
	toast.Text = text
	toast.TextColor3 = TOAST_COLORS[kind] or WHITE
	toast.Visible = true
	task.delay(4, function()
		if toastToken == myToken then
			toast.Visible = false
		end
	end)
end

local function shakeCamera()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	task.spawn(function()
		for _ = 1, 20 do
			humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * 0.8, (math.random() - 0.5) * 0.8, 0)
			task.wait(0.03)
		end
		humanoid.CameraOffset = Vector3.zero
	end)
end

---------------------------------------------------------------- 프론트 체크인 화면 (창 세 개)
-- desk 는 창 세 개(예약 확인서, CCTV, 손님 응대)를 한꺼번에 보이고 숨기는 투명한 틀이에요.
local desk = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
}, gui)

local function draggable(frame)
	pcall(function()
		make("UIDragDetector", {}, frame)
	end)
end

-- 제목 표시줄이 있는 창
local function window(title, titleColor, barColor, bodyColor, props)
	local frame = make("Frame", { BackgroundColor3 = bodyColor, BorderSizePixel = 0 }, desk)
	for key, value in pairs(props) do
		frame[key] = value
	end
	round(frame, 8)
	brassFrame(frame, 1.5)
	local bar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = barColor,
		BorderSizePixel = 0,
	}, frame)
	round(bar, 8)
	label(bar, {
		Text = title,
		TextColor3 = titleColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 4),
		Size = UDim2.new(1, -20, 1, -8),
	}, 16)
	local body = make("Frame", {
		Position = UDim2.new(0, 8, 0, 34),
		Size = UDim2.new(1, -16, 1, -42),
		BackgroundTransparency = 1,
	}, frame)
	draggable(frame)
	return frame, body
end

-- 창 1: 예약 확인서 (왼쪽 아래)
local _, photoBody = window("예약 확인서 · RESERVATION", rgb(225, 190, 120), rgb(50, 32, 22), rgb(238, 230, 212), {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.fromScale(0.3, 0.5),
})
maxSize(photoBody.Parent, 320, 440)
local photoCard = make("Frame", {
	Position = UDim2.fromScale(0.08, 0.02),
	Size = UDim2.fromScale(0.84, 0.66),
	BackgroundColor3 = rgb(250, 248, 240),
	Rotation = -2,
}, photoBody)
make("UIStroke", { Color = rgb(200, 190, 170), Thickness = 1 }, photoCard)
local photoView = make("ViewportFrame", {
	Position = UDim2.fromScale(0.06, 0.05),
	Size = UDim2.fromScale(0.88, 0.8),
	BackgroundColor3 = rgb(170, 185, 195),
	Ambient = rgb(170, 165, 160),
}, photoCard)
local photoCaption = label(photoCard, {
	Position = UDim2.fromScale(0.06, 0.86),
	Size = UDim2.fromScale(0.88, 0.12),
	TextColor3 = rgb(50, 40, 40),
	Font = Enum.Font.Garamond,
}, 18)
local photoInfo = label(photoBody, {
	Position = UDim2.fromScale(0.04, 0.71),
	Size = UDim2.fromScale(0.92, 0.28),
	TextColor3 = rgb(40, 32, 28),
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
}, 15)

-- 창 2: CCTV (왼쪽 위, Roblox 메뉴 버튼 아래)
local _, cctvBody = window("CCTV · CAM 01 · 프론트", rgb(140, 255, 140), rgb(15, 15, 15), rgb(45, 45, 45), {
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(0, 16, 0, 70),
	Size = UDim2.fromScale(0.3, 0.36),
})
maxSize(cctvBody.Parent, 380, 290)
local cctvCard = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(10, 12, 10),
	ClipsDescendants = true,
}, cctvBody)
round(cctvCard, 4)
local cctvView = make("ViewportFrame", {
	Position = UDim2.fromScale(0.02, 0.03),
	Size = UDim2.fromScale(0.96, 0.94),
	BackgroundColor3 = rgb(30, 40, 32),
	ImageColor3 = rgb(170, 235, 170),
	Ambient = rgb(120, 140, 120),
}, cctvCard)
for i = 1, 12 do
	make("Frame", {
		Position = UDim2.new(0.02, 0, i / 13, 0),
		Size = UDim2.new(0.96, 0, 0, 2),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, cctvCard)
end
-- CCTV 잡음 (모든 손님에게 가끔 생겨요)
local staticBars = {}
for i = 1, 4 do
	staticBars[i] = make("Frame", {
		Size = UDim2.new(0.96, 0, 0.04, 0),
		BackgroundColor3 = rgb(220, 255, 220),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
	}, cctvCard)
end
label(cctvCard, {
	Text = "CAM 01 · 프론트",
	Font = Enum.Font.Code,
	TextColor3 = rgb(140, 255, 140),
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.05),
	Size = UDim2.fromScale(0.6, 0.09),
	ZIndex = 4,
}, 16)
local recLabel = label(cctvCard, {
	Text = "● REC",
	Font = Enum.Font.Code,
	TextColor3 = rgb(255, 60, 60),
	TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.fromScale(0.65, 0.05),
	Size = UDim2.fromScale(0.3, 0.09),
	ZIndex = 4,
}, 16)
local timeLabel = label(cctvCard, {
	Font = Enum.Font.Code,
	TextColor3 = rgb(140, 255, 140),
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.05, 0.86),
	Size = UDim2.fromScale(0.7, 0.09),
	ZIndex = 4,
}, 14)

-- 창 3: 손님 응대 (가운데 아래)
local actionBar = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0.33, 0, 0, 104),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.05,
}, desk)
round(actionBar, 4)
maxSize(actionBar, 440, 104)
make("UIStroke", { Color = rgb(176, 136, 66), Thickness = 1 }, actionBar)
local deskHeader = label(actionBar, {
	Position = UDim2.new(0, 10, 0, 6),
	Size = UDim2.new(1, -20, 0, 18),
	TextColor3 = BRASS,
	Font = SERIF,
	TextXAlignment = Enum.TextXAlignment.Left,
}, 15)
local deskSpeech = label(actionBar, {
	Position = UDim2.new(0, 10, 0, 24),
	Size = UDim2.new(1, -20, 0, 30),
	Font = Enum.Font.Gotham,
	TextColor3 = rgb(255, 235, 200),
	TextXAlignment = Enum.TextXAlignment.Left,
}, 15)
local cctvButton = button(actionBar, "CCTV 보기", rgb(30, 45, 35), {
	TextColor3 = rgb(150, 240, 150),
	Position = UDim2.new(0, 10, 1, -44),
	Size = UDim2.new(1 / 3, -13, 0, 36),
}, 17)
brassFrame(cctvButton, 1)
local acceptButton = button(actionBar, "예약 받기", BOTTLE, {
	TextColor3 = CREAM,
	Position = UDim2.new(1 / 3, 3, 1, -44),
	Size = UDim2.new(1 / 3, -6, 0, 36),
}, 17)
local shutterButton = button(actionBar, "셔터 닫기", OXBLOOD, {
	TextColor3 = CREAM,
	Position = UDim2.new(2 / 3, 3, 1, -44),
	Size = UDim2.new(1 / 3, -13, 0, 36),
}, 17)

-- CCTV 창은 처음엔 숨겨 두고, [CCTV 보기] 버튼을 누르면 떠요.
local cctvWindow = cctvBody.Parent
cctvWindow.Visible = false

local currentGuestId = nil
local currentData = nil
local scaredGuestId = nil
local currentDay = 1
local photoMoveConnection = nil

local function fillViewport(view, data, anomaly, cameraCFrame, fov, withFloor)
	view:ClearAllChildren()
	local camera = make("Camera", { FieldOfView = fov, CFrame = cameraCFrame }, view)
	view.CurrentCamera = camera
	if withFloor then
		make("Part", {
			Anchored = true,
			Size = Vector3.new(30, 0.2, 30),
			CFrame = CFrame.new(0, -0.1, 0),
			Color = rgb(120, 115, 105),
		}, view)
	end
	local model = Animals.build(data, anomaly)
	model.Parent = view
	return model
end

local function hideDesk()
	desk.Visible = false
	cctvWindow.Visible = false
	currentGuestId = nil
	currentData = nil
	if photoMoveConnection then
		photoMoveConnection:Disconnect()
		photoMoveConnection = nil
	end
	photoView:ClearAllChildren()
	cctvView:ClearAllChildren()
end

---------------------------------------------------------------- 깜짝 놀래키기 (도플갱어)
-- 도플갱어의 무서운 얼굴이 화면 앞으로 확 달려들어요.
local scareFrame = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(60, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = 50,
}, gui)
local scareView = make("ViewportFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ImageColor3 = rgb(255, 200, 200),
	Ambient = rgb(130, 70, 70),
	LightColor = rgb(255, 90, 90),
	ZIndex = 51,
}, scareFrame)

local screamSound = nil
task.spawn(function()
	for _, id in ipairs(Sounds.Scream or {}) do
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = 0.8
		sound.Parent = SoundService
		local ok = false
		pcall(function()
			ContentProvider:PreloadAsync({ sound }, function(_, status)
				ok = status == Enum.AssetFetchStatus.Success
			end)
		end)
		if ok then
			screamSound = sound
			return
		end
		sound:Destroy()
	end
end)

local scaring = false
local function jumpScare(data, kind)
	if scaring then
		return
	end
	scaring = true
	scareView:ClearAllChildren()
	local camera = make("Camera", { FieldOfView = 60 }, scareView)
	scareView.CurrentCamera = camera
	local monster = Animals.build(data, kind)
	monster.Parent = scareView
	local headGroup = monster:FindFirstChild("HeadGroup")
	local target = headGroup and headGroup.PrimaryPart.Position or Vector3.new(0, 5.5, 0)

	scareFrame.Visible = true
	if screamSound then
		screamSound:Play()
	end
	shakeCamera()
	local start = os.clock()
	while os.clock() - start < 0.75 do
		local t = (os.clock() - start) / 0.75
		local distance = 7 - math.min(t * 4, 1) * 4.7 -- 순식간에 코앞까지
		local jitter = Vector3.new((math.random() - 0.5) * 0.15, (math.random() - 0.5) * 0.15, 0)
		camera.CFrame = CFrame.lookAt(target + Vector3.new(0, 0, -distance) + jitter, target)
		scareFrame.BackgroundTransparency = 0.25 + math.random() * 0.3
		RunService.RenderStepped:Wait()
	end
	scareFrame.Visible = false
	scareView:ClearAllChildren()
	scaring = false
end

-- 잠시 뒤 확률적으로 놀래켜요. (손님 한 명당 한 번만)
local function maybeScare(data, kind, delay, chance)
	task.delay(delay, function()
		if currentGuestId == data.id and scaredGuestId ~= data.id and math.random() < chance then
			scaredGuestId = data.id
			jumpScare(data, kind == "moving" and "mouth" or kind)
		end
	end)
end

-- 가짜 깜짝: 아무 손님에게나 가끔, CCTV에 검은 그림자가 스쳐 지나가요.
local function shadowFlash()
	if not cctvWindow.Visible then
		return
	end
	local shadow = Instance.new("Model")
	make("Part", { Anchored = true, Size = Vector3.new(1.4, 4.6, 0.9), CFrame = CFrame.new(4.5, 2.3, 5), Color = rgb(5, 5, 5) }, shadow)
	local head = make("Part", { Anchored = true, Size = Vector3.new(1.5, 1.5, 1.5), CFrame = CFrame.new(4.5, 5.3, 5), Color = rgb(5, 5, 5) }, shadow)
	head.Shape = Enum.PartType.Ball
	shadow.Parent = cctvView
	for _, bar in ipairs(staticBars) do
		bar.Visible = true
		bar.Position = UDim2.new(0.02, 0, math.random() * 0.9, 0)
	end
	task.wait(0.25)
	shadow:Destroy()
	for _, bar in ipairs(staticBars) do
		bar.Visible = false
	end
end

local function toggleCCTV()
	if not currentData then
		return
	end
	cctvWindow.Visible = not cctvWindow.Visible
	cctvButton.Text = cctvWindow.Visible and "CCTV 닫기" or "CCTV 보기"
	if cctvWindow.Visible then
		if currentData.cctvAnomaly then
			maybeScare(currentData, currentData.cctvAnomaly, 1 + math.random() * 0.8, 0.6)
		elseif math.random() < 0.12 then
			task.delay(0.8 + math.random(), shadowFlash)
		end
	end
end
cctvButton.Activated:Connect(toggleCCTV)

local function showGuest(data)
	currentGuestId = data.id
	currentData = data
	cctvWindow.Visible = false
	cctvButton.Text = "CCTV 보기"
	currentDay = data.day
	deskHeader.Text = ("손님 %d/%d · %s (%s)"):format(data.index, data.total, data.name, data.animalName)
	deskSpeech.Text = ("“%s”"):format(data.line or "...")
	photoCaption.Text = data.name
	photoInfo.Text = ("성명  %s\n구분  %s\n객실  %s호\n숙박  1박 · %d일차 체크인"):format(
		data.name,
		data.animalName,
		tostring(data.room or "-"),
		data.day or 1
	)

	-- 예약 사진: 얼굴이 잘 보이게 정면에서 찍어요.
	local photoModel = fillViewport(
		photoView,
		data,
		data.photoAnomaly,
		CFrame.lookAt(Vector3.new(0, 5.6, -8), Vector3.new(0, 5.4, 0)),
		40,
		false
	)
	if photoMoveConnection then
		photoMoveConnection:Disconnect()
		photoMoveConnection = nil
	end
	if data.photoAnomaly == "moving" then
		-- 사진 속 머리가 천천히 돌아가다가 가끔 뚝! 하고 꺾여요.
		local headGroup = photoModel:FindFirstChild("HeadGroup")
		local base = headGroup and headGroup:GetPivot()
		local t = 0
		photoMoveConnection = RunService.RenderStepped:Connect(function(dt)
			if not headGroup then
				return
			end
			t += dt
			local yaw = math.sin(t * 0.8) * 0.25
			local roll = 0
			local cycle = t % 2.6
			if cycle < 0.25 then
				roll = math.rad(70) -- 뚝!
			elseif cycle < 0.35 then
				roll = math.rad(-25)
			end
			headGroup:PivotTo(base * CFrame.Angles(0, yaw, roll))
		end)
	end

	-- CCTV: 위에서 비스듬히 내려다봐요.
	fillViewport(
		cctvView,
		data,
		data.cctvAnomaly,
		CFrame.lookAt(Vector3.new(4, 10, -11), Vector3.new(0, 3.8, 0)),
		50,
		true
	)

	desk.Visible = true

	-- 사진에 이상한 점이 있으면 가끔 사진 속 얼굴이 달려들어요.
	if data.photoAnomaly and data.photoAnomaly ~= "moving" then
		maybeScare(data, data.photoAnomaly, 2.5 + math.random() * 2, 0.35)
	end
end

local function decide(choice)
	if not currentGuestId then
		return
	end
	Remotes.Decide:FireServer(currentGuestId, choice)
	hideDesk()
end

acceptButton.Activated:Connect(function()
	decide("accept")
end)
shutterButton.Activated:Connect(function()
	decide("shutter")
end)

-- CCTV 시계와 REC 깜빡임
task.spawn(function()
	local blink = false
	while true do
		task.wait(0.5)
		blink = not blink
		recLabel.Visible = blink
		timeLabel.Text = ("DAY %d  %s"):format(currentDay, os.date("%H:%M:%S"))
	end
end)

-- CCTV 잡음: 가끔 화면이 지지직거려요.
task.spawn(function()
	while true do
		task.wait(1.5 + math.random() * 3)
		if desk.Visible then
			for _ = 1, 6 do
				for _, bar in ipairs(staticBars) do
					bar.Visible = math.random() < 0.7
					bar.Position = UDim2.new(0.03, 0, math.random() * 0.9, 0)
				end
				cctvView.ImageTransparency = math.random() * 0.4
				task.wait(0.05)
			end
			for _, bar in ipairs(staticBars) do
				bar.Visible = false
			end
			cctvView.ImageTransparency = 0
		end
	end
end)

---------------------------------------------------------------- 밤 결과 화면
local night = make("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromScale(0.45, 0.62),
	BackgroundColor3 = rgb(14, 10, 10),
	BackgroundTransparency = 0.06,
	Visible = false,
}, gui)
round(night, 6)
make("UISizeConstraint", { MaxSize = Vector2.new(420, 460), MinSize = Vector2.new(260, 300) }, night)
make("UIStroke", { Color = rgb(120, 30, 30), Thickness = 2 }, night)

local nightTitle = label(night, {
	Font = SERIF,
	TextColor3 = rgb(200, 80, 70),
	Position = UDim2.fromScale(0.06, 0.04),
	Size = UDim2.fromScale(0.88, 0.12),
}, 32)
local nightBody = label(night, {
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.06, 0.19),
	Size = UDim2.fromScale(0.88, 0.52),
}, 18)
local nightButton = button(night, "", BRASS, {
	TextColor3 = ESPRESSO,
	Position = UDim2.fromScale(0.08, 0.73),
	Size = UDim2.fromScale(0.84, 0.12),
})
local nightLobbyButton = button(night, "그만하고 로비로", rgb(45, 36, 30), {
	TextColor3 = rgb(170, 150, 125),
	Position = UDim2.fromScale(0.2, 0.87),
	Size = UDim2.fromScale(0.6, 0.08),
}, 16)

local nightMode = "next"

nightButton.Activated:Connect(function()
	night.Visible = false
	if nightMode == "next" then
		Remotes.NextDay:FireServer()
	else
		Remotes.BackToLobby:FireServer()
	end
end)
nightLobbyButton.Activated:Connect(function()
	night.Visible = false
	Remotes.BackToLobby:FireServer()
end)

local function showNight(report)
	hideDesk()
	nightTitle.Text = ("🌑 %d일차 근무 끝"):format(report.day)
	nightBody.Text = "새벽 3시... 직원들이 모두 퇴근했어요.\n\n로비를 둘러보세요."
	nightButton.Visible = false
	nightLobbyButton.Visible = false
	night.Visible = true

	task.wait(3)

	local lines = { ("💰 오늘 수입: %d"):format(report.earned) }
	if #report.victims > 0 then
		table.insert(lines, "💀 희생된 손님: " .. table.concat(report.victims, ", "))
		table.insert(lines, "로비에 쓰러진 손님들이 있어요... 도플갱어에게 속았어요.")
	else
		table.insert(lines, "✨ 로비가 깨끗해요. 오늘은 무사히 지나갔어요!")
	end
	table.insert(lines, ("\n총 돈: %d · 희생자 %d/%d"):format(report.money, report.deaths, report.maxDeaths))

	if report.gameOver then
		table.insert(lines, "\n❌ 희생자가 너무 많아서 해고됐어요...")
		for _, guest in ipairs(report.refused or {}) do
			table.insert(lines, ("• 오늘 돌려보낸 %s(%s): %s"):format(
				guest.name,
				guest.animalName,
				guest.isDoppel and "도플갱어였어요" or "평범한 손님이었어요"
			))
		end
		nightMode = "lobby"
		nightButton.Text = "로비로 돌아가기"
		nightLobbyButton.Visible = false
	else
		nightMode = "next"
		nightButton.Text = "🌙 다음 날 밤 근무로"
		nightLobbyButton.Visible = true
	end
	nightBody.Text = table.concat(lines, "\n")
	nightButton.Visible = true
end

-- 아침 보고서: 건조한 서류 양식으로 어젯밤 일과 어제 돌려보낸 손님의 정체를 알려줘요.
local INK = rgb(35, 30, 28)
local reportFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.86),
	BackgroundColor3 = rgb(236, 231, 218),
	Visible = false,
	ZIndex = 10,
}, gui)
maxSize(reportFrame, 520, 600)
make("UIStroke", { Color = rgb(150, 140, 120), Thickness = 1 }, reportFrame)

local function reportLabel(props, maxText)
	props.ZIndex = 11
	props.TextColor3 = props.TextColor3 or INK
	return label(reportFrame, props, maxText)
end

reportLabel({
	Text = "야간 근무 결과 보고서",
	Font = Enum.Font.GothamBold,
	Position = UDim2.fromScale(0.08, 0.03),
	Size = UDim2.fromScale(0.84, 0.07),
}, 26)
local reportMeta = reportLabel({
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.08, 0.11),
	Size = UDim2.fromScale(0.84, 0.08),
}, 13)
make("Frame", {
	Position = UDim2.fromScale(0.08, 0.2),
	Size = UDim2.new(0.84, 0, 0, 2),
	BackgroundColor3 = INK,
	BorderSizePixel = 0,
	ZIndex = 11,
}, reportFrame)
local reportBody = reportLabel({
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.08, 0.23),
	Size = UDim2.fromScale(0.84, 0.58),
}, 15)
local stamp = reportLabel({
	Text = "확 인",
	Font = Enum.Font.GothamBlack,
	TextColor3 = rgb(170, 30, 30),
	Rotation = -14,
	Position = UDim2.fromScale(0.66, 0.74),
	Size = UDim2.fromScale(0.24, 0.08),
	TextTransparency = 0.15,
}, 26)
make("UIStroke", { Color = rgb(170, 30, 30), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.15 }, stamp)
local reportButton = button(reportFrame, "결재", rgb(45, 40, 38), {
	Position = UDim2.fromScale(0.3, 0.88),
	Size = UDim2.fromScale(0.4, 0.07),
	ZIndex = 11,
}, 18)
reportButton.Activated:Connect(function()
	reportFrame.Visible = false
	Remotes.MorningOk:FireServer()
end)

local function showMorning(report)
	hideDesk()
	night.Visible = false
	reportMeta.Text = ("문서번호  DH-%03d-N\n작성일시  %d일차 06:00   작성  야간 경비팀"):format(report.day - 1, report.day)

	local lines = { "1. 야간 사고" }
	if #report.victims > 0 then
		table.insert(lines, ("   - 투숙객 사망 %d건"):format(#report.victims))
		for _, name in ipairs(report.victims) do
			table.insert(lines, "     " .. name)
		end
		table.insert(lines, "   - 시신 수습 및 로비 청소 완료")
	else
		table.insert(lines, "   - 해당 없음")
	end

	table.insert(lines, "")
	table.insert(lines, "2. 전일 체크인 거절 손님 신원 조회")
	local doppels = 0
	if #report.refused == 0 then
		table.insert(lines, "   - 해당 없음")
	end
	for _, guest in ipairs(report.refused) do
		if guest.isDoppel then
			doppels += 1
		end
		table.insert(lines, ("   - %s(%s) : %s"):format(
			guest.name,
			guest.animalName,
			guest.isDoppel and "도플갱어 확인" or "일반 투숙객 (오판)"
		))
	end

	table.insert(lines, "")
	table.insert(lines, ("3. 전일 수입 %d / 누적 %d"):format(report.earned, report.money))
	table.insert(lines, ("4. 누적 사망 %d / %d"):format(report.deaths, report.maxDeaths))
	table.insert(lines, "")
	local note = "없음."
	if doppels > 0 then
		note = "셔터 하단에서 긁힌 자국 발견. 보수 요청."
	elseif #report.victims > 0 then
		note = "새벽 3시 33분, 엘리베이터 B4 정지 기록."
	end
	table.insert(lines, "특이사항: " .. note)
	table.insert(lines, "")
	table.insert(lines, "이상.")
	reportBody.Text = table.concat(lines, "\n")
	reportFrame.Visible = true
end

---------------------------------------------------------------- 서버에서 온 신호 처리
local soloBusy = false
soloButton.Activated:Connect(function()
	if soloBusy then
		return
	end
	soloBusy = true
	Remotes.StartSolo:FireServer()
	task.delay(2, function()
		soloBusy = false
	end)
end)

Remotes.State.OnClientEvent:Connect(function(state)
	if state.phase == "Lobby" then
		lobbyFrame.Visible = true
		hud.Visible = false
		night.Visible = false
		hideDesk()
		return
	end

	lobbyFrame.Visible = false
	hud.Visible = true
	currentDay = state.day
	if state.phase == "Day" then
		night.Visible = false
	end

	local guests = ""
	if state.phase == "Day" and state.guestIndex > 0 then
		guests = ("   ·   손님 %d/%d"):format(state.guestIndex, state.guestsTotal)
	end
	hudText.Text = ("%d일차   ·   %s   ·   💰 %d   ·   💀 %d/%d%s"):format(
		state.day,
		state.phase == "Day" and "🌙 밤 근무" or "🌑 근무 끝",
		state.money,
		state.deaths,
		state.maxDeaths,
		guests
	)
end)

Remotes.GuestArrived.OnClientEvent:Connect(showGuest)

Remotes.Toast.OnClientEvent:Connect(function(message)
	showToast(message.text, message.kind)
	if message.shake then
		shakeCamera()
	end
end)

Remotes.NightReport.OnClientEvent:Connect(showNight)
Remotes.MorningReport.OnClientEvent:Connect(showMorning)
