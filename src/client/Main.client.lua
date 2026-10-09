-- 각 플레이어의 화면(UI)을 담당하는 스크립트예요.
-- 로비 화면, 위쪽 상태 표시, 체크인 창(예약 확인서 / CCTV / 손님 응대), 밤 결과, 아침 보고서가 있어요.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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

-- 비네트: 화면 가장자리를 어둡게 해서 음산한 느낌을 줘요. (정신력이 낮으면 더 어두워져요)
local vignetteGradients = {}
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
		local gradient = make("UIGradient", {
			Rotation = edge[3],
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, frame)
		table.insert(vignetteGradients, gradient)
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
	Visible = false, -- 노란 네모 안에 들어가면 떠요
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
		.. "• 정신력이 다 떨어지면 쓰러져요. 직원 공간의 음료 기계로 채우세요\n"
		.. "• 희생자가 3명이 되면 해고돼요",
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.07, 0.21),
	Size = UDim2.fromScale(0.86, 0.43),
}, 16)

-- 몇 명이서 근무할지 고르기
local partyQuestion = label(lobbyFrame, {
	Text = "몇 명이서 근무할까요?",
	Font = SERIF,
	TextColor3 = BRASS,
	Position = UDim2.fromScale(0.1, 0.66),
	Size = UDim2.fromScale(0.8, 0.07),
}, 22)
local sizeButtons = {}
for n = 1, 4 do
	local sizeButton = button(lobbyFrame, n == 1 and "혼자" or (n .. "명"), n == 1 and BRASS or rgb(60, 46, 36), {
		Position = UDim2.fromScale(0.1 + (n - 1) * 0.205, 0.76),
		Size = UDim2.fromScale(0.185, 0.12),
		TextColor3 = n == 1 and ESPRESSO or CREAM,
	}, 22)
	brassFrame(sizeButton, 1)
	sizeButton.Activated:Connect(function()
		Remotes.PartySize:FireServer(n)
	end)
	sizeButtons[n] = sizeButton
end
local partyStatus = label(lobbyFrame, {
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	Position = UDim2.fromScale(0.08, 0.67),
	Size = UDim2.fromScale(0.84, 0.15),
	Visible = false,
}, 18)
local startNowButton = button(lobbyFrame, "지금 인원으로 시작", BRASS, {
	Position = UDim2.fromScale(0.2, 0.85),
	Size = UDim2.fromScale(0.6, 0.1),
	TextColor3 = ESPRESSO,
	Visible = false,
}, 20)
startNowButton.Activated:Connect(function()
	Remotes.PartyStartNow:FireServer()
end)

local function showPartyChooser()
	lobbyFrame.Visible = true
	partyQuestion.Visible = true
	partyStatus.Visible = false
	startNowButton.Visible = false
	for _, b in ipairs(sizeButtons) do
		b.Visible = true
	end
end

local function showPartyStatus(info)
	lobbyFrame.Visible = true
	partyQuestion.Visible = false
	for _, b in ipairs(sizeButtons) do
		b.Visible = false
	end
	partyStatus.Visible = true
	partyStatus.Text = ("%s 님의 근무 팀 · 대기 %d / %d명\n친구가 노란 네모 안으로 들어오면 함께 출근해요."):format(info.hostName, info.count, info.size)
	if not info.joined then
		partyStatus.Text = ("%s 님의 팀이 가득 찼어요 (%d / %d명)."):format(info.hostName, info.count, info.size)
	end
	startNowButton.Visible = info.isHost
end

-- 광장 아래쪽 안내 문구
local lobbyHint = label(gui, {
	Text = "노란 네모 안으로 들어가면 출근할 수 있어요",
	Font = SERIF,
	TextColor3 = rgb(255, 215, 120),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.new(0.6, 0, 0, 30),
	BackgroundTransparency = 0.3,
	BackgroundColor3 = ESPRESSO,
}, 18)
round(lobbyHint, 4)
maxSize(lobbyHint, 520, 30)

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

---------------------------------------------------------------- 정신력 바 (상태바 바로 아래, 가로로 길게)
local sanityBar = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 44),
	Size = UDim2.new(0.62, 0, 0, 14),
	BackgroundColor3 = rgb(20, 14, 12),
	BackgroundTransparency = 0.15,
	Visible = false,
}, gui)
round(sanityBar, 3)
maxSize(sanityBar, 860, 14)
brassFrame(sanityBar, 1)
local sanityFill = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(150, 110, 200),
	BorderSizePixel = 0,
}, sanityBar)
round(sanityFill, 3)
make("UIGradient", {
	Color = ColorSequence.new(rgb(120, 70, 180), rgb(190, 160, 230)),
}, sanityFill)
local sanityText = label(sanityBar, {
	Text = "정신력 100",
	Font = SERIF,
	TextColor3 = CREAM,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 3,
}, 12)

-- 정신력이 낮을수록 화면이 바래고 붉어지고 가장자리가 어두워져요. (내 화면에만)
local Lighting = game:GetService("Lighting")
local sanityGrade = Instance.new("ColorCorrectionEffect")
sanityGrade.Name = "SanityGrade"
sanityGrade.Parent = Lighting

local function applySanity(value, max)
	local ratio = math.clamp(value / max, 0, 1)
	sanityFill.Size = UDim2.fromScale(ratio, 1)
	sanityText.Text = ("정신력 %d"):format(math.floor(value + 0.5))
	sanityFill.BackgroundColor3 = ratio < 0.3 and rgb(200, 60, 60) or rgb(150, 110, 200)
	local fear = 1 - ratio
	sanityGrade.Saturation = -0.5 * fear
	sanityGrade.TintColor = Color3.new(1, 1 - 0.25 * fear, 1 - 0.25 * fear)
	for _, gradient in ipairs(vignetteGradients) do
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35 - 0.3 * fear),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
end

---------------------------------------------------------------- 안내 메시지 (토스트)
local toast = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 66),
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

