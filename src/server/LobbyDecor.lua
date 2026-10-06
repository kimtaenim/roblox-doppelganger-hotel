-- 호텔 1층 로비를 꾸미는 모듈이에요.
-- 짙은 원목 벽판, 청록색 줄무늬 벽지, 놋쇠 장식, 대리석 바닥으로 "고급스럽지만 심플하고 오싹하게".
-- 프론트는 원목 창구 + 위쪽 격자 유리 + 뒤쪽 빨간 열쇠 보관함이에요.
-- 곳곳에 오싹한 소품이 있고, 몇 개는 움직여요. (animate 함수)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Animals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local Props = require(script.Parent:WaitForChild("Props"))

local LobbyDecor = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local Mat = Enum.Material

local WOOD = rgb(52, 32, 22)
local WOOD_DARK = rgb(32, 20, 14)
local BRASS = rgb(176, 136, 66)
local TEAL = rgb(36, 72, 76)
local PINSTRIPE = rgb(140, 115, 70)
local MAROON = rgb(100, 22, 28)
local MUSTARD = rgb(190, 145, 40)
local CHARCOAL = rgb(62, 58, 55)
local CREAM = rgb(225, 215, 195)
local BLOOD = rgb(90, 0, 0)
local WARM = rgb(255, 214, 160)

local FLOOR = 0.4 -- 1층 바닥 높이

