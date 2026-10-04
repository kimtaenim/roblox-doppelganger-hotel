-- 여러 곳에서 같이 쓰는 소품 만들기 도우미예요. (꽃, 화분, 책가방 등)
local Props = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local Mat = Enum.Material

Props.Colors = {
	WOOD = rgb(52, 32, 22),
	WOOD_DARK = rgb(32, 20, 14),
	BRASS = rgb(176, 136, 66),
	LEAF = rgb(50, 95, 50),
	LEAF_DARK = rgb(30, 65, 35),
}
local C = Props.Colors

-- 부딪히지 않는 장식 파트
function Props.part(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
	p.Color = color
	p.Material = material or Mat.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
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
local P = Props.part

-- 부딪히는 파트 (가구 몸체처럼 막혀야 하는 것)
function Props.solid(parent, name, size, cf, color, material, props)
	local p = P(parent, name, size, cf, color, material, props)
	p.CanCollide = true
	return p
end

function Props.ball(parent, name, diameter, pos, color, material)
	local p = P(parent, name, V(diameter, diameter, diameter), pos, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- 원기둥: cf 의 X축 방향으로 길어요.
function Props.cyl(parent, name, length, diameter, cf, color, material)
	local p = P(parent, name, V(length, diameter, diameter), cf, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- 세워진 원기둥
function Props.vcyl(parent, name, height, diameter, pos, color, material)
	return Props.cyl(parent, name, height, diameter, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material)
end

function Props.text(target, face, value, color, font, background)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = background and 0 or 1
	label.BackgroundColor3 = background or Color3.new(1, 1, 1)
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = font or Enum.Font.Garamond
	label.Text = value
	label.TextColor3 = color
	label.Parent = gui
	return label
end

-- 꽃 한 송이: 노란 꽃술 + 꽃잎 5장 + 줄기. pos 는 꽃송이 위치예요.
function Props.flower(parent, pos, petalColor, size, stemLength)
	size = size or 0.5
	local center = CFrame.new(pos)
	Props.ball(parent, "FlowerCenter", size * 0.35, pos, rgb(240, 200, 70))
	for i = 0, 4 do
		local angle = i * math.pi * 2 / 5
		local petal = center * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -size * 0.32) * CFrame.Angles(math.rad(-25), 0, 0)
		local p = P(parent, "Petal", V(size * 0.42, 0.04, size * 0.5), petal, petalColor)
		p.Material = Mat.SmoothPlastic
	end
	if stemLength and stemLength > 0 then
		P(parent, "Stem", V(0.06, stemLength, 0.06), center * CFrame.new(0, -stemLength / 2, 0), C.LEAF)
		P(parent, "Leaf", V(0.3, 0.03, 0.14), center * CFrame.new(0.12, -stemLength * 0.55, 0) * CFrame.Angles(0, 0, -0.5), C.LEAF)
	end
end

-- 장미 한 송이: 겹겹이 말린 꽃잎
function Props.rose(parent, pos, color, stemLength)
	Props.ball(parent, "RoseBud", 0.32, pos, color)
	for i = 0, 3 do
		local cf = CFrame.new(pos) * CFrame.Angles(0, i * math.pi / 2, 0) * CFrame.new(0, -0.02, -0.14) * CFrame.Angles(math.rad(-35), 0, 0)
		P(parent, "RosePetal", V(0.3, 0.22, 0.05), cf, color:Lerp(Color3.new(0, 0, 0), 0.15))
	end
	if stemLength then
		P(parent, "Stem", V(0.05, stemLength, 0.05), CFrame.new(pos) * CFrame.new(0, -stemLength / 2 - 0.12, 0), C.LEAF_DARK)
	end
end

-- 백합 한 송이: 뒤로 젖혀진 길쭉한 흰 꽃잎 6장
function Props.lily(parent, pos, stemLength)
	Props.ball(parent, "LilyCenter", 0.14, pos, rgb(220, 150, 60))
	for i = 0, 5 do
		local cf = CFrame.new(pos) * CFrame.Angles(0, i * math.pi / 3, 0) * CFrame.new(0, 0.05, -0.28) * CFrame.Angles(math.rad(-50), 0, 0)
		P(parent, "LilyPetal", V(0.18, 0.04, 0.6), cf, rgb(250, 248, 240))
	end
	if stemLength then
		P(parent, "Stem", V(0.05, stemLength, 0.05), CFrame.new(pos) * CFrame.new(0, -stemLength / 2, 0), C.LEAF)
	end
end

-- 꽃병에 꽂힌 꽃다발. kind: "rose" / "lily" / "flower"
function Props.bouquet(parent, base, kind, color, count, vaseColor)
	local vaseHeight = 1.1
	local vase = Props.vcyl(parent, "Vase", vaseHeight, 0.7, base + V(0, vaseHeight / 2, 0), vaseColor or rgb(60, 90, 80), Mat.Glass)
	vase.Transparency = 0.25
	Props.vcyl(parent, "VaseWater", 0.6, 0.6, base + V(0, 0.35, 0), rgb(120, 140, 120), Mat.Glass).Transparency = 0.5
	local random = Random.new(math.floor(base.X * 7 + base.Z * 13))
	for i = 1, count or 7 do
		local angle = i * 2.4
		local radius = random:NextNumber(0.1, 0.45)
		local height = random:NextNumber(1.2, 1.8)
		local pos = base + V(math.cos(angle) * radius, vaseHeight + height * 0.6, math.sin(angle) * radius)
		if kind == "rose" then
			Props.rose(parent, pos, color, height * 0.6)
		elseif kind == "lily" then
			Props.lily(parent, pos, height * 0.6)
		else
			Props.flower(parent, pos, color, 0.5, height * 0.6)
		end
	end
	for i = 1, 3 do
		local cf = CFrame.new(base + V(0, vaseHeight + 0.3, 0)) * CFrame.Angles(0, i * 2.1, 0) * CFrame.new(0, 0, -0.35) * CFrame.Angles(math.rad(-50), 0, 0)
		P(parent, "BouquetLeaf", V(0.25, 0.03, 0.7), cf, C.LEAF)
	end
end

-- 큰 화분 식물 (몬스테라 같은 넓은 잎)
function Props.plant(parent, base, height)
	height = height or 4
	Props.vcyl(parent, "PlanterPot", 1.6, 2.0, base + V(0, 0.8, 0), rgb(40, 34, 30), Mat.Concrete)
	Props.vcyl(parent, "PlanterRim", 0.2, 2.2, base + V(0, 1.6, 0), C.BRASS, Mat.Metal)
	Props.vcyl(parent, "Soil", 0.1, 1.8, base + V(0, 1.55, 0), rgb(45, 30, 20))
	local random = Random.new(math.floor(base.X * 3 + base.Z * 5))
	for i = 1, 9 do
		local yaw = i * 0.7 + random:NextNumber(-0.2, 0.2)
		local tilt = random:NextNumber(0.4, 0.9)
		local stemLength = height * random:NextNumber(0.5, 0.9)
		local stem = CFrame.new(base + V(0, 1.6, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-tilt * 0.5, 0, 0)
		P(parent, "PlantStem", V(0.08, stemLength, 0.08), stem * CFrame.new(0, stemLength / 2, 0), C.LEAF_DARK)
		local tip = stem * CFrame.new(0, stemLength, 0)
		local leaf = P(parent, "PlantLeaf", V(1.3, 0.05, 1.7), tip * CFrame.Angles(-tilt, 0, 0) * CFrame.new(0, 0, -0.6), i % 2 == 0 and C.LEAF or C.LEAF_DARK)
		leaf.Material = Mat.Grass
	end
end

-- 노란 책가방. cf 는 가방의 가운데이고, -Z 쪽이 앞주머니예요.
function Props.backpack(parent, cf)
	local bag = Instance.new("Model")
	bag.Name = "Backpack"
	local yellow = rgb(235, 185, 40)
	P(bag, "BagBody", V(1.2, 1.4, 0.6), cf, yellow, Mat.Fabric)
	P(bag, "BagTop", V(1.2, 0.3, 0.62), cf * CFrame.new(0, 0.75, 0) , yellow:Lerp(Color3.new(0, 0, 0), 0.15), Mat.Fabric)
	P(bag, "BagPocket", V(0.9, 0.6, 0.2), cf * CFrame.new(0, -0.3, -0.38), yellow:Lerp(Color3.new(1, 1, 1), 0.15), Mat.Fabric)
	for _, side in ipairs({ -1, 1 }) do
		P(bag, "BagStrap", V(0.15, 1.3, 0.08), cf * CFrame.new(side * 0.35, 0, 0.34), rgb(80, 60, 30), Mat.Fabric)
	end
	P(bag, "BagZip", V(0.9, 0.05, 0.05), cf * CFrame.new(0, 0.62, -0.32), rgb(60, 60, 60), Mat.Metal)
	-- 열쇠고리 (작은 토끼 얼굴)
	Props.ball(bag, "Charm", 0.22, (cf * CFrame.new(0.4, 0.5, -0.4)).Position, rgb(250, 240, 240))
	bag.PrimaryPart = bag.BagBody
	bag.Parent = parent
	return bag
end

return Props
