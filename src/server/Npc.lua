-- 손님 NPC를 걷게 하고, 밤에 실종된 손님의 소지품을 놓는 기능이에요.
local RunService = game:GetService("RunService")

local Npc = {}

-- target 위치까지 speed 속도로 걸어가요. (걷는 동안 살짝 통통 튀어요)
function Npc.walkTo(model, target, speed)
	local start = model:GetPivot().Position
	local offset = target - start
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local distance = flat.Magnitude
	if distance < 0.1 then
		return
	end

	local rotation = CFrame.lookAt(Vector3.zero, flat).Rotation
	local duration = distance / speed
	local elapsed = 0
	while elapsed < duration do
		if not model.Parent then
			return
		end
		elapsed = math.min(elapsed + RunService.Heartbeat:Wait(), duration)
		local position = start:Lerp(target, elapsed / duration)
		local bob = math.abs(math.sin(elapsed * 9)) * 0.3
		model:PivotTo(CFrame.new(position + Vector3.new(0, bob, 0)) * rotation)
	end
	if model.Parent then
		model:PivotTo(CFrame.new(target) * rotation)
	end
end

-- point 쪽을 바라보게 돌려요.
function Npc.face(model, point)
	local position = model:GetPivot().Position
	model:PivotTo(CFrame.lookAt(position, Vector3.new(point.X, position.Y, point.Z)))
end

-- 머리 위에 말풍선을 띄워요. 새 대사를 하면 이전 말풍선은 사라져요.
function Npc.say(model, text, duration)
	local headGroup = model:FindFirstChild("HeadGroup")
	local head = headGroup and headGroup.PrimaryPart
	if not head then
		return
	end
	local old = head:FindFirstChild("Speech")
	if old then
		old:Destroy()
	end

	local bubble = Instance.new("BillboardGui")
	bubble.Name = "Speech"
	bubble.Size = UDim2.fromOffset(200, 44)
	bubble.StudsOffset = Vector3.new(0, 2.8, 0)
	bubble.AlwaysOnTop = true
	bubble.MaxDistance = 80
	bubble.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	label.TextColor3 = Color3.fromRGB(20, 20, 20)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	label.Parent = bubble
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = label
	local size = Instance.new("UITextSizeConstraint")
	size.MaxTextSize = 14
	size.Parent = label

	task.delay(duration or 4, function()
		if bubble.Parent then
			bubble:Destroy()
		end
	end)
end

