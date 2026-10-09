-- 2층~4층 객실 복도를 만들어요. (밤 순찰과 룸서비스 배달을 하는 곳)
-- 1층 로비처럼 꾸몄어요: 청록 줄무늬 벽지, 원목 벽판, 대리석 바닥, 빨간 러너 카펫.
-- 층마다 긴 복도 양쪽에 객실 문이 6개씩 (01~12호), 문 사이마다 오래된 초상화가 걸려 있어요.
-- 복도 동쪽 끝은 작은 층 로비(소파, 화분, 샹들리에)이고, 엘리베이터로 층 사이를 오가요.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Animals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local Props = require(script.Parent:WaitForChild("Props"))

local Floors = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local Mat = Enum.Material
local P = Props.part
local C = Props.Colors

local FH = 14 -- 층 높이 (HotelBuilder 와 같아요)
local FLOOR_LIST = { 2, 3, 4 }
local DOOR_XS = { -22, -14, -6, 2, 10, 18 }
local PORTRAIT_XS = { -26.3, -18, -10, -2, 6, 14 } -- 문과 문 사이
local HALF = 3.5 -- 복도 폭의 절반
local LOUNGE_X = 21 -- 여기서부터 동쪽은 층 로비
local LOUNGE_HALF = 7
local WALL_H = 12.5
local DOOR_W, DOOR_H = 3.6, 8

-- 1층 로비와 같은 색
local WOOD = C.WOOD
local WOOD_DARK = C.WOOD_DARK
local BRASS = C.BRASS
local TEAL = rgb(36, 72, 76)
local PINSTRIPE = rgb(140, 115, 70)
local CREAM = rgb(225, 215, 195)
local MARBLE = rgb(215, 210, 200)
local RUNNER = rgb(110, 20, 25)
local CHARCOAL = rgb(62, 58, 55)
local MUSTARD = rgb(190, 145, 40)
local DOOR = rgb(70, 42, 28)
local WARM = rgb(255, 214, 160)
local GOLD = rgb(170, 128, 55)

Floors.List = FLOOR_LIST

local function floorY(floor)
	return (floor - 1) * FH + 0.5
end
Floors.floorY = floorY

local function prompt(parent, action, object, key, distance)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object or ""
	p.KeyboardKeyCode = key or Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = distance or 6
	p.RequiresLineOfSight = false
	p.Enabled = false
	p.Parent = parent
	return p
end

local function glow(part, range, brightness)
	part:SetAttribute("Zone", "Corridor")
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = brightness
	light.Color = WARM
	light.Shadows = true
	light.Parent = part
end

-- 1층 로비와 같은 벽 꾸밈. cf 는 벽 앞면 가운데 바닥이고, cf 의 -Z 가 복도 쪽이에요.
local function dressWall(parent, cf, length, height)
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	P(parent, "Wainscot", V(length, 4.4, 0.3), at(0, 2.2, -0.15), WOOD, Mat.Wood)
	local grooves = math.floor(length / 2.5)
	for i = 1, grooves do
		local x = -length / 2 + i * (length / (grooves + 1))
		P(parent, "Groove", V(0.12, 3.8, 0.05), at(x, 2.3, -0.32), WOOD_DARK, Mat.Wood)
	end
	P(parent, "Baseboard", V(length, 0.5, 0.4), at(0, 0.25, -0.2), WOOD_DARK, Mat.Wood)
	P(parent, "ChairRail", V(length, 0.35, 0.45), at(0, 4.5, -0.22), WOOD_DARK, Mat.Wood)
	P(parent, "BrassLine", V(length, 0.06, 0.47), at(0, 4.7, -0.23), BRASS, Mat.Metal)
	local paperH = height - 4.7 - 0.5
	P(parent, "Wallpaper", V(length, paperH, 0.15), at(0, 4.7 + paperH / 2, -0.075), TEAL, Mat.Fabric)
	local stripes = math.floor(length / 1.6)
	for i = 1, stripes do
		local x = -length / 2 + i * (length / (stripes + 1))
		P(parent, "Pinstripe", V(0.08, paperH, 0.04), at(x, 4.7 + paperH / 2, -0.17), PINSTRIPE)
	end
	P(parent, "Crown", V(length, 0.7, 0.5), at(0, height - 0.35, -0.25), WOOD_DARK, Mat.Wood)
end

-- 벽 한 조각 (부딪히는 벽 + 로비 꾸밈). from→to 는 x 범위, z 는 벽 앞면, side 는 방 쪽(-1/1)
local function wallSegment(parent, y, x0, x1, z, side)
	if x1 - x0 < 0.05 then
		return
	end
	local mid = (x0 + x1) / 2
	Props.solid(parent, "CorridorWall", V(x1 - x0, WALL_H, 0.5), V(mid, y + WALL_H / 2, z + side * 0.25), TEAL, Mat.Fabric)
	local face = CFrame.lookAt(V(mid, y, z), V(mid, y, z - side))
	dressWall(parent, face, x1 - x0, WALL_H)
end

-- 복도 벽 한 줄: 문 자리만 비워 두고 이어 붙여요.
local function corridorWall(parent, y, side)
	local z = side * HALF
	local cursor = -28.9
	for _, x in ipairs(DOOR_XS) do
		wallSegment(parent, y, cursor, x - DOOR_W / 2, z, side)
		-- 문 위쪽 벽
		Props.solid(parent, "Lintel", V(DOOR_W, WALL_H - DOOR_H, 0.5), V(x, y + DOOR_H + (WALL_H - DOOR_H) / 2, z + side * 0.25), TEAL, Mat.Fabric)
		P(parent, "Wallpaper", V(DOOR_W, WALL_H - DOOR_H - 0.5, 0.15), V(x, y + DOOR_H + (WALL_H - DOOR_H - 0.5) / 2, z - side * 0.075), TEAL, Mat.Fabric)
		P(parent, "Crown", V(DOOR_W, 0.7, 0.5), V(x, y + WALL_H - 0.35, z - side * 0.25), WOOD_DARK, Mat.Wood)
		-- 문틀
		P(parent, "DoorFrame", V(DOOR_W + 0.6, 0.45, 0.35), V(x, y + DOOR_H + 0.2, z - side * 0.15), WOOD_DARK, Mat.Wood)
		for _, dx in ipairs({ -1, 1 }) do
			P(parent, "DoorFrame", V(0.3, DOOR_H, 0.35), V(x + dx * (DOOR_W / 2 + 0.12), y + DOOR_H / 2, z - side * 0.15), WOOD_DARK, Mat.Wood)
		end
		cursor = x + DOOR_W / 2
	end
	wallSegment(parent, y, cursor, LOUNGE_X, z, side)
