-- 프런트 뒤쪽 직원 공간을 꾸미고, 음료 기계와 사물함을 관리하는 모듈이에요.
-- 직원 공간: x -29 ~ 29, z 6.5 ~ 19 (플레이어는 z 13 근처에 서 있어요)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local Props = require(script.Parent:WaitForChild("Props"))

local StaffRoom = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local Mat = Enum.Material
local P, S, ball, cyl, vcyl, text = Props.part, Props.solid, Props.ball, Props.cyl, Props.vcyl, Props.text
local WOOD, WOOD_DARK, BRASS = Props.Colors.WOOD, Props.Colors.WOOD_DARK, Props.Colors.BRASS

local FLOOR = 0.4
local MACHINE_SLOTS = {
	CFrame.new(-27.5, FLOOR, 9.5) * CFrame.Angles(0, math.rad(-90), 0),
	CFrame.new(-27.5, FLOOR, 14.3) * CFrame.Angles(0, math.rad(-90), 0),
}
local BAG_SPOT = CFrame.new(-11, 4.05, 17.2)

---------------------------------------------------------------- 음료 기계
-- base 의 -Z 쪽이 앞면이에요.
local function buildMachine(parent, index, base)
	local machine = Instance.new("Model")
	machine.Name = "DrinkMachine" .. index
	local function at(x, y, z)
		return base * CFrame.new(x, y, z)
	end
	S(machine, "Body", V(3.4, 7, 2.4), at(0, 3.5, 0), rgb(95, 22, 28), Mat.Metal)
	local panel = P(machine, "DisplayLight", V(2.1, 4.1, 0.05), at(-0.4, 4.4, -0.95), rgb(255, 220, 170), Mat.Neon)
	local glow = Instance.new("PointLight")
	glow.Range = 10
	glow.Brightness = 0.9
	glow.Color = rgb(255, 170, 130)
	glow.Parent = panel
	local colors = { rgb(200, 40, 40), rgb(60, 140, 70), rgb(230, 190, 60), rgb(80, 100, 190) }
	for row = 0, 3 do
		for col = 0, 2 do
			vcyl(machine, "Bottle", 0.8, 0.35, (at(-1.1 + col * 0.7, 2.9 + row * 1.0, -1.05)).Position, colors[row + 1], Mat.Glass)
		end
	end
	P(machine, "Glass", V(2.2, 4.2, 0.1), at(-0.4, 4.4, -1.22), rgb(220, 230, 235), Mat.Glass, { Transparency = 0.55 })
	P(machine, "SidePanel", V(0.9, 4.2, 0.1), at(1.2, 4.4, -1.22), rgb(30, 25, 25), Mat.Metal)
	ball(machine, "ButtonRed", 0.2, (at(1.2, 5.2, -1.3)).Position, rgb(220, 40, 40), Mat.Neon)
	ball(machine, "ButtonGreen", 0.2, (at(1.2, 4.7, -1.3)).Position, rgb(60, 220, 90), Mat.Neon)
	P(machine, "CoinSlot", V(0.1, 0.4, 0.05), at(1.2, 4.0, -1.29), rgb(10, 10, 10))
	local logo = P(machine, "Logo", V(3.2, 0.9, 0.1), at(0, 6.5, -1.22), rgb(160, 20, 30), Mat.Neon)
	text(logo, Enum.NormalId.Front, "SPIRIT TONIC · 정신 회복 음료", rgb(255, 235, 200), Enum.Font.GothamBlack)
	local tray = P(machine, "Tray", V(2, 0.8, 0.1), at(-0.4, 1.0, -1.22), rgb(15, 12, 12), Mat.Metal)
	local stock = P(machine, "StockLabel", V(0.9, 0.5, 0.06), at(1.2, 2.4, -1.25), rgb(10, 10, 10))
	text(stock, Enum.NormalId.Front, "", rgb(120, 255, 140), Enum.Font.Code)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DrinkPrompt"
	prompt.ActionText = "음료 챙기기"
	prompt.ObjectText = "정신력 회복"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = tray

	machine.WorldPivot = base
	machine.Parent = parent
	return machine