-- 사진과 CCTV 위에 공포 효과를 그리는 투명한 층
local photoFx = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8, ClipsDescendants = true }, photoCard)
local cctvFx = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8, ClipsDescendants = true }, cctvCard)
local photoModel, cctvModel = nil, nil
local guestToken = 0 -- 손님이 바뀔 때마다 1씩 늘어요 (지난 손님의 효과는 멈춰요)
local cctvFxUsed = false

local function hideDesk()
	desk.Visible = false
	cctvWindow.Visible = false
	currentGuestId = nil
	currentData = nil
	guestToken += 1
	if photoMoveConnection then
		photoMoveConnection:Disconnect()
		photoMoveConnection = nil
	end
	photoView:ClearAllChildren()
	cctvView:ClearAllChildren()
	photoFx:ClearAllChildren()
	cctvFx:ClearAllChildren()
	photoCard.Rotation = -2
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
	Remotes.Scared:FireServer()
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

---------------------------------------------------------------- 여러 가지 공포 효과
-- 같은 손님을 보고 있는 동안에만 계속돼요.
local function alive(token, needCCTV)
	return guestToken == token and currentGuestId ~= nil and (not needCCTV or cctvWindow.Visible)
end

local function staticBurst(seconds)
	local stop = os.clock() + seconds
	while os.clock() < stop do
		for _, bar in ipairs(staticBars) do
			bar.Visible = math.random() < 0.8
			bar.Position = UDim2.new(0.02, 0, math.random() * 0.9, 0)
		end
		task.wait(0.04)
	end
	for _, bar in ipairs(staticBars) do
		bar.Visible = false
	end
end

local CREEPY_LINES = { "뒤를 봐", "그건 손님이 아니야", "웃고 있어", "문을 닫아", "너를 보고 있어", "들여보내지 마", "도망쳐" }

-- 손님 모델의 검은 그림자 버전 (모든 파트가 새까매요)
local function silhouette(data)
	local model = Animals.build(data, nil)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = rgb(5, 5, 5)
			part.Material = Enum.Material.SmoothPlastic
		end
	end
	return model
end

-- 머리가 천천히 카메라 쪽으로 돌아가서 정면으로 쳐다봐요.
local function turnHeadToCamera(token, model, camera, seconds, needCCTV, glow)
	local headGroup = model and model:FindFirstChild("HeadGroup")
	if not headGroup or not camera then
		return
	end
	local base = headGroup:GetPivot()
	local target = CFrame.lookAt(base.Position, camera.CFrame.Position)
	local start = os.clock()
	while alive(token, needCCTV) and os.clock() - start < seconds do
		local t = (os.clock() - start) / seconds
		headGroup:PivotTo(base:Lerp(target, t * t * (3 - 2 * t)))
		RunService.RenderStepped:Wait()
	end
	if glow and alive(token, needCCTV) then
		for _, part in ipairs(headGroup:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name == "Pupil" or part.Name == "Iris") then
				part.Color = rgb(255, 30, 30)
				part.Material = Enum.Material.Neon
			end
		end
	end
end

local CCTV_FX = {}

-- 신호가 끊겼다가, 돌아오는 순간 얼굴이 화면에 가득 차요.
function CCTV_FX.noSignal(token, data, strong)
	local cover = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(5, 5, 20), ZIndex = 9 }, cctvFx)
	label(cover, { Text = "NO SIGNAL", Font = Enum.Font.Code, TextColor3 = rgb(200, 200, 255), Size = UDim2.fromScale(1, 1), ZIndex = 10 }, 22)
	staticBurst(0.8)
	cover:Destroy()
	local camera = cctvView.CurrentCamera
	local head = cctvModel and cctvModel:FindFirstChild("HeadGroup")
	if strong and camera and head and alive(token, true) then
		Remotes.Scared:FireServer()
		local original = camera.CFrame
		local headPos = head:GetPivot().Position
		camera.CFrame = CFrame.lookAt(headPos + Vector3.new(0.3, 0.3, -2.6), headPos)
		task.wait(0.4)
		staticBurst(0.15)
		camera.CFrame = original
	end
end

-- 손님이 천천히 고개를 들어 CCTV를 똑바로 쳐다보고, 눈이 빨갛게 빛나요.
function CCTV_FX.stare(token)
	Remotes.Scared:FireServer()
	turnHeadToCamera(token, cctvModel, cctvView.CurrentCamera, 1.8, true, true)
end

-- 화면에서 사라졌다가, 카메라 바로 앞에 다시 나타나요.
function CCTV_FX.vanish(token)
	if not cctvModel then
		return
	end
	local original = cctvModel:GetPivot()
	cctvModel.Parent = nil
	staticBurst(0.9)
	if not alive(token, true) then
		return
	end
	Remotes.Scared:FireServer()
	cctvModel:PivotTo(original * CFrame.new(1.5, 0, -5) * CFrame.Angles(0, math.rad(-15), 0))
	cctvModel.Parent = cctvView
	staticBurst(0.2)
end

-- 똑같은 손님이 하나 더 옆에 서 있다가 사라져요. (도플갱어!)
function CCTV_FX.duplicate(token, data)
	local twin = Animals.build(data, data.cctvAnomaly)
	twin:PivotTo(CFrame.new(-2.8, 0.1, 1.5) * CFrame.Angles(0, math.rad(20), 0))
	Remotes.Scared:FireServer()
	for _ = 1, 4 do
		if not alive(token, true) then
			break
		end
		twin.Parent = cctvView
		task.wait(0.12)
		twin.Parent = nil
		task.wait(0.25)
	end
	twin:Destroy()
end