-- 도플갱어에게 당한 손님은 사라지고, 바닥에 소지품만 덩그러니 남아요. (그 아래에 작은 핏자국)
function Npc.spawnBelongings(data, position, parent)
	local rgb = Color3.fromRGB
	local group = Instance.new("Model")
	group.Name = "Missing_" .. (data.name or "Guest")

	local function part(name, size, cf, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then
			p.Shape = shape
		end
		p.Parent = group
		return p
	end

	local floorY = position.Y + 0.02
	local base = CFrame.new(position.X, floorY, position.Z) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	local cloth = data.cloth or rgb(160, 120, 90)

	-- 핏물 웅덩이: 소지품 아래에서 넓게 번져 나와요. (가장자리는 검붉게, 가운데는 번들번들)
	local function blot(name, size, offset, color, lift, gloss)
		local p = part(name, Vector3.new(size.X, 0.04, size.Y), base * CFrame.new(offset + Vector3.new(0, lift, 0)) * CFrame.Angles(0, math.random() * math.pi, 0), color)
		p.Reflectance = gloss
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	local pools = {
		-- 가방 앞쪽으로 절반 넘게 흘러나온 웅덩이 (어느 쪽에서 봐도 보이게 뒤쪽에도 조금)
		{ Vector2.new(2.4, 1.8), Vector3.new(0.4, 0, 1.4) },
		{ Vector2.new(1, 0.8), Vector3.new(1.6, 0, 1.9) },
		{ Vector2.new(1.1, 0.85), Vector3.new(-0.4, 0, -1.2) },
	}
	for _, pool in ipairs(pools) do
		local size, offset = pool[1], pool[2]
		blot("BloodEdge", size + Vector2.new(0.2, 0.2), offset, rgb(55, 0, 2), 0, 0.05)
		blot("BloodPool", size, offset, rgb(100, 2, 6), 0.01, 0.2)
		blot("BloodShine", size * 0.35, offset + Vector3.new(0.3, 0, -0.2), rgb(145, 10, 14), 0.02, 0.5)
	end
	-- 튄 핏방울: 큰 웅덩이에서 한쪽 방향(앞쪽)으로만 부채꼴로 튀어요. 멀어질수록 작고 길쭉해요.
	local center = Vector3.new(0.4, 0, 1.4)
	for i = 1, 12 do
		local angle = math.pi / 2 + (math.random() - 0.5) * math.rad(60) -- 앞쪽(+Z) 기준 좌우 30도 안
		local distance = 1.1 + math.random() * 1.3
		local away = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local size = 0.28 - (distance - 1.1) * 0.12 + math.random() * 0.06
		local pos = center + away * distance
		local drop = part("BloodDrop", Vector3.new(size, 0.04, size * (1.4 + math.random())), base * CFrame.new(pos + Vector3.new(0, 0.006, 0)) * CFrame.Angles(0, -angle + math.pi / 2, 0), (i % 2 == 0) and rgb(90, 0, 3) or rgb(115, 4, 8))
		drop.Reflectance = 0.15
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = drop
		-- 큰 방울 몇 개는 바깥쪽에 작은 방울 꼬리가 붙어요
		if i % 3 == 0 then
			local tail = part("BloodDrop", Vector3.new(size * 0.45, 0.04, size * 0.45), base * CFrame.new(pos + away * (size * 1.6) + Vector3.new(0, 0.006, 0)), rgb(90, 0, 3))
			local tailMesh = Instance.new("SpecialMesh")
			tailMesh.MeshType = Enum.MeshType.Sphere
			tailMesh.Parent = tail
		end
	end

	-- 바닥에 눕혀진 낡은 가죽 여행 가방: 모서리 놋쇠 장식, 가죽 끈 두 줄, 둥근 손잡이, 손님 옷 색 꼬리표
	local leather = rgb(105, 62, 38)
	local brass = rgb(196, 156, 84)
	local bag = base * CFrame.new(0.2, 0.3, 0) * CFrame.Angles(0, 0.3, 0)
	local L, H, W = 2.3, 0.55, 1.5
	part("Suitcase", Vector3.new(L, H, W), bag, leather, Enum.Material.Leather)
	part("SuitcaseSeam", Vector3.new(L + 0.02, 0.06, W + 0.02), bag, rgb(70, 40, 25), Enum.Material.Leather) -- 뚜껑과 몸통 사이 이음새
	for _, x in ipairs({ -0.55, 0.55 }) do
		part("SuitcaseStrap", Vector3.new(0.2, H + 0.04, W + 0.04), bag * CFrame.new(x, 0, 0), rgb(60, 36, 22), Enum.Material.Leather)
		part("StrapBuckle", Vector3.new(0.24, 0.05, 0.18), bag * CFrame.new(x, H / 2 + 0.03, -0.3), brass, Enum.Material.Metal)
	end
	for _, cx in ipairs({ -1, 1 }) do
		for _, cz in ipairs({ -1, 1 }) do
			part("CornerCap", Vector3.new(0.22, H + 0.04, 0.22), bag * CFrame.new(cx * (L / 2 - 0.08), 0, cz * (W / 2 - 0.08)), brass, Enum.Material.Metal)
		end
	end
	-- 앞쪽 긴 옆면의 둥근 손잡이
	local front = bag * CFrame.new(0, 0, -W / 2 - 0.06)
	part("HandleBar", Vector3.new(0.6, 0.12, 0.12), front * CFrame.new(0, 0.05, -0.12), rgb(50, 30, 18), Enum.Material.Leather)
	for _, x in ipairs({ -0.3, 0.3 }) do
		part("HandleFoot", Vector3.new(0.1, 0.1, 0.22), front * CFrame.new(x, 0.05, -0.02), brass, Enum.Material.Metal)
	end
	-- 손님 옷 색의 짐표 꼬리표
	part("LuggageTag", Vector3.new(0.4, 0.04, 0.26), bag * CFrame.new(0.95, H / 2 + 0.03, 0.35) * CFrame.Angles(0, 0.4, 0), cloth)

	-- 바닥에 떨어진 모자 (옆으로 누워 있어요)
	local hat = base * CFrame.new(-1.4, 0.46, -0.5) * CFrame.Angles(0, 0.6, 0) -- 원기둥이 옆으로 누운 채
	part("HatCrown", Vector3.new(1, 0.9, 0.9), hat, rgb(35, 30, 32), Enum.Material.Fabric, Enum.PartType.Cylinder)
	part("HatBrim", Vector3.new(0.1, 1.5, 1.5), hat * CFrame.new(-0.5, 0, 0), rgb(35, 30, 32), Enum.Material.Fabric, Enum.PartType.Cylinder)

	-- 객실 열쇠 (놋쇠 꼬리표에 방 번호)
	local key = base * CFrame.new(0.9, 0.05, 1.1) * CFrame.Angles(0, 0.8, 0)
	part("KeyTag", Vector3.new(0.5, 0.06, 0.28), key, rgb(196, 156, 84), Enum.Material.Metal)
	part("Key", Vector3.new(0.5, 0.05, 0.08), key * CFrame.new(0.45, 0, 0), rgb(170, 170, 160), Enum.Material.Metal)

	group.Parent = parent
	return group
end

return Npc
