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

local function newPart(model, name, className, size, cframe, color)
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
	part.Parent = model
	return part
end

local function ball(model, name, diameter, cframe, color)
	local part = newPart(model, name, "Part", V(diameter, diameter, diameter), cframe, color)
	part.Shape = Enum.PartType.Ball
	return part
end

-- data: { name, animal, fur, cloth }
-- anomaly: nil 이면 멀쩡한 모습, "teeth"/"mouth"/"eyes"/"body" 면 그 이상한 점이 보여요.
-- ("moving" 은 모양은 멀쩡하고, 사진 화면에서 움직이게 만들어요.)
-- 모델의 앞쪽은 -Z 방향이고, 기준점(Pivot)은 발 밑이에요.
function Animals.build(data, anomaly)
	local def = Animals.Types[data.animal] or Animals.Types.cat
	local fur = data.fur or def.furs[1]
	local cloth = data.cloth or Animals.Clothes[1]
	local light = fur:Lerp(Color3.new(1, 1, 1), 0.55)
	local dark = fur:Lerp(Color3.new(0, 0, 0), 0.35)
	local pants = cloth:Lerp(Color3.new(0, 0, 0), 0.45)
	local pink = rgb(240, 160, 170)
	local black = rgb(20, 20, 20)
	local blood = rgb(90, 0, 0)
	local white = rgb(250, 250, 245)

	local model = Instance.new("Model")
	model.Name = data.name or "Guest"

	local root = newPart(model, "Root", "Part", V(1, 0.2, 1), CFrame.new(0, 0.1, 0), fur)
	root.Transparency = 1
	model.PrimaryPart = root

	local weirdBody = anomaly == "body"

	-- 다리와 몸통
	newPart(model, "LeftLeg", "Part", V(0.8, 2, 0.8), CFrame.new(-0.5, 1, 0), pants)
	newPart(model, "RightLeg", "Part", V(0.8, 2, 0.8), CFrame.new(0.5, 1, 0), pants)
	newPart(model, "Body", "Part", V(2.2, 2.4, 1.6), CFrame.new(0, 3.2, 0), cloth)

	-- 팔 (이상한 몸이면 바닥까지 길게 늘어나요)
	local armLength = weirdBody and 4.2 or 2
	local armY = 4.2 - armLength / 2
	newPart(model, "LeftArm", "Part", V(0.6, armLength, 0.6), CFrame.new(-1.45, armY, 0), fur)
	newPart(model, "RightArm", "Part", V(0.6, armLength, 0.6), CFrame.new(1.45, armY, 0), fur)

	-- 머리 (이상한 몸이면 목이 길게 늘어나고 머리가 꺾여요)
	local headCF
	if weirdBody then
		newPart(model, "Neck", "Part", V(0.7, 2.6, 0.7), CFrame.new(0, 5.6, 0), fur)
		headCF = CFrame.new(0, 7.6, 0) * CFrame.Angles(0, 0, math.rad(28))
	else
		headCF = CFrame.new(0, 5.6, 0)
	end
	ball(model, "Head", 2.4, headCF, fur)

	-- 귀
	for _, side in ipairs({ -1, 1 }) do
		if def.ears == "pointy" or def.ears == "small" then
			local s = def.ears == "small" and 0.6 or 1
			newPart(
				model,
				"Ear",
				"WedgePart",
				V(0.25, 1.1 * s, 0.9 * s),
				headCF * CFrame.new(side * 0.65, 1.15, 0.1) * CFrame.Angles(0, 0, -side * 0.25),
				fur
			)
		elseif def.ears == "floppy" then
			newPart(
				model,
				"Ear",
				"Part",
				V(0.35, 1.4, 0.8),
				headCF * CFrame.new(side * 1.2, 0, 0) * CFrame.Angles(0, 0, side * 0.25),
				dark
			)
		elseif def.ears == "long" then
			local earCF = headCF * CFrame.new(side * 0.45, 2.1, 0) * CFrame.Angles(0, 0, -side * 0.12)
			newPart(model, "Ear", "Part", V(0.5, 2.2, 0.3), earCF, fur)
			newPart(model, "EarInner", "Part", V(0.3, 1.7, 0.1), earCF * CFrame.new(0, 0, -0.12), pink)
		elseif def.ears == "round" then
			ball(model, "Ear", 0.8, headCF * CFrame.new(side * 0.85, 0.95, 0), fur)
		end
	end

	-- 주둥이와 코
	local mouthY, mouthZ = -0.55, -1.31
	if data.animal == "pig" then
		local snout = newPart(
			model,
			"Snout",
			"Part",
			V(0.5, 0.9, 0.9),
			headCF * CFrame.new(0, -0.2, -1.2) * CFrame.Angles(0, math.rad(90), 0),
			pink
		)
		snout.Shape = Enum.PartType.Cylinder
		for _, side in ipairs({ -1, 1 }) do
			ball(model, "Nostril", 0.15, headCF * CFrame.new(side * 0.17, -0.2, -1.45), black)
		end
		mouthY, mouthZ = -0.78, -0.95
	else
		newPart(model, "Muzzle", "Part", V(0.9, 0.6, 0.5), headCF * CFrame.new(0, -0.35, -1.05), light)
		ball(model, "Nose", 0.3, headCF * CFrame.new(0, -0.12, -1.32), black)
	end

	-- 눈
	if anomaly == "eyes" then
		newPart(model, "BlackEyes", "Part", V(1.7, 0.7, 0.25), headCF * CFrame.new(0, 0.3, -1.0), black)
		for _, side in ipairs({ -1, 1 }) do
			newPart(model, "Drip", "Part", V(0.15, 0.6, 0.1), headCF * CFrame.new(side * 0.5, -0.15, -1.08), black)
		end
	else
		for _, side in ipairs({ -1, 1 }) do
			ball(model, "Eye", 0.34, headCF * CFrame.new(side * 0.45, 0.3, -1.03), black)
			ball(model, "EyeShine", 0.1, headCF * CFrame.new(side * 0.4, 0.38, -1.18), white)
		end
	end

	-- 입
	local function teeth(count, width, y)
		for i = 1, count do
			local x = (i - (count + 1) / 2) * (width / count)
			newPart(model, "Tooth", "Part", V(0.1, 0.16, 0.05), headCF * CFrame.new(x, y, mouthZ - 0.04), white)
		end
	end

	if anomaly == "teeth" then
		newPart(model, "Mouth", "Part", V(0.8, 0.35, 0.06), headCF * CFrame.new(0, mouthY - 0.05, mouthZ - 0.01), blood)
		teeth(4, 0.7, mouthY + 0.06)
		teeth(4, 0.7, mouthY - 0.16)
	elseif anomaly == "mouth" then
		newPart(model, "Mouth", "Part", V(1.0, 0.32, 0.08), headCF * CFrame.new(0, mouthY, mouthZ - 0.01), blood)
		for _, side in ipairs({ -1, 1 }) do
			newPart(
				model,
				"TornMouth",
				"Part",
				V(1.0, 0.2, 0.3),
				headCF * CFrame.new(side * 0.85, mouthY + 0.25, -0.8) * CFrame.Angles(0, side * 0.6, side * 0.45),
				blood
			)
		end
		teeth(6, 0.9, mouthY + 0.08)
	else
		newPart(model, "Mouth", "Part", V(0.45, 0.08, 0.06), headCF * CFrame.new(0, mouthY, mouthZ), rgb(60, 30, 30))
	end

	-- 꼬리
	if data.animal == "cat" or data.animal == "dog" or data.animal == "fox" then
		local size = data.animal == "fox" and V(0.7, 0.7, 1.8) or V(0.4, 0.4, 1.4)
		newPart(model, "Tail", "Part", size, CFrame.new(0, 2.5, 1.3) * CFrame.Angles(math.rad(35), 0, 0), fur)
	else
		ball(model, "Tail", 0.6, CFrame.new(0, 2.3, 0.85), data.animal == "pig" and pink or light)
	end

	return model
end

return Animals