-- CCTV 화면에 빨간 글씨가 떠올랐다 사라져요.
function CCTV_FX.message(token)
	local text = label(cctvFx, {
		Text = CREEPY_LINES[math.random(#CREEPY_LINES)],
		Font = Enum.Font.Code,
		TextColor3 = rgb(255, 40, 40),
		TextTransparency = 1,
		Position = UDim2.fromScale(0.1 + math.random() * 0.3, 0.2 + math.random() * 0.5),
		Size = UDim2.fromScale(0.6, 0.12),
		ZIndex = 9,
	}, 22)
	for i = 1, 10 do
		text.TextTransparency = 1 - i / 10
		task.wait(0.05)
	end
	task.wait(1.2)
	for i = 1, 10 do
		text.TextTransparency = i / 10
		task.wait(0.05)
	end
	text:Destroy()
end

-- 카메라가 스스로 얼굴을 확대해요. 지지직거리면서.
function CCTV_FX.zoom(token, data, strong)
	local camera = cctvView.CurrentCamera
	if not camera then
		return
	end
	local fov = camera.FieldOfView
	local head = cctvModel and cctvModel:FindFirstChild("HeadGroup")
	local original = camera.CFrame
	local start = os.clock()
	while alive(token, true) and os.clock() - start < 2.5 do
		local t = (os.clock() - start) / 2.5
		camera.FieldOfView = fov - (fov - 18) * t
		if head then
			camera.CFrame = original:Lerp(CFrame.lookAt(original.Position, head:GetPivot().Position), t)
		end
		if math.random() < 0.08 then
			task.spawn(staticBurst, 0.1)
		end
		RunService.RenderStepped:Wait()
	end
	if strong and alive(token, true) then
		Remotes.Scared:FireServer()
		task.wait(0.8)
	end
	camera.FieldOfView = fov
	camera.CFrame = original
end

function CCTV_FX.shadow(token)
	local shadow = Instance.new("Model")
	make("Part", { Anchored = true, Size = Vector3.new(1.4, 4.6, 0.9), CFrame = CFrame.new(4.5, 2.3, 5), Color = rgb(5, 5, 5) }, shadow)
	local head = make("Part", { Anchored = true, Size = Vector3.new(1.5, 1.5, 1.5), CFrame = CFrame.new(4.5, 5.3, 5), Color = rgb(5, 5, 5) }, shadow)
	head.Shape = Enum.PartType.Ball
	shadow.Parent = cctvView
	staticBurst(0.25)
	shadow:Destroy()
end

local PHOTO_FX = {}

-- 사진 위쪽에서 핏물이 주르륵 흘러내려요.
function PHOTO_FX.drip(token)
	for _ = 1, 7 do
		local drip = make("Frame", {
			Position = UDim2.fromScale(0.05 + math.random() * 0.9, 0),
			Size = UDim2.new(0, math.random(2, 5), 0, 0),
			BackgroundColor3 = rgb(110, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 9,
		}, photoFx)
		TweenService:Create(drip, TweenInfo.new(2 + math.random() * 2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, drip.Size.X.Offset, 0.3 + math.random() * 0.6, 0),
		}):Play()
		task.wait(0.2)
	end
end

-- 사진에 쩍 금이 가요.
function PHOTO_FX.crack(token)
	local cx, cy = 0.3 + math.random() * 0.4, 0.3 + math.random() * 0.4
	for i = 1, 6 do
		make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(cx, cy),
			Size = UDim2.new(0.2 + math.random() * 0.3, 0, 0, 2),
			Rotation = i * 60 + math.random(-20, 20),
			BackgroundColor3 = rgb(20, 15, 15),
			BorderSizePixel = 0,
			ZIndex = 9,
		}, photoFx)
	end
	for _ = 1, 6 do
		photoCard.Rotation = -2 + (math.random() - 0.5) * 4
		task.wait(0.03)
	end
	photoCard.Rotation = -2
end