end

---------------------------------------------------------------- 직원 공간 꾸미기
function StaffRoom.build(hotel)
	local room = Instance.new("Folder")
	room.Name = "StaffRoom"
	room.Parent = hotel

	-- 바닥 깔개
	P(room, "StaffRug", V(12, 0.05, 6), V(0, 0.43, 12.8), rgb(40, 60, 45), Mat.Fabric)
	P(room, "StaffRugBorder", V(12.6, 0.04, 6.6), V(0, 0.42, 12.8), rgb(150, 120, 60), Mat.Fabric)

	-- 음료 기계 1대 (2번째 자리는 꼬마 손님의 보답으로 생겨요)
	buildMachine(room, 1, MACHINE_SLOTS[1])

	-- 뒤쪽 업무 책상과 의자
	S(room, "DeskTop", V(5, 0.25, 2.4), V(-12.5, 3.2, 17.2), WOOD, Mat.Wood)
	S(room, "DeskDrawers", V(1.6, 2.8, 2.2), V(-14.4, 1.8, 17.2), WOOD_DARK, Mat.Wood)
	for _, y in ipairs({ 2.6, 1.7, 0.8 }) do
		P(room, "DrawerHandle", V(0.5, 0.1, 0.1), V(-14.4, y, 16.05), BRASS, Mat.Metal)
	end
	S(room, "DeskLeg", V(0.3, 2.8, 2.2), V(-10.2, 1.8, 17.2), WOOD_DARK, Mat.Wood)
	-- 책상 위: 초록 갓 스탠드, 서류 더미, 김 나는 머그잔, 타자기, 연필꽂이, 시든 장미 한 송이
	P(room, "DeskLampBase", V(0.7, 0.12, 0.5), V(-14.3, 3.38, 17.6), BRASS, Mat.Metal)
	P(room, "DeskLampStem", V(0.1, 0.9, 0.1), V(-14.3, 3.85, 17.7), BRASS, Mat.Metal)
	local shade = cyl(room, "DeskLampShade", 1.2, 0.5, CFrame.new(-14.3, 4.35, 17.5), rgb(30, 100, 60), Mat.Glass)
	shade.Transparency = 0.15
	local deskLight = Instance.new("SpotLight")
	deskLight.Face = Enum.NormalId.Bottom
	deskLight.Range = 9
	deskLight.Angle = 110
	deskLight.Brightness = 1.8
	deskLight.Color = rgb(255, 220, 160)
	deskLight.Parent = shade
	for i = 0, 4 do
		P(room, "Paper", V(0.9, 0.04, 1.2), CFrame.new(-13.2, 3.35 + i * 0.05, 17.0) * CFrame.Angles(0, i * 0.12 - 0.2, 0), rgb(240, 235, 220))
	end
	vcyl(room, "Mug", 0.45, 0.4, V(-11.9, 3.55, 16.6), rgb(240, 240, 235))
	vcyl(room, "Coffee", 0.03, 0.34, V(-11.9, 3.76, 16.6), rgb(50, 30, 20))
	local steam = Instance.new("ParticleEmitter")
	steam.Rate = 3
	steam.Lifetime = NumberRange.new(1.5, 2.5)
	steam.Speed = NumberRange.new(0.3, 0.6)
	steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.4) })
	steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	steam.Color = ColorSequence.new(rgb(240, 240, 240))
	steam.EmissionDirection = Enum.NormalId.Top
	steam.Parent = room:FindFirstChild("Coffee", true)
	S(room, "Typewriter", V(1.4, 0.5, 1.0), V(-10.8, 3.58, 17.6), rgb(30, 30, 32), Mat.Metal)
	P(room, "TypewriterPaper", V(1.0, 0.7, 0.03), CFrame.new(-10.8, 4.1, 17.95) * CFrame.Angles(math.rad(-15), 0, 0), rgb(245, 240, 230))
	vcyl(room, "PencilCup", 0.5, 0.35, V(-12.2, 3.58, 17.9), BRASS, Mat.Metal)
	for i = 1, 3 do
		P(room, "Pencil", V(0.05, 0.7, 0.05), CFrame.new(-12.2 + (i - 2) * 0.08, 3.85, 17.9) * CFrame.Angles(0, 0, (i - 2) * 0.15), rgb(230, 190, 60))
	end
	vcyl(room, "BudVase", 0.6, 0.25, V(-10.4, 3.62, 16.6), rgb(140, 160, 170), Mat.Glass).Transparency = 0.3
	Props.rose(room, V(-10.35, 4.35, 16.65), rgb(110, 20, 30), 0.6)
	P(room, "FallenPetal", V(0.15, 0.02, 0.12), V(-10.0, 3.34, 16.4), rgb(110, 20, 30))
	-- 회전의자
	vcyl(room, "ChairSeat", 0.3, 1.6, V(-12.5, 2.0, 15.2), rgb(70, 30, 30), Mat.Leather)
	S(room, "ChairBack", V(1.5, 1.8, 0.25), V(-12.5, 3.0, 14.4), rgb(70, 30, 30), Mat.Leather)
	vcyl(room, "ChairPole", 1.4, 0.15, V(-12.5, 1.15, 15.2), rgb(40, 40, 40), Mat.Metal)
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		P(room, "ChairFoot", V(0.12, 0.12, 0.9), CFrame.new(-12.5, 0.5, 15.2) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.45), rgb(40, 40, 40), Mat.Metal)
	end
	-- 책상 위 벽시계
	local clock = cyl(room, "WallClock", 0.15, 1.6, CFrame.new(-12.5, 8.8, 18.6) * CFrame.Angles(0, math.rad(90), 0), rgb(235, 225, 200))
	text(clock, Enum.NormalId.Right, "3:33", rgb(40, 20, 20), Enum.Font.Garamond)
	vcyl(room, "Bin", 1.2, 1.0, V(-9.4, 1.0, 18.1), rgb(40, 40, 42), Mat.Metal)
	for i = 1, 3 do
		ball(room, "PaperBall", 0.35, V(-9.4 + (i - 2) * 0.25, 1.65, 18.1 + (i % 2) * 0.2), rgb(235, 232, 222))
	end

	-- 서류 캐비닛 두 개 (위에 낡은 라디오와 작은 화분)
	for i, x in ipairs({ -22.2, -19.9 }) do
		S(room, "FilingCabinet", V(2.1, 4.5, 1.8), V(x, 2.65, 17.9), rgb(80, 92, 86), Mat.Metal)
		for d = 0, 2 do
			P(room, "DrawerLine", V(1.9, 0.05, 0.05), V(x, 1.2 + d * 1.45, 16.98), rgb(40, 45, 42))
			P(room, "DrawerPull", V(0.6, 0.12, 0.1), V(x, 1.75 + d * 1.45, 16.95), BRASS, Mat.Metal)
			P(room, "DrawerLabel", V(0.5, 0.25, 0.03), V(x, 2.05 + d * 1.45, 16.98), rgb(235, 230, 215))
		end
		if i == 1 then
			S(room, "Radio", V(1.4, 0.8, 0.7), V(x, 5.3, 17.9), rgb(110, 70, 40), Mat.Wood)
			P(room, "RadioGrille", V(0.7, 0.5, 0.03), V(x - 0.2, 5.3, 17.53), rgb(40, 30, 20), Mat.Fabric)
			cyl(room, "RadioDial", 0.06, 0.25, CFrame.new(x + 0.4, 5.3, 17.53) * CFrame.Angles(0, math.rad(90), 0), BRASS, Mat.Metal)
		else
			vcyl(room, "SmallPot", 0.5, 0.6, V(x, 5.15, 17.9), rgb(150, 90, 60))
			for k = 1, 5 do
				P(room, "SmallLeaf", V(0.25, 0.03, 0.5), CFrame.new(x, 5.5, 17.9) * CFrame.Angles(0, k * 1.25, 0) * CFrame.new(0, 0, -0.2) * CFrame.Angles(math.rad(-40), 0, 0), Props.Colors.LEAF)
			end
		end
	end

	-- 코트 걸이 (낡은 코트와 중절모)
	vcyl(room, "CoatRackPole", 6.5, 0.2, V(-16.8, 3.65, 18.0), WOOD_DARK, Mat.Wood)
	vcyl(room, "CoatRackBase", 0.2, 1.4, V(-16.8, 0.5, 18.0), WOOD_DARK, Mat.Wood)
	for i = 0, 3 do
		P(room, "CoatHook", V(0.08, 0.08, 0.6), CFrame.new(-16.8, 6.6, 18.0) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, 0, -0.3) * CFrame.Angles(math.rad(-30), 0, 0), BRASS, Mat.Metal)
	end
	P(room, "Coat", V(1.4, 3.6, 0.6), CFrame.new(-16.8, 4.6, 17.55) * CFrame.Angles(0, 0, 0.05), rgb(55, 45, 40), Mat.Fabric)
	vcyl(room, "CoatHatBrim", 0.08, 1.3, V(-16.8, 7.1, 18.0), rgb(30, 28, 30))
	vcyl(room, "CoatHatCrown", 0.5, 0.85, V(-16.8, 7.4, 18.0), rgb(30, 28, 30))

	-- 화분들
	Props.plant(room, V(-27.6, FLOOR, 18.0), 4.5)
	Props.plant(room, V(20.5, FLOOR, 18.0), 3.8)
	Props.plant(room, V(-18.5, FLOOR, 8.4), 3.0)

	-- 근무 수칙 게시판 (뒤쪽 벽)
	S(room, "NoticeBoard", V(5, 3.6, 0.15), V(11.5, 7.6, 18.6), rgb(150, 110, 70), Mat.Fabric)
	local rules = P(room, "Rules", V(2.6, 3.0, 0.03), CFrame.new(10.6, 7.6, 18.5) * CFrame.Angles(0, 0, math.rad(-2)), rgb(240, 235, 220))
	text(
		rules,
		Enum.NormalId.Front,
		"근무 수칙\n1. 예약 사진과 얼굴을 꼭 확인할 것\n2. 이상하면 망설이지 말고 셔터를 내릴 것\n3. 3시 33분에는 엘리베이터를 보지 말 것\n4. 어린 손님에게는 친절할 것",
		rgb(30, 25, 25),
		Enum.Font.Garamond
	)
	local memo = P(room, "Memo", V(1.3, 1.3, 0.03), CFrame.new(12.9, 8.3, 18.5) * CFrame.Angles(0, 0, math.rad(6)), rgb(240, 220, 120))
	text(memo, Enum.NormalId.Front, "음료 기계\n고장 나면\n발로 차지 말 것", rgb(60, 40, 20), Enum.Font.Garamond)
	P(room, "Pin", V(0.12, 0.12, 0.1), V(12.9, 8.9, 18.45), rgb(200, 30, 30))

	-- 분실물 상자 (곰 인형과 우산)
	S(room, "LostBox", V(2, 1.4, 1.6), V(16.4, 1.1, 18.0), rgb(160, 120, 75), Mat.Cardboard)
	local boxLabel = P(room, "LostLabel", V(1.2, 0.4, 0.03), V(16.4, 1.3, 17.18), rgb(245, 240, 230))
	text(boxLabel, Enum.NormalId.Front, "분실물", rgb(40, 30, 30), Enum.Font.GothamBold)
	local teddy = Animals.build({ id = 5, name = "LostTeddy", animal = "bear", fur = rgb(170, 125, 80), cloth = rgb(60, 90, 140) }, nil)
	pcall(function()
		teddy:ScaleTo(0.25)
	end)
	teddy:PivotTo(CFrame.new(16.0, 1.8, 18.0))
	teddy.Parent = room
	P(room, "LostUmbrella", V(0.12, 2.4, 0.12), CFrame.new(17.0, 2.2, 18.1) * CFrame.Angles(0, 0, -0.3), rgb(20, 20, 25))

	-- 우산꽂이 (직원 출입구 옆)
	vcyl(room, "UmbrellaStand", 1.6, 0.9, V(22.4, 1.2, 7.6), BRASS, Mat.Metal)
	for i = 1, 3 do
		P(room, "Umbrella", V(0.15, 3, 0.15), CFrame.new(22.4 + (i - 2) * 0.2, 2.6, 7.6) * CFrame.Angles((i - 2) * 0.1, 0, (i - 2) * 0.12), ({ rgb(20, 20, 25), rgb(110, 20, 30), rgb(40, 60, 90) })[i])
	end

	-- 객실 열쇠 걸이판 (오른쪽 벽): 놋쇠 고리에 열쇠와 이름표가 걸려 있어요.
	S(room, "KeyBoard", V(0.2, 3.2, 5), V(28.6, 7.0, 10.8), WOOD, Mat.Wood)
	local keyTitle = P(room, "KeyBoardTitle", V(0.03, 0.45, 3), V(28.48, 8.3, 10.8), BRASS, Mat.Metal)
	text(keyTitle, Enum.NormalId.Left, "객실 열쇠", rgb(40, 25, 10), Enum.Font.Garamond)
	local keyRandom = Random.new(21)
	for row = 0, 1 do
		for col = 0, 6 do
			local z = 8.8 + col * 0.65
			local y = 7.5 - row * 1.4
			P(room, "KeyHook", V(0.25, 0.06, 0.06), V(28.4, y, z), BRASS, Mat.Metal)
			if keyRandom:NextNumber() < 0.8 then
				P(room, "HangingKey", V(0.05, 0.45, 0.14), CFrame.new(28.38, y - 0.3, z) * CFrame.Angles(keyRandom:NextNumber(-0.15, 0.15), 0, 0), BRASS, Mat.Metal)
				P(room, "HangingTag", V(0.04, 0.35, 0.22), V(28.37, y - 0.65, z), keyRandom:NextNumber() < 0.15 and rgb(150, 20, 20) or rgb(235, 230, 215))
			end
		end
	end

	-- 금고 (오른쪽 뒤 구석)
	S(room, "Safe", V(1.8, 2.2, 1.8), V(27.7, 1.5, 18.0), rgb(45, 45, 48), Mat.Metal)
	cyl(room, "SafeDial", 0.1, 0.6, CFrame.new(26.78, 1.8, 18.0), rgb(180, 180, 175), Mat.Metal)
	P(room, "SafeHandle", V(0.1, 0.12, 0.5), V(26.75, 1.2, 18.0), BRASS, Mat.Metal)

	-- 직원 사물함 (책가방을 숨길 수 있어요)
	local locker = Instance.new("Model")
	locker.Name = "Locker"
	local lockerBase = CFrame.new(27.9, FLOOR, 14.9) * CFrame.Angles(0, math.rad(90), 0)
	local lockerBody = S(locker, "LockerBody", V(2.6, 7.5, 2), lockerBase * CFrame.new(0, 3.75, 0), rgb(70, 85, 75), Mat.Metal)
	P(locker, "LockerSplit", V(0.05, 7.3, 0.05), lockerBase * CFrame.new(0, 3.75, -1.02), rgb(30, 35, 32))
	for side = -1, 1, 2 do
		for v = 0, 3 do
			P(locker, "Vent", V(0.8, 0.05, 0.05), lockerBase * CFrame.new(side * 0.65, 6.6 - v * 0.2, -1.02), rgb(30, 35, 32))
		end
		P(locker, "LockerHandle", V(0.08, 0.5, 0.1), lockerBase * CFrame.new(side * 0.2, 3.6, -1.05), rgb(190, 190, 185), Mat.Metal)
	end
	local plate = P(locker, "LockerPlate", V(1.4, 0.3, 0.03), lockerBase * CFrame.new(0, 5.6, -1.02), BRASS, Mat.Metal)
	text(plate, Enum.NormalId.Front, "직원 사물함", rgb(40, 25, 10), Enum.Font.Garamond)
	local hidePrompt = Instance.new("ProximityPrompt")
	hidePrompt.Name = "HidePrompt"
	hidePrompt.ActionText = "책가방 숨기기"
	hidePrompt.ObjectText = "직원 사물함"
	hidePrompt.HoldDuration = 1
	hidePrompt.MaxActivationDistance = 9
	hidePrompt.RequiresLineOfSight = false
	hidePrompt.Enabled = false
	hidePrompt.Parent = lockerBody
	locker.Parent = room
