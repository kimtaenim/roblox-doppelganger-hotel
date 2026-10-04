-- 손님(동물 NPC)의 종류를 정하고, 파트를 조립해서 모델로 만드는 모듈이에요.
-- 서버(호텔에 걸어오는 실제 손님)와 클라이언트(예약 사진, CCTV 화면)가 같이 써요.
local Animals = {}

local rgb = Color3.fromRGB
local V = Vector3.new

Animals.Types = {
	cat = { name = "고양이", ears = "pointy", furs = { rgb(235, 150, 70), rgb(150, 150, 155), rgb(60, 60, 65), rgb(240, 238, 230) } },
	dog = { name = "강아지", ears = "floppy", furs = { rgb(165, 115, 70), rgb(225, 185, 115), rgb(245, 240, 230) } },
	rabbit = { name = "토끼", ears = "long", furs = { rgb(245, 245, 245), rgb(185, 185, 190), rgb(185, 145, 110) } },
	bear = { name = "곰", ears = "round", furs = { rgb(125, 85, 55), rgb(80, 58, 40), rgb(240, 240, 235) } },
	fox = { name = "여우", ears = "pointy", furs = { rgb(225, 115, 45), rgb(200, 90, 40) } },
	pig = { name = "돼지", ears = "small", furs = { rgb(245, 175, 175), rgb(235, 160, 165) } },
}

Animals.List = { "cat", "dog", "rabbit", "bear", "fox", "pig" }

