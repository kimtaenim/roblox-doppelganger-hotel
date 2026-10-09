-- 2층~4층 객실 복도를 만들어요. (밤 순찰과 룸서비스 배달을 하는 곳)
-- 층마다 가운데에 긴 복도가 있고, 양쪽에 객실 문이 6개씩 (01~12호) 있어요.
-- 복도 동쪽 끝에는 엘리베이터가 있어서 층 사이를 오갈 수 있어요. (로비 엘리베이터 옆 버튼도 있어요)
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
local HALF = 3.5 -- 복도 폭의 절반
local WALL_H = 11
local DOOR_W, DOOR_H = 3.6, 8

local WALLPAPER = rgb(78, 28, 34)
local WAINSCOT = rgb(45, 28, 20)
local CARPET = rgb(95, 18, 24)
local DOOR = rgb(70, 42, 28)
local WARM = rgb(255, 205, 150)

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

local function lamp(lights, pos)
	local bulb = P(lights, "CorridorLamp", V(1.4, 0.25, 1.4), pos, WARM, Mat.Neon)
	bulb:SetAttribute("Zone", "Corridor")
	local light = Instance.new("PointLight")
	light.Range = 15
	light.Brightness = 0.7
	light.Color = WARM
	light.Shadows = true
	light.Parent = bulb
	return bulb
end

-- 벽 한 줄: 문 자리만 비워 두고 벽 조각을 이어 붙여요. side = -1 (앞쪽 방), 1 (뒤쪽 방)
local function corridorWall(parent, y, side)
	local z = side * (HALF + 0.25)
	local x0, x1 = -28.9, 28.9
	local cursor = x0
	local function segment(a, b)
		if b - a < 0.05 then
			return
		end
		local mid = (a + b) / 2
		Props.solid(parent, "CorridorWall", V(b - a, WALL_H, 0.5), V(mid, y + WALL_H / 2, z), WALLPAPER, Mat.Fabric)
		P(parent, "Wainscot", V(b - a, 3.2, 0.12), V(mid, y + 1.6, z - side * 0.3), WAINSCOT, Mat.Wood)
		P(parent, "Rail", V(b - a, 0.2, 0.2), V(mid, y + 3.3, z - side * 0.32), C.BRASS, Mat.Metal)
	end
	for _, x in ipairs(DOOR_XS) do
		segment(cursor, x - DOOR_W / 2)
		Props.solid(parent, "Lintel", V(DOOR_W, WALL_H - DOOR_H, 0.5), V(x, y + DOOR_H + (WALL_H - DOOR_H) / 2, z), WALLPAPER, Mat.Fabric)
		P(parent, "DoorFrame", V(DOOR_W + 0.5, 0.35, 0.3), V(x, y + DOOR_H + 0.15, z - side * 0.2), C.WOOD_DARK, Mat.Wood)
		for _, dx in ipairs({ -1, 1 }) do
			P(parent, "DoorFrame", V(0.25, DOOR_H, 0.3), V(x + dx * (DOOR_W / 2 + 0.1), y + DOOR_H / 2, z - side * 0.2), C.WOOD_DARK, Mat.Wood)
		end
		cursor = x + DOOR_W / 2
	end
	segment(cursor, x1)
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
	local hinge = CFrame.lookAt(V(x - DOOR_W / 2, y + DOOR_H / 2, wallZ), V(x - DOOR_W / 2, y + DOOR_H / 2, wallZ) + facing)
	-- hinge 의 오른쪽(+X 로컬)은 side 에 따라 반대라서, 문 가운데 쪽을 따로 계산해요.
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
	local knobSide = -math.sign(toCenter)
	Props.ball(door, "DoorKnob", 0.32, (front * CFrame.new(knobSide * -1.3, -0.3, -0.12)).Position, C.BRASS, Mat.Metal)
	local plate = P(door, "NumberPlate", V(1.2, 0.5, 0.06), front * CFrame.new(0, 3.1, -0.04), C.BRASS, Mat.Metal)
	Props.text(plate, Enum.NormalId.Front, tostring(number), rgb(40, 25, 15), Enum.Font.Garamond)
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
		extras = extras,
		-- 문을 열면 방 안쪽, 문에서 2.5칸 떨어진 곳 (방 안을 바라봐요)
		insideCF = CFrame.lookAt(V(x, y, wallZ + side * 2.6), V(x, y, wallZ + side * 8)),
		okPrompt = prompt(spot, "이상 없음", number .. "호", Enum.KeyCode.E),
		reportPrompt = prompt(spot, "이상 보고", number .. "호", Enum.KeyCode.R),
		knockPrompt = prompt(spot, "노크하기", number .. "호 룸서비스", Enum.KeyCode.F),
	}
end

