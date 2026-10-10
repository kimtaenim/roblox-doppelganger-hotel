-- 손님(동물 NPC)의 종류를 정하고, 파트를 조립해서 모델로 만드는 모듈이에요.
-- 서버(호텔에 걸어오는 실제 손님)와 클라이언트(예약 사진, CCTV 화면)가 같이 써요.
local Animals = {}

local rgb = Color3.fromRGB
local V = Vector3.new

-- 미니 인형처럼 부드러운 파스텔 색이에요.
Animals.Types = {
	cat = { name = "고양이", ears = "pointy", furs = { rgb(250, 205, 165), rgb(205, 200, 215), rgb(250, 240, 230), rgb(240, 185, 150) } },
	dog = { name = "강아지", ears = "floppy", furs = { rgb(235, 205, 160), rgb(250, 240, 225), rgb(215, 180, 150) } },
	rabbit = { name = "토끼", ears = "long", furs = { rgb(252, 248, 245), rgb(230, 215, 235), rgb(240, 210, 190) } },
	bear = { name = "곰", ears = "round", furs = { rgb(200, 160, 125), rgb(235, 215, 190), rgb(175, 140, 115) } },
	fox = { name = "여우", ears = "pointy", furs = { rgb(250, 175, 120), rgb(245, 195, 150) } },
	pig = { name = "돼지", ears = "small", furs = { rgb(252, 200, 205), rgb(248, 185, 195) } },
}

Animals.List = { "cat", "dog", "rabbit", "bear", "fox", "pig" }

Animals.Clothes = {
	rgb(160, 225, 210), -- 민트
	rgb(250, 175, 195), -- 분홍
	rgb(195, 175, 235), -- 라벤더
	rgb(250, 225, 140), -- 버터 노랑
	rgb(150, 200, 240), -- 하늘
	rgb(250, 190, 150), -- 복숭아
	rgb(245, 240, 225), -- 크림
}

-- 도플갱어의 이상한 점 종류
Animals.AnomalyKinds = { "teeth", "mouth", "eyes", "body", "moving", "noface", "upside", "manyeyes", "bigeye" }
-- 도플갱어 모습의 이름 (아침 보고서의 "새로운 도플갱어" 소식에 써요)
Animals.AnomalyNames = {
	teeth = "이빨을 드러낸 손님",
	mouth = "입이 찢어진 손님",
	eyes = "눈이 새까만 손님",
	body = "목과 팔이 길게 늘어난 손님",
	moving = "사진 속에서 움직이는 손님",
	noface = "얼굴이 없는 손님",
	upside = "머리가 거꾸로 달린 손님",
	manyeyes = "눈이 여러 개인 손님",
	bigeye = "거대한 눈알 하나뿐인 손님",
}

local WHITE = rgb(250, 250, 245)
local BLACK = rgb(15, 12, 12)
local BLOOD = rgb(110, 0, 0)
local DARK_BLOOD = rgb(45, 0, 0)
local TOOTH = rgb(235, 230, 200)
local PINK = rgb(240, 160, 170)

local function newPart(parent, name, className, size, cframe, color)
	local part = Instance.new(className)
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function ball(parent, name, diameter, cframe, color)
	local part = newPart(parent, name, "Part", V(diameter, diameter, diameter), cframe, color)
	part.Shape = Enum.PartType.Ball
	return part
end

-- 앞에서 보면 삼각형인 뾰족한 이빨. down 이면 아래를 향해요.
local function fang(parent, cframe, height, width, down)
	local cf = cframe * CFrame.Angles(0, math.rad(90), 0)
	if down then
		cf = cf * CFrame.Angles(math.pi, 0, 0)
	end
	return newPart(parent, "Fang", "WedgePart", V(0.06, height, width), cf, TOOTH)
end

