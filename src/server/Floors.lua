-- 2층~4층 객실 복도를 만들어요. (밤 순찰과 룸서비스 배달을 하는 곳)
-- 1층 로비처럼 꾸몄어요: 청록 줄무늬 벽지, 원목 벽판, 대리석 바닥, 빨간 러너 카펫.
-- 층마다 긴 복도 양쪽에 객실 문이 6개씩 (01~12호), 복도 끝과 양쪽 벽에 커다란 거울이 있어요.
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

Floors.List = FLOOR_LIST
-- 복도 이상의 이름 (아침 보고서의 "새로운 이상" 소식에 써요)
Floors.EventNames = {
	blood = "바닥에 흐르는 피의 강",
	eyes = "꽃 대신 눈알이 핀 꽃병",
	flip = "천장과 바닥이 뒤집힌 복도",
	red = "새빨갛게 물든 조명",
	doors = "한꺼번에 활짝 열린 객실 문",
	crowd = "천장에 거꾸로 매달린 검은 형체들",
	giant = "복도 끝에서 들여다보는 거대한 얼굴",
	balloons = "복도에 가득 떠 있는 빨간 풍선",
	flood = "출렁이는 검은 물에 잠긴 복도",
	fish = "물고기가 헤엄쳐 날아다니는 복도",
	forest = "밤의 숲으로 변한 복도",
	space = "별이 가득한 우주 공간이 된 복도",
	mirror = "거울 속 내가 이상한 복도",
}

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

---------------------------------------------------------------- 거울 (복도 끝 + 양쪽 벽에 하나씩, 층마다 세 개)
-- 로블록스에는 진짜 거울이 없어서, 거울 뒤쪽 빈 공간에 거울 앞의 복도와 사람을
-- 뒤집어 똑같이 만들어 보여 줘요. (Mirror.client.lua 가 각 화면에서 그려요)
local MIRROR_BOTTOM, MIRROR_TOP = 0.6, 9
local END_MIRROR_W, SIDE_MIRROR_W = 4, 3

-- 금빛 액자와 유리. faceCF: 벽 앞면, 거울 높이 가운데, 복도 쪽을 바라봐요.
local function makeMirror(parent, faceCF, width, settings)
	local h = MIRROR_TOP - MIRROR_BOTTOM
	for _, sx in ipairs({ -1, 1 }) do
		P(parent, "MirrorFrame", V(0.35, h + 0.7, 0.45), faceCF * CFrame.new(sx * (width / 2 + 0.1), 0, -0.05), BRASS, Mat.Metal)
		P(parent, "MirrorFrame", V(width + 0.55, 0.35, 0.45), faceCF * CFrame.new(0, sx * (h / 2 + 0.1), -0.05), BRASS, Mat.Metal)
	end
	local crest = P(parent, "MirrorFrame", V(0.9, 0.9, 0.9), faceCF * CFrame.new(0, h / 2 + 0.55, -0.05), BRASS, Mat.Metal)
	crest.Shape = Enum.PartType.Ball
	-- 유리: 앞면이 거울 면이에요. 부딪혀서 거울 속으로 들어갈 수는 없어요.
	local glass = Props.solid(parent, "MirrorGlass", V(width, h, 0.1), faceCF * CFrame.new(0, 0, 0.1), rgb(205, 220, 230), Mat.Glass, {
		Transparency = 0.88,
		Reflectance = 0.05,
	})
	for key, value in pairs(settings) do
		glass:SetAttribute(key, value)
	end
	glass:SetAttribute("MirrorHeight", WALL_H + 1)
	return glass
end

-- 복도 끝 벽: 가운데에 거울 구멍을 남기고 벽을 세워요.
local function buildMirrorWall(level, y, floor, api)
	local wallX = -29.15
	local W = END_MIRROR_W
	for _, side in ipairs({ -1, 1 }) do
		local width = HALF - W / 2
		local z = side * (W / 2 + width / 2)
		Props.solid(level, "WestEnd", V(0.5, WALL_H, width), V(wallX, y + WALL_H / 2, z), TEAL, Mat.Fabric)
		dressWall(level, CFrame.lookAt(V(-28.9, y, z), V(-27.9, y, z)), width, WALL_H)
	end
	local topH = WALL_H - MIRROR_TOP
	Props.solid(level, "WestEnd", V(0.5, topH, W), V(wallX, y + MIRROR_TOP + topH / 2, 0), TEAL, Mat.Fabric)
	P(level, "Crown", V(0.5, 0.7, W), V(-29.15, y + WALL_H - 0.35, 0), WOOD_DARK, Mat.Wood)
	Props.solid(level, "WestEnd", V(0.5, MIRROR_BOTTOM, W), V(wallX, y + MIRROR_BOTTOM / 2, 0), WOOD_DARK, Mat.Wood)
	local midY = y + (MIRROR_TOP + MIRROR_BOTTOM) / 2
	table.insert(api.mirrors[floor], makeMirror(level, CFrame.lookAt(V(-28.9, midY, 0), V(-27.9, midY, 0)), W, {
		MirrorDepth = 26, -- 거울 앞 이만큼까지 비춰요
		MirrorHalfWidth = HALF + 1,
		MirrorHide = true, -- 거울 뒤 건물 바깥벽은 안 보이게
	}))
end

-- 양쪽 벽 거울: 엘리베이터에서 복도를 바라볼 때 오른쪽 벽 앞쪽, 왼쪽 벽 뒤쪽
local SIDE_MIRRORS = { [-1] = 14, [1] = -18 }

