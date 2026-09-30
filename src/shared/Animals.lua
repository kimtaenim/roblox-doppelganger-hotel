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

-- data: { name, animal, fur, cloth }
-- anomaly: nil 이면 멀쩡한 모습, "teeth"/"mouth"/"eyes"/"body" 면 그 무서운 모습이 보여요.
-- ("moving" 은 모양은 멀쩡하고, 사진 화면에서 머리가 움직이게 만들어요.)
-- 모델의 앞쪽은 -Z 방향이고, 기준점(Pivot)은 발 밑이에요.
-- 머리와 얼굴 파트는 "HeadGroup" 모델 안에 있어요. (말풍선, 움직이는 사진에서 써요)
function Animals.build(data, anomaly)
	local def = Animals.Types[data.animal] or Animals.Types.cat
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
	local pants = cloth:Lerp(Color3.new(0, 0, 0), 0.45)

	local model = Instance.new("Model")
	model.Name = data.name or "Guest"

	local root = newPart(model, "Root", "Part", V(1, 0.2, 1), CFrame.new(0, 0.1, 0), fur)
	root.Transparency = 1
	model.PrimaryPart = root

	local weirdBody = anomaly == "body"

	-- 다리와 몸통
	newPart(model, "LeftLeg", "Part", V(0.8, 2, 0.8), CFrame.new(-0.5, 1, 0), pants)
	newPart(model, "RightLeg", "Part", V(0.8, 2, 0.8), CFrame.new(0.5, 1, 0), pants)
	if weirdBody then
		-- 앙상하게 마르고 앞으로 꺾인 몸
		newPart(model, "Body", "Part", V(1.5, 2.6, 1.1), CFrame.new(0, 3.3, -0.2) * CFrame.Angles(math.rad(-12), 0, 0), cloth)
	else
		newPart(model, "Body", "Part", V(2.2, 2.4, 1.6), CFrame.new(0, 3.2, 0), cloth)
	end

	-- 팔 (이상한 몸이면 바닥까지 늘어지고 긴 손톱이 있어요)
	for _, side in ipairs({ -1, 1 }) do
		if weirdBody then
			local x = side * 1.1
			newPart(model, "Arm", "Part", V(0.45, 4.6, 0.45), CFrame.new(x, 2.1, -0.3) * CFrame.Angles(0, 0, side * 0.08), fur)
			for i = -1, 1 do
				local claw = CFrame.new(x + side * 0.2 + i * 0.13, -0.05, -0.3) * CFrame.Angles(0, 0, math.rad(180))
				fang(model, claw, 0.6, 0.12, false).Color = BLACK
			end
		else
			newPart(model, "Arm", "Part", V(0.6, 2, 0.6), CFrame.new(side * 1.45, 3.2, 0), fur)
		end
	end

	-- 머리 (이상한 몸이면 목이 길게 늘어나고 머리가 옆으로 꺾여 매달려요)
	local headGroup = Instance.new("Model")
	headGroup.Name = "HeadGroup"
	headGroup.Parent = model

	local headCF
	if weirdBody then
		newPart(model, "Neck", "Part", V(0.5, 2.4, 0.5), CFrame.new(0, 5.6, -0.3), fur)
		newPart(model, "NeckBent", "Part", V(0.5, 1.8, 0.5), CFrame.new(0.55, 7.2, -0.3) * CFrame.Angles(0, 0, math.rad(-40)), fur)
		headCF = CFrame.new(1.6, 7.3, -0.3) * CFrame.Angles(0, 0, math.rad(-105))
	else
		headCF = CFrame.new(0, 5.6, 0)
	end
	local head = ball(headGroup, "Head", 2.4, headCF, fur)
	headGroup.PrimaryPart = head

	local function at(x, y, z)
		return headCF * CFrame.new(x, y, z)
	end

	-- 귀
	for _, side in ipairs({ -1, 1 }) do
		if def.ears == "pointy" or def.ears == "small" then
			local s = def.ears == "small" and 0.6 or 1
			newPart(headGroup, "Ear", "WedgePart", V(0.25, 1.1 * s, 0.9 * s), at(side * 0.65, 1.15, 0.1) * CFrame.Angles(0, 0, -side * 0.25), fur)
		elseif def.ears == "floppy" then
			newPart(headGroup, "Ear", "Part", V(0.35, 1.4, 0.8), at(side * 1.2, 0, 0) * CFrame.Angles(0, 0, side * 0.25), dark)
		elseif def.ears == "long" then
			local earCF = at(side * 0.45, 2.1, 0) * CFrame.Angles(0, 0, -side * 0.12)
			newPart(headGroup, "Ear", "Part", V(0.5, 2.2, 0.3), earCF, fur)
			newPart(headGroup, "EarInner", "Part", V(0.3, 1.7, 0.1), earCF * CFrame.new(0, 0, -0.12), PINK)
		elseif def.ears == "round" then
			ball(headGroup, "Ear", 0.8, at(side * 0.85, 0.95, 0), fur)
		end
	end

	-- 주둥이와 코
	local mouthY, mouthZ = -0.55, -1.31
	if data.animal == "pig" then
		local snout = newPart(headGroup, "Snout", "Part", V(0.5, 0.9, 0.9), at(0, -0.2, -1.2) * CFrame.Angles(0, math.rad(90), 0), PINK)
		snout.Shape = Enum.PartType.Cylinder
		for _, side in ipairs({ -1, 1 }) do
			ball(headGroup, "Nostril", 0.15, at(side * 0.17, -0.2, -1.45), BLACK)
		end
		mouthY, mouthZ = -0.78, -0.95
	else
		newPart(headGroup, "Muzzle", "Part", V(0.9, 0.6, 0.5), at(0, -0.35, -1.05), light)
		ball(headGroup, "Nose", 0.3, at(0, -0.12, -1.32), BLACK)
	end

	-- 눈: 흰자위 + 눈동자 + 반짝임
	if anomaly == "eyes" then
		-- 눈이 있어야 할 자리가 새까맣게 뚫려 있고, 검은 눈물이 흘러내려요.
		for _, side in ipairs({ -1, 1 }) do
			local x = side * 0.45
			ball(headGroup, "Void", 0.7, at(x, 0.3, -0.92), BLACK)
			local glint = ball(headGroup, "RedGlint", 0.09, at(x, 0.3, -1.28), rgb(255, 30, 30))
			glint.Material = Enum.Material.Neon
			newPart(headGroup, "BlackTear", "Part", V(0.14, 1.7, 0.1), at(x, -0.55, -1.02) * CFrame.Angles(math.rad(-20), 0, 0), BLACK)
			newPart(headGroup, "BlackTear", "Part", V(0.08, 1.1, 0.1), at(x + side * 0.2, -0.35, -0.98) * CFrame.Angles(math.rad(-15), 0, 0), BLACK)
		end
	else
		-- 이빨/입 도플갱어는 눈동자가 바늘처럼 작아져서 뚫어지게 쳐다봐요.
		local stare = anomaly == "teeth" or anomaly == "mouth"
		local pupil = stare and 0.08 or 0.24
		for _, side in ipairs({ -1, 1 }) do
			local x = side * 0.45
			local sclera = ball(headGroup, "EyeWhite", 0.5, at(x, 0.3, -0.98), WHITE)
			if stare then
				sclera.Color = rgb(250, 225, 220)
				for i = -1, 1, 2 do
					newPart(headGroup, "Vein", "Part", V(0.2, 0.03, 0.03), at(x + i * 0.12, 0.3 + i * 0.05, -1.21) * CFrame.Angles(0, 0, i * 0.5), rgb(200, 30, 30))
				end
			end
			ball(headGroup, "Pupil", pupil, at(x, 0.3, -1.26 + pupil / 2), BLACK)
			if not stare then
				ball(headGroup, "EyeShine", 0.08, at(x - 0.05, 0.37, -1.3), WHITE)
			end
		end
	end

	-- 입
	local function bloodDrip(x, length)
		newPart(headGroup, "Blood", "Part", V(0.08, length, 0.06), at(x, mouthY - 0.2 - length / 2, mouthZ + 0.08), BLOOD)
	end

	if anomaly == "teeth" then
		-- 쩍 벌어진 입 안에 뾰족한 이빨이 빽빽해요.
		newPart(headGroup, "Mouth", "Part", V(0.95, 0.6, 0.08), at(0, mouthY - 0.1, mouthZ - 0.01), DARK_BLOOD)
		newPart(headGroup, "Gum", "Part", V(0.95, 0.08, 0.09), at(0, mouthY + 0.18, mouthZ - 0.02), BLOOD)
		newPart(headGroup, "Gum", "Part", V(0.95, 0.08, 0.09), at(0, mouthY - 0.38, mouthZ - 0.02), BLOOD)
		for i = 1, 7 do
			local x = (i - 4) * 0.13
			fang(headGroup, at(x, mouthY + 0.05, mouthZ - 0.05), 0.24, 0.12, true)
			fang(headGroup, at(x + 0.06, mouthY - 0.26, mouthZ - 0.05), 0.2, 0.11, false)
		end
		bloodDrip(-0.3, 0.5)
		bloodDrip(0.25, 0.8)
	elseif anomaly == "mouth" then
		-- 입이 귀밑까지 쭉 찢어져서 웃고 있어요.
		newPart(headGroup, "Mouth", "Part", V(1.0, 0.36, 0.1), at(0, mouthY, mouthZ - 0.01), DARK_BLOOD)
		for _, side in ipairs({ -1, 1 }) do
			local cheek = at(side * 0.8, mouthY + 0.22, -0.85) * CFrame.Angles(0, side * 0.6, side * 0.45)
			newPart(headGroup, "TornMouth", "Part", V(1.1, 0.26, 0.35), cheek, DARK_BLOOD)
			newPart(headGroup, "TornEdge", "Part", V(1.1, 0.05, 0.37), cheek * CFrame.new(0, 0.14, 0), BLOOD)
			newPart(headGroup, "TornEdge", "Part", V(1.1, 0.05, 0.37), cheek * CFrame.new(0, -0.14, 0), BLOOD)
			for i = 0, 3 do
				local toothCF = cheek * CFrame.new(-side * 0.35 + side * i * 0.22, 0, -0.18)
				fang(headGroup, toothCF * CFrame.new(0, 0.06, 0), 0.16, 0.1, true)
			end
		end
		for i = 1, 6 do
			fang(headGroup, at((i - 3.5) * 0.15, mouthY + 0.1, mouthZ - 0.06), 0.2, 0.12, true)
			fang(headGroup, at((i - 3.5) * 0.15, mouthY - 0.12, mouthZ - 0.06), 0.16, 0.1, false)
		end
		bloodDrip(-0.4, 0.6)
		bloodDrip(0.05, 1.0)
		bloodDrip(0.42, 0.45)
	else
		newPart(headGroup, "Mouth", "Part", V(0.45, 0.08, 0.06), at(0, mouthY, mouthZ), rgb(60, 30, 30))
	end

	-- 꼬리
	if data.animal == "cat" or data.animal == "dog" or data.animal == "fox" then
		local size = data.animal == "fox" and V(0.7, 0.7, 1.8) or V(0.4, 0.4, 1.4)
		newPart(model, "Tail", "Part", size, CFrame.new(0, 2.5, 1.3) * CFrame.Angles(math.rad(35), 0, 0), fur)
	else
		ball(model, "Tail", 0.6, CFrame.new(0, 2.3, 0.85), data.animal == "pig" and PINK or light)
	end

	return model
end

return Animals
