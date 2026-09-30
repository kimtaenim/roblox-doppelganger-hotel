-- 각 플레이어의 화면(UI)을 담당하는 스크립트예요.
-- 로비 화면, 위쪽 상태 표시, 프론트 체크인 화면(예약 사진 + CCTV), 밤 결과 화면이 있어요.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Animals = require(Shared:WaitForChild("Animals"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local rgb = Color3.fromRGB
local WHITE = rgb(255, 255, 255)

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

---------------------------------------------------------------- 로비 화면
local lobbyFrame = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.7),
	BackgroundColor3 = rgb(25, 20, 35),
	BackgroundTransparency = 0.05,
}, gui)
round(lobbyFrame, 16)
maxSize(lobbyFrame, 560, 470)
make("UIStroke", { Color = rgb(200, 60, 60), Thickness = 2 }, lobbyFrame)

label(lobbyFrame, {
	Text = "🏨 도플갱어 호텔",
	Font = Enum.Font.GothamBlack,
	TextColor3 = rgb(255, 90, 90),
	Position = UDim2.fromScale(0.05, 0.04),
	Size = UDim2.fromScale(0.9, 0.14),
}, 44)

label(lobbyFrame, {
	Text = "당신은 호텔 프론트 직원이에요.\n\n"
		.. "• 손님이 오면 예약 사진과 CCTV를 확인해요\n"
		.. "• 이빨이 보이거나, 입이 찢어졌거나, 눈이 검게 가려졌거나, "
		.. "몸이 이상하거나, 사진이 움직이면... 셔터를 닫아요!\n"
		.. "• 첫날은 연습이에요. 둘째 날부터 도플갱어가 와요\n"
		.. "• 희생자가 3명이 되면 해고돼요",
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.07, 0.21),
	Size = UDim2.fromScale(0.86, 0.43),
}, 18)

local soloButton = button(lobbyFrame, "혼자 시작", rgb(60, 170, 90), {
	Position = UDim2.fromScale(0.1, 0.67),
	Size = UDim2.fromScale(0.8, 0.14),
}, 30)

button(lobbyFrame, "친구와 함께 (최대 4명) · 준비 중", rgb(90, 90, 100), {
	Position = UDim2.fromScale(0.1, 0.84),
	Size = UDim2.fromScale(0.8, 0.1),
	AutoButtonColor = false,
	TextColor3 = rgb(190, 190, 190),
}, 18)

---------------------------------------------------------------- 위쪽 상태 표시
local hud = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 64),
	Size = UDim2.new(0.9, 0, 0, 40),
	BackgroundColor3 = rgb(20, 20, 30),
	BackgroundTransparency = 0.2,
	Visible = false,
}, gui)
round(hud, 20)
maxSize(hud, 620, 40)
local hudText = label(hud, { Size = UDim2.fromScale(1, 1) }, 20)

---------------------------------------------------------------- 안내 메시지 (토스트)
local toast = label(gui, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 112),
	Size = UDim2.new(0.9, 0, 0, 56),
	BackgroundTransparency = 0.15,
	BackgroundColor3 = rgb(15, 15, 25),
	Visible = false,
}, 22)
round(toast, 12)
maxSize(toast, 760, 56)

local TOAST_COLORS = {
	accept = rgb(140, 255, 160),
	caught = rgb(255, 170, 80),
	missed = rgb(200, 200, 200),
	warn = rgb(255, 120, 120),
	info = WHITE,
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

---------------------------------------------------------------- 프론트 체크인 화면
local desk = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromScale(0.96, 0.64),
	BackgroundColor3 = rgb(30, 26, 24),
	BackgroundTransparency = 0.05,
	Visible = false,
}, gui)
round(desk, 16)
maxSize(desk, 900, 520)

local deskHeader = label(desk, {
	Position = UDim2.fromScale(0.03, 0.02),
	Size = UDim2.fromScale(0.94, 0.1),
	TextXAlignment = Enum.TextXAlignment.Left,
}, 24)

-- 예약 사진 (폴라로이드)
local photoCard = make("Frame", {
	Position = UDim2.fromScale(0.03, 0.14),
	Size = UDim2.fromScale(0.45, 0.63),
	BackgroundColor3 = rgb(245, 240, 225),
}, desk)
round(photoCard, 6)
local photoView = make("ViewportFrame", {
	Position = UDim2.fromScale(0.05, 0.05),
	Size = UDim2.fromScale(0.9, 0.76),
	BackgroundColor3 = rgb(190, 215, 235),
	Ambient = rgb(170, 170, 170),
}, photoCard)
local photoCaption = label(photoCard, {
	Position = UDim2.fromScale(0.05, 0.83),
	Size = UDim2.fromScale(0.9, 0.14),
	TextColor3 = rgb(50, 40, 40),
	Font = Enum.Font.Gotham,
}, 20)