-- 타원 모양 (길쭉한 공): 아몬드형 눈, 눈꺼풀에 써요.
local function ellipsoid(parent, name, size, cframe, color)
	local part = newPart(parent, name, "Part", size, cframe, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- 얇은 원판: 홍채와 눈동자. cframe 의 -Z 쪽을 바라봐요.
local function disc(parent, name, diameter, cframe, color)
	local part = newPart(parent, name, "Part", V(0.03, diameter, diameter), cframe * CFrame.Angles(0, math.rad(90), 0), color)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function vcyl(parent, name, height, diameter, cframe, color)
	local part = newPart(parent, name, "Part", V(height, diameter, diameter), cframe * CFrame.Angles(0, 0, math.rad(90)), color)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- data: { id, name, animal, fur, cloth }
-- anomaly: nil 이면 멀쩡한 모습, "teeth"/"mouth"/"eyes"/"body" 면 그 무서운 모습이 보여요.
-- ("moving" 은 모양은 멀쩡하고, 사진 화면에서 머리가 움직이게 만들어요.)
-- 모델의 앞쪽은 -Z 방향이고, 기준점(Pivot)은 발 밑이에요.
-- 머리와 얼굴 파트는 "HeadGroup" 모델 안에 있어요. (말풍선, 움직이는 사진에서 써요)
-- 넥타이 색, 신발, 모자/안경 같은 소품은 data.id 로 정해져서 서버와 화면에서 똑같이 보여요.
function Animals.build(data, anomaly)
	local def = Animals.Types[data.animal] or Animals.Types.cat
	local style = Random.new(data.id or 1)
	local fur = data.fur or def.furs[1]
	local cloth = data.cloth or Animals.Clothes[1]
	local isMonster = anomaly ~= nil and anomaly ~= "moving"
	if isMonster then
		-- 도플갱어의 진짜 모습은 핏기 없이 창백해요.
		fur = fur:Lerp(rgb(200, 205, 200), 0.35)
		cloth = cloth:Lerp(rgb(40, 40, 40), 0.35)
	end
	local light = fur:Lerp(Color3.new(1, 1, 1), 0.55)
	local dark = fur:Lerp(Color3.new(0, 0, 0), 0.35)
	local pants = cloth:Lerp(Color3.new(0, 0, 0), 0.5)
	local ties = { rgb(150, 30, 40), rgb(30, 50, 110), rgb(200, 160, 50), rgb(40, 90, 60), rgb(20, 20, 20) }
	local tieColor = ties[style:NextInteger(1, #ties)]
	local shoeColor = style:NextNumber() < 0.5 and rgb(30, 22, 18) or rgb(90, 55, 30)
	local accessory = style:NextInteger(0, 5) -- 0 없음, 1 중절모, 2 머리 리본, 3 목도리, 4 베레모, 5 나비넥타이

	local model = Instance.new("Model")
	model.Name = data.name or "Guest"

	local root = newPart(model, "Root", "Part", V(1, 0.2, 1), CFrame.new(0, 0.1, 0), fur)
	root.Transparency = 1
	model.PrimaryPart = root

	local weirdBody = anomaly == "body"

	-- 몸은 모두 매끈한 타원(곡선)으로 만들어요.
	-- 신발과 다리 (몸이 이상한 도플갱어는 안쪽으로 붙은 다리)
	for _, side in ipairs({ -1, 1 }) do
		if weirdBody then
			local x = side * 0.42
			ellipsoid(model, "Shoe", V(0.78, 0.55, 1.15), CFrame.new(x, 0.3, -0.15), shoeColor)
			ellipsoid(model, "Leg", V(0.7, 1.9, 0.7), CFrame.new(x, 1.3, 0), pants)
		else
			-- 가는 원기둥 모양의 늘씬한 다리, 두 다리 사이를 넉넉히 띄워요.
			local x = side * 0.72
			ellipsoid(model, "Shoe", V(0.9, 0.52, 1.15), CFrame.new(x, 0.26, -0.12), shoeColor)
			vcyl(model, "Leg", 1.9, 0.74, CFrame.new(x, 1.3, 0), pants)
		end
	end
	if weirdBody then
		ellipsoid(model, "Hips", V(1.8, 1.0, 1.45), CFrame.new(0, 2.2, 0), pants)
	end

	-- 몸통: 머리 바로 밑에 붙은 넓고 둥근 덩어리 (머리와 이어져서 서양배·베개 모양이 돼요)
	-- 몸이 이상한 도플갱어만 가늘고 길쭉해요.
	local torsoCF = weirdBody and CFrame.new(0, 3.3, -0.2) * CFrame.Angles(math.rad(-14), 0, 0) or CFrame.new(0, 3.85, 0)
	local torsoSize = weirdBody and V(1.4, 2.9, 1.1) or V(2.4, 2.7, 2.4)
	-- 셔츠, 넥타이, 단추 높이 (몸통 가운데 기준, 머리에 가려지지 않는 곳)
	local Y = weirdBody and { collar = 1.05, knot = 0.98, tie = 0.45, shirt = 0.75, button = -0.25, pocket = 0.5, pocketX = -0.5 }
		or { collar = 0.42, knot = 0.38, tie = -0.1, shirt = 0.1, button = -0.82, pocket = -0.1, pocketX = -0.62 }
	local tw, th, td = torsoSize.X / 2, torsoSize.Y / 2, torsoSize.Z / 2
	local edge = 0.5 -- 둥근 모서리의 반지름
	local bodyBottom = 1.85 - torsoCF.Y -- 몸통 원통 바닥 (몸통 가운데 기준, 바지까지 포함)
	if weirdBody then
		ellipsoid(model, "Torso", torsoSize, torsoCF, cloth)
	else
		-- 상반신과 하반신이 하나로 이어진 모서리가 둥근 원통 (위는 윗옷, 아래는 바지 색).
		-- 원통 아래에 다리가 바로 붙어요.
		local topY, beltY, bottomY = th - edge, bodyBottom + edge + 0.2, bodyBottom + edge
		ellipsoid(model, "TorsoTop", V(torsoSize.X, edge * 2, torsoSize.Z), torsoCF * CFrame.new(0, topY, 0), cloth)
		vcyl(model, "Torso", topY - beltY, torsoSize.X, torsoCF * CFrame.new(0, (topY + beltY) / 2, 0), cloth)
		vcyl(model, "Waist", beltY - bottomY, torsoSize.X, torsoCF * CFrame.new(0, (beltY + bottomY) / 2, 0), pants)
		ellipsoid(model, "TorsoBottom", V(torsoSize.X, edge * 2, torsoSize.Z), torsoCF * CFrame.new(0, bottomY, 0), pants)
		-- 허리띠와 버클
		vcyl(model, "Belt", 0.16, torsoSize.X + 0.04, torsoCF * CFrame.new(0, beltY, 0), rgb(70, 50, 40))
		newPart(model, "Buckle", "Part", V(0.3, 0.22, 0.06), torsoCF * CFrame.new(0, beltY, -td - 0.03), rgb(200, 165, 85))
		newPart(model, "BuckleHole", "Part", V(0.18, 0.1, 0.02), torsoCF * CFrame.new(0, beltY, -td - 0.065), rgb(70, 50, 40))
	end
	-- 몸통 앞면의 (x, y) 자리에 딱 붙는 위치 (곡면을 따라 기울어져요)
	local function onTorso(x, y, lift)
		if weirdBody then
			local k = math.max(0.03, 1 - (x / tw) ^ 2 - (y / th) ^ 2)
			local z = -td * math.sqrt(k) - (lift or 0.01)
			local pitch = math.atan(td * (y / (th * th)) / math.sqrt(k))
			local yaw = -math.atan(td * (x / (tw * tw)) / math.sqrt(k))
			return torsoCF * CFrame.new(x, y, z) * CFrame.Angles(pitch, yaw, 0)
		end
		-- 원통 옆면 (둥근 모서리 부분은 타원 면을 따라요)
		local over = math.max(0, y - (th - edge), (bodyBottom + edge) - y)
		local k = math.max(0.03, 1 - (x / tw) ^ 2 - (over / edge) ^ 2)
		local z = -td * math.sqrt(k) - (lift or 0.01)
		local pitch = over > 0 and math.sign(y) * math.atan(td * (over / (edge * edge)) / math.sqrt(k)) or 0
		local yaw = -math.atan(td * (x / (tw * tw)) / math.sqrt(k))
		return torsoCF * CFrame.new(x, y, z) * CFrame.Angles(pitch, yaw, 0)
	end
	ellipsoid(model, "Shirt", V(0.7, 1.1, 0.14), onTorso(0, Y.shirt, -0.02), WHITE)
	for _, side in ipairs({ -1, 1 }) do
		ellipsoid(model, "Collar", V(0.34, 0.15, 0.1), onTorso(side * 0.19, Y.collar, 0) * CFrame.Angles(0, 0, side * 0.6), WHITE)
		if weirdBody then
			ball(model, "Shoulder", 0.9, torsoCF * CFrame.new(side * 0.8, 0.85, 0), cloth)
		end
	end
	if accessory == 5 then
		for _, side in ipairs({ -1, 1 }) do
			ellipsoid(model, "BowTie", V(0.34, 0.22, 0.1), onTorso(side * 0.17, Y.knot, 0.02) * CFrame.Angles(0, 0, side * 0.25), tieColor)
		end
		ball(model, "BowKnot", 0.15, onTorso(0, Y.knot, 0.05), tieColor)
	else
		ball(model, "TieKnot", 0.22, onTorso(0, Y.knot, 0.03), tieColor)
		ellipsoid(model, "Tie", V(0.26, 1.0, 0.08), onTorso(0, Y.tie, 0.02), tieColor)
	end
	-- 단추: 테두리가 도톰한 동그란 금색 단추에 실 구멍 두 개
	local buttons = weirdBody and { { 0.28, Y.button }, { 0.28, Y.button - 0.38 } } or { { 0, Y.button }, { 0, Y.button - 0.27 } }
	for _, b in ipairs(buttons) do
		local cf = onTorso(b[1], b[2], 0)
		disc(model, "Button", 0.2, cf, rgb(200, 160, 75))
		disc(model, "Button", 0.14, cf * CFrame.new(0, 0, -0.012), rgb(170, 130, 55))
		for _, hx in ipairs({ -0.03, 0.03 }) do
			ball(model, "ButtonHole", 0.035, cf * CFrame.new(hx, 0, -0.02), rgb(80, 60, 30))
		end
	end
	ellipsoid(model, "PocketSquare", V(0.26, 0.15, 0.06), onTorso(Y.pocketX, Y.pocket, 0), tieColor:Lerp(WHITE, 0.4))

	-- 팔 (소매 + 흰 소맷부리 + 손)
	for _, side in ipairs({ -1, 1 }) do
		if weirdBody then
			-- 바닥까지 늘어진 팔과 긴 검은 손톱
			local x = side * 0.95
			ellipsoid(model, "Arm", V(0.42, 4.4, 0.42), CFrame.new(x, 2.4, -0.3) * CFrame.Angles(0, 0, side * 0.06), fur)
			for i = -1, 1 do
				local claw = CFrame.new(x + side * 0.15 + i * 0.12, 0.1, -0.3) * CFrame.Angles(0, 0, math.rad(180))
				fang(model, claw, 0.6, 0.12, false).Color = BLACK
			end
		else
			-- 둥근 몸통 옆구리에 짧은 팔이 붙어요.
			local armCF = CFrame.new(side * 1.32, 3.45, 0) * CFrame.Angles(0, 0, side * 0.25)
			ellipsoid(model, "Sleeve", V(0.62, 1.75, 0.62), armCF, cloth)
			ellipsoid(model, "Cuff", V(0.62, 0.16, 0.62), armCF * CFrame.new(0, -0.78, 0), WHITE)
			ball(model, "Hand", 0.64, armCF * CFrame.new(0, -0.98, 0), light)
			if side == -1 then
				ellipsoid(model, "Watch", V(0.66, 0.12, 0.66), armCF * CFrame.new(0, -0.66, 0), rgb(190, 150, 70))
			end
		end
	end

	-- 머리 (이상한 몸이면 목이 길게 늘어나고 머리가 옆으로 꺾여 매달려요)
	local headGroup = Instance.new("Model")
	headGroup.Name = "HeadGroup"
	headGroup.Parent = model

	local headCF
	if weirdBody then
		vcyl(model, "LongNeck", 2.4, 0.5, CFrame.new(0, 5.8, -0.3), fur)
		vcyl(model, "NeckBent", 1.8, 0.5, CFrame.new(0.55, 7.4, -0.3) * CFrame.Angles(0, 0, math.rad(-40)), fur)
		headCF = CFrame.new(1.6, 7.5, -0.3) * CFrame.Angles(0, 0, math.rad(-105))
	else
		headCF = CFrame.new(0, 5.45, 0) -- 목 없이 몸통 위에 바로 붙어요
	end
	local head = ball(headGroup, "Head", 2.4, headCF, fur)
	headGroup.PrimaryPart = head

	local function at(x, y, z)
		return headCF * CFrame.new(x, y, z)
	end

	-- 귀 (부드러운 타원, 안쪽은 분홍색)
	for _, side in ipairs({ -1, 1 }) do
		if def.ears == "pointy" or def.ears == "small" then
			local s = def.ears == "small" and 0.65 or 1
			local earCF = at(side * 0.68, 1.02, 0.05) * CFrame.Angles(0, 0, -side * 0.32)
			if def.ears == "pointy" then
				-- 고양이·여우: 끝이 뾰족한 세모 귀 (쐐기 두 개를 맞붙여 이등변 삼각형을 만들어요)
				local function triangle(name, cf, w, h, thick, color)
					for _, half in ipairs({ -1, 1 }) do
						newPart(headGroup, name, "WedgePart", V(thick, h, w / 2), cf * CFrame.new(half * w / 4, 0, 0) * CFrame.Angles(0, -half * math.pi / 2, 0), color)
					end
				end
				triangle("Ear", earCF, 1.0 * s, 1.2 * s, 0.28, fur)
				triangle("EarInner", earCF * CFrame.new(0, -0.12 * s, -0.15), 0.6 * s, 0.75 * s, 0.04, PINK)
			else
				ellipsoid(headGroup, "Ear", V(0.75 * s, 1.15 * s, 0.32), earCF, fur)
				ellipsoid(headGroup, "EarInner", V(0.42 * s, 0.75 * s, 0.12), earCF * CFrame.new(0, -0.05 * s, -0.12), PINK)
			end
			ball(headGroup, "EarFluff", 0.3 * s, earCF * CFrame.new(0, -0.32 * s, -0.15), light)
		elseif def.ears == "floppy" then
			ellipsoid(headGroup, "Ear", V(0.5, 1.6, 0.85), at(side * 1.2, -0.15, 0.05) * CFrame.Angles(0, 0, side * 0.25), dark)
		elseif def.ears == "long" then
			-- 토끼 귀: 두 마디로 만들어서 끝이 살짝 접혀요.
			-- (from 에서 시작해 tiltZ 만큼 옆으로, tiltX 만큼 앞으로 기운 마디, flat 이면 납작한 면이 위를 봐요)
			local function earSeg(from, tiltZ, tiltX, length, flat)
				local cf = from * CFrame.Angles(tiltX, 0, tiltZ)
				if flat then
					cf = cf * CFrame.Angles(0, math.pi / 2, 0)
				end
				local mid = cf * CFrame.new(0, length / 2, 0)
				ellipsoid(headGroup, "Ear", V(0.6, length + 0.3, 0.32), mid, fur)
				return mid, cf * CFrame.new(0, length, 0)
			end
			local hatted = accessory == 1 or accessory == 4
			if hatted then
				-- 모자에 눌려서 챙 밑으로 납작하게 옆으로 삐져나왔다가 아래로 축 처져요.
				local _, bend = earSeg(at(side * 0.5, 0.82, 0.05), -side * 1.42, 0, 0.75, true)
				local tipMid = earSeg(CFrame.new(bend.Position), -side * 2.55, -0.2, 0.85, false)
				ellipsoid(headGroup, "EarInner", V(0.3, 0.6, 0.1), tipMid * CFrame.new(0, 0.05, -0.13), PINK)
			else
				-- 쫑긋 서 있다가 끝이 바깥쪽 앞으로 살짝 꺾여요.
				local baseMid, bend = earSeg(at(side * 0.42, 0.85, 0.05), -side * 0.12, 0, 1.35, false)
				ellipsoid(headGroup, "EarInner", V(0.34, 1.25, 0.12), baseMid * CFrame.new(0, 0.05, -0.13), PINK)
				earSeg(CFrame.new(bend.Position), -side * 0.85, -0.3, 0.75, false)
			end
		elseif def.ears == "round" then
			ball(headGroup, "Ear", 0.85, at(side * 0.85, 0.95, 0), fur)
			ball(headGroup, "EarInner", 0.45, at(side * 0.85, 0.95, -0.28), dark)
		end
	end

	-- 주둥이, 코, 볼, 수염
	local mouthY, mouthZ = -0.72, -1.0
	if data.animal == "pig" then
		ellipsoid(headGroup, "Snout", V(0.6, 0.45, 0.35), at(0, -0.45, -1.07), PINK:Lerp(fur, 0.3))
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "Nostril", 0.1, at(side * 0.11, -0.45, -1.23), rgb(150, 80, 90))
		end
		mouthY, mouthZ = -0.78, -0.95
	elseif data.animal == "bear" then
		ball(headGroup, "Muzzle", 0.62, at(0, -0.52, -0.92), light)
		ball(headGroup, "Nose", 0.2, at(0, -0.42, -1.2), rgb(70, 45, 40))
		mouthY, mouthZ = -0.66, -1.17
	else
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "Muzzle", 0.48, at(side * 0.14, -0.55, -0.98), light)
		end
		if data.animal == "fox" then
			ball(headGroup, "Snout", 0.36, at(0, -0.48, -1.12), light)
		end
		ball(headGroup, "Nose", 0.17, at(0, -0.42, data.animal == "fox" and -1.29 or -1.17), data.animal == "rabbit" and PINK or rgb(70, 45, 40))
		mouthY, mouthZ = -0.68, -1.15
		if data.animal == "rabbit" and not isMonster then
			newPart(headGroup, "BuckTooth", "Part", V(0.14, 0.14, 0.04), at(0, -0.8, -1.08), WHITE)
		end
		if data.animal == "cat" or data.animal == "fox" or data.animal == "rabbit" then
			for _, side in ipairs({ -1, 1 }) do
				for i = 0, 1 do
					newPart(headGroup, "Whisker", "Part", V(0.6, 0.025, 0.025), at(side * 0.55, -0.52 - i * 0.1, -1.05) * CFrame.Angles(0, -side * 0.35, side * (0.1 - i * 0.18)), rgb(150, 130, 120))
				end
			end
		end
	end
	-- 코끝 반짝임
	local nose = headGroup:FindFirstChild("Nose")
	if nose then
		ball(headGroup, "NoseShine", 0.05, nose.CFrame * CFrame.new(-0.03, 0.04, -0.06), WHITE)
	end

	-- 통통한 볼살: 큰 공 → 중간 공 → 작은 공 순서로 조금씩 더 튀어나오게 겹쳐서
	-- 머리에서 볼까지 계단처럼 부드럽게 솟아올라요.
	local cheeks = {} -- 볼 공의 중심과 반지름 (찢어진 입이 볼 위로 이어지게 써요)
	for _, side in ipairs({ -1, 1 }) do
		local dir = Vector3.new(side * 0.66, -0.42, -0.62).Unit
		local center, size
		for _, layer in ipairs({ { 1.5, 0.05 }, { 1.1, 0.1 }, { 0.75, 0.14 } }) do
			size = layer[1]
			center = dir * (1.2 + layer[2] - size / 2)
			ball(headGroup, "CheekFluff", size, headCF * CFrame.new(center), fur)
			table.insert(cheeks, { center = center, radius = size / 2 })
		end
		if not isMonster then
			-- 가장 작은 볼 공 앞쪽 면에 발그레한 볼터치
			local face = (dir + Vector3.new(0, 0.1, -0.6)).Unit
			local spot = center + face * (size / 2 + 0.005)
			local blush = ellipsoid(headGroup, "Blush", V(0.4, 0.24, 0.06), headCF * CFrame.lookAt(spot, spot + face), rgb(255, 150, 170))
			blush.Transparency = 0.15
		end
	end
	-- 머리 앞면의 (x, y) 자리 (머리 곡면 위). 머리 밖이면 nil.
	local function headSurface(x, y, lift)
		local k = 1.44 - x * x - y * y
		local z = k >= 0.02 and -math.sqrt(k) or nil
		for _, cheek in ipairs(cheeks) do
			local c, r = cheek.center, cheek.radius
			local ck = r * r - (x - c.X) ^ 2 - (y - c.Y) ^ 2
			if ck >= 0.01 then
				local cz = c.Z - math.sqrt(ck)
				z = z and math.min(z, cz) or cz
			end
		end
		return z and z - (lift or 0.02)
	end
	-- 이마의 털 뭉치 (고양이·여우·강아지)
	if data.animal == "cat" or data.animal == "fox" or data.animal == "dog" then
		for i = -1, 1 do
			ellipsoid(headGroup, "Tuft", V(0.22, 0.45, 0.25), at(i * 0.2, 1.08, -0.45) * CFrame.Angles(math.rad(-30), 0, i * 0.3), fur)
		end
	end


	-- 점들을 이어서 구불구불한 선을 그려요. 겹치는 타원이라 매끈하게 이어져요.
	local function curvyLine(parent, name, points, width, depth, color, toCF)
		for i = 1, #points - 1 do
			local p1, p2 = points[i], points[i + 1]
			local w = type(width) == "function" and width(i / (#points - 1)) or width
			local mid = (p1 + p2) / 2
			local up = (p2 - p1)
			if up.Magnitude < 0.001 then
				continue
			end
			local cf = toCF(mid, up.Unit)
			ellipsoid(parent, name, V(w, up.Magnitude + w * 2.5, depth), cf, color)
		end
	end
	-- 머리 위의 선: 각 조각이 머리 곡면을 따라 누워요.
	local function onHead(mid, dir)
		local normal = mid.Unit
		local right = dir:Cross(normal).Unit
		return headCF * CFrame.fromMatrix(mid, right, dir)
	end

	-- 도플갱어: 얼굴의 검붉은 핏줄, 셔츠의 핏자국 (모두 구불구불한 곡선이에요)
	if isMonster then
		local veinRandom = Random.new((data.id or 1) + 99)
		for _ = 1, 5 do
			local x, y = veinRandom:NextNumber(-0.75, 0.75), veinRandom:NextNumber(0.35, 0.95)
			local angle = veinRandom:NextNumber(0, math.pi * 2)
			local points = {}
			for _ = 1, 11 do
				local z = headSurface(x, y, 0.01)
				if not z then
					break
				end
				table.insert(points, Vector3.new(x, y, z))
				x += math.cos(angle) * 0.05
				y += math.sin(angle) * 0.05
				angle += veinRandom:NextNumber(-0.5, 0.5)
			end
			curvyLine(headGroup, "FaceVein", points, function(t)
				return 0.045 - 0.025 * t
			end, 0.02, rgb(90, 20, 40), onHead)
		end
		-- 셔츠의 핏자국: 겹친 얼룩 + 아래로 구불구불 흘러내린 자국
		for _ = 1, 3 do
			local sx, sy = veinRandom:NextNumber(-0.6, 0.6), veinRandom:NextNumber(-0.3, 0.6)
			for _ = 1, 3 do
				local r = veinRandom:NextNumber(0.14, 0.26)
				ellipsoid(model, "BloodStain", V(r * 1.3, r, 0.03), onTorso(sx + veinRandom:NextNumber(-0.1, 0.1), sy + veinRandom:NextNumber(-0.08, 0.08), 0.01) * CFrame.Angles(0, 0, veinRandom:NextNumber(0, math.pi)), BLOOD)
			end
			local x, y = sx, sy
			local points = {}
			local phase = veinRandom:NextNumber(0, math.pi * 2)
			for i = 0, 6 do
				table.insert(points, Vector2.new(x + math.sin(phase + i * 0.9) * 0.05, y))
				y -= 0.11
			end
			for i = 1, #points - 1 do
				local a, b = points[i], points[i + 1]
				local tilt = math.atan2(b.X - a.X, a.Y - b.Y)
				local w = 0.08 - 0.03 * i / #points
				ellipsoid(model, "BloodStain", V(w, (a - b).Magnitude + w, 0.03), onTorso((a.X + b.X) / 2, (a.Y + b.Y) / 2, 0.01) * CFrame.Angles(0, 0, tilt), BLOOD)
			end
			ellipsoid(model, "BloodStain", V(0.1, 0.13, 0.03), onTorso(points[#points].X, points[#points].Y - 0.03, 0.012), BLOOD)
		end
	end

	-- 눈: 사람 같은 아몬드형 눈 (흰자위 타원 + 홍채 + 눈동자 + 반짝임 하나). 눈 위에는 아무것도 붙이지 않아요.
	-- 귀엽지만 눈을 한 번도 깜빡이지 않아서 어딘가 섬뜩해요.
	local irises = { rgb(95, 65, 40), rgb(60, 95, 130), rgb(80, 110, 70), rgb(120, 85, 50), rgb(110, 110, 115) }
	local irisColor = irises[style:NextInteger(1, #irises)]
	local function eyeFrame(side, size)
		local x, y = side * 0.46, 0.05
		local z = -math.sqrt(1.44 - x * x - y * y)
		local surface = Vector3.new(x, y, z)
		-- 눈 바깥쪽 끝이 살짝 올라가요.
		return headCF * CFrame.lookAt(surface, surface + surface.Unit) * CFrame.Angles(0, 0, side * (size or 0))
	end

	if anomaly == "eyes" then
		-- 눈 자리가 새까맣게 뚫려 있고, 검은 눈물이 흘러내리고, 이마와 볼에 작은 눈이 더 있어요.
		for _, side in ipairs({ -1, 1 }) do
			local eye = eyeFrame(side)
			ellipsoid(headGroup, "Void", V(0.8, 0.46, 0.16), eye * CFrame.new(0, 0, -0.02), BLACK)
			local glint = ball(headGroup, "RedGlint", 0.08, eye * CFrame.new(0, 0, -0.1), rgb(255, 30, 30))
			glint.Material = Enum.Material.Neon
			-- 검은 눈물: 눈 아래쪽 가장자리에서 시작해서 볼을 따라 흘러내려요.
			ellipsoid(headGroup, "BlackTear", V(0.08, 0.7, 0.05), eye * CFrame.new(-side * 0.08, -0.55, 0.0) * CFrame.Angles(math.rad(-18), 0, 0), BLACK)
			ellipsoid(headGroup, "BlackTear", V(0.06, 0.4, 0.05), eye * CFrame.new(side * 0.18, -0.4, 0.02) * CFrame.Angles(math.rad(-14), 0, 0), BLACK)
		end
		for i, spot in ipairs({ V(0, 0.85, -0.85), V(-0.75, -0.05, -0.92), V(0.55, 0.95, -0.7) }) do
			local cf = at(spot.X, spot.Y, spot.Z) * CFrame.Angles(0, 0, (i - 2) * 0.4)
			ellipsoid(headGroup, "ExtraEye", V(0.34, 0.16, 0.08), cf, rgb(245, 225, 215))
			local red = disc(headGroup, "ExtraPupil", 0.1, cf * CFrame.new(0, 0, -0.04), rgb(200, 0, 0))
			red.Material = Enum.Material.Neon
		end
	else
		-- 이빨/입 도플갱어는 핏발 선 눈을 크게 뜨고 빨간 바늘 같은 눈동자로 노려봐요.
		local stare = anomaly == "teeth" or anomaly == "mouth"
		for _, side in ipairs({ -1, 1 }) do
			local eye = eyeFrame(side, 0)
			local function on(x, y, z)
				return eye * CFrame.new(x, y, z)
			end
			local sclera = ellipsoid(headGroup, "EyeWhite", V(0.8, stare and 0.46 or 0.4, 0.16), on(0, 0, -0.01), rgb(245, 242, 235))
			if stare then
				-- 핏발 선 눈: 아몬드 모양 그대로, 흰자가 살짝 붉고 아주 가는 핏줄이 눈꼬리에서 홍채 쪽으로 구불구불 뻗어요.
				sclera.Color = rgb(242, 222, 216)
				local hw, hh, hd = 0.4, 0.23, 0.08 -- 흰자 반지름 (가로, 세로, 깊이)
				local function onSclera(x, y)
					local k = math.max(0.02, 1 - (x / hw) ^ 2 - (y / hh) ^ 2)
					return -0.01 - hd * math.sqrt(k) - 0.004
				end
				local veinRandom = Random.new((data.id or 1) * 7 + side)
				for _, corner in ipairs({ -1, 1 }) do
					for i = 1, 5 do
						local x, y = corner * 0.36, (i - 3) * 0.045
						local angle = (i - 3) * 0.3 + veinRandom:NextNumber(-0.25, 0.25)
						for _ = 1, 3 do
							local length = veinRandom:NextNumber(0.045, 0.075)
							local dx, dy = -corner * math.cos(angle) * length, math.sin(angle) * length
							local mx, my = x + dx / 2, y + dy / 2
							if math.abs(mx) < 0.17 then
								break -- 홍채 근처에서 멈춰요
							end
							newPart(headGroup, "EyeVein", "Part", V(length, 0.008, 0.006), on(mx, my, onSclera(mx, my)) * CFrame.Angles(0, 0, math.atan2(dy, dx)), rgb(160, 20, 30))
							x, y = x + dx, y + dy
							angle += veinRandom:NextNumber(-0.7, 0.7)
						end
					end
				end
				disc(headGroup, "Iris", 0.33, on(0, 0, -0.092), irisColor)
				disc(headGroup, "Pupil", 0.06, on(0, 0, -0.104), rgb(10, 8, 8))
				ball(headGroup, "EyeShine", 0.035, on(-0.05, 0.05, -0.115), WHITE)
			else
				-- 사람 같은 아몬드형 눈: 눈꼬리가 수평이고, 홍채가 흰자 위아래에 거의 닿아요.
				-- 동물 얼굴에 사람 눈이 달려 있어서 귀엽지만 섬뜩해요.
				disc(headGroup, "Iris", 0.35, on(0, 0, -0.085), irisColor)
				disc(headGroup, "Pupil", 0.16, on(0, 0, -0.1), rgb(15, 12, 15))
				ball(headGroup, "EyeShine", 0.07, on(-0.06, 0.06, -0.12), WHITE)
			end
		end
	end

	-- 입
	-- 입에서 흘러내리는 피: 얼굴 곡면을 따라 구불구불 흐르다가 끝에 동그란 핏방울이 맺혀요.
	local dripRandom = Random.new((data.id or 1) + 7)
	local function bloodDrip(x, length, startY, startZ)
		local y = startY or (mouthY - 0.15)
		local phase = dripRandom:NextNumber(0, math.pi * 2)
		local drift = dripRandom:NextNumber(-0.08, 0.08)
		local steps = math.max(6, math.floor(length / 0.05))
		local lastZ = startZ or headSurface(x, y, 0.02) or (mouthZ - 0.2)
		local points = {}
		for i = 0, steps do
			local t = i / steps
			local px = x + math.sin(phase + t * 5) * 0.045 + drift * t
			local py = y - length * t
			local z = headSurface(px, py, 0.025)
			if z and startZ and z > lastZ + 0.05 then
				z = nil -- 얼굴보다 앞에 떠서 떨어지는 피는 얼굴 쪽으로 휘지 않아요
			end
			if z then
				lastZ = z
			else
				lastZ -= 0.01 -- 턱 아래로는 살짝 앞으로 떨어져요
			end
			table.insert(points, Vector3.new(px, py, lastZ))
		end
		curvyLine(headGroup, "Blood", points, function(t)
			return 0.09 - 0.03 * t
		end, 0.05, BLOOD, function(mid, dir)
			local normal = headSurface(mid.X, mid.Y) and mid.Unit or Vector3.new(0, 0, -1)
			local right = dir:Cross(normal).Unit
			return headCF * CFrame.fromMatrix(mid, right, dir)
		end)
		local tip = points[#points]
		ellipsoid(headGroup, "Blood", V(0.13, 0.16, 0.09), headCF * CFrame.new(tip.X, tip.Y - 0.05, tip.Z), BLOOD)
	end

	-- 입 밖으로 축 늘어진 혀: 구불구불 흔들리며 내려오고, 가운데 홈과 끝에 맺힌 핏방울이 있어요.
	local TONGUE = rgb(150, 40, 60)
	local function hangingTongue(start, count, width, lead)
		local points = table.clone(lead or {})
		for i = 0, count do
			table.insert(points, start + Vector3.new(math.sin(i * 0.8) * 0.06, -i * 0.11, -0.03 * i))
		end
		local function toCF(mid, dir)
			local right = dir:Cross(Vector3.new(0, 0, -1)).Unit
			return headCF * CFrame.fromMatrix(mid, right, dir)
		end
		curvyLine(headGroup, "Tongue", points, function(t)
			return width - width * 0.2 * t
		end, 0.1, TONGUE, toCF)
		-- 가운데 홈 (조금 앞쪽에 어두운 선)
		local groove = {}
		for i = 1, #points - 2 do
			table.insert(groove, points[i] + Vector3.new(0, 0, -0.045))
		end
		curvyLine(headGroup, "TongueGroove", groove, 0.035, 0.02, TONGUE:Lerp(BLACK, 0.35), toCF)
		local tip = points[#points]
		ellipsoid(headGroup, "Tongue", V(width * 0.9, width * 0.65, 0.1), headCF * CFrame.new(tip + Vector3.new(0, -0.04, 0)), TONGUE)
		ellipsoid(headGroup, "Blood", V(0.1, 0.14, 0.08), headCF * CFrame.new(tip + Vector3.new(0.03, -0.17, -0.02)), BLOOD)
	end

	if anomaly == "teeth" then
		-- 턱이 빠진 듯 쩍 벌어진 동그란 입: 검붉은 구멍 + 피 묻은 입술 테두리,
		-- 테두리를 따라 안쪽을 향한 송곳니, 구불구불 늘어진 혀
		local mouthCenterY = mouthY - 0.28
		local surfaceZ = headSurface(0, mouthCenterY, 0) or mouthZ
		local sp = Vector3.new(0, mouthCenterY, surfaceZ)
		local normal = (sp.Unit + Vector3.new(0, 0, -1.4)).Unit
		local mouthLocal = CFrame.lookAt(sp - normal * 0.06, sp - normal * 0.06 + normal)
		local mouthCF = headCF * mouthLocal
		local mw, mh = 0.9, 0.62 -- 입 너비, 높이
		ellipsoid(headGroup, "Gum", V(mw + 0.14, mh + 0.14, 0.26), mouthCF, BLOOD)
		ellipsoid(headGroup, "Mouth", V(mw, mh, 0.3), mouthCF * CFrame.new(0, 0, -0.02), DARK_BLOOD)
		local teeth = 11
		for i = 0, teeth - 1 do
			for _, upper in ipairs({ true, false }) do
				local t = (i + 0.5) / teeth
				local theta = upper and (math.rad(15) + t * math.rad(150)) or (math.rad(195) + t * math.rad(150))
				local rimPoint = Vector3.new(math.cos(theta) * mw / 2 * 0.95, math.sin(theta) * mh / 2 * 0.95, 0)
				local inward = -rimPoint.Unit
				local middle = math.abs(math.cos(theta)) < 0.5
				local h = (upper and 0.26 or 0.2) * (middle and 1 or 0.7) * (i % 2 == 0 and 1 or 0.75)
				local cf = mouthCF * CFrame.new(rimPoint + inward * (h / 2) + Vector3.new(0, 0, -0.17)) * CFrame.Angles(0, 0, theta - math.pi / 2)
				fang(headGroup, cf, h, 0.1, true)
			end
		end
		-- 혀: 입 아래쪽에서 나와 구불구불 늘어져요
		-- 입 안쪽에서 시작해 아랫니와 입술 위로 넘어온 다음 아래로 늘어져서, 끊기지 않고 하나로 이어져요.
		local lipOver = mouthLocal * Vector3.new(0.06, -mh / 2 - 0.04, -0.3)
		hangingTongue(lipOver + Vector3.new(0, -0.1, -0.02), 7, 0.3, {
			mouthLocal * Vector3.new(0.03, 0.02, -0.08),
			mouthLocal * Vector3.new(0.05, -mh * 0.25, -0.2),
			lipOver,
		})
		-- 아랫입술에서 흘러내리는 피
		for _, drip in ipairs({ { -0.3, 0.55 }, { 0.32, 0.8 } }) do
			local lip = mouthLocal * Vector3.new(drip[1], -math.sqrt(1 - (drip[1] / (mw / 2)) ^ 2) * mh / 2, -0.12)
			bloodDrip(lip.X, drip[2], lip.Y, lip.Z)
		end
	elseif anomaly == "mouth" then
		-- 입이 귀밑까지 쭉 찢어져서 웃고 있어요. 가운데에서 양쪽 볼까지 끊김 없이 하나로 이어져요.
		local function mouthPoint(x)
			local y = mouthY + 0.42 * x * x
			local sphereZ = headSurface(x, y, 0.03) or -0.2
			local front = math.max(0, 1 - (math.abs(x) / 0.45) ^ 2)
			local z = sphereZ + ((mouthZ - 0.02) - sphereZ) * front
			return Vector3.new(x, y, z)
		end
		local function mouthHeight(x)
			return 0.1 + 0.26 * (1 - (math.abs(x) / 0.95) ^ 2)
		end
		local steps = 14
		for i = 0, steps - 1 do
			local x1 = -0.95 + 1.9 * i / steps
			local x2 = -0.95 + 1.9 * (i + 1) / steps
			local p1, p2 = mouthPoint(x1), mouthPoint(x2)
			local mid = (p1 + p2) / 2
			local normal = mid.Unit
			local length = (p2 - p1).Magnitude + 0.03
			local h = mouthHeight((x1 + x2) / 2)
			local seg = headCF * CFrame.lookAt(mid, p2, normal)
			newPart(headGroup, "Mouth", "Part", V(h, 0.12, length), seg, DARK_BLOOD)
			newPart(headGroup, "MouthEdge", "Part", V(0.04, 0.13, length), seg * CFrame.new(h / 2, 0, 0), BLOOD)
			newPart(headGroup, "MouthEdge", "Part", V(0.04, 0.13, length), seg * CFrame.new(-h / 2, 0, 0), BLOOD)
			-- 위아래 이빨 (볼 쪽으로 갈수록 작아져요)
			local slope = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
			local toothBase = headCF * CFrame.lookAt(mid, mid + normal) * CFrame.Angles(0, 0, -slope)
			local scale = 0.5 + 0.5 * (1 - math.abs((x1 + x2) / 2) / 0.95)
			fang(headGroup, toothBase * CFrame.new(0, h * 0.32, -0.07), 0.2 * scale, 0.11, true)
			fang(headGroup, toothBase * CFrame.new(0, -h * 0.32, -0.07), 0.16 * scale, 0.1, false)
		end
		bloodDrip(-0.5, 0.6, mouthPoint(-0.5).Y - mouthHeight(-0.5) / 2)
		-- 가운데에서는 혀가 길게 늘어져요
		local tongueStart = mouthPoint(0.05)
		hangingTongue(Vector3.new(0.05, tongueStart.Y - mouthHeight(0.05) * 0.2, tongueStart.Z - 0.06), 9, 0.32)
		bloodDrip(0.55, 0.45, mouthPoint(0.55).Y - mouthHeight(0.55) / 2)
	else
		-- 살짝 웃는 w 모양 입
		for _, side in ipairs({ -1, 1 }) do
			ellipsoid(headGroup, "Mouth", V(0.24, 0.06, 0.05), at(side * 0.1, mouthY, mouthZ) * CFrame.Angles(0, 0, side * 0.45), rgb(60, 30, 30))
		end
	end

	-- 소품 (모자, 리본, 목도리, 베레모)
	if accessory == 1 then
		local hatColor = style:NextNumber() < 0.5 and rgb(30, 28, 30) or rgb(90, 70, 50)
		vcyl(headGroup, "HatBrim", 0.12, 2.3, at(0, 1.05, 0) * CFrame.Angles(math.rad(-6), 0, 0), hatColor)
		vcyl(headGroup, "HatCrown", 0.9, 1.5, at(0, 1.5, 0.05) * CFrame.Angles(math.rad(-6), 0, 0), hatColor)
		vcyl(headGroup, "HatBand", 0.18, 1.52, at(0, 1.15, 0.03) * CFrame.Angles(math.rad(-6), 0, 0), tieColor)
	elseif accessory == 2 then
		-- 머리 위 큰 리본
		local bows = { rgb(250, 160, 190), rgb(255, 120, 150), rgb(170, 150, 235), rgb(130, 200, 235), rgb(255, 210, 120) }
		local bowColor = bows[style:NextInteger(1, #bows)]
		-- 귀와 헷갈리지 않게 한쪽 이마 옆에 작게 달아요 (귀는 꼭 두 개만 보여야 해요)
		local bowCF = at(-0.62, 0.72, -0.82) * CFrame.Angles(math.rad(-35), math.rad(30), 0.35)
		for _, side in ipairs({ -1, 1 }) do
			ellipsoid(headGroup, "Bow", V(0.42, 0.32, 0.14), bowCF * CFrame.new(side * 0.2, 0, 0) * CFrame.Angles(0, 0, side * 0.35), bowColor)
		end
		ball(headGroup, "BowKnot", 0.16, bowCF * CFrame.new(0, 0, -0.04), bowColor:Lerp(BLACK, 0.1))
	elseif accessory == 3 then
		if weirdBody then
			vcyl(model, "Scarf", 0.45, 1.1, CFrame.new(0, 4.3, -0.3), tieColor)
		else
			ellipsoid(model, "Scarf", V(2.9, 0.5, 2.6), CFrame.new(0, 4.55, 0), tieColor)
		end
		if weirdBody then
			newPart(model, "ScarfEnd", "Part", V(0.35, 1.0, 0.1), CFrame.new(0.35, 3.85, -0.92) * CFrame.Angles(0, 0, 0.1), tieColor)
		else
			ellipsoid(model, "ScarfEnd", V(0.42, 1.1, 0.1), onTorso(0.5, -0.15, 0.04) * CFrame.Angles(0, 0, 0.1), tieColor)
		end
	elseif accessory == 4 then
		vcyl(headGroup, "Beret", 0.45, 1.9, at(0.15, 1.05, 0.05) * CFrame.Angles(0, 0, -0.15), tieColor)
		ball(headGroup, "BeretTop", 0.25, at(0.3, 1.32, 0.05), tieColor)
	end

	-- 꼬리
	if data.animal == "cat" or data.animal == "fox" then
		local size = data.animal == "fox" and V(0.75, 0.75, 1.9) or V(0.45, 0.45, 1.6)
		local tailCF = CFrame.new(0, 2.4, 1.6) * CFrame.Angles(math.rad(35), 0, 0)
		ellipsoid(model, "Tail", size, tailCF, fur)
		if data.animal == "fox" then
			ball(model, "TailTip", 0.75, tailCF * CFrame.new(0, 0, 0.9), WHITE)
		end
	elseif data.animal == "dog" then
		ellipsoid(model, "Tail", V(0.4, 0.4, 1.3), CFrame.new(0, 2.5, 1.4) * CFrame.Angles(math.rad(50), 0, 0), fur)
	else
		ball(model, "Tail", 0.7, CFrame.new(0, 2.4, 1.2), data.animal == "pig" and PINK or data.animal == "bear" and fur or light)
	end

	-- 얼굴 없는 도플갱어: 눈, 코, 입, 수염, 볼터치가 모두 사라진 매끈한 얼굴
	if anomaly == "noface" then
		local FACE_PARTS = {
			EyeWhite = true, Iris = true, Pupil = true, EyeShine = true, EyeVein = true,
			Nose = true, NoseShine = true, Muzzle = true, Snout = true, Nostril = true,
			Whisker = true, Mouth = true, BuckTooth = true, Blush = true,
		}
		for _, d in ipairs(headGroup:GetChildren()) do
			if FACE_PARTS[d.Name] then
				d:Destroy()
			end
		end
	end

	-- 거대한 눈알 도플갱어: 눈코입이 모두 사라지고, 얼굴을 꽉 채운 둥근 눈알 하나가 노려봐요.
	if anomaly == "bigeye" then
		local FACE_PARTS = {
			EyeWhite = true, Iris = true, Pupil = true, EyeShine = true, EyeVein = true,
			Nose = true, NoseShine = true, Muzzle = true, Snout = true, Nostril = true,
			Whisker = true, Mouth = true, MouthEdge = true, BuckTooth = true, Blush = true,
			Gum = true, Tongue = true, TongueGroove = true, Void = true, RedGlint = true,
			Blood = true, BlackTear = true, FaceVein = true,
		}
		for _, d in ipairs(headGroup:GetChildren()) do
			if FACE_PARTS[d.Name] then
				d:Destroy()
			end
		end
		local center = V(0, 0.05, -0.5)
		local radius = 0.98
		ball(headGroup, "BigEyeball", radius * 2, at(center.X, center.Y, center.Z), rgb(248, 245, 238))
		-- 커다란 홍채와 눈동자, 반짝이
		local front = center.Z - radius
		ellipsoid(headGroup, "BigIris", V(1.1, 1.1, 0.3), at(0, 0.05, front + 0.1), irisColor)
		ellipsoid(headGroup, "BigIrisRing", V(0.8, 0.8, 0.28), at(0, 0.05, front + 0.05), irisColor:Lerp(rgb(0, 0, 0), 0.35))
		ellipsoid(headGroup, "BigPupil", V(0.5, 0.5, 0.24), at(0, 0.05, front + 0.02), rgb(10, 8, 10))
		ball(headGroup, "BigEyeShine", 0.2, at(0.2, 0.3, front + 0.02), WHITE)
		ball(headGroup, "BigEyeShine", 0.09, at(-0.16, -0.12, front + 0.03), WHITE)
	end

	-- 눈이 여러 개인 도플갱어: 이마, 볼, 코 옆까지 사람 같은 눈이 잔뜩 떠 있어요.
	if anomaly == "manyeyes" then
		local spots = { V(0, 0.75, -0.95), V(-0.55, 0.55, -0.95), V(0.55, 0.55, -0.95), V(-0.75, -0.3, -0.85), V(0.75, -0.3, -0.85), V(0, 0.32, -1.13), V(-0.32, 0.95, -0.6), V(0.32, 0.95, -0.6) }
		for i, spot in ipairs(spots) do
			local surface = spot.Unit * 1.2
			local cf = headCF * CFrame.lookAt(surface, surface + surface.Unit) * CFrame.Angles(0, 0, (i % 3 - 1) * 0.25)
			local size = (i == 6) and 0.5 or 0.38
			ellipsoid(headGroup, "ExtraEye", V(size, size * 0.5, 0.1), cf * CFrame.new(0, 0, -0.01), rgb(245, 242, 235))
			disc(headGroup, "ExtraIris", size * 0.45, cf * CFrame.new(0, 0, -0.05), irisColor)
			disc(headGroup, "ExtraPupil", size * 0.2, cf * CFrame.new(0, 0, -0.06), rgb(15, 12, 15))
		end
	end

	-- 미니 인형 같은 2등신 비율: 몸은 작게, 머리는 아주 크게 (몸이 이상한 도플갱어는 그대로 길쭉하게)
	if not weirdBody then
		headGroup.Parent = nil
		pcall(function()
			model:ScaleTo(0.8)
		end)
		pcall(function()
			headGroup:ScaleTo(1.5)
		end)
		headGroup:PivotTo(CFrame.new(0, 5.65, 0))
		if anomaly == "upside" then
			-- 머리가 거꾸로 달린 도플갱어: 귀가 아래로, 턱이 위로
			headGroup:PivotTo(CFrame.new(0, 5.75, 0) * CFrame.Angles(0, 0, math.pi))
		end
		headGroup.Parent = model
	end

	return model
end

-- 피눈물: 눈동자 바로 밑에서 볼을 타고 주르륵 흘러내려요. (예약 사진의 도플갱어에게 가끔)
function Animals.addBloodTears(model)
	local headGroup = model:FindFirstChild("HeadGroup")
	local head = headGroup and headGroup:FindFirstChild("Head")
	if not head then
		return
	end
	local radius = head.Size.X / 2
	local down = -head.CFrame.UpVector
	local eyes = {}
	for _, d in ipairs(headGroup:GetChildren()) do
		if d.Name == "Pupil" then
			table.insert(eyes, d)
		end
	end
	for _, eye in ipairs(eyes) do
		local c, r = head.Position, radius
		local onHead = function(p)
			return c + (p - c).Unit * (r + 0.015)
		end
		local start = eye.Position + down * (r * 0.12)
		local prev = onHead(start)
		local step = r * 0.13
		for k = 1, 6 do
			local nextPos = onHead(start + down * (k * step) + head.CFrame.RightVector * math.sin(k * 1.3) * radius * 0.015)
			local mid = (prev + nextPos) / 2
			local width = radius * (0.07 - k * 0.004)
			newPart(headGroup, "BloodTear", "Part", V(width, width * 0.4, (nextPos - prev).Magnitude + 0.02), CFrame.lookAt(mid, nextPos, (mid - c).Unit), BLOOD)
			prev = nextPos
		end
		ball(headGroup, "BloodTearDrop", radius * 0.09, CFrame.new(prev + down * radius * 0.03), BLOOD)
	end
end

return Animals
