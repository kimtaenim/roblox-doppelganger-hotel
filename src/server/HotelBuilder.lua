-- 게임이 시작될 때 땅, 로비(대기실), 호텔 건물을 만들어요.
-- Workspace에 이미 "Hotel" / "Lobby" / "Ground" 가 있으면 새로 만들지 않아요.
-- (나중에 Studio에서 직접 호텔을 꾸미고 싶으면, 같은 이름으로 넣어 두면 돼요.
--  단, Hotel 안의 Markers 폴더, Shutter 파트, Lights 폴더는 이름을 그대로 유지해 주세요.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local LobbyDecor = require(script.Parent:WaitForChild("LobbyDecor"))
local StaffRoom = require(script.Parent:WaitForChild("StaffRoom"))

local HotelBuilder = {}

local rgb = Color3.fromRGB
local V = Vector3.new

local W, D, FLOORS, FH = 60, 40, 4, 14 -- 호텔 가로, 세로, 층 수, 층 높이

local function part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
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

local function marker(parent, name, pos, size)
	return part(parent, name, size or V(2, 0.2, 2), pos, rgb(255, 0, 255), nil, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
end

local function sign(target, face, text, textColor, font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = font or Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = textColor
	label.Parent = gui
	return label
end

local function lamp(parent, pos, zone)
	local p = part(parent, "Lamp", V(3, 0.3, 3), pos, rgb(255, 240, 210), Enum.Material.Neon, { CanCollide = false })
	p:SetAttribute("Zone", zone)
	local light = Instance.new("PointLight")
	light.Range = 28
	light.Brightness = 1.4
	light.Color = rgb(255, 235, 200)
	light.Shadows = true
	light.Parent = p
	return p
end

-- cf 의 -Z 방향이 바깥쪽이에요.
local windowRandom = Random.new(42)
local function window(parent, cf)
	part(parent, "WindowFrame", V(6.6, 6.6, 0.3), cf * CFrame.new(0, 0, -0.15), rgb(40, 32, 28))
	-- 불 켜진 방(따뜻한 빛), 아주 가끔 빨간 방, 나머지는 캄캄한 방
	local roll = windowRandom:NextNumber()
	local color, material, transparency = rgb(35, 40, 55), Enum.Material.Glass, 0.1
	if roll < 0.06 then
		color, material, transparency = rgb(150, 20, 20), Enum.Material.Neon, 0.5
	elseif roll < 0.45 then
		color, material, transparency = rgb(255, 185, 110), Enum.Material.Neon, 0.55
	end
	part(parent, "WindowGlass", V(6, 6, 0.2), cf * CFrame.new(0, 0, -0.3), color, material, {
		Transparency = transparency,
		Reflectance = material == Enum.Material.Glass and 0.3 or 0,
	})
end

local function balcony(parent, cf)
	local railColor = rgb(245, 245, 245)
	part(parent, "BalconyFloor", V(8, 0.6, 3), cf * CFrame.new(0, -4, -1.5), rgb(190, 190, 190), Enum.Material.Concrete)
	part(parent, "BalconyRail", V(8, 1.8, 0.3), cf * CFrame.new(0, -2.8, -2.9), railColor)
	part(parent, "BalconyRail", V(0.3, 1.8, 3), cf * CFrame.new(-3.85, -2.8, -1.5), railColor)
	part(parent, "BalconyRail", V(0.3, 1.8, 3), cf * CFrame.new(3.85, -2.8, -1.5), railColor)
end

local function buildGround()
	local ground = Instance.new("Model")
	ground.Name = "Ground"
	part(ground, "Grass", V(800, 1, 800), V(0, -0.5, 0), rgb(90, 150, 70), Enum.Material.Grass)
	part(ground, "Road", V(800, 0.1, 24), V(0, 0.05, -62), rgb(45, 45, 50), Enum.Material.Asphalt)
	part(ground, "Sidewalk", V(800, 0.2, 10), V(0, 0.1, -45), rgb(185, 185, 180), Enum.Material.Concrete)
	part(ground, "Path", V(12, 0.2, 20), V(0, 0.1, -30), rgb(60, 55, 52), Enum.Material.Slate)

	-- 입구까지 이어지는 빨간 카펫과 놋쇠 기둥, 벨벳 줄
	part(ground, "EntranceCarpet", V(5, 0.06, 20), V(0, 0.23, -30), rgb(110, 20, 25), Enum.Material.Fabric)
	for _, x in ipairs({ -3.4, 3.4 }) do
		local previous
		for z = -38, -22, 4 do
			local post = part(ground, "Stanchion", V(3, 0.25, 0.25), CFrame.new(x, 1.7, z) * CFrame.Angles(0, 0, math.rad(90)), rgb(196, 156, 84), Enum.Material.Metal, {
				Shape = Enum.PartType.Cylinder,
				CanCollide = false,
			})
			part(ground, "StanchionTop", V(0.5, 0.5, 0.5), V(x, 3.3, z), rgb(196, 156, 84), Enum.Material.Metal, {
				Shape = Enum.PartType.Ball,
				CanCollide = false,
			})
			if previous then
				part(ground, "VelvetRope", V(0.18, 0.18, 4), V(x, 2.6, z - 2), rgb(120, 15, 25), Enum.Material.Fabric, {
					CanCollide = false,
				})
			end
			previous = post
		end
	end

	-- 가로등
	for _, x in ipairs({ -45, -22, 22, 45 }) do
		part(ground, "LampPost", V(0.4, 10, 0.4), V(x, 5, -40.6), rgb(20, 20, 22), Enum.Material.Metal)
		part(ground, "LampArm", V(0.2, 0.2, 1.6), V(x, 10, -40), rgb(20, 20, 22), Enum.Material.Metal)
		local bulb = part(ground, "LampGlow", V(0.7, 1, 0.7), V(x, 9.4, -39.4), rgb(255, 200, 130), Enum.Material.Neon, {
			CanCollide = false,
		})
		local glow = Instance.new("PointLight")
		glow.Range = 26
		glow.Brightness = 1.1
		glow.Color = rgb(255, 190, 120)
		glow.Shadows = true
		glow.Parent = bulb
	end
	ground.Parent = workspace
end

-- 로비: 호텔 길 건너편 바깥 광장이에요. 여기서 시작하고, 노란 네모 안으로 들어가면 출근할 수 있어요.
local function buildLobby()
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	local c = V(0, 0, -95) -- 광장 가운데 (호텔 정문은 z -20 쪽)
	local stone = rgb(88, 84, 80)
	local iron = rgb(25, 25, 28)

	-- 돌바닥 광장과 테두리
	part(lobby, "PlazaFloor", V(70, 0.3, 40), c + V(0, 0.15, 0), stone, Enum.Material.Cobblestone)
	part(lobby, "PlazaCurb", V(70, 0.4, 1), c + V(0, 0.2, 20), rgb(120, 115, 110), Enum.Material.Concrete)

	-- 낮은 철제 울타리 (뒤쪽과 양옆)
	local function fence(from, to)
		local length = (to - from).Magnitude
		local dir = (to - from).Unit
		local count = math.floor(length / 2.5)
		for i = 0, count do
			local p = from + dir * (i * length / count)
			part(lobby, "FencePost", V(0.25, 3, 0.25), p + V(0, 1.5, 0), iron, Enum.Material.Metal)
			part(lobby, "FenceTip", V(0.35, 0.35, 0.35), p + V(0, 3.15, 0), iron, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		end
		local mid = (from + to) / 2
		part(lobby, "FenceRail", V(0.15, 0.15, length), CFrame.lookAt(mid + V(0, 2.6, 0), to + V(0, 2.6, 0)), iron, Enum.Material.Metal)
		part(lobby, "FenceRail", V(0.15, 0.15, length), CFrame.lookAt(mid + V(0, 0.8, 0), to + V(0, 0.8, 0)), iron, Enum.Material.Metal)
	end
	fence(c + V(-35, 0, -20), c + V(35, 0, -20))
	fence(c + V(-35, 0, -20), c + V(-35, 0, 19))
	fence(c + V(35, 0, -20), c + V(35, 0, 19))

	-- 나무: 앙상하게 마른 나무와 짙은 잎 나무
	local function deadTree(pos)
		part(lobby, "TreeTrunk", V(1, 8, 1), pos + V(0, 4, 0), rgb(45, 35, 30), Enum.Material.Wood)
		for i = 1, 6 do
			local branch = CFrame.new(pos + V(0, 4 + i * 0.6, 0)) * CFrame.Angles(0, i * 1.1, math.rad(40 + (i % 3) * 10))
			part(lobby, "Branch", V(0.3, 3.5 - i * 0.2, 0.3), branch * CFrame.new(0, 1.6, 0), rgb(45, 35, 30), Enum.Material.Wood)
		end
	end
	local function leafyTree(pos)
		part(lobby, "TreeTrunk", V(1, 6, 1), pos + V(0, 3, 0), rgb(55, 40, 30), Enum.Material.Wood)
		for i, offset in ipairs({ V(0, 7, 0), V(1.4, 6, 0.6), V(-1.2, 6.3, -0.8), V(0.3, 8.2, 0.4) }) do
			part(lobby, "Foliage", V(4.5 - i * 0.4, 4.5 - i * 0.4, 4.5 - i * 0.4), pos + offset, rgb(30, 50, 35), Enum.Material.Grass, {
				Shape = Enum.PartType.Ball,
			})
		end
	end
	deadTree(c + V(-30, 0, -15))
	deadTree(c + V(29, 0, 8))
	deadTree(c + V(-17, 0, -17))
	leafyTree(c + V(30, 0, -15))
	leafyTree(c + V(-30, 0, 9))
	leafyTree(c + V(17, 0, -17))

	-- 벤치
	local function bench(pos, yaw)
		local base = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
		for i = 0, 2 do
			part(lobby, "BenchSlat", V(5, 0.2, 0.4), base * CFrame.new(0, 1.6, -0.5 + i * 0.5), rgb(90, 60, 40), Enum.Material.Wood)
		end
		for i = 0, 1 do
			part(lobby, "BenchBack", V(5, 0.3, 0.15), base * CFrame.new(0, 2.3 + i * 0.5, 0.75), rgb(90, 60, 40), Enum.Material.Wood)
		end
		for _, x in ipairs({ -2.2, 2.2 }) do
			part(lobby, "BenchLeg", V(0.2, 1.5, 1.6), base * CFrame.new(x, 0.9, 0.1), iron, Enum.Material.Metal)
		end
	end
	bench(c + V(-14, 0.3, -5), math.pi)
	bench(c + V(14, 0.3, -5), math.pi)
	bench(c + V(-24, 0.3, 4), math.rad(-90))
	bench(c + V(24, 0.3, 4), math.rad(90))

	-- 마른 분수와 이끼 낀 토끼 석상 (눈이 검게 뚫려 있어요)
	local fountain = c + V(0, 0.3, -11)
	part(lobby, "FountainBasin", V(1.2, 9, 9), CFrame.new(fountain + V(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(110, 108, 100), Enum.Material.Slate, {
		Shape = Enum.PartType.Cylinder,
	})
	part(lobby, "FountainWater", V(0.1, 8, 8), CFrame.new(fountain + V(0, 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(30, 45, 40), Enum.Material.Glass, {
		Shape = Enum.PartType.Cylinder,
		Transparency = 0.2,
		Reflectance = 0.3,
		CanCollide = false,
	})
	part(lobby, "FountainPillar", V(1.5, 3, 1.5), fountain + V(0, 2, 0), rgb(110, 108, 100), Enum.Material.Slate)
	local statue = Animals.build({ id = 13, name = "Statue", animal = "rabbit", fur = rgb(150, 150, 145), cloth = rgb(120, 120, 115) }, "eyes")
	for _, p in ipairs(statue:GetDescendants()) do
		if p:IsA("BasePart") then
			if p.Name ~= "Void" and p.Name ~= "BlackTear" and p.Name ~= "RedGlint" then
				p.Color = rgb(125, 128, 118)
				p.Material = Enum.Material.Slate
			end
			p.CanCollide = false
		end
	end
	pcall(function()
		statue:ScaleTo(0.8)
	end)
	statue:PivotTo(CFrame.new(fountain + V(0, 3.5, 0)))
	statue.Parent = lobby

	-- 가로등
	for _, offset in ipairs({ V(-12, 0, 15), V(12, 0, 15), V(-12, 0, -15), V(12, 0, -15) }) do
		local base = c + offset
		part(lobby, "LampPost", V(0.4, 9, 0.4), base + V(0, 4.8, 0), iron, Enum.Material.Metal)
		part(lobby, "LampTop", V(1.2, 0.3, 1.2), base + V(0, 9.4, 0), iron, Enum.Material.Metal)
		local glow = part(lobby, "LampGlow", V(0.8, 1.1, 0.8), base + V(0, 8.7, 0), rgb(255, 200, 130), Enum.Material.Neon, { CanCollide = false })
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.1
		light.Color = rgb(255, 190, 120)
		light.Shadows = true
		light.Parent = glow
	end

	-- 노란 선 네모: 출근 대기 구역
	local zoneCenter = c + V(0, 0, 10)
	local zoneSize = 12
	for _, strip in ipairs({
		{ V(zoneSize + 0.4, 0.08, 0.4), V(0, 0, -zoneSize / 2) },
		{ V(zoneSize + 0.4, 0.08, 0.4), V(0, 0, zoneSize / 2) },
		{ V(0.4, 0.08, zoneSize + 0.4), V(-zoneSize / 2, 0, 0) },
		{ V(0.4, 0.08, zoneSize + 0.4), V(zoneSize / 2, 0, 0) },
	}) do
		part(lobby, "ZoneLine", strip[1], zoneCenter + strip[2] + V(0, 0.34, 0), rgb(255, 210, 40), Enum.Material.Neon, { CanCollide = false })
	end
	local zoneText = part(lobby, "ZoneText", V(8, 0.05, 2.5), zoneCenter + V(0, 0.33, 0), rgb(255, 210, 40), nil, {
		Transparency = 1,
		CanCollide = false,
	})
	local zoneGui = Instance.new("SurfaceGui")
	zoneGui.Face = Enum.NormalId.Top
	zoneGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	zoneGui.PixelsPerStud = 40
	zoneGui.Parent = zoneText
	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Size = UDim2.fromScale(1, 1)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.TextScaled = true
	zoneLabel.Font = Enum.Font.GothamBlack
	zoneLabel.Text = "출근 대기"
	zoneLabel.TextColor3 = rgb(255, 210, 40)
	zoneLabel.TextTransparency = 0.2
	zoneLabel.Rotation = 180
	zoneLabel.Parent = zoneGui
	part(lobby, "StartZone", V(zoneSize, 8, zoneSize), zoneCenter + V(0, 4, 0), rgb(255, 210, 40), nil, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})

	-- 안내판
	for _, x in ipairs({ 7.6, 11.4 }) do
		part(lobby, "SignLeg", V(0.3, 3, 0.3), c + V(x, 1.8, 4), iron, Enum.Material.Metal)
	end
	local board = part(lobby, "Sign", V(5, 2.6, 0.3), c + V(9.5, 4.2, 4), rgb(25, 20, 18))
	sign(board, Enum.NormalId.Front, "도플갱어 호텔 직원 출입\n노란 네모 안으로 들어가세요", rgb(255, 210, 120))

	-- 처음 나타나는 곳 (호텔을 바라봐요)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = V(8, 0.4, 8)
	spawn.CFrame = CFrame.new(c + V(0, 0.35, -4)) * CFrame.Angles(0, math.pi, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = rgb(70, 20, 25)
	spawn.Material = Enum.Material.Slate
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby

	lobby.Parent = workspace
end

local function buildHotel()
	local hotel = Instance.new("Model")
	hotel.Name = "Hotel"
	local structure = Instance.new("Folder")
	structure.Name = "Structure"
	structure.Parent = hotel
	local interior = Instance.new("Folder")
	interior.Name = "Interior"
	interior.Parent = hotel
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = hotel
	local markers = Instance.new("Folder")
	markers.Name = "Markers"
	markers.Parent = hotel

	---------------------------------------------------------------- 건물 (아파트 모양)
	local wallColor0 = rgb(235, 225, 205)
	local wallColor = rgb(215, 200, 180)
	local fz = -D / 2 + 0.5 -- 앞벽 위치

	part(structure, "GroundFloor", V(W, 0.4, D), V(0, 0.2, 0), rgb(215, 210, 200), Enum.Material.Marble)
	for f = 1, FLOORS do
		part(structure, "Slab" .. f, V(W + 1, 1, D + 1), V(0, f * FH, 0), rgb(200, 200, 200), Enum.Material.Concrete)
	end

	for f = 0, FLOORS - 1 do
		local y0 = f * FH
		local cy = y0 + FH / 2
		local color = f == 0 and wallColor0 or wallColor
		local material = f == 0 and Enum.Material.SmoothPlastic or Enum.Material.Concrete

		part(structure, "BackWall", V(W, FH, 1), V(0, cy, D / 2 - 0.5), color, material)
		part(structure, "LeftWall", V(1, FH, D), V(-W / 2 + 0.5, cy, 0), color, material)
		part(structure, "RightWall", V(1, FH, D), V(W / 2 - 0.5, cy, 0), color, material)

		if f == 0 then
			local doorW, doorH = 10, 10
			local sideW = (W - doorW) / 2
			part(structure, "FrontWallL", V(sideW, FH, 1), V(-(doorW / 2 + sideW / 2), cy, fz), color, material)
			part(structure, "FrontWallR", V(sideW, FH, 1), V(doorW / 2 + sideW / 2, cy, fz), color, material)
			part(structure, "FrontWallTop", V(doorW, FH - doorH, 1), V(0, doorH + (FH - doorH) / 2, fz), color, material)
			for _, x in ipairs({ -20, -12, 12, 20 }) do
				window(structure, CFrame.new(x, 6, -D / 2))
			end
		else
			part(structure, "FrontWall", V(W, FH, 1), V(0, cy, fz), color, material)
			for i, x in ipairs({ -24, -12, 0, 12, 24 }) do
				local cf = CFrame.new(x, y0 + 7.5, -D / 2)
				window(structure, cf)
				if i % 2 == 1 then
					balcony(structure, cf)
				end
			end
			for _, z in ipairs({ -10, 10 }) do
				window(structure, CFrame.new(-W / 2, y0 + 7.5, z) * CFrame.Angles(0, math.rad(90), 0))
				window(structure, CFrame.new(W / 2, y0 + 7.5, z) * CFrame.Angles(0, math.rad(-90), 0))
			end
		end
	end

	-- 옥상 난간, 물탱크, 간판
	local roofY = FLOORS * FH + 0.5
	local parapet = rgb(180, 170, 155)
	part(structure, "Parapet", V(W + 1, 1.6, 1), V(0, roofY + 0.8, -D / 2), parapet)
	part(structure, "Parapet", V(W + 1, 1.6, 1), V(0, roofY + 0.8, D / 2), parapet)
	part(structure, "Parapet", V(1, 1.6, D + 1), V(-W / 2, roofY + 0.8, 0), parapet)
	part(structure, "Parapet", V(1, 1.6, D + 1), V(W / 2, roofY + 0.8, 0), parapet)
	part(structure, "WaterTank", V(6, 7, 7), CFrame.new(18, roofY + 3.5, 10) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 130, 170), Enum.Material.Metal, {
		Shape = Enum.PartType.Cylinder,
	})
	local roofSign = part(structure, "RoofSign", V(40, 6, 0.8), V(0, roofY + 5, -D / 2 + 2), rgb(30, 20, 25))
	sign(roofSign, Enum.NormalId.Front, "DOPPELGANGER HOTEL", rgb(255, 60, 60))
	part(structure, "RoofSignLeg", V(0.6, 3, 0.6), V(-15, roofY + 1.5, -D / 2 + 2), rgb(60, 60, 60))
	part(structure, "RoofSignLeg", V(0.6, 3, 0.6), V(15, roofY + 1.5, -D / 2 + 2), rgb(60, 60, 60))

	-- 입구 간판과 차양
	local doorSign = part(structure, "DoorSign", V(14, 2.5, 0.4), V(0, 12, -D / 2 - 0.2), rgb(40, 25, 30))
	sign(doorSign, Enum.NormalId.Front, "도플갱어 호텔", rgb(255, 220, 160))
	part(structure, "Canopy", V(16, 0.5, 6), V(0, 10.25, -D / 2 - 3), rgb(140, 30, 40))
	part(structure, "CanopyPost", V(0.6, 10, 0.6), V(-7.5, 5, -D / 2 - 5.7), rgb(60, 60, 60))
	part(structure, "CanopyPost", V(0.6, 10, 0.6), V(7.5, 5, -D / 2 - 5.7), rgb(60, 60, 60))
	lamp(lights, V(0, 9.8, -D / 2 - 3), "Outside")

	---------------------------------------------------------------- 1층 로비와 프론트
	-- 직원 구역과 손님 구역을 나누는 벽 (꾸밈은 LobbyDecor 에서 해요)
	part(interior, "PartitionL", V(18, FH, 1), V(-21, FH / 2, 6), rgb(52, 32, 22))
	-- 오른쪽 벽에는 직원용 출입구(x 24~28)가 뚫려 있어서 프런트 밖으로 나갈 수 있어요.
	part(interior, "PartitionR", V(12, FH, 1), V(18, FH / 2, 6), rgb(52, 32, 22))
	part(interior, "PartitionR2", V(2, FH, 1), V(29, FH / 2, 6), rgb(52, 32, 22))
	part(interior, "StaffDoorTop", V(4, FH - 9.4, 1), V(26, 9.4 + (FH - 9.4) / 2, 6), rgb(52, 32, 22))
	LobbyDecor.build(hotel, interior, lights, markers)
	StaffRoom.build(hotel)

	---------------------------------------------------------------- 위치 표시 (보이지 않아요)
	marker(markers, "DeskSpawn", V(0, 3.5, 13))
	marker(markers, "GuestSpawn", V(0, 0.3, -34))
	marker(markers, "Door", V(0, 0.5, -24))
	marker(markers, "Counter", V(0, 0.5, 2))
	marker(markers, "Elevator", V(26, 0.5, -2))
	marker(markers, "CorpseArea", V(6, 0.4, -7), V(16, 0.2, 12))

	hotel.Parent = workspace
	return hotel
end

function HotelBuilder.ensure()
	if not workspace:FindFirstChild("Ground") then
		buildGround()
	end
	if not workspace:FindFirstChild("Lobby") then
		buildLobby()
	end
	local hotel = workspace:FindFirstChild("Hotel") or buildHotel()
	LobbyDecor.animate(hotel)
	return hotel
end

return HotelBuilder