---------------------------------------------------------------- 도우미
local function P(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
	p.Color = color
	p.Material = material or Mat.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for key, value in pairs(props) do
			p[key] = value
		end
	end
	p.Parent = parent
	return p
end

-- 가구나 장식은 부딪히지 않게 (손님/플레이어가 걸리지 않도록)
local function D(parent, name, size, cf, color, material, props)
	local p = P(parent, name, size, cf, color, material, props)
	p.CanCollide = false
	return p
end

-- 원기둥: cf 의 X축 방향으로 길어요.
local function cyl(parent, name, length, diameter, cf, color, material)
	local p = D(parent, name, V(length, diameter, diameter), cf, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- 세워진 원기둥
local function vcyl(parent, name, height, diameter, pos, color, material)
	return cyl(parent, name, height, diameter, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material)
end

local function ball(parent, name, diameter, pos, color, material)
	local p = D(parent, name, V(diameter, diameter, diameter), pos, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function text(target, face, value, color, font, background)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = background and 0 or 1
	label.BackgroundColor3 = background or Color3.new(1, 1, 1)
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = font or Enum.Font.Garamond
	label.Text = value
	label.TextColor3 = color
	label.Parent = gui
	return label
end

local function light(part, range, brightness, color, zone)
	part:SetAttribute("Zone", zone)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = brightness
	l.Color = color or WARM
	l.Shadows = true
	l.Parent = part
	return l
end

-- 벽 꾸미기: cf 는 벽 표면의 가운데 아래(바닥 높이)이고, -Z 가 방 안쪽이에요.
local function dressWall(parent, cf, length)
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	-- 아래: 원목 벽판 + 세로 홈
	P(parent, "Wainscot", V(length, 4.4, 0.3), at(0, 2.2, -0.15), WOOD, Mat.Wood)
	local grooves = math.floor(length / 2.5)
	for i = 1, grooves do
		local x = -length / 2 + i * (length / (grooves + 1))
		D(parent, "Groove", V(0.12, 3.8, 0.05), at(x, 2.3, -0.32), WOOD_DARK, Mat.Wood)
	end
	P(parent, "Baseboard", V(length, 0.5, 0.4), at(0, 0.25, -0.2), WOOD_DARK, Mat.Wood)
	P(parent, "ChairRail", V(length, 0.35, 0.45), at(0, 4.5, -0.22), WOOD_DARK, Mat.Wood)
	D(parent, "BrassLine", V(length, 0.06, 0.47), at(0, 4.7, -0.23), BRASS, Mat.Metal)
	-- 위: 청록색 벽지 + 금색 가는 줄무늬
	P(parent, "Wallpaper", V(length, 7.9, 0.15), at(0, 8.7, -0.075), TEAL, Mat.Fabric)
	local stripes = math.floor(length / 1.6)
	for i = 1, stripes do
		local x = -length / 2 + i * (length / (stripes + 1))
		D(parent, "Pinstripe", V(0.08, 7.9, 0.04), at(x, 8.7, -0.17), PINSTRIPE, Mat.SmoothPlastic)
	end
	-- 천장 몰딩
	P(parent, "Crown", V(length, 0.85, 0.6), at(0, 12.7, -0.3), WOOD_DARK, Mat.Wood)
end

local function addWatcher(watchers, model, range)
	local headGroup = model:FindFirstChild("HeadGroup")
	if headGroup then
		table.insert(watchers, { head = headGroup, base = headGroup:GetPivot(), range = range, yaw = 0 })
	end
end

local function scaled(model, scale)
	pcall(function()
		model:ScaleTo(scale)
	end)
	return model
end

---------------------------------------------------------------- 로비 만들기
function LobbyDecor.build(hotel, interior, lights, markers)
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = hotel
	local animated = Instance.new("Folder")
	animated.Name = "Animated"
	animated.Parent = hotel
	local watchers = {}

	------------------------------------------------ 벽, 바닥, 천장
	local walls = {
		-- 손님 구역
		{ CFrame.new(-29, FLOOR, -6.75) * CFrame.Angles(0, math.rad(-90), 0), 24.5 },
		{ CFrame.new(29, FLOOR, -6.75) * CFrame.Angles(0, math.rad(90), 0), 24.5 },
		{ CFrame.new(-17, FLOOR, -19) * CFrame.Angles(0, math.pi, 0), 24 },
		{ CFrame.new(17, FLOOR, -19) * CFrame.Angles(0, math.pi, 0), 24 },
		{ CFrame.new(-21.4, FLOOR, 5.5), 15.2 },
		{ CFrame.new(18.9, FLOOR, 5.5), 10.2 },
		{ CFrame.new(28.5, FLOOR, 5.5), 1 },
		-- 직원 구역
		{ CFrame.new(0, FLOOR, 19), 58 },
		{ CFrame.new(-29, FLOOR, 12.75) * CFrame.Angles(0, math.rad(-90), 0), 12.5 },
		{ CFrame.new(29, FLOOR, 12.75) * CFrame.Angles(0, math.rad(90), 0), 12.5 },
		{ CFrame.new(-21.4, FLOOR, 6.5) * CFrame.Angles(0, math.pi, 0), 15.2 },
		{ CFrame.new(18.9, FLOOR, 6.5) * CFrame.Angles(0, math.pi, 0), 10.2 },
		{ CFrame.new(28.5, FLOOR, 6.5) * CFrame.Angles(0, math.pi, 0), 1 },
	}
	for _, wall in ipairs(walls) do
		dressWall(interior, wall[1], wall[2])
	end

	-- 천장: 크림색 판 + 원목 들보
	D(interior, "Ceiling", V(59, 0.2, 39), V(0, 13.35, 0), CREAM)
	for z = -17, 17, 5 do
		D(interior, "Beam", V(59, 0.5, 0.6), V(0, 13.0, z), WOOD_DARK, Mat.Wood)
	end

	-- 바닥: 대리석 위에 어두운 테두리, 입구에서 프론트까지 빨간 카펫
	for _, strip in ipairs({
		{ V(57, 0.04, 0.8), V(0, 0.42, -18.4) },
		{ V(57, 0.04, 0.8), V(0, 0.42, 4.7) },
		{ V(0.8, 0.04, 23.5), V(-28.4, 0.42, -6.85) },
		{ V(0.8, 0.04, 23.5), V(28.4, 0.42, -6.85) },
	}) do
		D(interior, "FloorBorder", strip[1], strip[2], rgb(60, 50, 45), Mat.Marble)
	end
	D(interior, "Runner", V(5, 0.05, 21), V(0, 0.43, -8.5), rgb(110, 20, 25), Mat.Fabric)
	D(interior, "RunnerEdge", V(0.2, 0.06, 21), V(-2.6, 0.43, -8.5), BRASS, Mat.Fabric)
	D(interior, "RunnerEdge", V(0.2, 0.06, 21), V(2.6, 0.43, -8.5), BRASS, Mat.Fabric)

	-- 입구 문틀과 위쪽 격자 유리
	D(interior, "DoorFrameL", V(0.8, 10, 0.6), V(-5.4, 5.4, -18.7), WOOD_DARK, Mat.Wood)
	D(interior, "DoorFrameR", V(0.8, 10, 0.6), V(5.4, 5.4, -18.7), WOOD_DARK, Mat.Wood)
	D(interior, "DoorFrameTop", V(11.6, 0.8, 0.6), V(0, 10.4, -18.7), WOOD_DARK, Mat.Wood)
	D(interior, "DoorTransom", V(10, 2.4, 0.1), V(0, 12, -18.8), rgb(210, 220, 215), Mat.Glass, { Transparency = 0.2 })
	for x = -4, 4, 2 do
		D(interior, "TransomBar", V(0.15, 2.4, 0.25), V(x, 12, -18.7), WOOD_DARK, Mat.Wood)
	end

	-- 큰 격자 창문 (앞벽 안쪽)
	for _, x in ipairs({ -17, 17 }) do
		D(interior, "WindowSill", V(11, 0.4, 0.9), V(x, 5.0, -18.6), rgb(220, 215, 205), Mat.Marble)
		D(interior, "WindowFrame", V(10.6, 7.6, 0.2), V(x, 8.7, -18.75), rgb(35, 40, 40), Mat.Metal)
		-- 달빛이 들어오는 창: 푸르스름하게 빛나고, 방 안으로 차가운 빛을 비춰요.
		local pane = D(interior, "WindowPane", V(10, 7, 0.1), V(x, 8.7, -18.6), rgb(70, 90, 130), Mat.Neon, { Transparency = 0.35 })
		local moon = Instance.new("SurfaceLight")
		moon.Face = Enum.NormalId.Back
		moon.Range = 18
		moon.Angle = 70
		moon.Brightness = 1.2
		moon.Color = rgb(120, 140, 200)
		moon.Parent = pane
		for dx = -4, 4, 2 do
			D(interior, "Mullion", V(0.15, 7, 0.15), V(x + dx, 8.7, -18.5), rgb(35, 40, 40), Mat.Metal)
		end
		for dy = -2.4, 2.4, 1.6 do
			D(interior, "Muntin", V(10, 0.15, 0.15), V(x, 8.7 + dy, -18.5), rgb(35, 40, 40), Mat.Metal)
		end
	end

	------------------------------------------------ 직원용 출입구 (프런트 오른쪽)
	for _, x in ipairs({ 23.8, 28.2 }) do
		D(interior, "StaffDoorPost", V(0.4, 9.4, 1.3), V(x, 5.1, 6), WOOD_DARK, Mat.Wood)
	end
	D(interior, "StaffDoorHeader", V(4.8, 0.5, 1.3), V(26, 9.65, 6), WOOD_DARK, Mat.Wood)
	for _, z in ipairs({ 5.42, 6.58 }) do
		D(interior, "StaffDoorWallpaper", V(4, 3.2, 0.15), V(26, 11.5, z), TEAL, Mat.Fabric)
		D(interior, "StaffDoorCrown", V(4, 0.85, 0.6), V(26, 13.1, z), WOOD_DARK, Mat.Wood)
	end
	local staffSign = D(interior, "StaffSign", V(2.4, 0.5, 0.05), V(26, 10.4, 5.36), BRASS, Mat.Metal)
	text(staffSign, Enum.NormalId.Front, "STAFF ONLY", rgb(40, 25, 10), Enum.Font.Garamond)

	------------------------------------------------ 프론트 데스크 (사진 오른쪽 느낌)
	-- 원목 카운터 + 세로 홈 + 놋쇠 테두리 (카운터 윗면 높이 3.6)
	P(interior, "Counter", V(24.8, 2.85, 2), V(0, 1.825, 6), WOOD, Mat.Wood)
	for x = -11.2, 11.2, 1.6 do
		D(interior, "CounterGroove", V(0.12, 2.5, 0.05), V(x, 1.85, 4.97), WOOD_DARK, Mat.Wood)
	end
	P(interior, "CounterTop", V(25.2, 0.35, 2.8), V(0, 3.425, 5.9), WOOD_DARK, Mat.Wood)
	D(interior, "CounterBrass", V(25.2, 0.08, 0.1), V(0, 3.42, 4.48), BRASS, Mat.Metal)
	P(interior, "CounterBarrier", V(24.8, 5.6, 0.3), V(0, 6.4, 6.6), rgb(255, 255, 255), nil, { Transparency = 1 })

	-- 창구 기둥과 윗부분 (셔터가 숨어 있는 곳)
	for _, x in ipairs({ -13.2, 13.2 }) do
		P(interior, "DeskPost", V(1.2, 13.1, 1.4), V(x, 6.95, 6), WOOD_DARK, Mat.Wood)
	end
	P(interior, "DeskHeader", V(27.6, 1.6, 2.2), V(0, 10.0, 5.6), WOOD_DARK, Mat.Wood)
	D(interior, "HeaderBrass", V(27.6, 0.08, 0.1), V(0, 9.22, 4.48), BRASS, Mat.Metal)

	-- 위쪽 격자 유리창
	D(interior, "Transom", V(25.2, 2.7, 0.2), V(0, 12.15, 6), rgb(215, 225, 215), Mat.Glass, { Transparency = 0.35 })
	for x = -12.6, 12.6, 2.1 do
		D(interior, "TransomBar", V(0.18, 2.7, 0.3), V(x, 12.15, 6), WOOD_DARK, Mat.Wood)
	end
	D(interior, "TransomBar", V(25.2, 0.18, 0.3), V(0, 12.15, 6), WOOD_DARK, Mat.Wood)

	-- 셔터 (평소엔 윗부분 안에 숨어 있다가 닫으면 내려와요)
	local shutterOpen = P(markers, "ShutterOpen", V(24.8, 0.4, 0.2), V(0, 10.0, 5.0), rgb(255, 0, 255), nil, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	P(markers, "ShutterClosed", V(24.8, 5.6, 0.2), V(0, 6.4, 5.0), rgb(255, 0, 255), nil, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	D(hotel, "Shutter", shutterOpen.Size, shutterOpen.CFrame, rgb(62, 56, 50), Mat.DiamondPlate)

	-- 카운터 위 소품: 벚꽃 화병, 떨어진 꽃잎, 종, 숙박부, 다이얼 전화기
	vcyl(interior, "Vase", 1.4, 0.7, V(-10.5, 4.3, 5.6), rgb(90, 120, 70), Mat.Glass).Transparency = 0.3
	local blossomRandom = Random.new(7)
	for i = 1, 5 do
		local angle = (i - 3) * 0.35
		local branch = CFrame.new(-10.5, 5.0, 5.6) * CFrame.Angles(0, 0, angle) * CFrame.new(0, 1.4, 0)
		D(interior, "Branch", V(0.08, 2.8, 0.08), branch, rgb(60, 40, 30), Mat.Wood)
		for k = 1, 7 do
			local p = (branch * CFrame.new(0, blossomRandom:NextNumber(-0.6, 1.4), 0)).Position
			local offset = V(blossomRandom:NextNumber(-0.35, 0.35), 0, blossomRandom:NextNumber(-0.35, 0.35))
			if k % 3 == 0 then
				Props.flower(interior, p + offset, rgb(245, 190, 210), 0.42)
			else
				ball(interior, "Blossom", 0.3, p + offset, k % 2 == 0 and rgb(240, 180, 200) or rgb(250, 215, 225))
			end
		end
	end
	for _ = 1, 6 do
		D(interior, "Petal", V(0.18, 0.02, 0.18), V(-10.5 + blossomRandom:NextNumber(-1.5, 2), 3.61, 5.2 + blossomRandom:NextNumber(0, 1)), rgb(230, 170, 190))
	end
	ball(interior, "Bell", 0.6, V(3, 3.85, 5.4), BRASS, Mat.Metal)
	D(interior, "Ledger", V(1.6, 0.1, 1.1), V(-3, 3.65, 5.6), rgb(240, 232, 215))
	D(interior, "Pen", V(0.05, 0.05, 0.9), CFrame.new(-2.3, 3.73, 5.5) * CFrame.Angles(0, 0.4, 0), WOOD_DARK)
	D(interior, "PhoneBase", V(1.2, 0.5, 1), V(8, 3.85, 5.6), rgb(20, 20, 20))
	D(interior, "PhoneHandset", V(1.4, 0.3, 0.35), V(8, 4.25, 5.6), rgb(20, 20, 20))
	cyl(interior, "PhoneDial", 0.05, 0.6, CFrame.new(8, 3.9, 5.08) * CFrame.Angles(0, math.rad(90), 0), rgb(230, 225, 210))

	-- 직원 쪽 낡은 브라운관 모니터 두 대
	for _, info in ipairs({ { -9, "CCTV", rgb(120, 255, 120) }, { 9, "예약 확인", rgb(150, 200, 255) } }) do
		local x = info[1]
		D(interior, "CRT", V(2.2, 1.7, 1.6), V(x, 4.45, 6.9), rgb(175, 170, 155))
		local screen = D(interior, "CRTScreen", V(1.8, 1.3, 0.05), V(x, 4.5, 7.71), rgb(10, 20, 10))
		text(screen, Enum.NormalId.Back, info[2], info[3], Enum.Font.Code)
	end

	-- 직원 구역 뒤쪽: 빨간 열쇠 보관함 + 놋쇠 랜턴
	D(interior, "CubbyLedge", V(15, 0.3, 1.2), V(0, 4.85, 18.4), WOOD_DARK, Mat.Wood)
	D(interior, "CubbyBack", V(14, 6.4, 0.2), V(0, 8.2, 18.75), rgb(40, 10, 12))
	D(interior, "CubbyFrame", V(14.4, 0.4, 1), V(0, 11.5, 18.4), MAROON, Mat.Wood)
	D(interior, "CubbyFrame", V(14.4, 0.4, 1), V(0, 5.0, 18.4), MAROON, Mat.Wood)
	local keyRandom = Random.new(3)
	for col = 0, 7 do
		D(interior, "CubbySlat", V(0.15, 6.2, 0.9), V(-7 + col * 2, 8.2, 18.4), MAROON, Mat.Wood)
	end
	for row = 0, 5 do
		D(interior, "CubbyShelf", V(14, 0.15, 0.9), V(0, 5.2 + row * 1.2, 18.4), MAROON, Mat.Wood)
	end
	for col = 0, 6 do
		for row = 0, 4 do
			if keyRandom:NextNumber() < 0.75 then
				local x, y = -6 + col * 2, 5.8 + row * 1.2
				D(interior, "Key", V(0.15, 0.45, 0.05), V(x - 0.2, y, 18.3), BRASS, Mat.Metal)
				D(interior, "KeyTag", V(0.3, 0.4, 0.05), V(x + 0.2, y - 0.05, 18.3), rgb(235, 230, 215))
			end
		end
	end
	for _, x in ipairs({ -6, 6 }) do
		D(interior, "LanternChain", V(0.08, 1.4, 0.08), V(x, 12.6, 9), BRASS, Mat.Metal)
		D(interior, "LanternCap", V(1.1, 0.25, 1.1), V(x, 11.8, 9), BRASS, Mat.Metal)
		local glow = D(lights, "Lantern", V(0.8, 1.1, 0.8), V(x, 11.1, 9), WARM, Mat.Neon)
		light(glow, 22, 1.2, WARM, "Staff")
		D(interior, "LanternBase", V(1.0, 0.2, 1.0), V(x, 10.45, 9), BRASS, Mat.Metal)
	end

	------------------------------------------------ 샹들리에와 벽등
	local function chandelier(center)
		D(interior, "Chain", V(0.15, 1.2, 0.15), center + V(0, 0.9, 0), BRASS, Mat.Metal)
		local hub = ball(lights, "ChandelierHub", 0.8, center, BRASS, Mat.Metal)
		light(hub, 32, 1.3, WARM, "Guest")
		for i = 0, 7 do
			local angle = i * math.pi / 4
			local dir = V(math.cos(angle), 0, math.sin(angle))
			D(interior, "Arm", V(0.12, 0.12, 2.4), CFrame.lookAt(center + dir * 1.2, center + dir * 2.4), BRASS, Mat.Metal)
			local globe = ball(lights, "Globe", 0.9, center + dir * 2.5 - V(0, 0.2, 0), rgb(255, 245, 225), Mat.Neon)
			globe:SetAttribute("Zone", "Guest")
		end
	end
	chandelier(V(0, 12, -8))
	chandelier(V(-20, 12, -9))

	local function sconce(pos, facing, zone)
		local cf = CFrame.lookAt(pos, pos + facing)
		D(interior, "SconcePlate", V(0.6, 1, 0.15), cf, BRASS, Mat.Metal)
		local bulb = D(lights, "Sconce", V(0.5, 0.7, 0.5), cf * CFrame.new(0, 0.3, -0.45), WARM, Mat.Neon)
		light(bulb, 16, 0.9, WARM, zone)
		return bulb
	end
	sconce(V(-28.65, 9, -15), V(1, 0, 0), "Guest")
	sconce(V(-28.65, 9, -3), V(1, 0, 0), "Guest")
	sconce(V(28.65, 9, -17.8), V(-1, 0, 0), "Guest")
	sconce(V(28.65, 9, -6.5), V(-1, 0, 0), "Flicker").Name = "FlickerSconce" -- 엘리베이터 옆, 혼자 깜빡여요

	------------------------------------------------ 왼쪽 라운지 (사진 왼쪽 느낌)
	D(interior, "Rug", V(13, 0.06, 11), V(-20, 0.43, -9), rgb(150, 85, 35), Mat.Fabric)
	D(interior, "RugInner", V(11, 0.07, 9), V(-20, 0.435, -9), rgb(125, 68, 28), Mat.Fabric)

	-- 짙은 회색 소파 (왼쪽 벽)
	D(interior, "SofaBase", V(3.2, 1.4, 10), V(-27.0, 1.1, -9), CHARCOAL, Mat.Fabric)
	D(interior, "SofaCushion", V(3, 0.5, 4.8), V(-27.1, 2.05, -11.45), rgb(72, 66, 62), Mat.Fabric)
	D(interior, "SofaCushion", V(3, 0.5, 4.8), V(-27.1, 2.05, -6.55), rgb(72, 66, 62), Mat.Fabric)
	D(interior, "SofaBack", V(1, 3.2, 10), V(-28.2, 2.6, -9), CHARCOAL, Mat.Fabric)
	D(interior, "SofaArm", V(3.4, 2.2, 0.9), V(-27.3, 1.9, -13.55), CHARCOAL, Mat.Fabric)
	D(interior, "SofaArm", V(3.4, 2.2, 0.9), V(-27.3, 1.9, -4.45), CHARCOAL, Mat.Fabric)
	for _, z in ipairs({ -14.1, -3.9 }) do
		vcyl(interior, "SofaPost", 3, 0.35, V(-25.5, 1.9, z), WOOD, Mat.Wood)
		ball(interior, "SofaKnob", 0.6, V(-25.5, 3.5, z), WOOD, Mat.Wood)
	end
	cyl(interior, "Bolster", 2.6, 0.9, CFrame.new(-27.1, 2.75, -12.6), rgb(55, 50, 48), Mat.Fabric)

	-- 낮은 원목 테이블 (계단처럼 겹친 상판)
	D(interior, "TableTop", V(5, 0.35, 4.5), V(-20.5, 2.0, -9), WOOD, Mat.Wood)
	D(interior, "TableTop2", V(3, 0.3, 2.5), V(-19.5, 2.33, -8.2), WOOD_DARK, Mat.Wood)
	for _, offset in ipairs({ V(-2, 0, -1.8), V(2, 0, -1.8), V(-2, 0, 1.8), V(2, 0, 1.8) }) do
		D(interior, "TableLeg", V(0.8, 1.6, 0.8), V(-20.5, 1.2, -9) + offset, WOOD_DARK, Mat.Wood)
	end
	-- 테이블 위: 검붉은 장미 꽃다발, 떨어진 꽃잎, 신문
	Props.bouquet(interior, V(-21.6, 2.18, -10.1), "rose", rgb(120, 15, 25), 9, rgb(40, 60, 55))
	for i = 1, 4 do
		D(interior, "FallenPetal", V(0.18, 0.02, 0.14), CFrame.new(-21.0 + i * 0.3, 2.19, -9.2 - (i % 2) * 0.3) * CFrame.Angles(0, i, 0), rgb(110, 15, 25))
	end
	local paper = D(interior, "Newspaper", V(1.8, 0.05, 1.3), CFrame.new(-19.6, 2.51, -8.3) * CFrame.Angles(0, 0.3, 0), rgb(225, 220, 205))
	text(paper, Enum.NormalId.Top, "호텔 투숙객\n연쇄 실종", rgb(30, 25, 25), Enum.Font.Garamond)

	-- 겨자색 안락의자 두 개 (소파를 바라봐요)
	local function armchair(cx, cz)
		D(interior, "ChairSeat", V(2.8, 1.2, 2.8), V(cx, 1.4, cz), MUSTARD, Mat.Fabric)
		D(interior, "ChairBack", V(0.6, 3.2, 2.8), V(cx + 1.5, 2.6, cz), MUSTARD, Mat.Fabric)
		for _, side in ipairs({ -1, 1 }) do
			D(interior, "ChairArm", V(3, 0.3, 0.4), V(cx, 2.65, cz + side * 1.55), WOOD, Mat.Wood)
			D(interior, "ChairCane", V(2.6, 1.3, 0.12), V(cx, 1.75, cz + side * 1.58), rgb(170, 130, 80), Mat.Fabric)
			for _, dx in ipairs({ -1.4, 1.6 }) do
				vcyl(interior, "ChairPost", 2.9, 0.35, V(cx + dx, 1.85, cz + side * 1.55), WOOD, Mat.Wood)
				ball(interior, "ChairKnob", 0.5, V(cx + dx, 3.4, cz + side * 1.55), WOOD, Mat.Wood)
			end
		end
	end
	armchair(-14.5, -12)
	armchair(-14.5, -6)

	------------------------------------------------ 오른쪽: 엘리베이터 (예약한 손님이 방으로 올라가는 곳)
	D(interior, "ElevatorFrame", V(0.5, 10.5, 8.4), V(28.5, 5.65, -2), rgb(120, 90, 50), Mat.Metal)
	D(interior, "ElevatorDoor", V(0.3, 9, 7), V(28.25, 4.9, -2), rgb(90, 70, 45), Mat.Metal)
	D(interior, "ElevatorGap", V(0.35, 9, 0.08), V(28.25, 4.9, -2), rgb(20, 15, 10))
	-- 문에 난 긁힌 자국
	for i = 1, 4 do
		D(interior, "Scratch", V(0.05, 2.2, 0.06), CFrame.new(28.08, 3.2 + i * 0.15, -3.6 + i * 0.25) * CFrame.Angles(math.rad(25), 0, 0), rgb(30, 25, 20))
	end
	local panel = D(interior, "ElevatorPanel", V(0.2, 1, 2.4), V(28.35, 10.9, -2), rgb(15, 10, 10))
	text(panel, Enum.NormalId.Left, "▼ B4", rgb(255, 60, 40), Enum.Font.Code)
	D(interior, "CallButton", V(0.15, 0.8, 0.5), V(28.4, 4.6, -6.7), BRASS, Mat.Metal)

	------------------------------------------------ 오싹한 소품들
	-- 1) 3시 33분에 멈춘(?) 괘종시계. 시계추는 혼자 흔들려요.
	D(interior, "ClockBody", V(1.4, 7.5, 1.8), V(28.0, 4.15, -16), WOOD_DARK, Mat.Wood)
	D(interior, "ClockHood", V(1.6, 1.6, 2.1), V(27.95, 8.7, -16), WOOD, Mat.Wood)
	local face = D(interior, "ClockFace", V(0.05, 1.4, 1.4), V(27.12, 8.7, -16), rgb(230, 220, 195))
	text(face, Enum.NormalId.Left, "3:33", rgb(40, 20, 20), Enum.Font.Garamond)
	D(interior, "ClockGlass", V(0.05, 3.6, 1.2), V(26.95, 4.2, -16), rgb(200, 210, 210), Mat.Glass, { Transparency = 0.6 })
	local pendulum = Instance.new("Model")
	pendulum.Name = "Pendulum"
	local pivot = CFrame.new(27.1, 5.8, -16)
	D(pendulum, "Rod", V(0.08, 2.6, 0.08), pivot * CFrame.new(0, -1.3, 0), BRASS, Mat.Metal)
	cyl(pendulum, "Bob", 0.08, 0.9, pivot * CFrame.new(0, -2.7, 0), BRASS, Mat.Metal)
	pendulum.WorldPivot = pivot
	pendulum.Parent = animated

	-- 2) 실종 손님 전단지 게시판
	D(interior, "Corkboard", V(0.2, 4, 6.4), V(28.6, 8.4, -10.5), rgb(150, 110, 70), Mat.Fabric)
	local title = D(interior, "CorkTitle", V(0.05, 0.7, 6), V(28.48, 10.0, -10.5), rgb(230, 225, 210))
	text(title, Enum.NormalId.Left, "실종 손님을 찾습니다", rgb(140, 0, 0), Enum.Font.GothamBlack)
	local missing = { "지우 (토끼)", "하린 (고양이)", "???", "건우 (곰)", "다은 (여우)", "시우 (강아지)" }
	for i, name in ipairs(missing) do
		local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
		local poster = D(interior, "Poster", V(0.05, 1.4, 1.6), CFrame.new(28.46, 8.9 - row * 1.6, -12.5 + col * 2) * CFrame.Angles(math.rad(math.random(-6, 6)), 0, 0), rgb(240, 235, 220))
		text(poster, Enum.NormalId.Left, "실종\n" .. name, name == "???" and rgb(120, 0, 0) or rgb(30, 30, 30), Enum.Font.Garamond)
	end

	-- 3) 낡은 짐수레와 가방들 (한 가방 밑으로 뭔가 새어 나와요)
	local cart = V(24, FLOOR, -10.5)
	D(interior, "CartBase", V(3, 0.3, 5), cart + V(0, 0.6, 0), BRASS, Mat.Metal)
	for _, dz in ipairs({ -2.3, 2.3 }) do
		vcyl(interior, "CartPost", 5.5, 0.2, cart + V(0, 3.4, dz), BRASS, Mat.Metal)
		for _, dx in ipairs({ -1.3, 1.3 }) do
			ball(interior, "Wheel", 0.5, cart + V(dx, 0.25, dz), rgb(20, 20, 20))
		end
	end
	D(interior, "CartBar", V(0.2, 0.2, 4.8), cart + V(0, 6.1, 0), BRASS, Mat.Metal)
	D(interior, "Suitcase", V(2.2, 1.2, 3), cart + V(0, 1.35, -0.6), rgb(80, 45, 30), Mat.Leather)
	D(interior, "Suitcase", V(1.8, 1.0, 2.4), cart + V(0.1, 2.45, -0.4), rgb(110, 30, 30), Mat.Leather)
	D(interior, "Suitcase", V(1.6, 1.6, 1.4), cart + V(-0.1, 1.55, 1.6), rgb(40, 40, 60), Mat.Leather)
	cyl(interior, "Leak", 0.03, 1.6, CFrame.new(cart + V(0.4, 0.03, -0.8)) * CFrame.Angles(0, 0, math.rad(90)), BLOOD)

	-- 4) 혼자 흔들리는 흔들의자 (왼쪽 앞 구석)
	local rocker = Instance.new("Model")
	rocker.Name = "RockingChair"
	local base = CFrame.new(-25, FLOOR, -16.5) * CFrame.Angles(0, math.rad(200), 0)
	local function rp(name, size, x, y, z, rx)
		D(rocker, name, size, base * CFrame.new(x, y, z) * CFrame.Angles(rx or 0, 0, 0), WOOD, Mat.Wood)
	end
	for _, x in ipairs({ -1, 1 }) do
		rp("Runner", V(0.2, 0.25, 3.6), x, 0.15, 0)
		rp("Runner", V(0.2, 0.25, 1), x, 0.3, -1.9, 0.35)
		rp("Runner", V(0.2, 0.25, 1), x, 0.3, 1.9, -0.35)
		rp("Leg", V(0.2, 1.6, 0.2), x, 1.0, -0.8)
		rp("Leg", V(0.2, 1.6, 0.2), x, 1.0, 0.9)
		rp("BackPost", V(0.2, 3.4, 0.2), x, 3.5, 1.05, -0.12)
		rp("ArmRest", V(0.2, 0.15, 2), x, 2.9, 0)
	end
	rp("Seat", V(2.2, 0.25, 2.2), 0, 1.9, 0)
	for i = -1, 1 do
		rp("Spindle", V(0.12, 2.8, 0.12), i * 0.5, 3.4, 1.0, -0.12)
	end
	rp("TopRail", V(2.4, 0.4, 0.2), 0, 5.1, 1.25, -0.12)
	rocker.WorldPivot = base
	rocker.Parent = animated

	-- 5) 시든 화분 (입구 양옆)
	local deadRandom = Random.new(11)
	for _, x in ipairs({ -7.8, 7.8 }) do
		vcyl(interior, "Urn", 2.2, 2, V(x, 1.5, -17.6), rgb(60, 50, 40), Mat.Metal)
		for i = 1, 5 do
			local tilt = CFrame.new(x, 2.8, -17.6) * CFrame.Angles(deadRandom:NextNumber(-0.5, 0.5), i, deadRandom:NextNumber(-0.5, 0.5))
			D(interior, "DeadBranch", V(0.1, 3, 0.1), tilt * CFrame.new(0, 1.4, 0), rgb(70, 50, 35), Mat.Wood)
		end
		for _ = 1, 4 do
			D(interior, "DeadLeaf", V(0.35, 0.02, 0.25), V(x + deadRandom:NextNumber(-2, 2), 0.42, -17 + deadRandom:NextNumber(-1, 2)), rgb(110, 80, 40))
		end
	end

	-- 6) 문에서 시작해서 오른쪽 벽을 타고 천장까지 올라간 발자국
	local stepFrom, stepTo = V(3, 0, -18), V(28.1, 0, -13.5)
	local steps = 12
	for i = 0, steps do
		local p = stepFrom:Lerp(stepTo, i / steps)
		local side = (i % 2 == 0) and 0.3 or -0.3
		local dir = (stepTo - stepFrom).Unit
		local cf = CFrame.lookAt(V(p.X, 0.43, p.Z), V(p.X, 0.43, p.Z) + dir) * CFrame.new(side, 0, 0)
		D(interior, "Footprint", V(0.5, 0.03, 0.8), cf, rgb(45, 30, 25))
	end
	for i = 0, 8 do
		local side = (i % 2 == 0) and 0.3 or -0.3
		D(interior, "WallFootprint", V(0.03, 0.8, 0.5), V(28.62, 1.2 + i * 1.35, -13.5 + side), rgb(45, 30, 25))
	end

	-- 7) 금 간 거울 (소파 위)
	D(interior, "MirrorFrame", V(0.3, 4.6, 3.6), V(-28.5, 8.6, -9), BRASS, Mat.Metal)
	D(interior, "Mirror", V(0.08, 4, 3), V(-28.32, 8.6, -9), rgb(180, 190, 195), Mat.Glass, { Reflectance = 0.6 })
	for i = 1, 5 do
		D(interior, "Crack", V(0.02, 1.6 + i * 0.2, 0.05), CFrame.new(-28.26, 8.9, -9.3) * CFrame.Angles(i * 1.15, 0, 0) * CFrame.new(0, 0.8, 0), rgb(40, 40, 40))
	end

	-- 8) 소파에 앉은 검은 눈 곰 인형
	local doll = Animals.build({ name = "Doll", animal = "bear", fur = rgb(150, 105, 70), cloth = rgb(120, 30, 40) }, "eyes")
	scaled(doll, 0.3)
	doll:PivotTo(CFrame.new(-26.8, 2.32, -7.5) * CFrame.Angles(0, math.rad(-90), 0))
	doll.Parent = decor

	-- 9) 얼굴 없는 벨보이 마네킹 (고개가 플레이어를 따라 돌아가요)
	local bellhop = Animals.build({ name = "Bellhop", animal = "fox", fur = rgb(225, 225, 220), cloth = rgb(130, 20, 30) }, nil)
	for _, part in ipairs(bellhop:GetDescendants()) do
		if part:IsA("BasePart") and (part.Name:find("Eye") or part.Name == "Pupil" or part.Name == "Iris" or part.Name == "Mouth" or part.Name:find("Nose") or part.Name == "Brow" or part.Name == "Blush" or part.Name:find("Glasses") or part.Name:find("Hat") or part.Name:find("Beret")) then
			part:Destroy()
		end
	end
	local bellHead = bellhop.HeadGroup.PrimaryPart.CFrame
	vcyl(bellhop.HeadGroup, "Cap", 0.7, 1.4, (bellHead * CFrame.new(0, 1.3, 0)).Position, rgb(130, 20, 30), Mat.Fabric)
	vcyl(bellhop.HeadGroup, "CapBand", 0.2, 1.45, (bellHead * CFrame.new(0, 1.05, 0)).Position, BRASS, Mat.Metal)
	bellhop:PivotTo(CFrame.new(-8, 0.5, -14.5) * CFrame.Angles(0, math.rad(160), 0))
	bellhop.Parent = decor
	addWatcher(watchers, bellhop, 45)

	-- 10) 초상화 두 점: 검은 눈의 초대 지배인, 그리고 눈이 따라오는 고양이 부인
	local function portrait(x, data, anomaly, plaque, watch)
		D(interior, "PortraitFrame", V(4, 5, 0.3), V(x, 8.8, 5.2), BRASS, Mat.Metal)
		D(interior, "PortraitCanvas", V(3.4, 4.4, 0.1), V(x, 8.8, 5.02), rgb(25, 20, 18))
		local bust = Animals.build(data, anomaly)
		scaled(bust, 0.45)
		bust:PivotTo(CFrame.new(x, 6, 4.6))
		local headPos = bust.HeadGroup:GetPivot().Position
		bust:PivotTo(bust:GetPivot() + (Vector3.new(x, 8.8, 4.6) - headPos))
		bust.Parent = decor
		local plate = D(interior, "Plaque", V(1.8, 0.4, 0.05), V(x, 6.0, 5.02), BRASS, Mat.Metal)
		text(plate, Enum.NormalId.Front, plaque, rgb(40, 25, 10), Enum.Font.Garamond)
		if watch then
			addWatcher(watchers, bust, 40)
		end
	end
	portrait(-21, { name = "Founder", animal = "rabbit", fur = rgb(230, 230, 230), cloth = rgb(30, 30, 35) }, "eyes", "초대 지배인", false)
	portrait(21, { name = "Madam", animal = "cat", fur = rgb(60, 60, 65), cloth = rgb(90, 20, 40) }, nil, "마담 X", true)

	-- 꽃 장식: 하얀 백합 받침대 (초상화 옆), 프런트 앞 장미 받침대, 엘리베이터 옆 꽃병
	local function pedestal(pos, kind, color, count)
		vcyl(interior, "PedestalBase", 0.3, 1.6, pos + V(0, 0.15, 0), rgb(200, 195, 185), Mat.Marble)
		vcyl(interior, "PedestalColumn", 3, 1.0, pos + V(0, 1.8, 0), rgb(215, 210, 200), Mat.Marble)
		vcyl(interior, "PedestalTop", 0.3, 1.5, pos + V(0, 3.45, 0), rgb(200, 195, 185), Mat.Marble)
		Props.bouquet(interior, pos + V(0, 3.6, 0), kind, color, count, rgb(30, 30, 35))
	end
	pedestal(V(-26.5, FLOOR, 3.2), "lily", nil, 8)
	pedestal(V(-7, FLOOR, 1.8), "rose", rgb(150, 20, 30), 11)
	pedestal(V(20.5, FLOOR, 3.4), "flower", rgb(235, 225, 240), 9)

	-- 11) 촛대 (밤에도 꺼지지 않아요)
	D(interior, "SideTable", V(2, 2.4, 2), V(-27.3, 1.6, -2.3), WOOD_DARK, Mat.Wood)
	vcyl(interior, "Candelabra", 1.2, 0.25, V(-27.3, 3.4, -2.3), BRASS, Mat.Metal)
	D(interior, "CandleArm", V(0.12, 0.12, 1.4), V(-27.3, 4.0, -2.3), BRASS, Mat.Metal)
	for _, dz in ipairs({ -0.7, 0, 0.7 }) do
		vcyl(interior, "Candle", 0.8, 0.2, V(-27.3, 4.45 + (dz == 0 and 0.25 or 0), -2.3 + dz), rgb(240, 235, 220))
		local flame = ball(lights, "Flame", 0.18, V(-27.3, 4.95 + (dz == 0 and 0.25 or 0), -2.3 + dz), rgb(255, 170, 60), Mat.Neon)
		flame:SetAttribute("Zone", "Candle")
		if dz == 0 then
			light(flame, 10, 0.7, rgb(255, 160, 80), "Candle")
		end
	end

	-- 12) 문이 열린 빈 새장과 흩어진 깃털 (창가)
	vcyl(interior, "CageStand", 4, 0.2, V(-12, 2.4, -17.8), BRASS, Mat.Metal)
	vcyl(interior, "CageFloor", 0.15, 2, V(-12, 4.45, -17.8), BRASS, Mat.Metal)
	for i = 0, 11 do
		local a = i * math.pi / 6
		if i ~= 3 then -- 문이 열린 자리
			D(interior, "CageBar", V(0.05, 2.2, 0.05), V(-12 + math.cos(a), 5.6, -17.8 + math.sin(a)), BRASS, Mat.Metal)
		end
	end
	ball(interior, "CageTop", 2.1, V(-12, 6.7, -17.8), BRASS, Mat.Metal).Transparency = 0.6
	D(interior, "CageDoor", V(0.05, 2.0, 0.6), CFrame.new(-11.7, 5.6, -16.6) * CFrame.Angles(0, 0.9, 0), BRASS, Mat.Metal)
	for i = 1, 4 do
		D(interior, "Feather", V(0.15, 0.02, 0.5), CFrame.new(-12 + math.sin(i * 2) * 1.5, 0.43, -16.5 + math.cos(i * 2)) * CFrame.Angles(0, i, 0), rgb(235, 235, 230))
	end

	-- 13) "청소 중" 표지판과 대걸레 양동이 (물이 이상한 색이에요)
	vcyl(interior, "Bucket", 1.2, 1.4, V(12, 1.0, -17.5), rgb(220, 190, 40))
	vcyl(interior, "BucketWater", 0.05, 1.25, V(12, 1.55, -17.5), rgb(80, 10, 10))
	D(interior, "MopStick", V(0.12, 4.5, 0.12), CFrame.new(12.4, 2.8, -17.4) * CFrame.Angles(0, 0, -0.25), rgb(150, 120, 80), Mat.Wood)
	local signBoard = D(interior, "WetFloorSign", V(1.6, 2.4, 0.08), CFrame.new(14.2, 1.6, -16.8) * CFrame.Angles(math.rad(-12), math.rad(20), 0), rgb(230, 200, 40))
	text(signBoard, Enum.NormalId.Front, "청소 중\n밟지 마세요", rgb(30, 30, 30), Enum.Font.GothamBlack)

	------------------------------------------------ 입구를 비추는 CCTV 카메라
	local camPos = V(22, 12.4, -18)
	local cam = D(interior, "CCTVCamera", V(1, 1, 2), CFrame.lookAt(camPos, V(0, 4, 0)), rgb(40, 40, 45))
	D(interior, "CCTVLight", V(0.2, 0.2, 0.2), cam.CFrame * CFrame.new(0.3, 0.4, -1), rgb(255, 0, 0), Mat.Neon)

	------------------------------------------------ 분위기 디테일 (고급스럽고 음산하게)
	-- 격자 천장 (세로 들보를 더해서 우물 모양 천장)
	for x = -24, 24, 8 do
		D(interior, "BeamZ", V(0.6, 0.5, 39), V(x, 13.0, 0), WOOD_DARK, Mat.Wood)
	end

	-- 창문 양옆 와인색 벨벳 커튼과 놋쇠 커튼봉
	for _, x in ipairs({ -17, 17 }) do
		D(interior, "CurtainRod", V(13, 0.15, 0.15), V(x, 12.45, -18.2), BRASS, Mat.Metal)
		for _, side in ipairs({ -1, 1 }) do
			for fold = 0, 2 do
				D(
					interior,
					"Curtain",
					V(0.7, 8.4, 0.35),
					CFrame.new(x + side * (5.7 + fold * 0.45), 8.2, -18.3 + (fold % 2) * 0.12) * CFrame.Angles(0, 0, side * 0.03 * fold),
					rgb(85, 14, 20),
					Mat.Fabric
				)
			end
			D(interior, "CurtainTie", V(1.6, 0.2, 0.5), V(x + side * 6.1, 6.0, -18.2), BRASS, Mat.Metal)
		end
	end

	-- 안락의자 옆 갓 씌운 스탠드 (어둠 속 따뜻한 빛 웅덩이)
	vcyl(interior, "FloorLampBase", 0.2, 1.4, V(-12, 0.5, -15.2), BRASS, Mat.Metal)
	vcyl(interior, "FloorLampPole", 6, 0.15, V(-12, 3.5, -15.2), BRASS, Mat.Metal)
	local shade = vcyl(lights, "LampShade", 1.4, 1.9, V(-12, 6.9, -15.2), rgb(225, 205, 170), Mat.Fabric)
	shade.Transparency = 0.1
	light(shade, 14, 1.2, rgb(255, 200, 140), "Guest")

	-- 카운터 끝 초록 갓 은행원 스탠드
	D(interior, "BankerBase", V(0.8, 0.15, 0.5), V(11.5, 3.68, 5.6), BRASS, Mat.Metal)
	D(interior, "BankerStem", V(0.1, 0.9, 0.1), V(11.5, 4.2, 5.7), BRASS, Mat.Metal)
	local banker = cyl(lights, "BankerShade", 1.4, 0.6, CFrame.new(11.5, 4.75, 5.6), rgb(30, 100, 60), Mat.Glass)
	banker.Transparency = 0.15
	banker:SetAttribute("Zone", "Guest")
	local bankerLight = Instance.new("SpotLight")
	bankerLight.Face = Enum.NormalId.Bottom
	bankerLight.Range = 8
	bankerLight.Angle = 100
	bankerLight.Brightness = 2
	bankerLight.Color = rgb(255, 225, 170)
	bankerLight.Parent = banker

	-- 초상화를 비추는 놋쇠 액자등
	for _, x in ipairs({ -21, 21 }) do
		local bar = D(lights, "PictureLight", V(2.4, 0.25, 0.3), CFrame.new(x, 11.6, 4.7) * CFrame.Angles(math.rad(-25), 0, 0), BRASS, Mat.Metal)
		bar:SetAttribute("Zone", "Guest")
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Range = 9
		spot.Angle = 70
		spot.Brightness = 2.5
		spot.Color = WARM
		spot.Parent = bar
	end

	-- 입구 바닥의 흑백 대리석 체크무늬
	for row = 0, 2 do
		for col = -4, 4 do
			if (row + col) % 2 == 0 then
				D(interior, "CheckerTile", V(2, 0.03, 2), V(col * 2, 0.415, -17.6 + row * 2), rgb(30, 28, 27), Mat.Marble)
			end
		end
	end

	-- 천장 구석의 거미줄
	for _, corner in ipairs({ { 1, -1, -18.85 }, { -1, -1, -18.85 }, { 1, 1, 5.35 }, { -1, 1, 5.35 } }) do
		local sx, sz, wallZ = corner[1], corner[2], corner[3]
		local center = V(sx * 27.9, 11.9, wallZ - sz * 0.9)
		local d = V(-sx, 0, sz).Unit
		D(interior, "Cobweb", V(0.03, 2.4, 2.8), CFrame.lookAt(center, center - d) * CFrame.Angles(0, 0, math.pi), rgb(230, 230, 225), Mat.SmoothPlastic, {
			Transparency = 0.55,
		})
	end

	-- 공기 중에 떠다니는 먼지 (불빛에 반짝여요)
	local dustBox = P(decor, "Dust", V(54, 10, 22), V(0, 6.5, -7), rgb(255, 255, 255), nil, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local dust = Instance.new("ParticleEmitter")
	dust.Shape = Enum.ParticleEmitterShape.Box
	dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	dust.Rate = 10
	dust.Lifetime = NumberRange.new(8, 14)
	dust.Speed = NumberRange.new(0.1, 0.4)
	dust.SpreadAngle = Vector2.new(180, 180)
	dust.Size = NumberSequence.new(0.07)
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.45),
		NumberSequenceKeypoint.new(0.7, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.LightEmission = 0.4
	dust.LightInfluence = 1
	dust.Color = ColorSequence.new(rgb(255, 230, 190))
	dust.RotSpeed = NumberRange.new(-20, 20)
	dust.Parent = dustBox

	hotel:SetAttribute("HasDecor", true)
	LobbyDecor.watchers = watchers
end

---------------------------------------------------------------- 움직이는 소품
function LobbyDecor.animate(hotel)
	local animated = hotel:FindFirstChild("Animated")
	local pendulum = animated and animated:FindFirstChild("Pendulum")
	local rocker = animated and animated:FindFirstChild("RockingChair")
	local pendulumBase = pendulum and pendulum:GetPivot()
	local rockerBase = rocker and rocker:GetPivot()
	local watchers = LobbyDecor.watchers or {}

	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		if pendulum then
			pendulum:PivotTo(pendulumBase * CFrame.Angles(math.sin(t * 2.2) * 0.22, 0, 0))
		end
		if rocker then
			-- 가끔 멈췄다가 다시 흔들려요.
			local strength = math.max(0, math.sin(t * 0.35)) * 0.12
			rocker:PivotTo(rockerBase * CFrame.Angles(math.sin(t * 1.8) * strength, 0, 0))
		end
	end)

	-- 고개가 가장 가까운 플레이어를 천천히 따라 돌아가요.
	task.spawn(function()
		while true do
			task.wait(0.05)
			for _, w in ipairs(watchers) do
				if w.head.Parent then
					local target, best = nil, w.range
					local headPos = w.base.Position
					for _, player in ipairs(Players:GetPlayers()) do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root then
							local distance = (root.Position - headPos).Magnitude
							if distance < best then
								target, best = root.Position, distance
							end
						end
					end
					local goal = 0
					if target then
						local dir = w.base:PointToObjectSpace(target)
						goal = math.clamp(math.atan2(-dir.X, -dir.Z), -1.1, 1.1)
					end
					w.yaw += (goal - w.yaw) * 0.08
					w.head:PivotTo(w.base * CFrame.Angles(0, w.yaw, 0))
				end
			end
		end
	end)

	-- 엘리베이터 옆 벽등이 혼자 깜빡여요.
	local lights = hotel:FindFirstChild("Lights")
	local flicker = lights and lights:FindFirstChild("FlickerSconce")
	local flickerLight = flicker and flicker:FindFirstChildOfClass("PointLight")
	if flicker and flickerLight then
		task.spawn(function()
			while true do
				task.wait(math.random() * 4 + 1)
				for _ = 1, math.random(2, 6) do
					flickerLight.Enabled = false
					flicker.Material = Mat.SmoothPlastic
					task.wait(math.random() * 0.12 + 0.03)
					flickerLight.Enabled = true
					flicker.Material = Mat.Neon
					task.wait(math.random() * 0.15 + 0.03)
				end
			end
		end)
	end

	-- 촛불이 일렁여요.
	if lights then
		task.spawn(function()
			while true do
				task.wait(0.1)
				for _, flame in ipairs(lights:GetChildren()) do
					if flame.Name == "Flame" then
						local l = flame:FindFirstChildOfClass("PointLight")
						if l then
							l.Brightness = 0.5 + math.random() * 0.4
						end
					end
				end
			end
		end)
	end
end

return LobbyDecor