local function buildElevator(parent, floor, api)
	local y = floorY(floor)
	-- 복도 동쪽 끝 벽(x 29)에 엘리베이터 문
	P(parent, "ElevatorFrame", V(0.5, 9.5, 6.4), V(28.6, y + 4.75, 0), rgb(120, 90, 50), Mat.Metal)
	P(parent, "ElevatorDoor", V(0.3, 8.5, 5.4), V(28.4, y + 4.25, 0), rgb(90, 70, 45), Mat.Metal)
	P(parent, "ElevatorGap", V(0.35, 8.5, 0.08), V(28.4, y + 4.25, 0), rgb(20, 15, 10))
	local sign = P(parent, "FloorSign", V(0.15, 1.2, 2.4), V(28.5, y + 9.9, 0), rgb(15, 10, 10))
	Props.text(sign, Enum.NormalId.Left, floor .. "F", rgb(255, 200, 120), Enum.Font.Garamond)
	api.exits[floor] = CFrame.lookAt(V(25.5, y + 3, 0), V(20, y + 3, 0))
	return V(28.5, y + 4.5, -3.6) -- 버튼 판 위치
end

-- 엘리베이터 버튼: 누르면 그 층으로 가요. (숫자 키 1~4 로도 눌러요)
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
local function buttonPanel(parent, base, here, api)
	P(parent, "ButtonPanel", V(0.12, 2.6, 0.8), base, rgb(30, 22, 18), Mat.Metal)
	local targets = { 1, 2, 3, 4 }
	for i, target in ipairs(targets) do
		local button = P(parent, "FloorButton", V(0.12, 0.45, 0.45), base + V(-0.06, 1.0 - (i - 1) * 0.6, 0), target == here and rgb(255, 170, 80) or C.BRASS, target == here and Mat.Neon or Mat.Metal)
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

	local api = { rooms = {}, exits = {}, elevatorPrompts = {}, figures = {} }
	api.exits[1] = CFrame.lookAt(V(24.5, 3.5, -2), V(18, 3.5, -2))

	for _, floor in ipairs(FLOOR_LIST) do
		local y = floorY(floor)
		local level = Instance.new("Model")
		level.Name = "Floor" .. floor
		level.Parent = folder

		-- 바닥 카펫, 천장, 벽
		P(level, "Carpet", V(57.8, 0.06, HALF * 2), V(0, y + 0.03, 0), CARPET, Mat.Fabric)
		P(level, "CarpetBorder", V(57.8, 0.07, 0.4), V(0, y + 0.035, -HALF + 0.5), rgb(160, 120, 60), Mat.Fabric)
		P(level, "CarpetBorder", V(57.8, 0.07, 0.4), V(0, y + 0.035, HALF - 0.5), rgb(160, 120, 60), Mat.Fabric)
		Props.solid(level, "CorridorCeiling", V(57.8, 0.4, HALF * 2 + 1), V(0, y + WALL_H + 0.2, 0), rgb(40, 30, 28), Mat.Wood)
		Props.solid(level, "WestEnd", V(0.5, WALL_H, HALF * 2), V(-28.7, y + WALL_H / 2, 0), WALLPAPER, Mat.Fabric)
		corridorWall(level, y, -1)
		corridorWall(level, y, 1)

		-- 천장 등과 벽 그림
		for x = -24, 24, 8 do
			lamp(lights, V(x, y + WALL_H - 0.1, 0))
		end
		for i, x in ipairs({ -18, -10, -2, 6, 14 }) do
			local side = i % 2 == 0 and 1 or -1
			local z = side * (HALF - 0.05)
			P(level, "PaintingFrame", V(1.8, 2.2, 0.15), V(x, y + 6, z), C.BRASS, Mat.Metal)
			local tones = { rgb(40, 50, 45), rgb(60, 40, 35), rgb(35, 35, 50), rgb(55, 50, 35) }
			P(level, "Painting", V(1.5, 1.9, 0.16), V(x, y + 6, z - side * 0.02), tones[i % #tones + 1], Mat.SmoothPlastic)
		end
		-- 서쪽 끝 작은 창문 (달빛)
		P(level, "EndWindow", V(0.2, 3, 2.4), V(-28.4, y + 6, 0), rgb(60, 70, 110), Mat.Neon, { Transparency = 0.6 })

		for i, x in ipairs(DOOR_XS) do
			for _, side in ipairs({ -1, 1 }) do
				local room = buildRoom(level, floor, i, side, x)
				api.rooms[room.number] = room
			end
		end

		local panelBase = buildElevator(level, floor, api)
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
	end

	function api.setOccupied(room, occupied)
		room.strip.Color = occupied and rgb(255, 190, 120) or rgb(20, 16, 14)
		room.strip.Material = occupied and Mat.Neon or Mat.SmoothPlastic
	end

	-- 문을 안쪽으로 살짝(또는 활짝) 열어요.
	function api.openDoor(room, degrees)
		room.door:PivotTo(room.closedPivot)
		local pivot = room.hinge
		local offset = pivot:ToObjectSpace(room.closedPivot)
		room.door:PivotTo(pivot * CFrame.Angles(0, math.rad(degrees) * room.swing, 0) * offset)
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

	api.resetAll()
	return api
end

return Floors
