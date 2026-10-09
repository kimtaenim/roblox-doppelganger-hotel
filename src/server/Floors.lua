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
local HALF = 5 -- 복도 폭의 절반 (넉넉하게 10칸)
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
Floors.PortraitKinds = { "flip", "doppel", "away", "gone", "blood", "tilt", "red", "twins" }

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

	-- 캔버스 위의 그림은 각 플레이어 화면에서 그려요. (Portraits.client.lua)
	-- 어떤 그림인지만 캔버스에 적어 둬요.
	local data = kind == "swap" and p.swapData or p.data
	canvas:SetAttribute("Portrait", true)
	canvas:SetAttribute("Animal", data.animal)
	canvas:SetAttribute("Fur", data.fur)
	canvas:SetAttribute("Cloth", data.cloth)
	canvas:SetAttribute("DataId", data.id)
	canvas:SetAttribute("Background", p.bg)
	canvas:SetAttribute("Kind", kind)
	canvas:SetAttribute("Doppel", kind == "doppel" and p.doppelFace or "")
	canvas:SetAttribute("Side", p.tiltSide)

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
		id = #api.portraits + 1,
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
	drawPortrait(p, "normal")
	table.insert(api.portraits, p)
	return p
end

---------------------------------------------------------------- 꽃병
-- 탁자 위의 꽃병. 밤에 몰래 시들거나, 피를 흘리거나, 쓰러지거나, 꽃이 눈알로 바뀌거나, 사라지거나, 떠올라요.
Floors.VaseKinds = { "wilt", "blood", "tipped", "eyes", "gone", "float" }
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
			Props.ball(model, "EyeFlower", 0.6, eyePos, rgb(240, 235, 225))
			local iris = P(model, "EyeIris", V(0.03, 0.34, 0.34), look * CFrame.new(0, 0, -0.29) * CFrame.Angles(0, math.rad(90), 0), rgb(110, 70, 40))
			iris.Shape = Enum.PartType.Cylinder
			local pupil = P(model, "EyePupil", V(0.03, 0.15, 0.15), look * CFrame.new(0, 0, -0.31) * CFrame.Angles(0, math.rad(90), 0), rgb(10, 8, 8))
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
		id = #api.vases + 1,
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
	drawVase(v, "normal")
	table.insert(api.vases, v)
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
	api.chandeliers[floor] = center

	-- 엘리베이터 (동쪽 벽)
	P(parent, "ElevatorFrame", V(0.5, 9.5, 6.4), V(28.6, y + 4.75, 0), rgb(120, 90, 50), Mat.Metal)
	P(parent, "ElevatorDoor", V(0.3, 8.5, 5.4), V(28.4, y + 4.25, 0), rgb(90, 70, 45), Mat.Metal)
	P(parent, "ElevatorGap", V(0.35, 8.5, 0.08), V(28.4, y + 4.25, 0), rgb(20, 15, 10))
	-- 엘리베이터 문 위의 낡은 등: 지직지직 깜빡여요.
	local elevatorLamp = P(lights, "ElevatorLamp", V(0.3, 0.4, 2.2), V(28.45, y + 9.15, 0), rgb(255, 230, 190), Mat.Neon)
	elevatorLamp:SetAttribute("Zone", "Flicker")
	local lampLight = Instance.new("SpotLight")
	lampLight.Face = Enum.NormalId.Left
	lampLight.Range = 16
	lampLight.Angle = 100
	lampLight.Brightness = 1.6
	lampLight.Color = rgb(255, 220, 180)
	lampLight.Parent = elevatorLamp
	table.insert(api.elevatorLamps, elevatorLamp)
	local sign = P(parent, "FloorSign", V(0.15, 1.2, 2.4), V(28.5, y + 10.3, 0), rgb(15, 10, 10))
	api.signs[floor] = Props.text(sign, Enum.NormalId.Left, floor .. "F", rgb(255, 200, 120), Enum.Font.Garamond)
	api.exits[floor] = CFrame.lookAt(V(25.5, y + 3, 0), V(20, y + 3, 0))
	return V(28.5, y + 4.5, -3.6) -- 버튼 판 위치
end