end

---------------------------------------------------------------- 게임에서 쓰는 기능
-- onDrink(player, machine) 는 누군가 음료 기계를 쓸 때 불려요. true 를 돌려주면 한 잔이 줄어요.
function StaffRoom.setup(hotel, onDrink)
	local room = hotel:WaitForChild("StaffRoom")
	local api = { machines = {} }

	local function updateLabel(machine)
		local label = machine:FindFirstChild("StockLabel")
		local gui = label and label:FindFirstChildOfClass("SurfaceGui")
		local textLabel = gui and gui:FindFirstChildOfClass("TextLabel")
		if textLabel then
			local stock = machine:GetAttribute("Stock") or 0
			textLabel.Text = stock > 0 and ("남은 %d"):format(stock) or "품절"
			textLabel.TextColor3 = stock > 0 and rgb(120, 255, 140) or rgb(255, 90, 80)
		end
	end

	local function register(machine)
		table.insert(api.machines, machine)
		machine:SetAttribute("Stock", machine:GetAttribute("Stock") or 0)
		updateLabel(machine)
		local prompt = machine:FindFirstChild("DrinkPrompt", true)
		if prompt then
			prompt.Triggered:Connect(function(player)
				local stock = machine:GetAttribute("Stock") or 0
				if onDrink(player, machine, stock) and stock > 0 then
					machine:SetAttribute("Stock", stock - 1)
					updateLabel(machine)
				end
			end)
		end
	end

	for _, child in ipairs(room:GetChildren()) do
		if child:IsA("Model") and child.Name:match("^DrinkMachine") then
			register(child)
		end
	end

	-- 매일 밤 근무가 시작될 때 음료를 다시 채워요.
	function api.refill(amount)
		for _, machine in ipairs(api.machines) do
			machine:SetAttribute("Stock", amount)
			updateLabel(machine)
		end
	end

	-- 음료 한 잔을 꺼내요. (꼬마 손님에게 줄 때) 성공하면 true
	function api.takeDrink()
		for _, machine in ipairs(api.machines) do
			local stock = machine:GetAttribute("Stock") or 0
			if stock > 0 then
				machine:SetAttribute("Stock", stock - 1)
				updateLabel(machine)
				return true
			end
		end
		return false
	end

	-- 음료 기계를 하나 더 놓아요. (꼬마 손님의 보답)
	function api.addMachine(stock)
		local index = #api.machines + 1
		local slot = MACHINE_SLOTS[index]
		if not slot then
			return nil
		end
		local machine = buildMachine(room, index, slot)
		machine:SetAttribute("Stock", stock or 0)
		register(machine)
		return machine
	end

	-- 게임이 끝나면 처음처럼 1대만 남겨요.
	function api.reset()
		while #api.machines > 1 do
			table.remove(api.machines):Destroy()
		end
		api.refill(0)
		api.setBag(false)
		api.enableHide(false)
	end

	-- 책상 위 책가방
	function api.setBag(visible)
		local bag = room:FindFirstChild("Backpack")
		if visible and not bag then
			Props.backpack(room, BAG_SPOT)
		elseif not visible and bag then
			bag:Destroy()
		end
	end

	-- 사물함 숨기기 버튼 (반짝이는 테두리와 함께)
	local locker = room:WaitForChild("Locker")
	local hidePrompt = locker:FindFirstChild("HidePrompt", true)
	function api.enableHide(enabled)
		hidePrompt.Enabled = enabled
		local highlight = locker:FindFirstChild("HideHighlight")
		if enabled and not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "HideHighlight"
			highlight.FillTransparency = 0.8
			highlight.OutlineColor = rgb(255, 210, 90)
			highlight.Parent = locker
		elseif not enabled and highlight then
			highlight:Destroy()
		end
	end
	api.hidePrompt = hidePrompt

	return api
end

return StaffRoom