-- 사진 아래쪽에 빨간 손글씨가 서서히 나타나요.
function PHOTO_FX.write(token)
	local lines = { "도와줘", "나는 여기 없어", "진짜는 지하에 있어", "그 애를 믿지 마", "다음은 너야" }
	local text = label(photoFx, {
		Text = lines[math.random(#lines)],
		Font = Enum.Font.Fondamento,
		TextColor3 = rgb(150, 0, 0),
		TextTransparency = 1,
		Rotation = math.random(-8, 8),
		Position = UDim2.fromScale(0.1, 0.6),
		Size = UDim2.fromScale(0.8, 0.18),
		ZIndex = 9,
	}, 26)
	for i = 1, 20 do
		text.TextTransparency = 1 - i / 20
		task.wait(0.08)
	end
end

-- 사진이 순간순간 다른 모습(괴물 / 검은 그림자)으로 바뀌어 보여요.
function PHOTO_FX.flicker(token, data)
	if not photoModel then
		return
	end
	local strong = data.photoAnomaly ~= nil
	local other = strong and Animals.build(data, data.photoAnomaly == "moving" and "mouth" or data.photoAnomaly) or silhouette(data)
	if strong then
		Remotes.Scared:FireServer()
	end
	for _ = 1, strong and 5 or 2 do
		if not alive(token) then
			break
		end
		photoModel.Parent = nil
		other.Parent = photoView
		task.wait(0.08)
		other.Parent = nil
		photoModel.Parent = photoView
		task.wait(0.3 + math.random() * 0.4)
	end
	other:Destroy()
end

-- 사진 속 손님이 천천히 고개를 돌려 나를 쳐다봐요.
function PHOTO_FX.turn(token)
	Remotes.Scared:FireServer()
	turnHeadToCamera(token, photoModel, photoView.CurrentCamera, 2.5, false, true)
end

function PHOTO_FX.lunge(token, data)
	jumpScare(data, data.photoAnomaly == "moving" and "mouth" or data.photoAnomaly)
end

local function pick(list)
	return list[math.random(#list)]
end

-- 사진: 이상한 점이 있는 사진은 강한 효과, 평범한 사진도 가끔 약한 효과가 있어요.
local function photoEffects(data, token)
	local strong = data.photoAnomaly and data.photoAnomaly ~= "moving"
	local chance = strong and 0.75 or 0.25
	if math.random() > chance then
		return
	end
	task.wait(2 + math.random() * 3)
	if not alive(token) then
		return
	end
	local choices = strong and { "lunge", "flicker", "turn", "drip" } or { "drip", "crack", "write", "flicker" }
	PHOTO_FX[pick(choices)](token, data)
end

-- CCTV: 처음 열었을 때 한 번. 이상한 점이 있으면 강한 효과, 없어도 가끔 약한 효과가 있어요.
local function cctvEffects(data, token)
	if cctvFxUsed then
		return
	end
	cctvFxUsed = true
	local strong = data.cctvAnomaly ~= nil
	if math.random() > (strong and 0.8 or 0.3) then
		return
	end
	task.wait(1 + math.random() * 1.5)
	if not alive(token, true) then
		return
	end
	if strong then
		local choice = pick({ "lunge", "stare", "vanish", "duplicate", "noSignal", "zoom" })
		if choice == "lunge" then
			jumpScare(data, data.cctvAnomaly)
		else
			CCTV_FX[choice](token, data, true)
		end
	else
		CCTV_FX[pick({ "shadow", "noSignal", "message", "zoom" })](token, data, false)
	end
end

local function toggleCCTV()
	if not currentData then
		return
	end
	cctvWindow.Visible = not cctvWindow.Visible
	cctvButton.Text = cctvWindow.Visible and "CCTV 닫기" or "CCTV 보기"
	if cctvWindow.Visible then
		task.spawn(cctvEffects, currentData, guestToken)
	end
end
cctvButton.Activated:Connect(toggleCCTV)

local function showGuest(data)
	hideDesk()
	currentGuestId = data.id
	currentData = data
	cctvFxUsed = false
	local token = guestToken
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
	photoModel = fillViewport(
		photoView,
		data,
		data.photoAnomaly,
		CFrame.lookAt(Vector3.new(0, 5.9, -10), Vector3.new(0, 5.6, 0)),
		40,
		false
	)
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
	cctvModel = fillViewport(
		cctvView,
		data,
		data.cctvAnomaly,
		CFrame.lookAt(Vector3.new(4, 10, -11), Vector3.new(0, 3.8, 0)),
		50,
		true
	)

	desk.Visible = true
	task.spawn(photoEffects, data, token)
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
	if report.patrol then
		local patrol = report.patrol
		table.insert(lines, ("🔦 순찰: 찾은 이상 %d · 놓친 이상 %d · 헛보고 %d · 봉쇄한 방 %d"):format(patrol.portraitsFound or 0, patrol.portraitsMissed or 0, patrol.falseReports, patrol.saved))
		table.insert(lines, ("🛎 룸서비스: 팁 +%d · 놓친 전화 %d"):format(patrol.tips, patrol.missed))
	end
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
	table.insert(lines, "3. 야간 순찰 및 객실 서비스")
	local patrol = report.patrol
	if patrol then
		table.insert(lines, ("   - 복도 이상 발견 %d건 / 미발견 %d건 / 오보 %d건"):format(patrol.portraitsFound or 0, patrol.portraitsMissed or 0, patrol.falseReports))
		table.insert(lines, ("   - 이상 객실 봉쇄 %d건"):format(patrol.saved))
		table.insert(lines, ("   - 룸서비스 완료 %d건 / 미응답 %d건"):format(patrol.served, patrol.missed))
	else
		table.insert(lines, "   - 기록 없음")
	end
	table.insert(lines, "")
	table.insert(lines, ("4. 전일 수입 %d / 누적 %d"):format(report.earned, report.money))
	table.insert(lines, ("5. 누적 사망 %d / %d"):format(report.deaths, report.maxDeaths))
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
---------------------------------------------------------------- 꼬마 손님 대화창
local kidFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0.5, 0, 0, 150),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.05,
	Visible = false,
	ZIndex = 5,
}, gui)
round(kidFrame, 6)
maxSize(kidFrame, 560, 150)
brassFrame(kidFrame, 1.5)
local kidSpeaker = label(kidFrame, {
	Font = SERIF,
	TextColor3 = rgb(255, 210, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.new(0, 14, 0, 8),
	Size = UDim2.new(1, -28, 0, 22),
	ZIndex = 6,
}, 18)
local kidLine = label(kidFrame, {
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.new(0, 14, 0, 34),
	Size = UDim2.new(1, -28, 0, 56),
	ZIndex = 6,
}, 17)
local kidButtons = {}
local kidAskId = nil
for i = 1, 2 do
	local kidButton = button(kidFrame, "", i == 1 and BOTTLE or rgb(70, 50, 40), {
		TextColor3 = CREAM,
		Position = UDim2.new((i - 1) * 0.5, i == 1 and 14 or 5, 1, -50),
		Size = UDim2.new(0.5, -19, 0, 38),
		ZIndex = 6,
	}, 18)
	brassFrame(kidButton, 1)
	kidButton.Activated:Connect(function()
		if kidAskId then
			Remotes.KidChoice:FireServer(kidAskId, i)
			kidAskId = nil
			kidFrame.Visible = false
		end
	end)
	kidButtons[i] = kidButton
end

Remotes.KidEvent.OnClientEvent:Connect(function(ask)
	hideDesk()
	kidAskId = ask.id
	kidSpeaker.Text = ask.speaker
	kidLine.Text = ("“%s”"):format(ask.line)
	for i, kidButton in ipairs(kidButtons) do
		kidButton.Text = ask.choices[i] or ""
	end
	kidFrame.Visible = true
end)

---------------------------------------------------------------- 가방 (화면 오른쪽 아래): 음료를 들고 다니다가 1번 키나 버튼으로 마셔요
local UserInputService = game:GetService("UserInputService")
local bag = make("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 330, 0, 64),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.15,
	Visible = false,
	ZIndex = 6,
}, gui)
round(bag, 8)
brassFrame(bag, 1)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
}, bag)
local drinkSlot = button(bag, "🥤 0", rgb(60, 48, 34), {
	Size = UDim2.new(0, 150, 0, 50),
	ZIndex = 7,
}, 20)
local traySlot = label(bag, {
	Text = "",
	Font = Enum.Font.GothamBold,
	TextColor3 = CREAM,
	BackgroundTransparency = 0.3,
	BackgroundColor3 = rgb(40, 32, 26),
	Size = UDim2.new(0, 150, 0, 50),
	ZIndex = 7,
}, 14)
round(traySlot, 10)
local drinkCount, drinkMax = 0, 3
local trayText = nil
local function refreshBag()
	drinkSlot.Text = ("🥤 음료 %d/%d  [1]"):format(drinkCount, drinkMax)
	drinkSlot.TextTransparency = drinkCount > 0 and 0 or 0.5
	traySlot.Text = trayText or "🛎 빈손"
	traySlot.TextTransparency = trayText and 0 or 0.5