-- 벽에 거울 구멍 (corridorWall 에서 불러요): 구멍 위아래만 벽을 채워요.
local function mirrorHole(parent, y, x, z, side)
	local W = SIDE_MIRROR_W
	local topH = WALL_H - MIRROR_TOP
	Props.solid(parent, "CorridorWall", V(W, topH, 0.5), V(x, y + MIRROR_TOP + topH / 2, z + side * 0.25), TEAL, Mat.Fabric)
	P(parent, "Wallpaper", V(W, topH - 0.7, 0.15), V(x, y + MIRROR_TOP + (topH - 0.7) / 2, z - side * 0.075), TEAL, Mat.Fabric)
	P(parent, "Crown", V(W, 0.7, 0.5), V(x, y + WALL_H - 0.35, z - side * 0.25), WOOD_DARK, Mat.Wood)
	Props.solid(parent, "CorridorWall", V(W, MIRROR_BOTTOM, 0.5), V(x, y + MIRROR_BOTTOM / 2, z + side * 0.25), WOOD_DARK, Mat.Wood)
	P(parent, "Baseboard", V(W, 0.5, 0.4), V(x, y + 0.25, z - side * 0.2), WOOD_DARK, Mat.Wood)
end

local function buildSideMirrors(level, y, floor, api)
	local midY = y + (MIRROR_TOP + MIRROR_BOTTOM) / 2
	for side, x in pairs(SIDE_MIRRORS) do
		local z = side * HALF
		table.insert(api.mirrors[floor], makeMirror(level, CFrame.lookAt(V(x, midY, z), V(x, midY, z - side)), SIDE_MIRROR_W, {
			MirrorDepth = HALF * 2 + 1, -- 맞은편 벽까지
			MirrorHalfWidth = SIDE_MIRROR_W / 2 + 1.5,
			MirrorClip = true, -- 거울 뒤는 객실이라, 거울 너비 밖으로는 그리지 않아요
		}))
	end
end

-- 복도 벽 한 줄: 문 자리만 비워 두고 이어 붙여요.
local function corridorWall(parent, y, side)
	local z = side * HALF
	local cursor = -28.9
	for _, x in ipairs(DOOR_XS) do
		local mx = SIDE_MIRRORS[side]
		if mx and mx > cursor and mx < x then
			wallSegment(parent, y, cursor, mx - SIDE_MIRROR_W / 2, z, side)
			mirrorHole(parent, y, mx, z, side)
			cursor = mx + SIDE_MIRROR_W / 2
		end
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

