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
Animals.AnomalyKinds = { "teeth", "mouth", "eyes", "body", "moving" }
Animals.AnomalyNames = {
	teeth = "이빨이 드러남",
	mouth = "입이 쭉 찢어짐",
	eyes = "눈이 검게 가려짐",
	body = "몸이 이상함",
	moving = "사진이 움직임",
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
	else
		ellipsoid(model, "Hips", V(2.2, 0.8, 1.9), CFrame.new(0, 2.4, 0), pants)
	end

	-- 몸통: 머리 바로 밑에 붙은 넓고 둥근 덩어리 (머리와 이어져서 서양배·베개 모양이 돼요)
	-- 몸이 이상한 도플갱어만 가늘고 길쭉해요.
	local torsoCF = weirdBody and CFrame.new(0, 3.3, -0.2) * CFrame.Angles(math.rad(-14), 0, 0) or CFrame.new(0, 3.85, 0)
	local torsoSize = weirdBody and V(1.4, 2.9, 1.1) or V(2.4, 2.7, 2.4)
	-- 셔츠, 넥타이, 단추 높이 (몸통 가운데 기준, 머리에 가려지지 않는 곳)
	local Y = weirdBody and { collar = 1.05, knot = 0.98, tie = 0.45, shirt = 0.75, button = -0.25, pocket = 0.5, pocketX = -0.5 }
		or { collar = 0.42, knot = 0.38, tie = -0.1, shirt = 0.1, button = -0.6, pocket = -0.1, pocketX = -0.62 }
	local tw, th, td = torsoSize.X / 2, torsoSize.Y / 2, torsoSize.Z / 2
	local edge = 0.5 -- 둥근 모서리의 반지름
	if weirdBody then
		ellipsoid(model, "Torso", torsoSize, torsoCF, cloth)
	else
		-- 모서리가 둥근 원통: 가운데 원통 + 위아래 납작한 타원으로 모서리를 둥글게 이어요.
		vcyl(model, "Torso", torsoSize.Y - edge * 2, torsoSize.X, torsoCF, cloth)
		ellipsoid(model, "TorsoTop", V(torsoSize.X, edge * 2, torsoSize.Z), torsoCF * CFrame.new(0, th - edge, 0), cloth)
		ellipsoid(model, "TorsoBottom", V(torsoSize.X, edge * 2, torsoSize.Z), torsoCF * CFrame.new(0, -(th - edge), 0), cloth)
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
		local straight = th - edge
		local over = math.max(0, math.abs(y) - straight)
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
	for i = 0, 1 do
		ball(model, "Button", 0.13, onTorso(0.28, Y.button - i * 0.38, 0), rgb(190, 150, 70))
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
			ellipsoid(headGroup, "Ear", V(0.75 * s, 1.15 * s, 0.32), earCF, fur)
			ellipsoid(headGroup, "EarInner", V(0.42 * s, 0.75 * s, 0.12), earCF * CFrame.new(0, -0.05 * s, -0.12), PINK)
			ball(headGroup, "EarFluff", 0.3 * s, earCF * CFrame.new(0, -0.32 * s, -0.15), light)
		elseif def.ears == "floppy" then
			ellipsoid(headGroup, "Ear", V(0.5, 1.6, 0.85), at(side * 1.2, -0.15, 0.05) * CFrame.Angles(0, 0, side * 0.25), dark)
		elseif def.ears == "long" then
			local earCF = at(side * 0.42, 2.0, 0.05) * CFrame.Angles(0, 0, -side * 0.12)
			ellipsoid(headGroup, "Ear", V(0.6, 2.4, 0.34), earCF, fur)
			ellipsoid(headGroup, "EarInner", V(0.34, 1.8, 0.12), earCF * CFrame.new(0, 0, -0.13), PINK)
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
					newPart(headGroup, "Whisker", "Part", V(0.6, 0.025, 0.025), at(side * 0.55, -0.52 - i * 0.1, -1.0) * CFrame.Angles(0, -side * 0.35, side * (0.1 - i * 0.18)), rgb(150, 130, 120))
				end
			end
		end
	end
	-- 코끝 반짝임
	local nose = headGroup:FindFirstChild("Nose")
	if nose then
		ball(headGroup, "NoseShine", 0.05, nose.CFrame * CFrame.new(-0.03, 0.04, -0.06), WHITE)
	end

	-- 통통한 볼살 (얼굴 아래쪽을 둥글고 넓게)
	if data.animal ~= "pig" then
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "CheekFluff", 0.8, at(side * 0.8, -0.4, -0.45), fur)
		end
	end
	-- 이마의 털 뭉치 (고양이·여우·강아지)
	if data.animal == "cat" or data.animal == "fox" or data.animal == "dog" then
		for i = -1, 1 do
			ellipsoid(headGroup, "Tuft", V(0.22, 0.45, 0.25), at(i * 0.2, 1.08, -0.45) * CFrame.Angles(math.rad(-30), 0, i * 0.3), fur)
		end
	end
	if not isMonster then
		for _, side in ipairs({ -1, 1 }) do
			local blush = ellipsoid(headGroup, "Blush", V(0.42, 0.24, 0.08), at(side * 0.78, -0.42, -0.82) * CFrame.Angles(0, -side * 0.75, 0), rgb(255, 150, 170))
			blush.Transparency = 0.15
		end
	end


	-- 도플갱어: 퀭하게 꺼진 눈두덩, 얼굴의 검붉은 핏줄, 셔츠의 핏자국
	if isMonster then
		local veinRandom = Random.new((data.id or 1) + 99)
		for _ = 1, 7 do
			local vx, vy = veinRandom:NextNumber(-0.8, 0.8), veinRandom:NextNumber(-0.4, 1.0)
			local vz = -math.sqrt(math.max(0.05, 1.44 - vx * vx - vy * vy)) - 0.01
			newPart(headGroup, "FaceVein", "Part", V(0.03, veinRandom:NextNumber(0.3, 0.6), 0.03), at(vx, vy, vz) * CFrame.Angles(0, 0, veinRandom:NextNumber(-1, 1)), rgb(90, 20, 40))
		end
		for _ = 1, 4 do
			newPart(model, "BloodStain", "Part", V(veinRandom:NextNumber(0.2, 0.5), veinRandom:NextNumber(0.2, 0.6), 0.04), onTorso(veinRandom:NextNumber(-0.5, 0.5), veinRandom:NextNumber(-0.7, 0.5), 0.01), BLOOD)
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
	local function bloodDrip(x, length)
		newPart(headGroup, "Blood", "Part", V(0.08, length, 0.06), at(x, mouthY - 0.2 - length / 2, mouthZ + 0.08), BLOOD)
	end

	if anomaly == "teeth" then
		-- 턱이 빠진 듯 쩍 벌어진 입, 빽빽한 송곳니, 길게 늘어진 혀
		newPart(headGroup, "Mouth", "Part", V(0.95, 0.95, 0.08), at(0, mouthY - 0.28, mouthZ - 0.12), DARK_BLOOD)
		newPart(headGroup, "Gum", "Part", V(0.95, 0.08, 0.09), at(0, mouthY + 0.18, mouthZ - 0.13), BLOOD)
		newPart(headGroup, "Gum", "Part", V(0.95, 0.08, 0.09), at(0, mouthY - 0.74, mouthZ - 0.13), BLOOD)
		for i = 1, 7 do
			local x = (i - 4) * 0.13
			fang(headGroup, at(x, mouthY + 0.02, mouthZ - 0.16), i % 3 == 1 and 0.36 or 0.24, 0.12, true)
			fang(headGroup, at(x + 0.06, mouthY - 0.6, mouthZ - 0.16), i % 3 == 2 and 0.32 or 0.2, 0.11, false)
		end
		newPart(headGroup, "Tongue", "Part", V(0.3, 1.5, 0.1), at(0.12, mouthY - 1.1, mouthZ - 0.2) * CFrame.Angles(math.rad(-10), 0, 0.15), rgb(120, 20, 35))
		bloodDrip(-0.3, 0.7)
		bloodDrip(0.3, 1.0)
	elseif anomaly == "mouth" then
		-- 입이 귀밑까지 쭉 찢어져서 웃고 있어요. 가운데에서 양쪽 볼까지 끊김 없이 하나로 이어져요.
		local function mouthPoint(x)
			local y = mouthY + 0.42 * x * x
			local sphereZ = -math.sqrt(math.max(0.05, 1.44 - x * x - y * y)) - 0.03
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
		bloodDrip(-0.45, 0.7)
		bloodDrip(0.05, 1.2)
		bloodDrip(0.45, 0.5)
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
		for _, side in ipairs({ -1, 1 }) do
			ellipsoid(headGroup, "Bow", V(0.75, 0.55, 0.28), at(side * 0.4, 1.0, -0.35) * CFrame.Angles(math.rad(-25), 0, side * 0.35), bowColor)
		end
		ball(headGroup, "BowKnot", 0.3, at(0, 1.02, -0.42), bowColor:Lerp(BLACK, 0.1))
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
		ball(model, "Tail", 0.7, CFrame.new(0, 2.4, 1.2), data.animal == "pig" and PINK or light)
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
		headGroup.Parent = model
	end

	return model
end

return Animals