end
refreshBag()
local function drink()
	if drinkCount > 0 then
		Remotes.UseDrink:FireServer()
	end
end
drinkSlot.Activated:Connect(drink)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.One and bag.Visible then
		drink()
	end
end)
Remotes.Inventory.OnClientEvent:Connect(function(info)
	drinkCount = info.drinks or 0
	drinkMax = info.max or drinkMax
	refreshBag()
end)

---------------------------------------------------------------- 야간 순찰 목록 (오른쪽)
local patrolFrame = make("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 70),
	Size = UDim2.fromScale(0.26, 0.55),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.12,
	Visible = false,
}, gui)
round(patrolFrame, 6)
maxSize(patrolFrame, 300, 380)
brassFrame(patrolFrame, 1)
local patrolTitle = label(patrolFrame, {
	Font = SERIF,
	TextColor3 = rgb(255, 210, 120),
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.new(0, 12, 0, 8),
	Size = UDim2.new(1, -24, 0, 24),
}, 20)
local patrolBody = label(patrolFrame, {
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	RichText = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.new(0, 12, 0, 38),
	Size = UDim2.new(1, -24, 1, -46),
}, 15)

local function showPatrol(info)
	trayText = nil
	for _, call in ipairs(info.calls or {}) do
		if call.state == "carrying" and call.who == player.DisplayName then
			trayText = ("🛎 %s → %d호"):format(call.item or "", call.room or 0)
		end
	end
	refreshBag()
	if not info.active then
		patrolFrame.Visible = false
		return
	end
	local left = info.timeLeft or 0
	patrolTitle.Text = ("🔦 야간 순찰  ·  %d:%02d"):format(math.floor(left / 60), left % 60)
	local lines = { "<b>복도 순찰</b>  (떠날 때 엘리베이터에서 물어봐요)" }
	local floorMarks = {}
	for _, f in ipairs(info.floors or {}) do
		table.insert(floorMarks, f.inspected and ('<font color="#9FD99F">%d층 ✓</font>'):format(f.floor) or ('<font color="#CFC3A8">%d층 ·</font>'):format(f.floor))
	end
	table.insert(lines, table.concat(floorMarks, "   "))
	table.insert(lines, ('<font color="#A8A39A">찾아낸 이상 %d개</font>'):format(info.found or 0))
	table.insert(lines, "")
	table.insert(lines, "<b>오늘 체크인한 손님</b>")
	if #(info.guests or {}) == 0 then
		table.insert(lines, '<font color="#A8A39A">오늘 받은 손님이 없어요.</font>')
	end
	for _, guest in ipairs(info.guests or {}) do
		table.insert(lines, ("%d호  %s"):format(guest.room, guest.label))
	end
	table.insert(lines, ('<font color="#A8A39A">그 밖에 며칠째 묵고 있는 손님 %d명 (문 밑 불빛이 켜진 방)</font>'):format(info.residents or 0))
	table.insert(lines, "")
	table.insert(lines, "<b>룸서비스</b>")
	for _, call in ipairs(info.calls or {}) do
		if call.state == "ringing" then
			table.insert(lines, '<font color="#F0A85A">📞 프런트 전화가 울려요! (전화기 앞에서 E)</font>')
		elseif call.state == "carrying" then
			table.insert(lines, ("🛎 %d호  %s  —  %s 님 배달 중 (F 노크)"):format(call.room, call.item, call.who or "?"))
		else
			table.insert(lines, ('<font color="#A8A39A">%d호  %s  —  %s</font>'):format(call.room or 0, call.item or "", call.stateText))
		end
	end
	if (info.callsLeft or 0) > 0 then
		table.insert(lines, '<font color="#A8A39A">...전화가 더 올지도 몰라요</font>')
	end
	if info.canLeave then
		table.insert(lines, "")
		table.insert(lines, '<font color="#9FD99F"><b>🛎 할 일 끝! 프런트 종 앞에서 Q로 퇴근</b></font>')
	end
	patrolBody.Text = table.concat(lines, "\n")
	patrolFrame.Visible = true
end

---------------------------------------------------------------- 엘리베이터: "이 층에 이상한 게 있었나요?"
local ask = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.5, 0.34),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.03,
	Visible = false,
	ZIndex = 30,
}, gui)
round(ask, 8)
maxSize(ask, 480, 230)
brassFrame(ask, 1.5)
local askTitle = label(ask, {
	Font = SERIF,
	TextColor3 = rgb(255, 210, 120),
	Position = UDim2.fromScale(0.06, 0.06),
	Size = UDim2.fromScale(0.88, 0.2),
	ZIndex = 31,
}, 24)
local askSub = label(ask, {
	Font = Enum.Font.Gotham,
	TextColor3 = CREAM,
	Position = UDim2.fromScale(0.06, 0.28),
	Size = UDim2.fromScale(0.88, 0.18),
	ZIndex = 31,
}, 16)
-- 1단계: 이 층에 이상한 게 있었나요?
local askYes = button(ask, "😨 이상 있었어요", OXBLOOD, {
	Position = UDim2.fromScale(0.06, 0.52),
	Size = UDim2.fromScale(0.42, 0.26),
	ZIndex = 31,
}, 18)
local askNo = button(ask, "🙂 이상 없었어요", BOTTLE, {
	Position = UDim2.fromScale(0.52, 0.52),
	Size = UDim2.fromScale(0.42, 0.26),
	ZIndex = 31,
}, 18)
-- 2단계: 어느 층으로 갈까요?
local floorButtons = {}
for target = 1, 4 do
	local b = button(ask, target == 1 and "로비" or target .. "층", rgb(80, 62, 40), {
		Position = UDim2.fromScale(0.06 + (target - 1) * 0.225, 0.52),
		Size = UDim2.fromScale(0.2, 0.26),
		ZIndex = 31,
	}, 18)
	floorButtons[target] = b
