-- 게임이 시작될 때 땅, 로비(대기실), 호텔 건물을 만들어요.
-- Workspace에 이미 "Hotel" / "Lobby" / "Ground" 가 있으면 새로 만들지 않아요.
-- (나중에 Studio에서 직접 호텔을 꾸미고 싶으면, 같은 이름으로 넣어 두면 돼요.
--  단, Hotel 안의 Markers 폴더, Shutter 파트, Lights 폴더는 이름을 그대로 유지해 주세요.)
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
local function window(parent, cf)
	part(parent, "WindowFrame", V(6.6, 6.6, 0.3), cf * CFrame.new(0, 0, -0.15), rgb(70, 70, 75))
	part(parent, "WindowGlass", V(6, 6, 0.2), cf * CFrame.new(0, 0, -0.3), rgb(150, 200, 230), Enum.Material.Glass, {
		Transparency = 0.2,
		Reflectance = 0.2,
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
	part(ground, "Path", V(12, 0.2, 20), V(0, 0.1, -30), rgb(200, 195, 185), Enum.Material.Slate)
	ground.Parent = workspace
end

local function buildLobby()
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	local c = V(-140, 0, 0)
	local wallColor = rgb(60, 50, 75)

	part(lobby, "Floor", V(44, 0.4, 44), c + V(0, 0.2, 0), rgb(110, 80, 60), Enum.Material.WoodPlanks)
	part(lobby, "Roof", V(44, 1, 44), c + V(0, 12.5, 0), rgb(40, 35, 50))
	part(lobby, "WallN", V(44, 12, 1), c + V(0, 6, -21.5), wallColor)
	part(lobby, "WallS", V(44, 12, 1), c + V(0, 6, 21.5), wallColor)
	part(lobby, "WallW", V(1, 12, 44), c + V(-21.5, 6, 0), wallColor)
	part(lobby, "WallE", V(1, 12, 44), c + V(21.5, 6, 0), wallColor)

	local board = part(lobby, "Sign", V(26, 7, 0.5), c + V(0, 7, -20.7), rgb(25, 20, 30))
	sign(board, Enum.NormalId.Back, "🏨 도플갱어 호텔 로비\n화면의 [혼자 시작] 버튼을 누르세요", rgb(255, 90, 90))

	-- 친구 4명이 설 대기 자리 (나중에 함께하기에서 쓸 거예요)
	local padColors = { rgb(255, 90, 90), rgb(90, 170, 255), rgb(120, 220, 120), rgb(255, 210, 80) }
	for i, x in ipairs({ -12, -4, 4, 12 }) do
		part(lobby, "WaitingPad" .. i, V(5, 0.2, 5), c + V(x, 0.45, 10), padColors[i], Enum.Material.Neon, {
			CanCollide = false,
		})
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = V(8, 0.4, 8)
	spawn.CFrame = CFrame.new(c + V(0, 0.5, 2))
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = rgb(200, 60, 60)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby

	lamp(lobby, c + V(0, 11.8, 0), "Lobby")
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

	part(structure, "GroundFloor", V(W, 0.4, D), V(0, 0.2, 0), rgb(205, 195, 175), Enum.Material.Marble)
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
	part(interior, "Carpet", V(12, 0.06, 22), V(0, 0.43, -9), rgb(150, 30, 40), Enum.Material.Fabric)

	-- 직원 구역과 손님 구역을 나누는 벽
	local partition = rgb(60, 90, 75)
	part(interior, "PartitionL", V(18, FH, 1), V(-21, FH / 2, 6), partition)
	part(interior, "PartitionR", V(18, FH, 1), V(21, FH / 2, 6), partition)
	part(interior, "WallAboveDesk", V(24, FH - 9.2, 1), V(0, 9.2 + (FH - 9.2) / 2, 6), partition)

	-- 프론트 데스크
	part(interior, "Counter", V(24, 4, 2), V(0, 2.4, 6), rgb(110, 70, 45), Enum.Material.WoodPlanks)
	part(interior, "CounterTop", V(24.6, 0.4, 2.8), V(0, 4.6, 5.9), rgb(240, 235, 225), Enum.Material.Marble)
	part(interior, "CounterBarrier", V(24, 4.4, 0.3), V(0, 7, 6.6), rgb(255, 255, 255), nil, {
		Transparency = 1,
	})

	-- 셔터 (평소엔 위에 말려 있다가 닫으면 내려와요)
	part(interior, "ShutterBox", V(24.6, 1.4, 1.2), V(0, 9.9, 4.9), rgb(110, 110, 115), Enum.Material.Metal)
	local shutterOpen = marker(markers, "ShutterOpen", V(0, 9.4, 4.9), V(23.6, 0.4, 0.25))
	marker(markers, "ShutterClosed", V(0, 7, 4.9), V(23.6, 4.4, 0.25))
	part(hotel, "Shutter", shutterOpen.Size, shutterOpen.CFrame, rgb(150, 150, 155), Enum.Material.DiamondPlate, {
		CanCollide = false,
	})

	-- 모니터 두 대 (직원 쪽을 향해요)
	for _, info in ipairs({ { -7, "CCTV", rgb(120, 255, 120) }, { 7, "예약 확인", rgb(150, 200, 255) } }) do
		local x = info[1]
		part(interior, "MonitorStand", V(0.4, 1, 0.4), V(x, 5.3, 6.6), rgb(40, 40, 40))
		local screen = part(interior, "Monitor", V(3.2, 2, 0.25), V(x, 6.8, 6.6), rgb(15, 15, 20))
		sign(screen, Enum.NormalId.Back, info[2], info[3], Enum.Font.Code)
	end
	local bell = part(interior, "Bell", V(0.6, 0.6, 0.6), V(2, 5.1, 5.4), rgb(230, 190, 60), Enum.Material.Metal, {
		Shape = Enum.PartType.Ball,
	})
	bell.CanCollide = false
	part(interior, "GuestBook", V(1.5, 0.1, 1), V(-2, 4.85, 5.6), rgb(245, 240, 230))

	-- 직원 구역 뒤쪽 열쇠 보관함
	part(interior, "KeyRack", V(12, 5, 0.3), V(0, 7, D / 2 - 1.2), rgb(120, 80, 50), Enum.Material.WoodPlanks)
	for row = 0, 2 do
		for col = 0, 5 do
			part(interior, "Key", V(0.3, 0.7, 0.1), V(-4.5 + col * 1.8, 8.3 - row * 1.4, D / 2 - 1.4), rgb(230, 190, 60), Enum.Material.Metal)
		end
	end

	-- 화분과 소파
	for _, x in ipairs({ -26, 26 }) do
		part(interior, "Pot", V(2, 2, 2), CFrame.new(x, 1.4, -16) * CFrame.Angles(0, 0, math.rad(90)), rgb(150, 90, 60), nil, {
			Shape = Enum.PartType.Cylinder,
		})
		part(interior, "Leaves", V(3.5, 3.5, 3.5), V(x, 3.8, -16), rgb(60, 140, 60), Enum.Material.Grass, {
			Shape = Enum.PartType.Ball,
		})
	end
	part(interior, "SofaSeat", V(3, 1.4, 8), V(27, 1.1, -5), rgb(120, 40, 50), Enum.Material.Fabric)
	part(interior, "SofaBack", V(0.8, 3, 8), V(28.6, 2, -5), rgb(110, 35, 45), Enum.Material.Fabric)

	-- 엘리베이터 (예약한 손님이 방으로 올라가는 곳)
	part(interior, "ElevatorFrame", V(0.4, 10, 8.4), V(-29.1, 5.4, -8), rgb(60, 60, 65), Enum.Material.Metal)
	part(interior, "ElevatorDoor", V(0.3, 9, 7), V(-28.9, 4.9, -8), rgb(170, 170, 175), Enum.Material.Metal)
	part(interior, "ElevatorGap", V(0.35, 9, 0.1), V(-28.9, 4.9, -8), rgb(40, 40, 40))
	local panel = part(interior, "ElevatorPanel", V(0.2, 1, 2.4), V(-28.85, 10.9, -8), rgb(20, 20, 20))
	sign(panel, Enum.NormalId.Right, "▲ 1F", rgb(255, 150, 50), Enum.Font.Code)

	-- 입구를 비추는 CCTV 카메라
	local camPos = V(22, 12.4, -17)
	local cam = part(interior, "CCTVCamera", V(1, 1, 2), CFrame.lookAt(camPos, V(0, 4, 0)), rgb(40, 40, 45))
	part(interior, "CCTVLight", V(0.2, 0.2, 0.2), cam.CFrame * CFrame.new(0.3, 0.4, -1), rgb(255, 0, 0), Enum.Material.Neon)

	-- 조명
	for _, pos in ipairs({ V(-15, 13.2, -12), V(0, 13.2, -12), V(15, 13.2, -12), V(-15, 13.2, -2), V(15, 13.2, -2) }) do
		lamp(lights, pos, "Guest")
	end
	lamp(lights, V(-8, 13.2, 13), "Staff")
	lamp(lights, V(8, 13.2, 13), "Staff")

	---------------------------------------------------------------- 위치 표시 (보이지 않아요)
	marker(markers, "DeskSpawn", V(0, 3.5, 13))
	marker(markers, "GuestSpawn", V(0, 0.3, -34))
	marker(markers, "Door", V(0, 0.5, -24))
	marker(markers, "Counter", V(0, 0.5, 2))
	marker(markers, "Elevator", V(-26, 0.5, -8))
	marker(markers, "CorpseArea", V(0, 0.4, -8), V(36, 0.2, 16))

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
	return workspace:FindFirstChild("Hotel") or buildHotel()
end

return HotelBuilder