local decoRandom = Random.new(2024)

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
		color = FLOWER_COLORS[decoRandom:NextInteger(1, #FLOWER_COLORS)],
		vaseColor = ({ rgb(40, 60, 55), rgb(60, 40, 50), rgb(200, 205, 210) })[decoRandom:NextInteger(1, 3)],
		kind = "normal",
		kinds = Floors.VaseKinds,
		draw = drawVase,
		what = "꽃병",
		whatObj = "꽃병을",
		whatIs = "꽃병이에요",
	}
	repeat
		v.altColor = FLOWER_COLORS[decoRandom:NextInteger(1, #FLOWER_COLORS)]
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

	local api = { elevatorLamps = {}, List = FLOOR_LIST, rooms = {}, exits = {}, elevatorPrompts = {}, figures = {}, portraits = {}, vases = {}, events = {}, levels = {}, lamps = {}, signs = {}, chairs = {}, chandeliers = {}, mirrors = {} }
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
		api.mirrors[floor] = {}
		buildMirrorWall(level, y, floor, api)
		buildSideMirrors(level, y, floor, api)

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

		-- 꽃병과 탁자 (숲·우주 복도에서는 통째로 숨겨요)
		local portraits = Instance.new("Folder")
		portraits.Name = "Portraits"
		portraits.Parent = level
		-- 벽 앞 탁자 위 꽃병 (층마다 3개)
		for _, spotInfo in ipairs({ { -18, -1 }, { -2, -1 }, { 14, 1 } }) do
			local top = consoleTable(portraits, spotInfo[1], y, spotInfo[2])
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
	-- giant: 복도 끝에서 거대한 도플갱어 얼굴이 들여다봐요 / balloons: 빨간 풍선이 복도에 가득 떠 있어요 /
	-- flood: 복도가 검은 물에 잠기고 물건이 떠다녀요
	-- fish: 물고기 떼가 공중을 헤엄쳐 다녀요 / forest: 복도가 밤의 숲으로 변하고 객실 문만 남아요
	-- space: 복도가 별이 가득한 우주가 되고, 행성이 돌고 물건들이 무중력으로 떠다녀요
	-- mirror: 거울 속의 내가 뒤돌아 서 있거나, 아예 비치지 않아요
	api.EventKinds = { "blood", "eyes", "flip", "red", "doors", "crowd", "giant", "balloons", "flood", "fish", "forest", "space", "mirror" }

	-- 움직이는 이상(출렁이는 물, 헤엄치는 물고기, 반딧불): 그 이상이 사라지면 저절로 멈춰요.
	local function animate(ev, step)
		ev.anim = (ev.anim or 0) + 1
		local token = ev.anim
		step(0) -- 처음 자리부터 바로 잡아 둬요
		task.spawn(function()
			local t = 0
			while ev.anim == token and ev.folder.Parent do
				t += task.wait(0.1)
				step(t)
			end
		end)
	end
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

	-- 숲·우주처럼 복도가 통째로 바뀔 때: 꽃병, 탁자와 복도 등을 치우고 객실 문만 남겨요.
	local function emptyCorridor(ev, floor)
		local deco = api.levels[floor]:FindFirstChild("Portraits")
		if deco then
			ev.hiddenDeco = deco
			deco.Parent = nil
		end
		for _, bulb in ipairs(lampsOn(floor)) do
			local l = bulb:FindFirstChildWhichIsA("Light")
			if l then
				l.Enabled = false
			end
			bulb.Transparency = 1
		end
	end
	local function restoreCorridor(ev, floor)
		if ev.hiddenDeco then
			ev.hiddenDeco.Parent = api.levels[floor]
			ev.hiddenDeco = nil
		end
		for _, bulb in ipairs(lampsOn(floor)) do
			local l = bulb:FindFirstChildWhichIsA("Light")
			if l then
				l.Enabled = true
			end
			bulb.Transparency = 0
		end
	end
	-- 벽 앞을 덮는 판 (문 자리만 비워요)
	local function coverWalls(ev, y, color, material)
		for _, side in ipairs({ -1, 1 }) do
			local from = -28.9
			local function cover(to)
				if to - from > 0.1 then
					P(ev.folder, "WallCover", V(to - from, WALL_H, 0.1), V((from + to) / 2, y + WALL_H / 2, side * (HALF - 0.45)), color, material)
				end
			end
			for _, dx in ipairs(DOOR_XS) do
				cover(dx - DOOR_W / 2 - 0.4)
				from = dx + DOOR_W / 2 + 0.4
				-- 문 위쪽 벽도 덮어요
				local h = WALL_H - DOOR_H - 0.5
				P(ev.folder, "WallCover", V(DOOR_W + 0.8, h, 0.1), V(dx, y + DOOR_H + 0.5 + h / 2, side * (HALF - 0.45)), color, material)
			end
			cover(LOUNGE_X - 0.5)
		end
		P(ev.folder, "WallCover", V(0.1, WALL_H, HALF * 2), V(-28.4, y + WALL_H / 2, 0), color, material)
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
			-- 복도가 붉은 빛으로 물들어요: 모든 등이 빨갛게, 빨간 빛을 조금 더 달아요. (앞이 잘 보일 정도로만)
			for _, bulb in ipairs(lampsOn(floor)) do
				bulb.Color = on and rgb(230, 30, 30) or WARM
				local light = bulb:FindFirstChildWhichIsA("Light")
				if light then
					if on then
						light:SetAttribute("NormalRange", light.Range)
					end
					light.Color = on and rgb(255, 40, 30) or WARM
					light.Brightness = on and 1.6 or (bulb.Name == "LoungeChandelier" and 0.9 or 0.7)
					light.Range = on and 18 or (light:GetAttribute("NormalRange") or light.Range)
				end
			end
			if on then
				-- 빨간 빛을 조금 더 달아요.
				for x = -24, 24, 8 do
					local glowPart = P(ev.folder, "RedGlow", V(0.5, 0.5, 0.5), V(x, y + WALL_H - 1, 0), rgb(255, 0, 0), Mat.Neon, { Transparency = 1 })
					local red = Instance.new("PointLight")
					red.Color = rgb(255, 40, 30)
					red.Range = 14
					red.Brightness = 1
					red.Shadows = false
					red.Parent = glowPart
				end
			else
				ev.folder:ClearAllChildren()
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
		elseif kind == "giant" then
			ev.anim = (ev.anim or 0) + 1
			if on then
				-- 서쪽 끝 벽을 뚫고 거대한 얼굴이 복도를 꽉 채운 채 이쪽을 들여다봐요.
				local face = Animals.build({ id = 7000 + floor, name = "?", animal = Animals.List[(floor % #Animals.List) + 1], fur = rgb(235, 225, 215), cloth = rgb(40, 30, 30) }, floor % 2 == 0 and "mouth" or "eyes")
				for _, d in ipairs(face:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CanCollide = false
						d.CanQuery = false
					end
				end
				local headGroup = face:FindFirstChild("HeadGroup")
				if headGroup then
					headGroup.Parent = ev.folder
					face:Destroy()
					pcall(function()
						headGroup:ScaleTo(headGroup:GetScale() * 3)
					end)
					headGroup:PivotTo(CFrame.lookAt(V(-25.5, y + 5.4, 0), V(30, y + 5.4, 0)))
				else
					face.Parent = ev.folder
				end
			else
				ev.folder:ClearAllChildren()
			end
		elseif kind == "balloons" then
			if on then
				-- 빨간 풍선이 천장 가득 떠 있고, 끈이 축 늘어져 있어요. 몇 개는 웃는 얼굴이 그려져 있어요.
				local random = Random.new(floor * 97)
				for _ = 1, 34 do
					local pos = V(random:NextNumber(-27, 26), y + random:NextNumber(6.5, 10.5), random:NextNumber(-HALF + 1, HALF - 1))
					local balloon = P(ev.folder, "Balloon", V(1.3, 1.6, 1.3), CFrame.new(pos), rgb(200, 15, 25), Mat.SmoothPlastic, { Reflectance = 0.2 })
					Instance.new("SpecialMesh", balloon).MeshType = Enum.MeshType.Sphere
					P(ev.folder, "BalloonKnot", V(0.18, 0.18, 0.18), CFrame.new(pos - V(0, 0.85, 0)), rgb(150, 10, 15))
					local length = random:NextNumber(2.5, 5)
					P(ev.folder, "BalloonString", V(0.04, length, 0.04), CFrame.new(pos - V(0, 0.9 + length / 2, 0)), rgb(235, 235, 230))
					if random:NextNumber() < 0.35 then
						-- 복도 쪽을 보는 하얀 웃는 얼굴
						local look = CFrame.lookAt(pos, pos + V(1, 0, 0)) * CFrame.new(0, 0, -0.64)
						for _, dx in ipairs({ -0.22, 0.22 }) do
							local eye = P(ev.folder, "BalloonEye", V(0.16, 0.22, 0.03), look * CFrame.new(dx, 0.2, 0), rgb(250, 250, 245))
							Instance.new("SpecialMesh", eye).MeshType = Enum.MeshType.Sphere
						end
						for i = -2, 2 do
							P(ev.folder, "BalloonSmile", V(0.14, 0.05, 0.03), look * CFrame.new(i * 0.12, -0.2 + math.abs(i) * 0.05, 0) * CFrame.Angles(0, 0, i * 0.35), rgb(250, 250, 245))
						end
					end
				end
			else
				ev.folder:ClearAllChildren()
			end
		elseif kind == "flood" then
			if on then
				-- 무릎까지 차오른 검은 물 (걸어 다닐 수 있어요). 의자와 꽃병 꽃, 신발이 둥둥 떠 있어요.
				local length = LOUNGE_X + 28.9
				local midX = (LOUNGE_X - 28.9) / 2
				P(ev.folder, "BlackWater", V(length, 1.6, HALF * 2 - 0.1), V(midX, y + 0.8, 0), rgb(6, 7, 12), Mat.Glass, { Transparency = 0.04, Reflectance = 0.5 })
				P(ev.folder, "BlackWater", V(28.9 - LOUNGE_X, 1.6, LOUNGE_HALF * 2 - 0.1), V((LOUNGE_X + 28.9) / 2, y + 0.8, 0), rgb(6, 7, 12), Mat.Glass, { Transparency = 0.04, Reflectance = 0.5 })
				local random = Random.new(floor * 13)
				for _ = 1, 14 do
					local pos = V(random:NextNumber(-26, 24), y + 1.65, random:NextNumber(-HALF + 1, HALF - 1))
					local roll = random:NextNumber()
					if roll < 0.4 then
						P(ev.folder, "FloatingShoe", V(0.5, 0.35, 1), CFrame.new(pos) * CFrame.Angles(0, random:NextNumber(0, 6), 0.2), rgb(40, 28, 22), Mat.Leather)
					elseif roll < 0.7 then
						local flower = P(ev.folder, "FloatingFlower", V(0.45, 0.45, 0.45), CFrame.new(pos), rgb(240, 170, 190))
						flower.Shape = Enum.PartType.Ball
					else
						P(ev.folder, "FloatingBook", V(1, 0.15, 0.7), CFrame.new(pos) * CFrame.Angles(0, random:NextNumber(0, 6), 0), rgb(110, 30, 30))
					end
				end
				-- 물결: 물이 천천히 출렁이고, 떠 있는 물건도 같이 둥실거려요.
				local bobbing = {}
				for _, part in ipairs(ev.folder:GetChildren()) do
					if part:IsA("BasePart") then
						table.insert(bobbing, { part = part, home = part.CFrame, phase = part.Position.X * 0.4, water = part.Name == "BlackWater" })
					end
				end
				-- 물 위 잔물결 (밝은 줄무늬가 오락가락해요)
				local ripples = {}
				for i = 1, 10 do
					local ripple = P(ev.folder, "Ripple", V(0.15, 0.03, HALF * 2 - 0.6), CFrame.new(-27 + i * 4.8, y + 1.62, 0), rgb(70, 80, 100), Mat.Neon, { Transparency = 0.6 })
					table.insert(ripples, { part = ripple, x = -27 + i * 4.8 })
				end
				animate(ev, function(t)
					for _, b in ipairs(bobbing) do
						local wave = math.sin(t * 1.6 + b.phase)
						if b.water then
							b.part.CFrame = b.home * CFrame.new(0, wave * 0.18, 0) * CFrame.Angles(wave * 0.004, 0, math.cos(t * 1.3) * 0.004)
						else
							b.part.CFrame = b.home * CFrame.new(0, wave * 0.2, 0) * CFrame.Angles(wave * 0.15, t * 0.05, math.cos(t + b.phase) * 0.12)
						end
					end
					for _, r in ipairs(ripples) do
						local x = ((r.x + 27 + t * 2.2) % 48) - 27
						r.part.CFrame = CFrame.new(x, y + 1.62 + math.sin(t * 1.6 + x * 0.4) * 0.18, 0)
					end
				end)
				-- 물속에서 떠오르는 검은 손 (움직이지 않아요)
				for i = 1, 4 do
					local arm = CFrame.new(-22 + i * 10, y + 2, random:NextNumber(-2, 2)) * CFrame.Angles(0, 0, random:NextNumber(-0.3, 0.3))
					P(ev.folder, "DrownedArm", V(0.4, 1.4, 0.4), arm, rgb(15, 15, 18))
					local hand = P(ev.folder, "DrownedHand", V(0.6, 0.7, 0.3), arm * CFrame.new(0, 0.9, 0), rgb(15, 15, 18))
					Instance.new("SpecialMesh", hand).MeshType = Enum.MeshType.Sphere
				end
			else
				ev.folder:ClearAllChildren()
			end
		elseif kind == "fish" then
			if on then
				-- 물고기 떼가 공중을 헤엄쳐 다녀요. 알록달록한 열대어, 커다란 잉어, 해파리까지.
				local random = Random.new(floor * 41)
				local COLORS = { rgb(255, 150, 40), rgb(80, 170, 255), rgb(255, 220, 60), rgb(240, 100, 150), rgb(120, 220, 190), rgb(250, 250, 245) }
				local swimmers = {}
				for i = 1, 16 do
					local fish = Instance.new("Model")
					fish.Name = "FlyingFish"
					local big = i <= 3
					local scale = big and 2.2 or random:NextNumber(0.8, 1.3)
					local color = big and rgb(240, 120, 40) or COLORS[random:NextInteger(1, #COLORS)]
					local body = P(fish, "FishBody", V(0.7, 0.9, 1.8) * scale, CFrame.new(), color, Mat.SmoothPlastic, { Reflectance = 0.15 })
					Instance.new("SpecialMesh", body).MeshType = Enum.MeshType.Sphere
					fish.PrimaryPart = body
					-- 꼬리는 마름모를 반쯤 몸에 묻어서 부채꼴처럼, 등지느러미도 작은 마름모, 그리고 눈
					local finColor = color:Lerp(rgb(255, 255, 255), 0.25)
					P(fish, "FishTail", V(0.08, 0.75, 0.75) * scale, CFrame.new(0, 0, 1.05 * scale) * CFrame.Angles(math.rad(45), 0, 0), finColor)
					P(fish, "FishFin", V(0.06, 0.4, 0.4) * scale, CFrame.new(0, 0.42 * scale, 0.15 * scale) * CFrame.Angles(math.rad(45), 0, 0), finColor)
					for _, side in ipairs({ -1, 1 }) do
						local eye = P(fish, "FishEye", V(0.22, 0.22, 0.22) * scale, CFrame.new(side * 0.32 * scale, 0.12 * scale, -0.55 * scale), rgb(250, 250, 250))
						eye.Shape = Enum.PartType.Ball
						local pupil = P(fish, "FishPupil", V(0.12, 0.12, 0.12) * scale, CFrame.new(side * 0.4 * scale, 0.12 * scale, -0.6 * scale), rgb(10, 10, 15))
						pupil.Shape = Enum.PartType.Ball
					end
					fish.Parent = ev.folder
					table.insert(swimmers, {
						model = fish,
						x = random:NextNumber(-27, 26),
						dir = random:NextNumber() < 0.5 and -1 or 1,
						speed = random:NextNumber(1.5, 3.5) / (big and 1.6 or 1),
						height = random:NextNumber(3, 9.5),
						lane = random:NextNumber(-HALF + 1.5, HALF - 1.5),
						phase = random:NextNumber(0, 6.28),
					})
				end
				-- 둥실둥실 해파리 (위아래로만 천천히)
				for i = 1, 4 do
					local jelly = P(ev.folder, "Jellyfish", V(1.6, 1.1, 1.6), CFrame.new(-20 + i * 9, y + 8, (i % 2 == 0) and 2 or -2), rgb(200, 170, 255), Mat.Neon, { Transparency = 0.45 })
					Instance.new("SpecialMesh", jelly).MeshType = Enum.MeshType.Sphere
					table.insert(swimmers, { jelly = jelly, home = jelly.CFrame, phase = i })
				end
				animate(ev, function(t)
					for _, f in ipairs(swimmers) do
						if f.jelly then
							f.jelly.CFrame = f.home * CFrame.new(0, math.sin(t * 0.8 + f.phase) * 1.2, 0)
						else
							f.x += f.dir * f.speed * 0.1
							if f.x > 27 or f.x < -27 then
								f.dir = -f.dir -- 벽 끝에서 휙 돌아서요
							end
							local z = f.lane + math.sin(t * 0.9 + f.phase) * 1.2
							local h = y + f.height + math.sin(t * 1.3 + f.phase) * 0.6
							local pos = V(f.x, h, z)
							local wiggle = math.sin(t * 8 + f.phase) * 0.25 -- 꼬리를 살랑살랑
							f.model:PivotTo(CFrame.lookAt(pos, pos + V(f.dir, 0, math.cos(t * 0.9 + f.phase) * 0.3)) * CFrame.Angles(0, wiggle, 0))
						end
					end
				end)
			else
				ev.anim = (ev.anim or 0) + 1
				ev.folder:ClearAllChildren()
			end
		elseif kind == "forest" then
			if on then
				-- 밤의 숲: 바닥은 풀밭, 벽 앞은 빽빽한 나무줄기, 천장은 나뭇잎. 객실 문들만 숲속에 덩그러니 서 있어요.
				local random = Random.new(floor * 59)
				local length = LOUNGE_X + 28.9
				local midX = (LOUNGE_X - 28.9) / 2
				P(ev.folder, "ForestGrass", V(length, 0.3, HALF * 2 - 0.1), V(midX, y + 0.2, 0), rgb(40, 70, 35), Mat.Grass)
				P(ev.folder, "ForestPath", V(length, 0.31, 2.2), V(midX, y + 0.21, 0), rgb(70, 55, 40), Mat.Ground)
				-- 천장을 덮은 나뭇잎
				for x = -28, 20, 2.4 do
					for _, z in ipairs({ -3.2, 0, 3.2 }) do
						local leaf = P(ev.folder, "Canopy", V(4, 2.2, 4) * random:NextNumber(0.8, 1.2), CFrame.new(x + random:NextNumber(-0.5, 0.5), y + WALL_H - 0.9, z), random:NextNumber() < 0.5 and rgb(25, 50, 30) or rgb(35, 65, 35), Mat.Grass)
						leaf.Shape = Enum.PartType.Ball
					end
				end
				-- 벽 앞에 늘어선 나무줄기 (문 자리는 비워 둬요)
				local function nearDoor(x)
					for _, dx in ipairs(DOOR_XS) do
						if math.abs(x - dx) < DOOR_W / 2 + 0.6 then
							return true
						end
					end
					return false
				end
				-- 나무 사이로 보이는 건 벽지 대신 깜깜한 숲속이에요. (문 자리만 비워요)
				coverWalls(ev, y, rgb(16, 34, 20), Mat.Grass)
				P(ev.folder, "ForestSky", V(length, 0.1, HALF * 2), V(midX, y + WALL_H - 0.7, 0), rgb(8, 12, 24)) -- 천장 대신 밤하늘
				for _, side in ipairs({ -1, 1 }) do
					local x = -28.3
					while x < LOUNGE_X - 0.5 do
						if not nearDoor(x) then
							local width = random:NextNumber(0.9, 1.5)
							local trunk = P(ev.folder, "TreeTrunk", V(WALL_H, width, width), CFrame.new(x, y + WALL_H / 2, side * (HALF - 0.7) + random:NextNumber(-0.2, 0.2)) * CFrame.Angles(0, 0, math.rad(90)), random:NextNumber() < 0.5 and rgb(55, 40, 30) or rgb(45, 35, 28), Mat.Wood)
							trunk.Shape = Enum.PartType.Cylinder
							-- 뿌리
							P(ev.folder, "TreeRoot", V(0.35, 0.3, 1.2), CFrame.new(x, y + 0.35, side * (HALF - 1.3)) * CFrame.Angles(0.3 * side, random:NextNumber(-0.5, 0.5), 0), rgb(50, 38, 28), Mat.Wood)
							-- 나무줄기를 감고 올라가는 담쟁이
							if random:NextNumber() < 0.6 then
								local trunkPos = V(x, 0, trunk.Position.Z)
								for k = 0, 13 do
									local angle = k * 0.9 + random:NextNumber(0, 0.4)
									local d = V(math.cos(angle), 0, math.sin(angle))
									local pos = V(trunkPos.X, y + 0.6 + k * 0.75, trunkPos.Z) + d * (width / 2 + 0.03)
									local l = P(ev.folder, "TrunkIvy", V(0.5, 0.4, 0.08), CFrame.lookAt(pos, pos + d) * CFrame.Angles(0, 0, random:NextNumber(0, 6.28)), random:NextNumber() < 0.5 and rgb(40, 90, 40) or rgb(60, 115, 50), Mat.Grass)
									Instance.new("SpecialMesh", l).MeshType = Enum.MeshType.Sphere
								end
							end
							x += width + random:NextNumber(0.2, 0.7)
						else
							x += 0.5
						end
					end
				end
				-- 벽을 뒤덮은 잎사귀 (여러 가지 초록색, 이리저리 돌아간 타원 잎)
				local GREENS = { rgb(30, 70, 35), rgb(45, 95, 45), rgb(25, 55, 30), rgb(60, 110, 50), rgb(35, 80, 55) }
				local function leaf(pos, size, side, color)
					local l = P(ev.folder, "WallLeaf", size, CFrame.lookAt(pos, pos - V(0, 0, side)) * CFrame.Angles(0, 0, random:NextNumber(0, math.pi * 2)), color, Mat.Grass)
					Instance.new("SpecialMesh", l).MeshType = Enum.MeshType.Sphere
					return l
				end
				for _, side in ipairs({ -1, 1 }) do
					local wallZ = side * (HALF - 0.52)
					for _ = 1, 420 do
						local x = random:NextNumber(-28.5, LOUNGE_X - 0.8)
						local h = random:NextNumber(0.3, WALL_H - 0.5)
						if not nearDoor(x) or h > DOOR_H + 0.9 then
							local s = random:NextNumber(0.9, 1.7)
							leaf(V(x, y + h, wallZ - side * random:NextNumber(0, 0.12)), V(s, s * 0.5, 0.12), side, GREENS[random:NextInteger(1, #GREENS)])
						end
					end
					-- 위에서 늘어진 담쟁이 덩굴: 구불구불한 줄기에 하트 모양 잎이 조롱조롱
					for _ = 1, 16 do
						local x = random:NextNumber(-28, LOUNGE_X - 1)
						if not nearDoor(x) then
							local z = side * (HALF - 0.75)
							local top = y + WALL_H - 0.6
							local length = random:NextNumber(4, 10)
							local prev = V(x, top, z)
							local seg = 0.8
							for k = 1, math.floor(length / seg) do
								local nextPos = V(x + math.sin(k * 0.9) * 0.35, top - k * seg, z)
								local mid = (prev + nextPos) / 2
								P(ev.folder, "IvyVine", V(0.07, 0.07, seg + 0.05), CFrame.lookAt(mid, nextPos), rgb(55, 75, 35), Mat.Wood)
								for _, dx in ipairs({ -1, 1 }) do
									leaf(nextPos + V(dx * 0.22, 0.05, -side * 0.05), V(0.42, 0.36, 0.08), side, GREENS[random:NextInteger(1, #GREENS)])
								end
								prev = nextPos
							end
						end
					end
				end
				-- 문틀 위로 넘어온 덩굴 잎 몇 장 (문만 덩그러니 남은 느낌)
				for _, dx in ipairs(DOOR_XS) do
					for _, side in ipairs({ -1, 1 }) do
						for k = 1, 3 do
							local pos = V(dx + (k - 2) * 1.1 + random:NextNumber(-0.3, 0.3), y + 8.4 + random:NextNumber(0, 0.5), side * (HALF - 0.6))
							leaf(pos, V(0.6, 0.45, 0.1), side, GREENS[random:NextInteger(1, #GREENS)])
						end
					end
				end
				-- 버섯과 덤불
				for _ = 1, 14 do
					local pos = V(random:NextNumber(-27, 20), y + 0.35, random:NextNumber(-HALF + 1.4, HALF - 1.4))
					if random:NextNumber() < 0.5 then
						P(ev.folder, "MushroomStem", V(0.18, 0.4, 0.18), CFrame.new(pos + V(0, 0.2, 0)), rgb(235, 225, 205))
						local cap = P(ev.folder, "MushroomCap", V(0.6, 0.3, 0.6), CFrame.new(pos + V(0, 0.45, 0)), rgb(200, 40, 40))
						Instance.new("SpecialMesh", cap).MeshType = Enum.MeshType.Sphere
					else
						local bush = P(ev.folder, "Bush", V(1.4, 1, 1.4), CFrame.new(pos + V(0, 0.3, 0)), rgb(30, 60, 32), Mat.Grass)
						bush.Shape = Enum.PartType.Ball
					end
				end
				-- 푸른 달빛과 반딧불
				for x = -24, 18, 10 do
					local moon = P(ev.folder, "MoonLight", V(0.3, 0.3, 0.3), V(x, y + WALL_H - 2.5, 0), rgb(150, 180, 255), Mat.Neon, { Transparency = 1 })
					local light = Instance.new("PointLight")
					light.Color = rgb(140, 170, 255)
					light.Range = 16
					light.Brightness = 1
					light.Parent = moon
				end
				local flies = {}
				for i = 1, 24 do
					local home = V(random:NextNumber(-27, 20), y + random:NextNumber(1.5, 6), random:NextNumber(-HALF + 1.2, HALF - 1.2))
					local fly = P(ev.folder, "Firefly", V(0.16, 0.16, 0.16), CFrame.new(home), rgb(220, 255, 120), Mat.Neon)
					fly.Shape = Enum.PartType.Ball
					table.insert(flies, { part = fly, home = home, phase = i * 0.7 })
				end
				animate(ev, function(t)
					for _, f in ipairs(flies) do
						local p = f.phase
						f.part.CFrame = CFrame.new(f.home + V(math.sin(t * 0.7 + p) * 0.8, math.sin(t * 1.1 + p) * 0.5, math.cos(t * 0.6 + p) * 0.6))
						f.part.Transparency = (math.sin(t * 2 + p) > 0.3) and 0 or 0.8 -- 깜빡깜빡
					end
				end)
				emptyCorridor(ev, floor) -- 꽃병·복도 등은 사라지고 객실 문만 남아요 (숲은 달빛만)
			else
				ev.anim = (ev.anim or 0) + 1
				ev.folder:ClearAllChildren()
				restoreCorridor(ev, floor)
			end
		elseif kind == "mirror" then
			-- 거울 속 내가 이상해요: 뒤돌아 서 있거나, 아예 비치지 않아요. (복도 끝까지 가서 거울을 봐야 알아요)
			local strange = on and (math.random() < 0.5 and "back" or "none") or nil
			for _, glass in ipairs(api.mirrors[floor] or {}) do
				glass:SetAttribute("Strange", strange)
			end
		elseif kind == "space" then
			if on then
				-- 우주 복도: 벽, 바닥, 천장이 모두 별이 빛나는 깜깜한 우주가 되고, 객실 문만 둥실 떠 있어요.
				-- 행성과 달이 천천히 돌고, 호텔 물건들이 무중력으로 떠다니고, 가끔 별똥별이 지나가요.
				local random = Random.new(floor * 73)
				local length = LOUNGE_X + 28.9
				local midX = (LOUNGE_X - 28.9) / 2
				local SPACE = rgb(6, 6, 18)
				coverWalls(ev, y, SPACE, Mat.SmoothPlastic)
				P(ev.folder, "SpaceFloor", V(length, 0.3, HALF * 2 - 0.1), V(midX, y + 0.2, 0), rgb(3, 3, 10), Mat.Glass, { Reflectance = 0.1 })
				P(ev.folder, "SpaceSky", V(length, 0.1, HALF * 2), V(midX, y + WALL_H - 0.7, 0), SPACE)
				-- 발밑의 길: 희미하게 빛나는 두 줄
				for _, side in ipairs({ -1, 1 }) do
					P(ev.folder, "SpacePath", V(length, 0.05, 0.08), V(midX, y + 0.37, side * 1.4), rgb(90, 140, 255), Mat.Neon, { Transparency = 0.3 })
				end
				-- 사방에 뿌려진 별 (벽, 천장, 바닥)
				local STAR_COLORS = { rgb(255, 255, 255), rgb(200, 220, 255), rgb(255, 240, 190), rgb(255, 200, 230) }
				local stars = {}
				for i = 1, 260 do
					local where = random:NextNumber()
					local x = random:NextNumber(-28.6, LOUNGE_X - 0.6)
					local pos
					if where < 0.6 then
						local side = random:NextNumber() < 0.5 and -1 or 1
						pos = V(x, y + random:NextNumber(0.5, WALL_H - 0.8), side * (HALF - 0.52))
					elseif where < 0.85 then
						pos = V(x, y + WALL_H - 0.77, random:NextNumber(-HALF + 0.5, HALF - 0.5))
					else
						pos = V(x, y + 0.36, random:NextNumber(-HALF + 0.5, HALF - 0.5))
					end
					local size = random:NextNumber() < 0.1 and 0.16 or random:NextNumber(0.05, 0.1)
					local star = P(ev.folder, "Star", V(size, size, size), CFrame.new(pos), STAR_COLORS[random:NextInteger(1, #STAR_COLORS)], Mat.Neon)
					star.Shape = Enum.PartType.Ball
					if i % 4 == 0 then
						table.insert(stars, { part = star, phase = random:NextNumber(0, 6.28) })
					end
				end
				-- 보랏빛 성운 (흐릿한 큰 덩어리)
				for i = 1, 6 do
					local side = i % 2 == 0 and -1 or 1
					local cloud = P(ev.folder, "Nebula", V(random:NextNumber(4, 6), random:NextNumber(1.6, 2.4), 0.1), CFrame.new(-26 + i * 7.5, y + random:NextNumber(9.8, 10.8), side * (HALF - 0.55)), i % 3 == 0 and rgb(80, 160, 255) or rgb(170, 70, 220), Mat.Neon, { Transparency = 0.88 })
					Instance.new("SpecialMesh", cloud).MeshType = Enum.MeshType.Sphere
				end
				-- 고리가 있는 행성
				local ringed = V(-14, y + 8.5, 0)
				local planet = P(ev.folder, "Planet", V(3.6, 3.6, 3.6), CFrame.new(ringed), rgb(230, 160, 80), Mat.SmoothPlastic)
				planet.Shape = Enum.PartType.Ball
				local band = P(ev.folder, "PlanetBand", V(3.62, 0.5, 3.62), CFrame.new(ringed + V(0, 0.5, 0)), rgb(200, 120, 60), Mat.SmoothPlastic)
				Instance.new("SpecialMesh", band).MeshType = Enum.MeshType.Sphere
				local ring = P(ev.folder, "PlanetRing", V(0.05, 6.4, 6.4), CFrame.new(ringed) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(20), 0, 0), rgb(240, 210, 160), Mat.SmoothPlastic, { Transparency = 0.35 })
				ring.Shape = Enum.PartType.Cylinder
				-- 파란 지구 같은 행성과 구름
				local earthPos = V(8, y + 8, 0.5)
				local earth = P(ev.folder, "BluePlanet", V(2.6, 2.6, 2.6), CFrame.new(earthPos), rgb(50, 110, 220), Mat.SmoothPlastic)
				earth.Shape = Enum.PartType.Ball
				for k = 1, 5 do
					local d = V(math.cos(k * 1.3), math.sin(k * 2.1) * 0.6, math.sin(k * 1.3)).Unit
					local land = P(ev.folder, "PlanetLand", V(1, 0.7, 0.3), CFrame.lookAt(earthPos + d * 1.2, earthPos + d * 2), k % 2 == 0 and rgb(70, 160, 80) or rgb(240, 245, 250), Mat.SmoothPlastic)
					Instance.new("SpecialMesh", land).MeshType = Enum.MeshType.Sphere
				end
				-- 울퉁불퉁 달
				local moonPos = V(-24, y + 4, -2.5)
				local moon = P(ev.folder, "Moon", V(1.6, 1.6, 1.6), CFrame.new(moonPos), rgb(200, 200, 195), Mat.Slate)
				moon.Shape = Enum.PartType.Ball
				for k = 1, 4 do
					local d = V(math.cos(k * 1.7), math.sin(k * 2.3) * 0.7, math.sin(k * 1.7) + 0.3).Unit
					local crater = P(ev.folder, "Crater", V(0.45, 0.45, 0.12), CFrame.lookAt(moonPos + d * 0.76, moonPos + d * 2), rgb(150, 150, 148), Mat.Slate)
					Instance.new("SpecialMesh", crater).MeshType = Enum.MeshType.Sphere
				end
				-- 무중력으로 떠다니는 호텔 물건들 (트렁크, 의자, 찻잔, 베개)
				local floaters = {}
				local function floater(name, size, color, pos)
					local part = P(ev.folder, name, size, CFrame.new(pos), color, Mat.SmoothPlastic)
					table.insert(floaters, { part = part, home = pos, phase = random:NextNumber(0, 6.28), spin = random:NextNumber(0.3, 0.8) })
					return part
				end
				floater("FloatingSuitcase", V(1.6, 1.1, 0.5), rgb(120, 70, 40), V(-20, y + 6, 2))
				floater("FloatingPillow", V(1.4, 0.4, 0.9), rgb(245, 245, 250), V(-4, y + 5, -2.2))
				floater("FloatingBook", V(0.8, 0.15, 1.1), rgb(150, 30, 40), V(2, y + 7, 2.4))
				floater("FloatingTray", V(1.4, 0.1, 1), rgb(200, 200, 205), V(14, y + 5.5, -1.5))
				local cup = floater("FloatingCup", V(0.5, 0.45, 0.5), rgb(250, 250, 245), V(15, y + 4.5, 1.8))
				cup.Shape = Enum.PartType.Cylinder
				-- 은은한 우주 빛
				for x = -22, 18, 13 do
					local glow = P(ev.folder, "SpaceGlow", V(0.3, 0.3, 0.3), V(x, y + WALL_H - 2.5, 0), rgb(120, 110, 255), Mat.Neon, { Transparency = 1 })
					local light = Instance.new("PointLight")
					light.Color = rgb(130, 120, 255)
					light.Range = 18
					light.Brightness = 1.2
					light.Parent = glow
				end
				-- 별똥별
				local shooting = P(ev.folder, "ShootingStar", V(1.6, 0.06, 0.06), CFrame.new(0, -500, 0), rgb(255, 255, 230), Mat.Neon)
				local planetCF, ringCF, bandCF = planet.CFrame, ring.CFrame, band.CFrame
				animate(ev, function(t)
					for _, s in ipairs(stars) do
						s.part.Transparency = (math.sin(t * 3 + s.phase) > 0.6) and 0.7 or 0 -- 반짝반짝
					end
					local bob = V(0, math.sin(t * 0.5) * 0.3, 0)
					planet.CFrame = planetCF * CFrame.new(bob) * CFrame.Angles(0, t * 0.2, 0)
					band.CFrame = CFrame.new(bob) * bandCF * CFrame.Angles(0, t * 0.2, 0)
					ring.CFrame = CFrame.new(bob) * ringCF
					earth.CFrame = CFrame.new(earthPos + V(0, math.sin(t * 0.4 + 1) * 0.3, 0)) * CFrame.Angles(0, t * 0.3, 0)
					for _, f in ipairs(floaters) do
						f.part.CFrame = CFrame.new(f.home + V(math.sin(t * 0.3 + f.phase) * 0.6, math.sin(t * 0.5 + f.phase) * 0.5, 0))
							* CFrame.Angles(t * f.spin, t * f.spin * 0.7, t * f.spin * 0.4)
					end
					-- 6초마다 천장 쪽을 휙 가로질러요
					local cycle = t % 6
					if cycle < 1.2 then
						local p = cycle / 1.2
						local from, to = V(-26, y + WALL_H - 1.5, -3), V(18, y + WALL_H - 3.5, 3)
						local pos = from:Lerp(to, p)
						shooting.CFrame = CFrame.lookAt(pos, to) * CFrame.Angles(0, math.rad(90), 0)
						shooting.Transparency = p > 0.8 and (p - 0.8) * 5 or 0
					else
						shooting.CFrame = CFrame.new(0, -500, 0)
					end
				end)
				emptyCorridor(ev, floor)
			else
				ev.anim = (ev.anim or 0) + 1
				ev.folder:ClearAllChildren()
				restoreCorridor(ev, floor)
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