end

-- 객실 하나: 문(경첩으로 열리는), 방 번호판, 문 밑 불빛, 문 앞 확인 지점
local function buildRoom(parent, floor, index, side, x)
	local y = floorY(floor)
	local number = floor * 100 + (side == -1 and index * 2 - 1 or index * 2)
	local wallZ = side * (HALF + 0.25)
	local room = Instance.new("Model")
	room.Name = "Room" .. number
	room.Parent = parent

	-- 문: 경첩(왼쪽 모서리) 기준으로 돌아가요. 문 앞면(복도 쪽)은 -side 방향이에요.
	local facing = V(0, 0, -side)
	local hingePos = V(x - DOOR_W / 2, y + DOOR_H / 2, wallZ)
	local hinge = CFrame.lookAt(hingePos, hingePos + facing)
	local toCenter = hinge:PointToObjectSpace(V(x, y + DOOR_H / 2, wallZ)).X
	local door = Instance.new("Model")
	door.Name = "Door"
	door.Parent = room
	local slab = Props.solid(door, "DoorSlab", V(DOOR_W - 0.1, DOOR_H - 0.1, 0.3), hinge * CFrame.new(toCenter, 0, 0), DOOR, Mat.Wood)
	door.PrimaryPart = slab
	local front = hinge * CFrame.new(toCenter, 0, -0.17) -- 문 앞면 (복도 쪽)
	for _, dy in ipairs({ 1.8, -1.6 }) do
		P(door, "DoorPanel", V(DOOR_W - 1.1, 2.6, 0.06), front * CFrame.new(0, dy, 0), rgb(85, 52, 34), Mat.Wood)
	end
	local knobSide = math.sign(toCenter)
	Props.ball(door, "DoorKnob", 0.32, (front * CFrame.new(knobSide * 1.3, -0.3, -0.12)).Position, BRASS, Mat.Metal)
	local plate = P(door, "NumberPlate", V(1.2, 0.5, 0.06), front * CFrame.new(0, 3.1, -0.04), BRASS, Mat.Metal)
	local plateLabel = Props.text(plate, Enum.NormalId.Front, tostring(number), rgb(40, 25, 15), Enum.Font.Garamond)
	-- 문 밑 틈으로 새어 나오는 불빛 (손님이 있으면 따뜻하게, 없으면 캄캄하게)
	local strip = P(room, "UnderDoorLight", V(DOOR_W - 0.4, 0.06, 0.5), V(x, y + 0.05, wallZ - side * 0.4), rgb(20, 16, 14), Mat.SmoothPlastic)
	-- 문 앞 확인 지점 (보이지 않아요, 여기에 확인/보고/노크 버튼이 떠요)
	local spot = P(room, "DoorSpot", V(1, 1, 1), V(x, y + 3, wallZ - side * 1.4), rgb(255, 0, 255), nil, {
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
	})
	local extras = Instance.new("Folder")
	extras.Name = "Extras"
	extras.Parent = room

	return {
		number = number,
		floor = floor,
		x = x,
		side = side,
		model = room,
		door = door,
		hinge = hinge,
		closedPivot = door:GetPivot(),
		swing = -math.sign(toCenter), -- 이 방향으로 돌리면 문이 방 안쪽으로 열려요
		strip = strip,
		spot = spot,
		plateLabel = plateLabel,
		extras = extras,
		-- 방 안쪽 깊숙한 곳, 문이 열리는 쪽 반대편(문틈이 보이는 쪽) (방 안을 바라봐요)
		-- 문이 열려도, 뒤돌아서도 문과 겹치지 않을 만큼 떨어져 있어요.
		insideCF = CFrame.lookAt(V(x + 0.6, y, wallZ + side * 4.8), V(x + 0.6, y, wallZ + side * 10)),
		okPrompt = prompt(spot, "이상 없음", number .. "호", Enum.KeyCode.E),
		reportPrompt = prompt(spot, "이상 보고", number .. "호", Enum.KeyCode.R),
		knockPrompt = prompt(spot, "노크하기", number .. "호 룸서비스", Enum.KeyCode.F),
	}
end

---------------------------------------------------------------- 초상화
-- 어두운 배경에 동물 손님의 상반신. 밤에 몰래 뒤집히거나, 얼굴이 이상해지거나, 사라지거나...
local PORTRAIT_BG = { rgb(30, 40, 34), rgb(48, 26, 26), rgb(28, 30, 44), rgb(44, 38, 26) }
local PORTRAIT_CLOTH = { rgb(40, 30, 30), rgb(30, 35, 50), rgb(55, 25, 30), rgb(35, 45, 38), rgb(60, 50, 40) }
local DOPPEL_FACES = { "teeth", "mouth", "eyes" }
-- 눈에 확 띄는 것(뒤집힘, 피)부터 자세히 봐야 아는 것(옆을 봄, 다른 동물, 가까워짐)까지
Floors.PortraitKinds = { "flip", "doppel", "away", "gone", "blood", "tilt", "swap", "closer", "side", "red", "twins" }

local portraitRandom = Random.new(2024)