end
local askClose = button(ask, "닫기", rgb(45, 36, 30), {
	Position = UDim2.fromScale(0.35, 0.83),
	Size = UDim2.fromScale(0.3, 0.12),
	TextColor3 = rgb(170, 150, 125),
	ZIndex = 31,
}, 14)

local askId, askFloor, askSaw = nil, nil, nil
local function showFloorStep()
	askTitle.Text = "🛗 어느 층으로 갈까요?"
	askSub.Text = askFloor == 1 and "엘리베이터 불빛이 지직거려요..." or ("지금은 %d층이에요."):format(askFloor)
	askYes.Visible = false
	askNo.Visible = false
	for target, b in ipairs(floorButtons) do
		b.Visible = true
		b.AutoButtonColor = target ~= askFloor
		b.BackgroundColor3 = target == askFloor and rgb(40, 34, 30) or rgb(80, 62, 40)
		b.TextTransparency = target == askFloor and 0.6 or 0
	end
end
local function closeAsk(tellServer)
	if tellServer and askId then
		Remotes.AskFloorAnswer:FireServer(askId, nil)
	end
	askId = nil
	ask.Visible = false
end
askYes.Activated:Connect(function()
	askSaw = true
	showFloorStep()
end)
askNo.Activated:Connect(function()
	askSaw = false
	showFloorStep()
end)
for target, b in ipairs(floorButtons) do
	b.Activated:Connect(function()
		if not askId or target == askFloor then
			return
		end
		Remotes.AskFloorAnswer:FireServer(askId, target, askSaw)
		closeAsk(false)
	end)
end
askClose.Activated:Connect(function()
	closeAsk(true)
end)
local function showAsk(info)
	if info.close then
		closeAsk(false)
		return
	end
	askId = info.id
	askFloor = info.floor
	askSaw = nil
	if info.askAnomaly then
		askTitle.Text = ("🛗 %d층을 떠나기 전에... 이상한 게 있었나요?"):format(info.floor)
		askSub.Text = "초상화, 꽃병, 문, 조명, 표시판, 의자... 처음과 달라진 게 있었나요?"
		askYes.Visible = true
		askNo.Visible = true
		for _, b in ipairs(floorButtons) do
			b.Visible = false
		end
	else
		showFloorStep()
	end
	ask.Visible = true
end

---------------------------------------------------------------- 안내 창 (순찰 시작, 룸서비스)
local guide = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.62, 0.62),
	BackgroundColor3 = rgb(236, 231, 218),
	Visible = false,
	ZIndex = 40,
}, gui)
round(guide, 6)
maxSize(guide, 560, 430)
make("UIStroke", { Color = rgb(150, 140, 120), Thickness = 1 }, guide)
local guideTitle = label(guide, {
	Font = Enum.Font.GothamBold,
	TextColor3 = rgb(35, 30, 28),
	Position = UDim2.fromScale(0.06, 0.04),
	Size = UDim2.fromScale(0.88, 0.11),
	ZIndex = 41,
}, 24)
local guideBody = label(guide, {
	Font = Enum.Font.Gotham,
	TextColor3 = rgb(35, 30, 28),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.07, 0.18),
	Size = UDim2.fromScale(0.86, 0.64),
	ZIndex = 41,
}, 17)
local guideButton = button(guide, "알겠어요", rgb(45, 40, 38), {
	Position = UDim2.fromScale(0.3, 0.86),
	Size = UDim2.fromScale(0.4, 0.09),
	ZIndex = 41,
}, 18)
guideButton.Activated:Connect(function()
	guide.Visible = false
end)

local GUIDES = {
	patrol = {
		title = "🔦 야간 순찰 안내",
		body = table.concat({
			"1. 프런트 오른쪽 STAFF ONLY 문으로 나가요.",
			"2. 엘리베이터 옆 버튼 판에서 E → 2층, 3층, 4층을 골라 올라가요.",
			"3. 복도를 걸으며 초상화, 꽃병, 객실 문, 조명, 층 표시판, 의자를 잘 봐 두세요.",
			"    (피, 뒤집힌 그림, 열린 문, 꺼진 불... 이상한 게 생겨요)",
			"4. 그 층을 떠나려고 엘리베이터를 타면 \"이상한 게 있었나요?\" 하고 물어봐요.",
			"    맞히면 수당 + 도플갱어 방 봉쇄! 놓치면 정신력이 떨어져요.",
			"5. 프런트 전화가 울리면 받아서 룸서비스를 배달해요.",
			"6. 2~4층을 다 둘러보고 배달도 끝나면, 프런트 종 앞에서 Q로 퇴근!",
			"",
			"🥤 정신력이 떨어지면 가방(화면 오른쪽 아래)의 음료를 마셔요. (1번 키)",
		}, "\n"),
	},
	roomservice = {
		title = "🛎 룸서비스 안내",
		body = "",
	},
}
local function showGuide(fx)
	local data = GUIDES[fx.topic]
	if not data then
		return
	end
	guideTitle.Text = data.title
	if fx.topic == "roomservice" then
		guideBody.Text = table.concat({
			("주문: %s"):format(fx.line or ""),
			"",
			("1. 쟁반을 들고 엘리베이터로 %d층에 가요."):format(math.floor((fx.room or 200) / 100)),
			("2. %d호 문 앞에서 F를 눌러 노크해요."):format(fx.room or 0),
			"3. 손님이 체인을 건 채 문을 열면 얼굴과 말을 잘 봐요.",
			"    · 얼굴이 이상하거나(검은 눈, 이빨, 찢어진 입) 말이 이상하면 도플갱어!",
			"    · 숙박부에 없는 빈방에서 온 전화도 조심해요.",
			"4. 진짜 손님이면 \"방에 들어가 건네기\" → 팁 +30",
			"    수상하면 \"팁 포기, 문 앞에 두기\" → 안전",
			"    (도플갱어 방에 들어가면 정신력이 크게 떨어져요!)",
		}, "\n")
	else
		guideBody.Text = data.body
	end
	guide.Visible = true