-- CCTV 화면
local cctvCard = make("Frame", {
	Position = UDim2.fromScale(0.52, 0.14),
	Size = UDim2.fromScale(0.45, 0.63),
	BackgroundColor3 = rgb(10, 12, 10),
}, desk)
round(cctvCard, 6)
local cctvView = make("ViewportFrame", {
	Position = UDim2.fromScale(0.03, 0.04),
	Size = UDim2.fromScale(0.94, 0.92),
	BackgroundColor3 = rgb(30, 40, 32),
	ImageColor3 = rgb(170, 235, 170),
	Ambient = rgb(120, 140, 120),
}, cctvCard)
for i = 1, 12 do
	make("Frame", {
		Position = UDim2.new(0.03, 0, i / 13, 0),
		Size = UDim2.new(0.94, 0, 0, 2),
		BackgroundColor3 = rgb(0, 0, 0),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, cctvCard)
end
label(cctvCard, {
	Text = "CAM 01 · 프론트",
	Font = Enum.Font.Code,
	TextColor3 = rgb(140, 255, 140),
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.06, 0.06),
	Size = UDim2.fromScale(0.6, 0.09),
	ZIndex = 4,
}, 18)
local recLabel = label(cctvCard, {
	Text = "● REC",
	Font = Enum.Font.Code,
	TextColor3 = rgb(255, 60, 60),
	TextXAlignment = Enum.TextXAlignment.Right,
	Position = UDim2.fromScale(0.64, 0.06),
	Size = UDim2.fromScale(0.3, 0.09),
	ZIndex = 4,
}, 18)
local timeLabel = label(cctvCard, {
	Font = Enum.Font.Code,
	TextColor3 = rgb(140, 255, 140),
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromScale(0.06, 0.85),
	Size = UDim2.fromScale(0.7, 0.09),
	ZIndex = 4,
}, 16)

local acceptButton = button(desk, "✅ 예약 받기", rgb(60, 160, 90), {
	Position = UDim2.fromScale(0.03, 0.8),
	Size = UDim2.fromScale(0.45, 0.12),
})
local shutterButton = button(desk, "🛑 셔터 닫기", rgb(200, 60, 60), {
	Position = UDim2.fromScale(0.52, 0.8),
	Size = UDim2.fromScale(0.45, 0.12),
})
label(desk, {
	Text = "이빨 · 찢어진 입 · 검은 눈 · 이상한 몸 · 움직이는 사진 → 셔터!",
	Font = Enum.Font.Gotham,
	TextColor3 = rgb(190, 180, 170),
	Position = UDim2.fromScale(0.03, 0.93),
	Size = UDim2.fromScale(0.94, 0.06),
}, 16)

local currentGuestId = nil
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
	currentGuestId = nil
	if photoMoveConnection then
		photoMoveConnection:Disconnect()
		photoMoveConnection = nil
	end
	photoView:ClearAllChildren()
	cctvView:ClearAllChildren()
end

local function showGuest(data)
	currentGuestId = data.id
	currentDay = data.day
	deskHeader.Text = ("📋 체크인 · %s (%s) · 손님 %d/%d"):format(data.name, data.animalName, data.index, data.total)
	photoCaption.Text = ("예약 사진 · %s"):format(data.name)

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
		-- 사진인데 움직여요...!
		local t = 0
		photoMoveConnection = RunService.RenderStepped:Connect(function(dt)
			t += dt
			photoModel:PivotTo(CFrame.Angles(0, math.sin(t * 1.7) * 0.35, math.sin(t * 2.3) * 0.06))
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

---------------------------------------------------------------- 밤 결과 화면
local night = make("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromScale(0.45, 0.62),
	BackgroundColor3 = rgb(15, 12, 25),
	BackgroundTransparency = 0.08,
	Visible = false,
}, gui)
round(night, 16)
make("UISizeConstraint", { MaxSize = Vector2.new(420, 460), MinSize = Vector2.new(260, 300) }, night)
make("UIStroke", { Color = rgb(120, 60, 160), Thickness = 2 }, night)

local nightTitle = label(night, {
	Font = Enum.Font.GothamBlack,
	Position = UDim2.fromScale(0.06, 0.04),
	Size = UDim2.fromScale(0.88, 0.12),
}, 32)
local nightBody = label(night, {
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Position = UDim2.fromScale(0.06, 0.19),
	Size = UDim2.fromScale(0.88, 0.52),
}, 18)
local nightButton = button(night, "", rgb(70, 110, 200), {
	Position = UDim2.fromScale(0.08, 0.73),
	Size = UDim2.fromScale(0.84, 0.12),
})
local nightLobbyButton = button(night, "그만하고 로비로", rgb(80, 80, 90), {
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
	nightTitle.Text = ("🌙 %d일차 밤"):format(report.day)
	nightBody.Text = "직원들이 모두 퇴근했어요...\n\n로비를 둘러보세요."
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
	if report.caught > 0 then
		table.insert(lines, ("🛑 막아낸 도플갱어: %d"):format(report.caught))
	end
	if report.missed > 0 then
		table.insert(lines, ("😢 돌려보낸 평범한 손님: %d"):format(report.missed))
	end
	table.insert(lines, ("\n총 돈: %d · 희생자 %d/%d"):format(report.money, report.deaths, report.maxDeaths))

	if report.gameOver then
		table.insert(lines, "\n❌ 희생자가 너무 많아서 해고됐어요...")
		nightMode = "lobby"
		nightButton.Text = "로비로 돌아가기"
		nightLobbyButton.Visible = false
	else
		nightMode = "next"
		nightButton.Text = "☀️ 다음 날로"
		nightLobbyButton.Visible = true
	end
	nightBody.Text = table.concat(lines, "\n")
	nightButton.Visible = true
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
		guests = ("  ·  손님 %d/%d"):format(state.guestIndex, state.guestsTotal)
	end
	hudText.Text = ("%d일차 · %s  ·  💰 %d  ·  💀 %d/%d%s"):format(
		state.day,
		state.phase == "Day" and "☀️ 낮" or "🌙 밤",
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