local function drawPortrait(p, kind)
	local model = p.model
	model:ClearAllChildren()
	local cf = p.cf -- 캔버스 가운데, -Z 가 복도 쪽
	P(model, "PortraitFrame", V(3, 3.7, 0.25), cf * CFrame.new(0, 0, 0.05), GOLD, Mat.Metal)
	P(model, "PortraitBevel", V(2.7, 3.4, 0.3), cf, rgb(120, 88, 38), Mat.Metal)
	for _, corner in ipairs({ V(-1.4, 1.75, 0), V(1.4, 1.75, 0), V(-1.4, -1.75, 0), V(1.4, -1.75, 0) }) do
		-- 납작한 모서리 장식 (액자 밖으로 튀어나오지 않아요)
		P(model, "FrameKnot", V(0.4, 0.4, 0.06), cf * CFrame.new(corner + V(0, 0, -0.15)) * CFrame.Angles(0, 0, math.rad(45)), GOLD, Mat.Metal)
	end
	local canvas = P(model, "Canvas", V(2.4, 3.1, 0.3), cf * CFrame.new(0, 0, -0.02), p.bg, Mat.Fabric)
	local plaque = P(model, "Plaque", V(1.2, 0.3, 0.05), cf * CFrame.new(0, -2.15, -0.05), BRASS, Mat.Metal)
	Props.text(plaque, Enum.NormalId.Front, p.title, rgb(40, 25, 15), Enum.Font.Garamond)

	-- 캔버스 위의 그림: 액자 안에 납작한 그림으로 그려져요. (SurfaceGui + ViewportFrame)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 1 -- 어두운 복도에서는 그림도 어둡게
	gui.Parent = canvas
	local view = Instance.new("ViewportFrame")
	view.Size = UDim2.fromScale(1, 1)
	view.BackgroundColor3 = p.bg
	view.BorderSizePixel = 0
	view.Ambient = rgb(120, 105, 95)
	view.LightColor = rgb(255, 220, 180)
	view.LightDirection = Vector3.new(-0.6, -0.5, 1)
	view.ImageColor3 = kind == "red" and rgb(255, 110, 100) or rgb(235, 220, 195) -- 오래된 유화처럼 누렇게 (이상하면 붉게)
	view.Parent = gui
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local distance = kind == "closer" and 7 or (kind == "twins" and 18 or 13) -- "closer": 그림 속 얼굴이 성큼 다가와 있어요
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 5.7, -distance), Vector3.new(0, 5.5, 0))
	camera.Parent = view
	view.CurrentCamera = camera
	if kind ~= "gone" then
		local data = kind == "swap" and p.swapData or p.data -- "swap": 같은 옷을 입은 다른 동물
		local subject = Animals.build(data, kind == "doppel" and p.doppelFace or nil)
		if kind == "away" then
			subject:PivotTo(CFrame.Angles(0, math.pi, 0)) -- 뒤돌아섬
		elseif kind == "side" then
			subject:PivotTo(CFrame.Angles(0, math.rad(55) * p.tiltSide, 0)) -- 고개를 돌려 옆을 봄
		elseif kind == "twins" then
			subject:PivotTo(CFrame.new(-1.7, 0, 0)) -- 그림 속에 똑같은 사람이 둘
			local twin = Animals.build(data, nil)
			twin:PivotTo(CFrame.new(1.7, 0, 0))
			twin.Parent = view
		end
		subject.Parent = view
	end
	-- 가장자리가 어두운 유화 느낌
	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = rgb(0, 0, 0)
	shade.BorderSizePixel = 0
	shade.ZIndex = 2
	shade.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.35),
	})
	gradient.Parent = shade

	if kind == "blood" then
		-- 액자 위에서 피가 흘러내려 벽까지 번져요.
		for i = 1, 6 do
			local x = -1.1 + i * 0.32 + portraitRandom:NextNumber(-0.08, 0.08)
			local length = portraitRandom:NextNumber(1.2, 4.2)
			P(model, "Blood", V(0.09, length, 0.03), cf * CFrame.new(x, 1.6 - length / 2, -0.3), rgb(110, 0, 0))
			local drop = P(model, "BloodDrop", V(0.16, 0.2, 0.04), cf * CFrame.new(x, 1.6 - length - 0.05, -0.3), rgb(110, 0, 0))
			Instance.new("SpecialMesh", drop).MeshType = Enum.MeshType.Sphere
		end
	end

	-- 기울이기 / 뒤집기는 그림 전체를 돌려요.
	local turn = kind == "flip" and math.pi or (kind == "tilt" and math.rad(22) * p.tiltSide or 0)
	if turn ~= 0 then
		local pivot = cf
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = pivot * CFrame.Angles(0, 0, turn) * pivot:ToObjectSpace(d.CFrame)
			end
		end
	end
	p.kind = kind
end

local NAMES = { "초대 지배인", "백작 부인", "이름 없는 손님", "1923년 투숙객", "사라진 벨보이", "주인의 딸", "옛 요리사", "마지막 손님" }