Animals.Clothes = {
	rgb(70, 110, 190),
	rgb(190, 60, 60),
	rgb(70, 150, 90),
	rgb(230, 190, 60),
	rgb(130, 80, 170),
	rgb(60, 60, 70),
	rgb(240, 240, 240),
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
	local lapel = cloth:Lerp(Color3.new(0, 0, 0), 0.25)
	local ties = { rgb(150, 30, 40), rgb(30, 50, 110), rgb(200, 160, 50), rgb(40, 90, 60), rgb(20, 20, 20) }
	local tieColor = ties[style:NextInteger(1, #ties)]
	local shoeColor = style:NextNumber() < 0.5 and rgb(30, 22, 18) or rgb(90, 55, 30)
	local accessory = style:NextInteger(0, 5) -- 0 없음, 1 중절모, 2 안경, 3 목도리, 4 베레모, 5 나비넥타이

	local model = Instance.new("Model")
	model.Name = data.name or "Guest"

	local root = newPart(model, "Root", "Part", V(1, 0.2, 1), CFrame.new(0, 0.1, 0), fur)
	root.Transparency = 1
	model.PrimaryPart = root

	local weirdBody = anomaly == "body"

	-- 신발과 다리
	for _, side in ipairs({ -1, 1 }) do
		local x = side * 0.45
		newPart(model, "Shoe", "Part", V(0.75, 0.5, 0.8), CFrame.new(x, 0.25, 0), shoeColor)
		ball(model, "ShoeToe", 0.75, CFrame.new(x, 0.32, -0.42), shoeColor)
		vcyl(model, "Leg", 1.7, 0.68, CFrame.new(x, 1.3, 0), pants)
	end
	newPart(model, "Hips", "Part", V(1.7, 0.6, 1.3), CFrame.new(0, 2.15, 0), pants)

	-- 몸통 (재킷) + 셔츠, 넥타이, 단추, 벨트
	local torsoCF = weirdBody and CFrame.new(0, 3.3, -0.2) * CFrame.Angles(math.rad(-14), 0, 0) or CFrame.new(0, 3.2, 0)
	local torsoWidth = weirdBody and 1.3 or 1.9
	vcyl(model, "Torso", weirdBody and 2.6 or 2.3, torsoWidth, torsoCF, cloth)
	local front = -torsoWidth / 2
	vcyl(model, "Belt", 0.2, torsoWidth + 0.05, torsoCF * CFrame.new(0, -1.0, 0), rgb(30, 25, 20))
	newPart(model, "Buckle", "Part", V(0.3, 0.22, 0.06), torsoCF * CFrame.new(0, -1.0, front - 0.03), rgb(190, 150, 70))
	newPart(model, "Shirt", "Part", V(0.6, 1.0, 0.1), torsoCF * CFrame.new(0, 0.55, front + 0.02), WHITE)
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Lapel", "Part", V(0.3, 1.1, 0.08), torsoCF * CFrame.new(side * 0.36, 0.55, front - 0.01) * CFrame.Angles(0, 0, side * 0.3), lapel)
		ball(model, "Shoulder", 0.85, torsoCF * CFrame.new(side * (torsoWidth / 2 + 0.05), 0.9, 0), cloth)
	end
	if accessory == 5 then
		for _, side in ipairs({ -1, 1 }) do
			newPart(model, "BowTie", "WedgePart", V(0.08, 0.3, 0.3), torsoCF * CFrame.new(side * 0.15, 0.95, front - 0.04) * CFrame.Angles(0, side * math.rad(90), 0), tieColor)
		end
	else
		ball(model, "TieKnot", 0.2, torsoCF * CFrame.new(0, 0.95, front - 0.02), tieColor)
		newPart(model, "Tie", "Part", V(0.2, 0.85, 0.05), torsoCF * CFrame.new(0, 0.45, front - 0.03), tieColor)
	end
	for i = 0, 1 do
		ball(model, "Button", 0.12, torsoCF * CFrame.new(0.2, -0.3 - i * 0.35, front - 0.01), rgb(190, 150, 70))
	end
	-- 셔츠 깃, 가슴 주머니와 행커치프
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Collar", "Part", V(0.26, 0.16, 0.06), torsoCF * CFrame.new(side * 0.17, 1.02, front - 0.04) * CFrame.Angles(0, 0, side * 0.6), WHITE)
	end
	local pocketZ = -math.sqrt(math.max(0.01, (torsoWidth / 2) ^ 2 - 0.3)) - 0.02
	newPart(model, "PocketFlap", "Part", V(0.45, 0.08, 0.06), torsoCF * CFrame.new(-0.55, 0.4, pocketZ), lapel)
	newPart(model, "PocketSquare", "Part", V(0.22, 0.16, 0.05), torsoCF * CFrame.new(-0.55, 0.5, pocketZ - 0.01), tieColor:Lerp(WHITE, 0.4))

	-- 팔 (소매 + 흰 소맷부리 + 손)
	for _, side in ipairs({ -1, 1 }) do
		if weirdBody then
			-- 바닥까지 늘어진 팔과 긴 검은 손톱
			local x = side * 0.95
			vcyl(model, "Arm", 4.4, 0.42, CFrame.new(x, 2.4, -0.3) * CFrame.Angles(0, 0, side * 0.06), fur)
			for i = -1, 1 do
				local claw = CFrame.new(x + side * 0.15 + i * 0.12, 0.1, -0.3) * CFrame.Angles(0, 0, math.rad(180))
				fang(model, claw, 0.6, 0.12, false).Color = BLACK
			end
		else
			local armCF = CFrame.new(side * 1.2, 3.25, 0) * CFrame.Angles(0, 0, side * 0.07)
			vcyl(model, "Sleeve", 1.6, 0.6, armCF, cloth)
			vcyl(model, "Cuff", 0.14, 0.62, armCF * CFrame.new(0, -0.82, 0), WHITE)
			ball(model, "Hand", 0.62, armCF * CFrame.new(0, -1.1, 0), light)
			if side == -1 then
				vcyl(model, "Watch", 0.12, 0.66, armCF * CFrame.new(0, -0.68, 0), rgb(190, 150, 70))
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

	-- 귀 (안쪽은 분홍색)
	for _, side in ipairs({ -1, 1 }) do
		if def.ears == "pointy" or def.ears == "small" then
			local s = def.ears == "small" and 0.6 or 1
			local earCF = at(side * 0.65, 1.15, 0.1) * CFrame.Angles(0, 0, -side * 0.25)
			newPart(headGroup, "Ear", "WedgePart", V(0.25, 1.1 * s, 0.9 * s), earCF, fur)
			newPart(headGroup, "EarInner", "WedgePart", V(0.1, 0.75 * s, 0.55 * s), earCF * CFrame.new(0, -0.1 * s, -0.05), PINK)
			ball(headGroup, "EarFluff", 0.3 * s, earCF * CFrame.new(0, -0.35 * s, -0.15), light)
		elseif def.ears == "floppy" then
			newPart(headGroup, "Ear", "Part", V(0.35, 1.5, 0.8), at(side * 1.18, -0.05, 0) * CFrame.Angles(0, 0, side * 0.25), dark)
			ball(headGroup, "EarTip", 0.8, at(side * 1.32, -0.75, 0), dark)
		elseif def.ears == "long" then
			local earCF = at(side * 0.45, 2.1, 0) * CFrame.Angles(0, 0, -side * 0.12)
			newPart(headGroup, "Ear", "Part", V(0.5, 2.2, 0.3), earCF, fur)
			ball(headGroup, "EarTip", 0.5, earCF * CFrame.new(0, 1.05, 0), fur)
			newPart(headGroup, "EarInner", "Part", V(0.3, 1.7, 0.1), earCF * CFrame.new(0, 0, -0.12), PINK)
		elseif def.ears == "round" then
			ball(headGroup, "Ear", 0.85, at(side * 0.85, 0.95, 0), fur)
			ball(headGroup, "EarInner", 0.45, at(side * 0.85, 0.95, -0.28), dark)
		end
	end

	-- 주둥이, 코, 볼, 수염
	local mouthY, mouthZ = -0.6, -1.2
	if data.animal == "pig" then
		local snout = newPart(headGroup, "Snout", "Part", V(0.5, 0.9, 0.9), at(0, -0.2, -1.2) * CFrame.Angles(0, math.rad(90), 0), PINK)
		snout.Shape = Enum.PartType.Cylinder
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "Nostril", 0.15, at(side * 0.17, -0.2, -1.45), BLACK)
		end
		mouthY, mouthZ = -0.78, -0.95
	elseif data.animal == "bear" then
		ball(headGroup, "Muzzle", 1.0, at(0, -0.35, -0.9), light)
		ball(headGroup, "Nose", 0.34, at(0, -0.15, -1.36), BLACK)
		mouthZ = -1.3
	else
		local size = data.animal == "dog" and 0.85 or 0.72
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "Muzzle", size, at(side * 0.22, -0.38, -0.95), light)
		end
		ball(headGroup, "Chin", 0.55, at(0, -0.62, -0.88), light)
		if data.animal == "fox" then
			ball(headGroup, "Snout", 0.55, at(0, -0.28, -1.22), light)
		end
		ball(headGroup, "Nose", 0.28, at(0, -0.12, data.animal == "fox" and -1.47 or -1.3), data.animal == "rabbit" and PINK or BLACK)
		if data.animal == "rabbit" and not isMonster then
			newPart(headGroup, "BuckTooth", "Part", V(0.22, 0.22, 0.06), at(0, -0.72, -1.15), WHITE)
		end
		if data.animal == "cat" or data.animal == "fox" or data.animal == "rabbit" then
			for _, side in ipairs({ -1, 1 }) do
				for i = 0, 1 do
					newPart(headGroup, "Whisker", "Part", V(0.9, 0.03, 0.03), at(side * 0.75, -0.3 - i * 0.12, -1.05) * CFrame.Angles(0, -side * 0.35, side * (0.12 - i * 0.2)), rgb(60, 55, 50))
				end
			end
		end
	end
	-- 코끝 반짝임
	local nose = headGroup:FindFirstChild("Nose")
	if nose then
		ball(headGroup, "NoseShine", 0.08, nose.CFrame * CFrame.new(-0.05, 0.07, -0.1), WHITE)
	end

	-- 통통한 볼살 (얼굴 아래쪽을 둥글고 넓게)
	if data.animal ~= "pig" then
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "CheekFluff", 0.95, at(side * 0.78, -0.32, -0.5), fur)
		end
	end
	-- 이마의 털 뭉치 (고양이·여우·강아지)
	if data.animal == "cat" or data.animal == "fox" or data.animal == "dog" then
		for i = -1, 1 do
			newPart(headGroup, "Tuft", "WedgePart", V(0.18, 0.35, 0.4), at(i * 0.2, 1.08, -0.45) * CFrame.Angles(math.rad(-30), 0, i * 0.3), fur)
		end
	end
	if not isMonster then
		for _, side in ipairs({ -1, 1 }) do
			local blush = newPart(headGroup, "Blush", "Part", V(0.4, 0.22, 0.05), at(side * 0.72, -0.12, -0.92) * CFrame.Angles(0, -side * 0.6, 0), PINK)
			blush.Transparency = 0.35
		end
	end

	-- 눈썹
	for _, side in ipairs({ -1, 1 }) do
		local angle = isMonster and side * 0.45 or -side * 0.12
		newPart(headGroup, "Brow", "Part", V(0.42, 0.08, 0.06), at(side * 0.45, 0.72, -1.0) * CFrame.Angles(0, 0, angle), dark:Lerp(BLACK, 0.4))
	end

	-- 도플갱어: 퀭하게 꺼진 눈두덩, 얼굴의 검붉은 핏줄, 셔츠의 핏자국
	if isMonster then
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "Socket", 0.78, at(side * 0.45, 0.3, -0.84), rgb(35, 18, 22))
		end
		local veinRandom = Random.new((data.id or 1) + 99)
		for _ = 1, 7 do
			local vx, vy = veinRandom:NextNumber(-0.8, 0.8), veinRandom:NextNumber(-0.4, 1.0)
			local vz = -math.sqrt(math.max(0.05, 1.44 - vx * vx - vy * vy)) - 0.01
			newPart(headGroup, "FaceVein", "Part", V(0.03, veinRandom:NextNumber(0.3, 0.6), 0.03), at(vx, vy, vz) * CFrame.Angles(0, 0, veinRandom:NextNumber(-1, 1)), rgb(90, 20, 40))
		end
		for _ = 1, 4 do
			newPart(model, "BloodStain", "Part", V(veinRandom:NextNumber(0.2, 0.5), veinRandom:NextNumber(0.2, 0.6), 0.04), torsoCF * CFrame.new(veinRandom:NextNumber(-0.6, 0.6), veinRandom:NextNumber(-0.8, 0.6), front - 0.05), BLOOD)
		end
	end

	-- 눈
	local irises = { rgb(200, 140, 40), rgb(90, 150, 60), rgb(110, 70, 40), rgb(70, 120, 190) }
	local irisColor = irises[style:NextInteger(1, #irises)]
	if anomaly == "eyes" then
		-- 눈 자리가 새까맣게 뚫려 있고, 검은 눈물이 흘러내리고, 이마와 볼에 작은 눈이 더 있어요.
		for _, side in ipairs({ -1, 1 }) do
			local x = side * 0.45
			ball(headGroup, "Void", 0.72, at(x, 0.3, -0.92), BLACK)
			local glint = ball(headGroup, "RedGlint", 0.09, at(x, 0.3, -1.29), rgb(255, 30, 30))
			glint.Material = Enum.Material.Neon
			newPart(headGroup, "BlackTear", "Part", V(0.14, 1.7, 0.1), at(x, -0.55, -1.02) * CFrame.Angles(math.rad(-20), 0, 0), BLACK)
			newPart(headGroup, "BlackTear", "Part", V(0.08, 1.1, 0.1), at(x + side * 0.2, -0.35, -0.98) * CFrame.Angles(math.rad(-15), 0, 0), BLACK)
		end
		for _, spot in ipairs({ V(0, 0.85, -0.85), V(-0.75, -0.05, -0.92), V(0.55, 0.95, -0.7) }) do
			local cf = at(spot.X, spot.Y, spot.Z)
			ball(headGroup, "ExtraEye", 0.3, cf, rgb(245, 225, 215))
			local red = ball(headGroup, "ExtraPupil", 0.12, cf * CFrame.new(0, 0, -0.12), rgb(200, 0, 0))
			red.Material = Enum.Material.Neon
		end
	else
		-- 이빨/입 도플갱어는 핏발 선 눈에 빨갛게 빛나는 바늘 같은 눈동자로 노려봐요.
		local stare = anomaly == "teeth" or anomaly == "mouth"
		for _, side in ipairs({ -1, 1 }) do
			local x = side * 0.45
			local sclera = ball(headGroup, "EyeWhite", 0.56, at(x, 0.3, -0.97), WHITE)
			if stare then
				sclera.Color = rgb(250, 215, 210)
				for i = -1, 1, 2 do
					newPart(headGroup, "Vein", "Part", V(0.2, 0.03, 0.03), at(x + i * 0.13, 0.3 + i * 0.05, -1.22) * CFrame.Angles(0, 0, i * 0.5), rgb(200, 30, 30))
				end
				local pupil = ball(headGroup, "Pupil", 0.08, at(x, 0.3, -1.24), rgb(255, 20, 20))
				pupil.Material = Enum.Material.Neon
			else
				ball(headGroup, "Iris", 0.42, at(x, 0.3, -1.1), irisColor)
				ball(headGroup, "Pupil", 0.22, at(x, 0.3, -1.24), BLACK)
				ball(headGroup, "EyeShine", 0.1, at(x - 0.07, 0.38, -1.36), WHITE)
				ball(headGroup, "EyeShine", 0.05, at(x + 0.06, 0.23, -1.35), WHITE)
			end
			-- 윗눈꺼풀 (부드러운 눈매)
			newPart(headGroup, "Eyelid", "Part", V(0.62, 0.13, 0.3), at(x, 0.57, -0.98) * CFrame.Angles(math.rad(-15), 0, -side * 0.1), dark)
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
		-- 입이 귀밑까지 쭉 찢어져서 웃고 있어요.
		newPart(headGroup, "Mouth", "Part", V(1.2, 0.45, 0.1), at(0, mouthY, mouthZ - 0.12), DARK_BLOOD)
		for _, side in ipairs({ -1, 1 }) do
			local cheek = at(side * 0.82, mouthY + 0.28, -0.85) * CFrame.Angles(0, side * 0.6, side * 0.5)
			newPart(headGroup, "TornMouth", "Part", V(1.25, 0.32, 0.35), cheek, DARK_BLOOD)
			newPart(headGroup, "TornEdge", "Part", V(1.25, 0.05, 0.37), cheek * CFrame.new(0, 0.17, 0), BLOOD)
			newPart(headGroup, "TornEdge", "Part", V(1.25, 0.05, 0.37), cheek * CFrame.new(0, -0.17, 0), BLOOD)
			for i = 0, 4 do
				local toothCF = cheek * CFrame.new(-side * 0.45 + side * i * 0.22, 0, -0.18)
				fang(headGroup, toothCF * CFrame.new(0, 0.08, 0), 0.18, 0.1, true)
				fang(headGroup, toothCF * CFrame.new(0.05, -0.08, 0), 0.15, 0.09, false)
			end
		end
		for i = 1, 8 do
			fang(headGroup, at((i - 4.5) * 0.14, mouthY + 0.14, mouthZ - 0.17), 0.22, 0.12, true)
			fang(headGroup, at((i - 4.5) * 0.14, mouthY - 0.15, mouthZ - 0.17), 0.18, 0.1, false)
		end
		bloodDrip(-0.45, 0.7)
		bloodDrip(0.05, 1.2)
		bloodDrip(0.45, 0.5)
	else
		-- 살짝 웃는 w 모양 입
		for _, side in ipairs({ -1, 1 }) do
			newPart(headGroup, "Mouth", "Part", V(0.22, 0.05, 0.05), at(side * 0.1, mouthY, mouthZ) * CFrame.Angles(0, 0, side * 0.45), rgb(60, 30, 30))
		end
	end

	-- 소품 (모자, 안경, 목도리, 베레모)
	if accessory == 1 then
		local hatColor = style:NextNumber() < 0.5 and rgb(30, 28, 30) or rgb(90, 70, 50)
		vcyl(headGroup, "HatBrim", 0.12, 2.3, at(0, 1.05, 0) * CFrame.Angles(math.rad(-6), 0, 0), hatColor)
		vcyl(headGroup, "HatCrown", 0.9, 1.5, at(0, 1.5, 0.05) * CFrame.Angles(math.rad(-6), 0, 0), hatColor)
		vcyl(headGroup, "HatBand", 0.18, 1.52, at(0, 1.15, 0.03) * CFrame.Angles(math.rad(-6), 0, 0), tieColor)
	elseif accessory == 2 then
		for _, side in ipairs({ -1, 1 }) do
			local lens = newPart(headGroup, "Glasses", "Part", V(0.06, 0.62, 0.62), at(side * 0.45, 0.3, -1.3) * CFrame.Angles(0, math.rad(90), 0), rgb(200, 220, 230))
			lens.Shape = Enum.PartType.Cylinder
			lens.Transparency = 0.7
			local rim = newPart(headGroup, "GlassesRim", "Part", V(0.04, 0.68, 0.68), at(side * 0.45, 0.3, -1.27) * CFrame.Angles(0, math.rad(90), 0), rgb(40, 30, 25))
			rim.Shape = Enum.PartType.Cylinder
			rim.Transparency = 0.15
		end
		newPart(headGroup, "GlassesBridge", "Part", V(0.3, 0.05, 0.05), at(0, 0.36, -1.32), rgb(40, 30, 25))
	elseif accessory == 3 then
		vcyl(model, "Scarf", 0.45, 1.1, CFrame.new(0, 4.3, weirdBody and -0.3 or 0), tieColor)
		newPart(model, "ScarfEnd", "Part", V(0.35, 1.0, 0.1), CFrame.new(0.35, 3.85, (weirdBody and -0.3 or 0) - 0.62) * CFrame.Angles(0, 0, 0.1), tieColor)
	elseif accessory == 4 then
		vcyl(headGroup, "Beret", 0.45, 1.9, at(0.15, 1.05, 0.05) * CFrame.Angles(0, 0, -0.15), tieColor)
		ball(headGroup, "BeretTop", 0.25, at(0.3, 1.32, 0.05), tieColor)
	end

	-- 꼬리
	if data.animal == "cat" or data.animal == "fox" then
		local size = data.animal == "fox" and V(0.7, 0.7, 1.8) or V(0.35, 0.35, 1.6)
		local tailCF = CFrame.new(0, 2.4, 1.25) * CFrame.Angles(math.rad(35), 0, 0)
		newPart(model, "Tail", "Part", size, tailCF, fur)
		if data.animal == "fox" then
			ball(model, "TailTip", 0.75, tailCF * CFrame.new(0, 0, 0.9), WHITE)
		end
	elseif data.animal == "dog" then
		newPart(model, "Tail", "Part", V(0.35, 0.35, 1.2), CFrame.new(0, 2.5, 1.1) * CFrame.Angles(math.rad(50), 0, 0), fur)
	else
		ball(model, "Tail", 0.6, CFrame.new(0, 2.3, 0.8), data.animal == "pig" and PINK or light)
	end

	return model
end

return Animals