-- 엘리베이터 버튼 판: "엘리베이터 타기"(E)를 누르면 화면에 층 고르기 창이 떠요.
local function buttonPanel(parent, base, here, api)
	local panel = P(parent, "ButtonPanel", V(0.12, 2.6, 0.8), base, rgb(30, 22, 18), Mat.Metal)
	for target = 1, 4 do
		local button = P(parent, "FloorButton", V(0.12, 0.45, 0.45), base + V(-0.06, 1.0 - (target - 1) * 0.6, 0), target == here and rgb(255, 170, 80) or BRASS, target == here and Mat.Neon or Mat.Metal)
		Props.text(button, Enum.NormalId.Left, target == 1 and "L" or tostring(target), rgb(30, 20, 10), Enum.Font.GothamBold)
	end
	local p = prompt(panel, "엘리베이터 타기", here == 1 and "로비" or here .. "층", Enum.KeyCode.E, 7)
	p.HoldDuration = 0.3
	table.insert(api.elevatorPrompts, { prompt = p, floor = here })
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

	local api = { elevatorLamps = {}, List = FLOOR_LIST, rooms = {}, exits = {}, elevatorPrompts = {}, figures = {}, portraits = {}, vases = {}, events = {}, levels = {}, lamps = {}, signs = {}, chairs = {}, chandeliers = {} }
	api.exits[1] = CFrame.lookAt(V(24.5, 3.5, -2), V(18, 3.5, -2))

	for _, floor in ipairs(FLOOR_LIST) do
		local y = floorY(floor)
		local level = Instance.new("Model")
		level.Name = "Floor" .. floor
		level.Parent = folder
		api.levels[floor] = level

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
	local lobbyLamp = P(lights, "ElevatorLamp", V(0.3, 0.4, 2.2), V(28.2, 10.2, -2), rgb(255, 230, 190), Mat.Neon)
	lobbyLamp:SetAttribute("Zone", "Flicker")
	local lobbyLight = Instance.new("SpotLight")
	lobbyLight.Face = Enum.NormalId.Left
	lobbyLight.Range = 16
	lobbyLight.Angle = 100
	lobbyLight.Brightness = 1.6
	lobbyLight.Color = rgb(255, 220, 180)
	lobbyLight.Parent = lobbyLamp
	table.insert(api.elevatorLamps, lobbyLamp)

	-- 엘리베이터 등 깜빡임: 평소엔 켜져 있다가 지직, 지지직 하고 꺼졌다 켜져요.
	task.spawn(function()
		while folder.Parent do
			task.wait(0.4 + math.random() * 1.6)
			for _, lamp in ipairs(api.elevatorLamps) do
				if math.random() < 0.6 then
					task.spawn(function()
						local light = lamp:FindFirstChildWhichIsA("Light")
						for _ = 1, math.random(2, 6) do
							local on = math.random() < 0.4
							lamp.Material = on and Mat.Neon or Mat.SmoothPlastic
							lamp.Color = on and rgb(255, 230, 190) or rgb(60, 55, 50)
							if light then
								light.Enabled = on
							end
							task.wait(0.03 + math.random() * 0.09)
						end
						lamp.Material = Mat.Neon
						lamp.Color = rgb(255, 230, 190)
						if light then
							light.Enabled = true
						end
					end)
				end
			end
		end
	end)

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
		for _, floor in ipairs(FLOOR_LIST) do
			api.setEvent(floor, "normal")
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

	---------------------------------------------------------------- 층 전체가 확 바뀌는 이상 (아주 뚜렷한 것만)
	-- blood: 복도 바닥에 피가 강물처럼 흘러요 / eyes: 꽃병마다 꽃 대신 커다란 눈알 /
	-- flip: 천장과 바닥이 뒤집혀요 (가구가 천장에 거꾸로 매달려요) / red: 조명이 전부 새빨개요 / doors: 모든 객실 문이 활짝 열려요
	-- crowd: 새까만 형체들이 빨간 눈을 빛내며 천장에 거꾸로 매달려 있어요 (움직이지 않아요)
	api.EventKinds = { "blood", "eyes", "flip", "red", "doors", "crowd" }
	for _, floor in ipairs(FLOOR_LIST) do
		local eventFolder = Instance.new("Folder")
		eventFolder.Name = "Event"
		eventFolder.Parent = api.levels[floor]
		api.events[floor] = { floor = floor, kind = "normal", folder = eventFolder }
	end

	local function lampsOn(floor)
		local list = {}
		for _, lamp in ipairs(api.lamps) do
			if lamp.floor == floor then
				table.insert(list, lamp.bulb)
			end
		end
		table.insert(list, api.chandeliers[floor])
		return list
	end

	-- 뒤집을 파트: 객실 문(방 번호, 노크 자리)과 엘리베이터 버튼은 그대로 두고 나머지 전부
	local function flipParts(floor)
		local level = api.levels[floor]
		local list = {}
		for _, d in ipairs(level:GetDescendants()) do
			if d:IsA("BasePart") then
				local inRoom = false
				local node = d.Parent
				while node and node ~= level do
					if node.Name:match("^Room%d") then
						inRoom = true
						break
					end
					node = node.Parent
				end
				if not inRoom and d.Name ~= "ButtonPanel" and d.Name ~= "FloorButton" then
					table.insert(list, d)
				end
			end
		end
		for _, bulb in ipairs(lampsOn(floor)) do
			table.insert(list, bulb)
		end
		return list
	end

	local function applyEvent(ev, kind, on)
		local floor = ev.floor
		local y = floorY(floor)
		if kind == "blood" then
			if on then
				-- 진짜 피처럼: 둥근 웅덩이를 겹겹이 이어 붙인 구불구불한 피의 강.
				-- 가장자리는 굳어서 검붉고, 가운데는 번들번들 윤이 나요. 주변엔 튄 방울, 발자국, 끌린 자국.
				local random = Random.new(floor * 31)
				local DARK = rgb(55, 0, 2)
				local MID = rgb(95, 2, 6)
				local WET = rgb(140, 8, 12)
				local function blot(name, pos, w, l, yaw, color, lift, gloss)
					local part = P(ev.folder, name, V(w, 0.04, l), CFrame.new(pos + V(0, lift, 0)) * CFrame.Angles(0, yaw, 0), color, Mat.SmoothPlastic, { Reflectance = gloss or 0.05 })
					Instance.new("SpecialMesh", part).MeshType = Enum.MeshType.Sphere
					return part
				end
				local floorTop = y + 0.1
				-- 1) 강줄기
				local x = -27
				while x < 22 do
					local z = math.sin(x * 0.28) * 1.6 + math.sin(x * 0.9) * 0.4
					local width = 1.8 + math.sin(x * 0.5) * 0.6 + random:NextNumber(-0.3, 0.3)
					local pos = V(x, floorTop, z)
					local yaw = math.atan2(math.cos(x * 0.28) * 0.45, 1)
					blot("BloodEdge", pos, width + 0.7, 1.8, yaw, DARK, 0.0)
					blot("BloodRiver", pos, width, 1.6, yaw, MID, 0.01, 0.15)
					if random:NextNumber() < 0.5 then
						blot("BloodShine", pos + V(random:NextNumber(-0.3, 0.3), 0, random:NextNumber(-0.3, 0.3)), width * 0.45, 0.7, yaw, WET, 0.02, 0.45)
					end
					x += 0.7
				end
				-- 2) 강에서 번진 웅덩이 (객실 문 쪽으로 흘러들어요)
				for _ = 1, 9 do
					local center = V(random:NextNumber(-25, 19), floorTop, random:NextNumber(-HALF + 1, HALF - 1))
					local size = random:NextNumber(1.6, 3)
					blot("BloodEdge", center, size + 0.6, size * random:NextNumber(0.6, 1), random:NextNumber(0, 3), DARK, 0.0)
					blot("BloodPool", center, size, size * random:NextNumber(0.6, 0.9), random:NextNumber(0, 3), MID, 0.01, 0.2)
					blot("BloodShine", center + V(0.2, 0, -0.1), size * 0.35, size * 0.2, random:NextNumber(0, 3), WET, 0.02, 0.5)
				end
				-- 3) 튄 핏방울
				for _ = 1, 70 do
					local pos = V(random:NextNumber(-27, 21), floorTop, random:NextNumber(-HALF + 0.4, HALF - 0.4))
					local size = random:NextNumber(0.08, 0.35)
					blot("BloodDrop", pos, size, size * random:NextNumber(0.6, 1.4), random:NextNumber(0, 3), random:NextNumber() < 0.5 and DARK or MID, 0.005, 0.1)
				end
				-- 4) 핏물을 밟고 지나간 발자국 (엘리베이터 쪽으로, 점점 옅어져요)
				for i = 0, 13 do
					local fx = -6 + i * 1.6
					local fz = 2.6 + ((i % 2 == 0) and -0.35 or 0.35)
					local fade = i / 13
					local foot = blot("BloodFootprint", V(fx, floorTop, fz), 0.75, 0.38, 0, DARK:Lerp(rgb(150, 120, 100), fade * 0.55), 0.015)
					foot.Transparency = fade * 0.6
				end
				-- 5) 무언가를 끌고 간 자국
				for i = 0, 10 do
					blot("BloodDrag", V(-20 + i * 0.9, floorTop, -2.8 + math.sin(i * 0.6) * 0.3), 1.3, 0.5, 0.05, MID, 0.012, 0.1).Transparency = i / 14
				end
				-- 6) 벽: 피 얼룩에서 핏줄기가 흘러내려 끝에 방울이 맺혀요
				for wx = -24, 18, 5.5 do
					for _, side in ipairs({ -1, 1 }) do
						local wz = side * (HALF - 0.43)
						local top = y + random:NextNumber(5.5, 9)
						local cx = wx + random:NextNumber(-1, 1)
						local smear = P(ev.folder, "WallSmear", V(random:NextNumber(0.9, 1.6), random:NextNumber(0.6, 1), 0.04), CFrame.new(cx, top, wz), MID, Mat.SmoothPlastic, { Reflectance = 0.1 })
						Instance.new("SpecialMesh", smear).MeshType = Enum.MeshType.Sphere
						for _ = 1, random:NextInteger(3, 5) do
							local dx = random:NextNumber(-0.6, 0.6)
							local length = random:NextNumber(1, 4.5)
							local width = random:NextNumber(0.05, 0.13)
							P(ev.folder, "WallDrip", V(width, length, 0.03), CFrame.new(cx + dx, top - length / 2, wz), MID)
							local bead = P(ev.folder, "WallDripBead", V(width * 1.9, width * 2.4, 0.05), CFrame.new(cx + dx, top - length, wz), DARK)
							Instance.new("SpecialMesh", bead).MeshType = Enum.MeshType.Sphere
						end
					end
				end
			else
				ev.folder:ClearAllChildren()
			end
		elseif kind == "crowd" then
			if on then
				local random = Random.new(floor * 53)
				for i = 1, 7 do
					local x = -25 + i * 6 + random:NextNumber(-1.5, 1.5)
					local z = random:NextNumber(-HALF + 1.5, HALF - 1.5)
					local figure = Animals.build({ id = 900 + i, name = "?", animal = Animals.List[random:NextInteger(1, #Animals.List)], fur = rgb(10, 9, 12), cloth = rgb(10, 9, 12) }, nil)
					for _, d in ipairs(figure:GetDescendants()) do
						if d:IsA("BasePart") then
							d.CanCollide = false
							d.CanQuery = false
							local name = d.Name
							if name == "EyeWhite" or name == "Iris" or name == "Pupil" or name == "EyeShine" then
								d.Color = rgb(255, 20, 20)
								d.Material = Mat.Neon
							else
								d.Color = rgb(10, 9, 12)
							end
						end
					end
					-- 천장에 발이 붙은 채 거꾸로 매달려서, 엘리베이터 쪽(오는 사람)을 바라봐요.
					local ceiling = y + WALL_H
					figure:PivotTo(CFrame.lookAt(V(x, ceiling, z), V(30, ceiling, z)) * CFrame.Angles(0, 0, math.pi))
					figure.Parent = ev.folder
				end
			else
				ev.folder:ClearAllChildren()
			end
		elseif kind == "eyes" then
			for _, v in ipairs(api.vases) do
				if v.floor == floor then
					drawVase(v, on and "eyes" or "normal")
				end
			end
		elseif kind == "red" then
			for _, bulb in ipairs(lampsOn(floor)) do
				bulb.Color = on and rgb(230, 20, 20) or WARM
				local light = bulb:FindFirstChildWhichIsA("Light")
				if light then
					light.Color = on and rgb(255, 20, 20) or WARM
					light.Brightness = on and 1.4 or (bulb.Name == "LoungeChandelier" and 0.9 or 0.7)
				end
			end
		elseif kind == "doors" then
			if on then
				ev.doorPivots = {}
				for _, room in pairs(api.rooms) do
					if room.floor == floor then
						ev.doorPivots[room] = room.door:GetPivot()
						api.openDoor(room, 80)
					end
				end
			else
				for room, pivot in pairs(ev.doorPivots or {}) do
					room.door:PivotTo(pivot)
				end
				ev.doorPivots = nil
			end
		elseif kind == "flip" then
			-- 복도 한가운데 높이를 축으로 180도 돌려요. (두 번 돌리면 제자리)
			local mid = CFrame.new(0, y + WALL_H / 2, 0)
			local turn = mid * CFrame.Angles(math.pi, 0, 0) * mid:Inverse()
			if on then
				ev.flipped = flipParts(floor)
			end
			for _, part in ipairs(ev.flipped or {}) do
				part.CFrame = turn * part.CFrame
			end
			if not on then
				ev.flipped = nil
			end
		end
	end

	-- 층 전체 이상을 바꿔요. ("normal" 이면 원래대로)
	function api.setEvent(floor, kind)
		local ev = api.events[floor]
		if not ev or ev.kind == kind then
			return
		end
		if ev.kind ~= "normal" then
			applyEvent(ev, ev.kind, false)
		end
		if kind ~= "normal" then
			applyEvent(ev, kind, true)
		end
		ev.kind = kind
	end

	api.resetAll()
	return api
end

return Floors