local function newPortrait(parent, floor, cf, api)
	local animal = Animals.List[portraitRandom:NextInteger(1, #Animals.List)]
	local def = Animals.Types[animal]
	local p = {
		id = #api.oddities + 1,
		floor = floor,
		cf = cf,
		bg = PORTRAIT_BG[portraitRandom:NextInteger(1, #PORTRAIT_BG)],
		title = NAMES[portraitRandom:NextInteger(1, #NAMES)],
		doppelFace = DOPPEL_FACES[portraitRandom:NextInteger(1, #DOPPEL_FACES)],
		tiltSide = portraitRandom:NextNumber() < 0.5 and -1 or 1,
		data = {
			id = portraitRandom:NextInteger(1, 9999),
			name = "Portrait",
			animal = animal,
			fur = def.furs[portraitRandom:NextInteger(1, #def.furs)],
			cloth = PORTRAIT_CLOTH[portraitRandom:NextInteger(1, #PORTRAIT_CLOTH)],
		},
		kind = "normal",
		kinds = Floors.PortraitKinds,
		draw = drawPortrait,
		what = "초상화",
		whatObj = "초상화를",
		whatIs = "초상화예요",
	}
	-- "swap" 때 나타날 다른 동물 (같은 옷, 같은 소품)
	local others = {}
	for _, other in ipairs(Animals.List) do
		if other ~= animal then
			table.insert(others, other)
		end
	end
	local swapAnimal = others[portraitRandom:NextInteger(1, #others)]
	local swapDef = Animals.Types[swapAnimal]
	p.swapData = table.clone(p.data)
	p.swapData.animal = swapAnimal
	p.swapData.fur = swapDef.furs[portraitRandom:NextInteger(1, #swapDef.furs)]
	local model = Instance.new("Model")
	model.Name = "Portrait" .. p.id
	model.Parent = parent
	p.model = model
	-- 초상화 앞의 보이지 않는 지점: 여기에 "이상 보고" 버튼이 떠요.
	local spot = P(parent, "PortraitSpot", V(1, 1, 1), (cf * CFrame.new(0, -3.2, -1.2)).Position, rgb(255, 0, 255), nil, {
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
	})
	p.spot = spot
	p.reportPrompt = prompt(spot, "이상 보고", "초상화 · " .. p.title, Enum.KeyCode.R, 6)
	drawPortrait(p, "normal")
	table.insert(api.oddities, p)
	return p
end

---------------------------------------------------------------- 꽃병
-- 탁자 위의 꽃병. 밤에 몰래 시들거나, 피를 흘리거나, 쓰러지거나, 꽃이 눈알로 바뀌거나, 사라지거나, 떠올라요.
Floors.VaseKinds = { "wilt", "blood", "tipped", "eyes", "gone", "float", "color", "single", "moved" }
local FLOWER_COLORS = { rgb(235, 235, 225), rgb(240, 170, 190), rgb(250, 215, 120), rgb(200, 170, 230), rgb(170, 30, 40) }

local function drawVase(v, kind)
	local model = v.model
	model:ClearAllChildren()
	local base = v.base -- 탁자 윗면 가운데, -Z 가 복도 쪽
	if kind == "gone" then
		-- 꽃병이 있던 자리에 물 자국만 남아요.
		local ring = P(model, "WaterRing", V(0.03, 0.8, 0.8), base * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 50, 45))
		ring.Shape = Enum.PartType.Cylinder
		v.kind = kind
		return
	end
	if kind == "moved" then
		base = base * CFrame.new(-0.62, 0, -0.28) * CFrame.Angles(0, 0.5, 0) -- 탁자 모서리로 밀려나 있어요
	end
	local vaseCF = base * CFrame.new(0, 0.6, 0)
	if kind == "float" then
		vaseCF = base * CFrame.new(0, 2.2, 0) * CFrame.Angles(0.15, 0.4, 0.25)
	elseif kind == "tipped" then
		vaseCF = base * CFrame.new(0.2, 0.36, 0) * CFrame.Angles(0, 0, math.rad(-90))
	end
	local vase = P(model, "Vase", V(1.2, 0.7, 0.7), vaseCF * CFrame.Angles(0, 0, math.rad(90)), v.vaseColor, Mat.Glass, { Transparency = 0.2 })
	vase.Shape = Enum.PartType.Cylinder
	local rim = P(model, "VaseRim", V(0.12, 0.8, 0.8), vaseCF * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), BRASS, Mat.Metal)
	rim.Shape = Enum.PartType.Cylinder

	local headColor = v.color
	local stemColor = C.LEAF_DARK
	if kind == "wilt" then
		headColor = rgb(55, 40, 30)
		stemColor = rgb(70, 60, 35)
	elseif kind == "blood" then
		headColor = rgb(90, 0, 0)
	elseif kind == "color" then
		headColor = v.altColor -- 꽃 색이 바뀌었어요
	end
	local count = kind == "single" and 1 or 6 -- "single": 꽃이 한 송이만 남았어요
	for i = 1, count do
		local angle = i / 6 * math.pi * 2
		local lean = kind == "wilt" and math.rad(115) or (kind == "single" and math.rad(70) or math.rad(18))
		local stem = vaseCF * CFrame.new(math.cos(angle) * 0.15, 0.5, math.sin(angle) * 0.15) * CFrame.Angles(0, -angle, 0) * CFrame.Angles(0, 0, -lean) -- 바깥쪽으로 퍼져요
		local length = 1.1 + (i % 3) * 0.15
		P(model, "Stem", V(0.06, length, 0.06), stem * CFrame.new(0, length / 2, 0), stemColor)
		local tip = stem * CFrame.new(0, length, 0)
		if kind == "eyes" then
			-- 꽃 대신 눈알이 복도를 쳐다봐요.
			local eyePos = tip.Position
			local look = CFrame.lookAt(eyePos, eyePos + (base * CFrame.new(0, 0, -5)).LookVector * 5 + V(0, -0.3, 0))
			Props.ball(model, "EyeFlower", 0.36, eyePos, rgb(240, 235, 225))
			local iris = P(model, "EyeIris", V(0.03, 0.2, 0.2), look * CFrame.new(0, 0, -0.17) * CFrame.Angles(0, math.rad(90), 0), rgb(110, 70, 40))
			iris.Shape = Enum.PartType.Cylinder
			local pupil = P(model, "EyePupil", V(0.03, 0.09, 0.09), look * CFrame.new(0, 0, -0.185) * CFrame.Angles(0, math.rad(90), 0), rgb(10, 8, 8))
			pupil.Shape = Enum.PartType.Cylinder
		else
			Props.ball(model, "FlowerHead", 0.38, tip.Position, headColor)
			Props.ball(model, "FlowerCenter", 0.16, (tip * CFrame.new(0, 0.14, 0)).Position, kind == "wilt" and rgb(30, 25, 20) or rgb(250, 210, 80))
		end
	end

	if kind == "wilt" then
		-- 떨어진 꽃잎
		for i = 1, 5 do
			P(model, "FallenPetal", V(0.2, 0.02, 0.15), base * CFrame.new(-0.7 + i * 0.25, 0.02, -0.2 + (i % 2) * 0.3) * CFrame.Angles(0, i, 0), rgb(70, 50, 35))
		end
	elseif kind == "blood" then
		-- 꽃병 위로 피가 넘쳐 탁자와 바닥까지 흘러요.
		for i = 1, 4 do
			local x = -0.3 + i * 0.12
			local length = 0.4 + (i % 3) * 0.3
			P(model, "Blood", V(0.06, length, 0.03), vaseCF * CFrame.new(x, 0.6 - length / 2, -0.36), rgb(100, 0, 0))
		end
		P(model, "Blood", V(1.2, 0.03, 0.8), base * CFrame.new(0.1, 0.02, -0.1), rgb(100, 0, 0))
		P(model, "Blood", V(0.12, 2.9, 0.04), base * CFrame.new(0.3, -1.45, -0.52), rgb(100, 0, 0))
		local puddle = P(model, "Blood", V(0.04, 1.4, 1.4), base * CFrame.new(0.3, -2.95, -0.9) * CFrame.Angles(0, 0, math.rad(90)), rgb(90, 0, 0))
		puddle.Shape = Enum.PartType.Cylinder
	elseif kind == "tipped" then
		-- 쏟아진 물
		local puddle = P(model, "Water", V(0.03, 1.3, 1.1), base * CFrame.new(0.9, 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(120, 140, 150), Mat.Glass, { Transparency = 0.4 })
		puddle.Shape = Enum.PartType.Cylinder
	end
	v.kind = kind
end

local function newVase(parent, floor, base, api)
	local v = {
		id = #api.oddities + 1,
		floor = floor,
		base = base,
		color = FLOWER_COLORS[portraitRandom:NextInteger(1, #FLOWER_COLORS)],
		vaseColor = ({ rgb(40, 60, 55), rgb(60, 40, 50), rgb(200, 205, 210) })[portraitRandom:NextInteger(1, 3)],
		kind = "normal",
		kinds = Floors.VaseKinds,
		draw = drawVase,
		what = "꽃병",
		whatObj = "꽃병을",
		whatIs = "꽃병이에요",
	}
	repeat
		v.altColor = FLOWER_COLORS[portraitRandom:NextInteger(1, #FLOWER_COLORS)]
	until v.altColor ~= v.color
	local model = Instance.new("Model")
	model.Name = "Vase" .. v.id
	model.Parent = parent
	v.model = model
	local spot = P(parent, "VaseSpot", V(1, 1, 1), (base * CFrame.new(0, 0, -1.3)).Position, rgb(255, 0, 255), nil, {
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
	})
	v.spot = spot
	v.reportPrompt = prompt(spot, "이상 보고", "꽃병", Enum.KeyCode.R, 6)
	drawVase(v, "normal")
	table.insert(api.oddities, v)
	return v
end

-- 벽에 붙인 작은 원목 탁자 (꽃병 받침)
local function consoleTable(parent, x, y, side)
	local z = side * (HALF - 0.85)
	Props.solid(parent, "ConsoleTop", V(1.9, 0.15, 1.0), V(x, y + 2.95, z), WOOD_DARK, Mat.Wood)
	P(parent, "ConsoleApron", V(1.8, 0.35, 0.9), V(x, y + 2.7, z), WOOD, Mat.Wood)
	for _, dx in ipairs({ -0.8, 0.8 }) do
		for _, dz in ipairs({ -0.35, 0.35 }) do
			P(parent, "ConsoleLeg", V(0.14, 2.6, 0.14), V(x + dx, y + 1.3, z + dz), WOOD_DARK, Mat.Wood)
		end
	end
	return CFrame.lookAt(V(x, y + 3.03, z), V(x, y + 3.03, z - side))
end

---------------------------------------------------------------- 층 로비 (엘리베이터 앞)
local function buildLounge(parent, lights, floor, api)
	local y = floorY(floor)
	-- 벽: 남북 벽(z ±7)과, 복도와 이어지는 짧은 벽(x 21)
	for _, side in ipairs({ -1, 1 }) do
		local z = side * LOUNGE_HALF
		Props.solid(parent, "LoungeWall", V(28.9 - LOUNGE_X, WALL_H, 0.5), V((LOUNGE_X + 28.9) / 2, y + WALL_H / 2, z + side * 0.25), TEAL, Mat.Fabric)
		dressWall(parent, CFrame.lookAt(V((LOUNGE_X + 28.9) / 2, y, z), V((LOUNGE_X + 28.9) / 2, y, z - side)), 28.9 - LOUNGE_X, WALL_H)
		local zMid = side * (HALF + LOUNGE_HALF) / 2
		Props.solid(parent, "LoungeWall", V(0.5, WALL_H, LOUNGE_HALF - HALF), V(LOUNGE_X - 0.25, y + WALL_H / 2, zMid), TEAL, Mat.Fabric)
		dressWall(parent, CFrame.lookAt(V(LOUNGE_X, y, zMid), V(LOUNGE_X + 1, y, zMid)), LOUNGE_HALF - HALF, WALL_H)
	end
	-- 동쪽 벽 꾸밈 (엘리베이터 양옆)
	for _, side in ipairs({ -1, 1 }) do
		local zMid = side * 5.1
		dressWall(parent, CFrame.lookAt(V(28.9, y, zMid), V(27.9, y, zMid)), 3.8, WALL_H)
	end

	-- 러그, 소파, 안락의자, 탁자, 꽃, 화분
	P(parent, "LoungeRug", V(6.5, 0.06, 9), V(25, y + 0.06, 0), rgb(150, 85, 35), Mat.Fabric)
	P(parent, "LoungeRugInner", V(5.3, 0.07, 7.8), V(25, y + 0.065, 0), rgb(125, 68, 28), Mat.Fabric)
	-- 소파 (북쪽 벽)
	Props.solid(parent, "SofaBase", V(5, 1.4, 2.4), V(24.5, y + 0.7, 5.6), CHARCOAL, Mat.Fabric)
	P(parent, "SofaBack", V(5, 2.4, 0.8), V(24.5, y + 1.9, 6.6), CHARCOAL, Mat.Fabric)
	for _, dx in ipairs({ -1.2, 1.2 }) do
		P(parent, "SofaCushion", V(2.3, 0.45, 2.1), V(24.5 + dx, y + 1.6, 5.5), rgb(72, 66, 62), Mat.Fabric)
	end
	for _, dx in ipairs({ -2.6, 2.6 }) do
		P(parent, "SofaArm", V(0.6, 2, 2.4), V(24.5 + dx, y + 1.2, 5.6), CHARCOAL, Mat.Fabric)
	end
	-- 겨자색 안락의자 (남쪽 벽)
	local chair = Instance.new("Model")
	chair.Name = "LoungeChair"
	chair.Parent = parent
	local seat = Props.solid(chair, "ChairSeat", V(2.6, 1.2, 2.4), V(23.5, y + 0.6, -5.6), MUSTARD, Mat.Fabric)
	P(chair, "ChairBack", V(2.6, 2.8, 0.6), V(23.5, y + 1.9, -6.6), MUSTARD, Mat.Fabric)
	chair.PrimaryPart = seat
	api.chairs[floor] = { model = chair, home = chair:GetPivot(), parent = parent }
	-- 둥근 탁자와 검붉은 장미
	Props.vcyl(parent, "SideTable", 0.25, 2.2, V(25.5, y + 2.2, -5.3), WOOD_DARK, Mat.Wood)
	Props.vcyl(parent, "SideTableLeg", 2.1, 0.3, V(25.5, y + 1.05, -5.3), WOOD_DARK, Mat.Wood)
	Props.bouquet(parent, V(25.5, y + 2.33, -5.3), "rose", rgb(120, 15, 25), 7, rgb(40, 60, 55))
	-- 화분
	Props.plant(parent, V(22.3, y, -5.8), 3.6)
	Props.plant(parent, V(27.6, y, 5.8), 3.6)
	-- 샹들리에
	local cy = y + WALL_H - 1.6
	P(parent, "ChandelierChain", V(0.1, 1.3, 0.1), V(25, cy + 0.9, 0), BRASS, Mat.Metal)
	Props.vcyl(parent, "ChandelierRing", 0.15, 2.4, V(25, cy, 0), BRASS, Mat.Metal)
	for i = 1, 6 do
		local angle = i / 6 * math.pi * 2
		local pos = V(25 + math.cos(angle) * 1.1, cy + 0.3, math.sin(angle) * 1.1)
		Props.vcyl(parent, "Candle", 0.4, 0.15, pos, CREAM)
		P(parent, "CandleFlame", V(0.12, 0.2, 0.12), pos + V(0, 0.3, 0), WARM, Mat.Neon)
	end
	local center = P(lights, "LoungeChandelier", V(0.5, 0.5, 0.5), V(25, cy - 0.2, 0), WARM, Mat.Neon)
	center.Shape = Enum.PartType.Ball
	glow(center, 18, 0.9)

	-- 엘리베이터 (동쪽 벽)
	P(parent, "ElevatorFrame", V(0.5, 9.5, 6.4), V(28.6, y + 4.75, 0), rgb(120, 90, 50), Mat.Metal)
	P(parent, "ElevatorDoor", V(0.3, 8.5, 5.4), V(28.4, y + 4.25, 0), rgb(90, 70, 45), Mat.Metal)
	P(parent, "ElevatorGap", V(0.35, 8.5, 0.08), V(28.4, y + 4.25, 0), rgb(20, 15, 10))
	local sign = P(parent, "FloorSign", V(0.15, 1.2, 2.4), V(28.5, y + 10.3, 0), rgb(15, 10, 10))
	api.signs[floor] = Props.text(sign, Enum.NormalId.Left, floor .. "F", rgb(255, 200, 120), Enum.Font.Garamond)
	api.exits[floor] = CFrame.lookAt(V(25.5, y + 3, 0), V(20, y + 3, 0))
	return V(28.5, y + 4.5, -3.6) -- 버튼 판 위치
end

-- 엘리베이터 버튼: 누르면 그 층으로 가요. (숫자 키 1~4 로도 눌러요)
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
local function buttonPanel(parent, base, here, api)
	P(parent, "ButtonPanel", V(0.12, 2.6, 0.8), base, rgb(30, 22, 18), Mat.Metal)
	for target = 1, 4 do
		local button = P(parent, "FloorButton", V(0.12, 0.45, 0.45), base + V(-0.06, 1.0 - (target - 1) * 0.6, 0), target == here and rgb(255, 170, 80) or BRASS, target == here and Mat.Neon or Mat.Metal)
		Props.text(button, Enum.NormalId.Left, target == 1 and "L" or tostring(target), rgb(30, 20, 10), Enum.Font.GothamBold)
		if target ~= here then
			local p = prompt(button, target == 1 and "로비로" or target .. "층으로", "엘리베이터", KEYS[target], 7)
			table.insert(api.elevatorPrompts, { prompt = p, target = target })
		end
	end
end

function Floors.build(hotel)
	local existing = hotel:FindFirstChild("Floors")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Floors"
	folder.Parent = hotel
	local lights = hotel:FindFirstChild("Lights") or folder

	local api = { rooms = {}, exits = {}, elevatorPrompts = {}, figures = {}, oddities = {}, lamps = {}, signs = {}, chairs = {} }
	api.exits[1] = CFrame.lookAt(V(24.5, 3.5, -2), V(18, 3.5, -2))

	for _, floor in ipairs(FLOOR_LIST) do
		local y = floorY(floor)
		local level = Instance.new("Model")
		level.Name = "Floor" .. floor
		level.Parent = folder

		-- 바닥: 대리석 + 어두운 테두리 + 빨간 러너 (1층 로비와 같아요)
		local length = LOUNGE_X + 28.9
		local midX = (LOUNGE_X - 28.9) / 2
		P(level, "Marble", V(length, 0.06, HALF * 2), V(midX, y + 0.03, 0), MARBLE, Mat.Marble)
		P(level, "Marble", V(28.9 - LOUNGE_X, 0.06, LOUNGE_HALF * 2), V((LOUNGE_X + 28.9) / 2, y + 0.03, 0), MARBLE, Mat.Marble)
		for _, side in ipairs({ -1, 1 }) do
			P(level, "FloorBorder", V(length, 0.07, 0.6), V(midX, y + 0.035, side * (HALF - 0.4)), rgb(60, 50, 45), Mat.Marble)
		end
		P(level, "Runner", V(length + 3, 0.08, 3), V(midX + 1.5, y + 0.04, 0), RUNNER, Mat.Fabric)
		for _, side in ipairs({ -1, 1 }) do
			P(level, "RunnerEdge", V(length + 3, 0.09, 0.2), V(midX + 1.5, y + 0.045, side * 1.55), BRASS, Mat.Fabric)
		end

		-- 천장: 크림색 판 + 원목 들보
		Props.solid(level, "CorridorCeiling", V(length, 0.4, HALF * 2 + 1), V(midX, y + WALL_H + 0.2, 0), CREAM)
		Props.solid(level, "LoungeCeiling", V(28.9 - LOUNGE_X, 0.4, LOUNGE_HALF * 2 + 1), V((LOUNGE_X + 28.9) / 2, y + WALL_H + 0.2, 0), CREAM)
		for x = -26, 26, 5 do
			local width = x > LOUNGE_X and LOUNGE_HALF * 2 or HALF * 2
			P(level, "Beam", V(0.6, 0.5, width), V(x, y + WALL_H - 0.25, 0), WOOD_DARK, Mat.Wood)
		end

		-- 벽
		corridorWall(level, y, -1)
		corridorWall(level, y, 1)
		Props.solid(level, "WestEnd", V(0.5, WALL_H, HALF * 2), V(-29.15, y + WALL_H / 2, 0), TEAL, Mat.Fabric)
		dressWall(level, CFrame.lookAt(V(-28.9, y, 0), V(-27.9, y, 0)), HALF * 2, WALL_H)
		-- 서쪽 끝 작은 창문 (달빛)
		P(level, "EndWindow", V(0.2, 3, 2.4), V(-28.55, y + 8, 0), rgb(60, 70, 110), Mat.Neon, { Transparency = 0.6 })

		-- 천장 등 (놋쇠 갓 + 따뜻한 빛)
		for x = -24, 16, 8 do
			local shade = P(level, "LampShade", V(1.6, 0.4, 1.6), V(x, y + WALL_H - 0.45, 0), BRASS, Mat.Metal)
			local bulb = P(lights, "CorridorLamp", V(1.2, 0.2, 1.2), V(x, y + WALL_H - 0.7, 0), WARM, Mat.Neon)
			glow(bulb, 15, 0.7)
			table.insert(api.lamps, { floor = floor, x = x, y = y, shade = shade, bulb = bulb, parent = level })
		end

		-- 객실 문
		for i, x in ipairs(DOOR_XS) do
			for _, side in ipairs({ -1, 1 }) do
				local room = buildRoom(level, floor, i, side, x)
				api.rooms[room.number] = room
			end
		end

		-- 문 사이마다 초상화
		local portraits = Instance.new("Folder")
		portraits.Name = "Portraits"
		portraits.Parent = level
		for _, x in ipairs(PORTRAIT_XS) do
			for _, side in ipairs({ -1, 1 }) do
				local z = side * (HALF - 0.35)
				newPortrait(portraits, floor, CFrame.lookAt(V(x, y + 8, z), V(x, y + 8, z - side)), api)
			end
		end
		-- 초상화 밑 탁자 위 꽃병 (층마다 3개)
		for _, spotInfo in ipairs({ { -18, 1 }, { -2, -1 }, { 14, 1 } }) do
			local top = consoleTable(level, spotInfo[1], y, spotInfo[2])
			newVase(portraits, floor, top, api)
		end

		local panelBase = buildLounge(level, lights, floor, api)
		buttonPanel(level, panelBase, floor, api)
	end

	-- 로비 엘리베이터 옆 버튼 판 (원래 있던 호출 버튼 자리)
	buttonPanel(folder, V(28.5, 4.6, -7.4), 1, api)

	-- 복도 끝에 서 있다가 다가가면 사라지는 그림자 자리
	for _, floor in ipairs(FLOOR_LIST) do
		api.figures[floor] = CFrame.lookAt(V(-26.5, floorY(floor), 0), V(0, floorY(floor), 0))
	end

	---------------------------------------------------------------- 객실 상태 바꾸기
	-- 문을 닫고, 불빛을 끄고, 덧붙였던 소품을 모두 치워요.
	function api.resetRoom(room)
		room.door:PivotTo(room.closedPivot)
		room.extras:ClearAllChildren()
		room.strip.Color = rgb(20, 16, 14)
		room.strip.Material = Mat.SmoothPlastic
		room.okPrompt.Enabled = false
		room.reportPrompt.Enabled = false
		room.knockPrompt.Enabled = false
	end

	function api.resetAll()
		for _, room in pairs(api.rooms) do
			api.resetRoom(room)
		end
		for _, entry in ipairs(api.elevatorPrompts) do
			entry.prompt.Enabled = false
		end
		for _, o in ipairs(api.oddities) do
			if o.kind ~= "normal" then
				o.draw(o, "normal")
			end
			o.reportPrompt.Enabled = false
		end
	end

	function api.setOccupied(room, occupied)
		room.strip.Color = occupied and rgb(255, 190, 120) or rgb(20, 16, 14)
		room.strip.Material = occupied and Mat.Neon or Mat.SmoothPlastic
	end

	-- 문을 안쪽으로 살짝(또는 활짝) 열어요.
	function api.openDoor(room, degrees)
		room.door:PivotTo(room.closedPivot)
		local offset = room.hinge:ToObjectSpace(room.closedPivot)
		room.door:PivotTo(room.hinge * CFrame.Angles(0, math.rad(degrees) * room.swing, 0) * offset)
	end

	function api.closeDoor(room)
		room.door:PivotTo(room.closedPivot)
	end

	-- 문 앞면 위의 한 점 (dx: 가로, dy: 세로, 문 가운데 기준)
	function api.onDoor(room, dx, dy)
		return room.closedPivot * CFrame.new(dx, dy, -0.2)
	end

	function api.setElevators(enabled)
		for _, entry in ipairs(api.elevatorPrompts) do
			entry.prompt.Enabled = enabled
		end
	end

	-- 초상화·꽃병을 바꿔요. ("normal" 이면 원래대로)
	function api.setOddity(o, kind)
		o.draw(o, kind)
	end

	---------------------------------------------------------------- 그 밖의 이상해지는 것들
	local function hiddenSpot(parent, pos)
		return P(parent, "OdditySpot", V(1, 1, 1), pos, rgb(255, 0, 255), nil, {
			Transparency = 1,
			CanQuery = false,
			CanTouch = false,
		})
	end
	local function addOddity(o)
		o.id = #api.oddities + 1
		o.kind = "normal"
		table.insert(api.oddities, o)
		return o
	end

	-- 빈방의 문: 번호가 바뀌거나, 거꾸로 붙거나, 문이 열려 있거나, 빨간 불빛, 젖은 발자국, 작은 손자국
	-- (손님이 묵는 방은 바뀌지 않아요. 문 앞의 "이상 보고" 버튼을 같이 써요.)
	local DOOR_KINDS = { "plate", "plateflip", "ajar", "redlight", "footprints", "hand" }
	local function drawDoor(o, kind)
		local room = o.room
		room.extras:ClearAllChildren()
		api.closeDoor(room)
		room.plateLabel.Text = tostring(room.number)
		room.plateLabel.Rotation = 0
		room.strip.Color = rgb(20, 16, 14)
		room.strip.Material = Mat.SmoothPlastic
		if kind == "plate" then
			-- 옆방과 같은 번호 (같은 번호가 둘!)
			room.plateLabel.Text = tostring(room.number + (room.number % 100 <= 2 and 2 or -2))
		elseif kind == "plateflip" then
			room.plateLabel.Rotation = 180
		elseif kind == "ajar" then
			api.openDoor(room, 25)
		elseif kind == "redlight" then
			room.strip.Color = rgb(200, 20, 20)
			room.strip.Material = Mat.Neon
		elseif kind == "footprints" then
			-- 복도에서 빈방 안으로 이어지는 젖은 발자국
			local start = room.spot.Position - V(0, 2.97, 0)
			local inward = V(0, 0, room.side)
			for i = 0, 5 do
				local foot = start - inward * (2.4 - i * 0.55) + V((i % 2 == 0) and -0.25 or 0.25, 0, 0)
				local footprint = P(room.extras, "WetFootprint", V(0.35, 0.02, 0.6), CFrame.new(foot), rgb(40, 50, 55), Mat.Glass, { Transparency = 0.3 })
				Instance.new("SpecialMesh", footprint).MeshType = Enum.MeshType.Sphere
			end
		elseif kind == "hand" then
			-- 문 아래쪽, 아이 키 높이의 작은 손자국
			local cf = api.onDoor(room, 0.4, -2.2)
			local palm = P(room.extras, "SmallHand", V(0.26, 0.3, 0.03), cf, rgb(110, 0, 0))
			Instance.new("SpecialMesh", palm).MeshType = Enum.MeshType.Sphere
			for f = -2, 2 do
				local finger = P(room.extras, "SmallHand", V(0.05, 0.18, 0.03), cf * CFrame.new(f * 0.055, 0.22 - math.abs(f) * 0.03, 0) * CFrame.Angles(0, 0, f * 0.15), rgb(110, 0, 0))
				Instance.new("SpecialMesh", finger).MeshType = Enum.MeshType.Sphere
			end
		end
		o.kind = kind
	end
	for _, room in pairs(api.rooms) do
		room.oddity = addOddity({
			floor = room.floor,
			room = room,
			kinds = DOOR_KINDS,
			draw = drawDoor,
			reportPrompt = room.reportPrompt,
			shared = true, -- 문 앞 버튼은 순찰 쪽에서 따로 처리해요
			what = "방문",
			whatObj = "방문을",
			whatIs = "방문이에요",
		})
	end

	-- 천장 조명: 빨개지거나, 꺼지거나, 축 처지거나, 비스듬히 기울어요.
	local LAMP_KINDS = { "red", "off", "low", "swing" }
	local function drawLamp(o, kind)
		local lamp = o.lamp
		local top = CFrame.new(lamp.x, lamp.y + WALL_H, 0)
		local drop, tilt = 0, 0
		if kind == "low" then
			drop = 3
		elseif kind == "swing" then
			tilt = math.rad(28)
		end
		local hang = top * CFrame.Angles(tilt, 0, tilt * 0.5) * CFrame.new(0, -drop, 0)
		lamp.shade.CFrame = hang * CFrame.new(0, -0.45, 0)
		lamp.bulb.CFrame = hang * CFrame.new(0, -0.7, 0)
		if o.chain then
			o.chain:Destroy()
			o.chain = nil
		end
		if drop > 0 then
			o.chain = P(lamp.parent, "LampChain", V(0.08, drop, 0.08), top * CFrame.new(0, -drop / 2, 0), BRASS, Mat.Metal)
		end
		local light = lamp.bulb:FindFirstChildWhichIsA("Light")
		lamp.bulb.Color = kind == "red" and rgb(220, 30, 30) or (kind == "off" and rgb(50, 45, 40) or WARM)
		lamp.bulb.Material = kind == "off" and Mat.SmoothPlastic or Mat.Neon
		if light then
			light.Enabled = kind ~= "off"
			light.Color = kind == "red" and rgb(255, 40, 30) or WARM
		end
		o.kind = kind
	end
	for _, lamp in ipairs(api.lamps) do
		local spot = hiddenSpot(lamp.parent, V(lamp.x, lamp.y + 3, 0))
		addOddity({
			floor = lamp.floor,
			lamp = lamp,
			kinds = LAMP_KINDS,
			draw = drawLamp,
			reportPrompt = prompt(spot, "이상 보고", "천장 조명", Enum.KeyCode.R, 4.5),
			what = "조명",
			whatObj = "조명을",
			whatIs = "조명이에요",
		})
	end

	-- 엘리베이터 층 표시판: 없는 층(13F, B4)을 가리키거나 거꾸로 돼요.
	local SIGN_KINDS = { "thirteen", "b4", "flip", "wrong" }
	local function drawSign(o, kind)
		local label = o.label
		label.Rotation = kind == "flip" and 180 or 0
		label.TextColor3 = (kind == "b4" or kind == "thirteen") and rgb(255, 60, 40) or rgb(255, 200, 120)
		if kind == "thirteen" then
			label.Text = "13F"
		elseif kind == "b4" then
			label.Text = "B4"
		elseif kind == "wrong" then
			label.Text = (o.floor == 4 and 2 or o.floor + 1) .. "F"
		else
			label.Text = o.floor .. "F"
		end
		o.kind = kind
	end
	for _, floor in ipairs(FLOOR_LIST) do
		local spot = hiddenSpot(folder, V(25.5, floorY(floor) + 3, 2.6))
		addOddity({
			floor = floor,
			label = api.signs[floor],
			kinds = SIGN_KINDS,
			draw = drawSign,
			reportPrompt = prompt(spot, "이상 보고", "층 표시판", Enum.KeyCode.R, 5),
			what = "층 표시판",
			whatObj = "층 표시판을",
			whatIs = "층 표시판이에요",
		})
	end

	-- 층 로비 의자: 벽을 보고 돌아앉거나, 엘리베이터 앞으로 나와 있거나, 사라져요.
	local CHAIR_KINDS = { "turned", "middle", "gone" }
	local function drawChair(o, kind)
		local chair = o.chair
		if kind == "gone" then
			chair.model.Parent = nil
		else
			chair.model.Parent = chair.parent
		end
		if kind == "turned" then
			chair.model:PivotTo(chair.home * CFrame.Angles(0, math.pi, 0))
		elseif kind == "middle" then
			local floorY0 = chair.home.Position.Y
			chair.model:PivotTo(CFrame.lookAt(V(25.5, floorY0, -0.5), V(28, floorY0, -0.5)))
		else
			chair.model:PivotTo(chair.home)
		end
		o.kind = kind
	end
	for _, floor in ipairs(FLOOR_LIST) do
		local spot = hiddenSpot(folder, V(23.5, floorY(floor) + 3, -3.4))
		addOddity({
			floor = floor,
			chair = api.chairs[floor],
			kinds = CHAIR_KINDS,
			draw = drawChair,
			reportPrompt = prompt(spot, "이상 보고", "의자", Enum.KeyCode.R, 5),
			what = "의자",
			whatObj = "의자를",
			whatIs = "의자예요",
		})
	end

	api.resetAll()
	return api
end

return Floors