end

---------------------------------------------------------------- 룸서비스: 체인 건 문틈
local peep = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.72, 0.62),
	BackgroundColor3 = ESPRESSO,
	BackgroundTransparency = 0.03,
	Visible = false,
	ZIndex = 20,
}, gui)
round(peep, 8)
maxSize(peep, 640, 430)
brassFrame(peep, 1.5)
local peepTitle = label(peep, {
	Font = SERIF,
	TextColor3 = rgb(255, 210, 120),
	Position = UDim2.fromScale(0.04, 0.03),
	Size = UDim2.fromScale(0.92, 0.09),
	ZIndex = 21,
}, 24)

-- 왼쪽: 숙박부 사진
local registerCard = make("Frame", {
	Position = UDim2.fromScale(0.05, 0.15),
	Size = UDim2.fromScale(0.4, 0.62),
	BackgroundColor3 = rgb(250, 248, 240),
	Rotation = -2,
	ZIndex = 21,
}, peep)
local registerView = make("ViewportFrame", {
	Position = UDim2.fromScale(0.06, 0.05),
	Size = UDim2.fromScale(0.88, 0.76),
	BackgroundColor3 = rgb(170, 185, 195),
	Ambient = rgb(170, 165, 160),
	ZIndex = 22,
}, registerCard)
local registerCaption = label(registerCard, {
	Font = Enum.Font.Garamond,
	TextColor3 = rgb(50, 40, 40),
	Position = UDim2.fromScale(0.06, 0.83),
	Size = UDim2.fromScale(0.88, 0.15),
	ZIndex = 22,
}, 18)

-- 오른쪽: 체인을 건 채 빼꼼 열린 문틈
local doorFrame = make("Frame", {
	Position = UDim2.fromScale(0.55, 0.15),
	Size = UDim2.fromScale(0.4, 0.62),
	BackgroundColor3 = rgb(70, 42, 28),
	ZIndex = 21,
	ClipsDescendants = true,
}, peep)
make("UIStroke", { Color = rgb(40, 25, 16), Thickness = 2 }, doorFrame)
local slit = make("ViewportFrame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromScale(0.72, 1),
	BackgroundColor3 = rgb(8, 7, 8),
	Ambient = rgb(150, 140, 130),
	LightColor = rgb(240, 220, 190),
	LightDirection = Vector3.new(0.6, -0.4, 1),
	ZIndex = 22,
}, doorFrame)
-- 문틈 위에 겹치는 투명한 층 (가장자리 그림자, 어둠 속 눈). 문틈 그림을 새로 그려도 지워지지 않아요.
local slitOverlay = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromScale(0.72, 1),
	BackgroundTransparency = 1,
	ZIndex = 23,
}, doorFrame)
-- 문틈 가장자리 그림자
for _, side in ipairs({ 0, 1 }) do
	local shade = make("Frame", {
		AnchorPoint = Vector2.new(side, 0),
		Position = UDim2.fromScale(side, 0),
		Size = UDim2.fromScale(0.12, 1),
		BackgroundColor3 = rgb(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 23,
	}, slitOverlay)
	make("UIGradient", {
		Rotation = side == 0 and 0 or 180,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }),
	}, shade)
end
-- 도어 체인
local chain = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.new(0.8, 0, 0, 3),
	BackgroundColor3 = rgb(200, 170, 100),
	BorderSizePixel = 0,
	Rotation = 6,
	ZIndex = 24,
}, doorFrame)
round(chain, 2)
-- 빈방의 어둠 속 두 눈
local darkEyes = {}
for i, x in ipairs({ 0.36, 0.64 }) do
	local eye = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, 0.33),
		Size = UDim2.fromScale(0.16, 0.035),
		BackgroundColor3 = rgb(235, 230, 220),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 25,
	}, slitOverlay)
	round(eye, 20)
	make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.3, 1),
		BackgroundColor3 = rgb(160, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 26,
	}, eye)
	darkEyes[i] = eye
end
-- 숙박부 사진과 문틈을 똑같은 구도로 보여줘서 비교하기 쉬워요. (머리부터 가슴까지)
local PEEP_CAMERA = CFrame.lookAt(Vector3.new(0, 6, -12), Vector3.new(0, 5.3, 0))
local peepCallId = nil
local peepToken = 0
local peepInfo = nil

-- 문틈 속 손님을 그려요. 도플갱어는 얼굴이 이상하게 보여요.
local function drawSlit()
	local info = peepInfo
	if not info or info.empty then
		return
	end
	local token = peepToken
	local model = fillViewport(slit, info.visual, info.visualKind, PEEP_CAMERA, 40, false)
	local headGroup = model:FindFirstChild("HeadGroup")
	if headGroup then
		local base = headGroup:GetPivot()
		task.spawn(function()
			local t = 0
			while peepToken == token and model.Parent do
				t += RunService.RenderStepped:Wait()
				headGroup:PivotTo(base * CFrame.Angles(0, math.sin(t * 0.7) * 0.08, math.sin(t * 0.5) * 0.12))
			end
		end)
	end
end

-- 손님의 말 (말투가 이상한지도 잘 들어 봐요)
local peepLine = label(peep, {
	Font = Enum.Font.GothamBold,
	TextColor3 = rgb(255, 235, 200),
	Position = UDim2.fromScale(0.05, 0.785),
	Size = UDim2.fromScale(0.9, 0.08),
	ZIndex = 21,
}, 18)
local enterButton = button(peep, "🚪 방에 들어가 건네기 (팁)", BOTTLE, {
	Position = UDim2.fromScale(0.05, 0.88),
	Size = UDim2.fromScale(0.43, 0.09),
	ZIndex = 21,
}, 18)
local leaveButton = button(peep, "팁 포기, 문 앞에 두기", OXBLOOD, {
	Position = UDim2.fromScale(0.52, 0.88),
	Size = UDim2.fromScale(0.43, 0.09),
	ZIndex = 21,
}, 18)

local function closePeep()
	peep.Visible = false
	peepCallId = nil
	peepInfo = nil
	peepToken += 1
	registerView:ClearAllChildren()
	slit:ClearAllChildren()
end

local function choosePeep(choice)
	if not peepCallId then
		return
	end
	Remotes.PeepholeChoice:FireServer(peepCallId, choice)
	closePeep()
end
enterButton.Activated:Connect(function()
	choosePeep("enter")
end)
leaveButton.Activated:Connect(function()
	choosePeep("leave")
end)

local function showPeep(info)
	closePeep()
	peepCallId = info.callId
	peepInfo = info
	local token = peepToken
	peepTitle.Text = ("🛎 %d호 · %s 배달"):format(info.room, info.item)
	peepLine.Text = ("“%s”"):format(info.line or "...")

	-- 숙박부 사진
	if info.register then
		fillViewport(registerView, info.register, nil, PEEP_CAMERA, 40, false)
		registerCaption.Text = ("숙박부 · %d호 %s (%s)"):format(info.room, info.register.name, info.register.animalName or "")
	else
		registerCaption.Text = ("숙박부 · %d호 — 기록 없음"):format(info.room)
	end

	-- 문틈
	for _, eye in ipairs(darkEyes) do
		eye.Visible = false
	end
	if info.empty then
		-- 아무도 없어야 할 방... 어둠 속에서 눈이 떠져요.
		task.delay(1.4, function()
			if peepToken == token then
				for _, eye in ipairs(darkEyes) do
					eye.Visible = true
				end
			end
		end)
	else
		drawSlit()
	end
	peep.Visible = true
end

---------------------------------------------------------------- 순찰 중 공포 효과
local fadeFrame = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(0, 0, 0),
	BackgroundTransparency = 1,
	ZIndex = 60,
}, gui)
local flashFrame = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(120, 0, 0),
	BackgroundTransparency = 1,
	ZIndex = 59,
}, gui)

local function playScream(volume, speed)
	if not screamSound then
		return
	end
	local sound = screamSound:Clone()
	sound.Volume = volume
	sound.PlaybackSpeed = speed
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function onNightFx(fx)
	if fx.kind == "scare" then
		closePeep()
		task.spawn(jumpScare, fx.data, fx.anomaly)
	elseif fx.kind == "sting" then
		-- 휙 돌아보는 순간: 짧은 비명과 붉은 번쩍임
		playScream(0.5, 1.3)
		shakeCamera()
		flashFrame.BackgroundTransparency = 0.5
		TweenService:Create(flashFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
	elseif fx.kind == "whisper" then
		-- 복도 끝 그림자가 사라질 때: 낮게 깔리는 소리
		playScream(0.25, 0.45)
		shakeCamera()
	elseif fx.kind == "guide" then
		showGuide(fx)
	elseif fx.kind == "fade" then
		-- 엘리베이터: 불이 지직지직 깜빡이다가 캄캄해졌다가 다시 밝아져요.
		task.spawn(function()
			for _ = 1, 9 do
				fadeFrame.BackgroundTransparency = math.random() < 0.5 and 0.05 or 0.55 + math.random() * 0.3
				flashFrame.BackgroundTransparency = math.random() < 0.2 and 0.7 or 1
				task.wait(0.05 + math.random() * 0.08)
			end
			flashFrame.BackgroundTransparency = 1
			fadeFrame.BackgroundTransparency = 0
			task.wait(0.6)
			for _ = 1, 4 do
				fadeFrame.BackgroundTransparency = math.random() < 0.5 and 0.2 or 0.8
				task.wait(0.06)
			end
			TweenService:Create(fadeFrame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		end)
		shakeCamera()
	end
end

---------------------------------------------------------------- 광장 출근 대기
Remotes.PartyPrompt.OnClientEvent:Connect(showPartyChooser)
Remotes.PartyStatus.OnClientEvent:Connect(showPartyStatus)
Remotes.PartyClosed.OnClientEvent:Connect(function()
	lobbyFrame.Visible = false
end)

Remotes.Sanity.OnClientEvent:Connect(function(info)
	applySanity(info.value, info.max)
end)

Remotes.State.OnClientEvent:Connect(function(state)
	if state.phase == "Lobby" then
		lobbyHint.Visible = true
		hud.Visible = false
		sanityBar.Visible = false
		night.Visible = false
		kidFrame.Visible = false
		reportFrame.Visible = false
		applySanity(100, 100) -- 화면 효과 되돌리기
		hideDesk()
		patrolFrame.Visible = false
		bag.Visible = false
		closePeep()
		showAsk({ close = true })
		return
	end
	bag.Visible = true
	if state.phase ~= "Patrol" then
		patrolFrame.Visible = false
		closePeep()
		showAsk({ close = true })
	end

	lobbyFrame.Visible = false
	lobbyHint.Visible = false
	hud.Visible = true
	sanityBar.Visible = true
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
		state.phase == "Day" and "🌙 밤 근무" or state.phase == "Patrol" and "🔦 야간 순찰" or "🌑 근무 끝",
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
Remotes.PatrolState.OnClientEvent:Connect(showPatrol)
Remotes.Peephole.OnClientEvent:Connect(showPeep)
Remotes.NightFx.OnClientEvent:Connect(onNightFx)
Remotes.AskFloor.OnClientEvent:Connect(showAsk)
Remotes.MorningReport.OnClientEvent:Connect(showMorning)
