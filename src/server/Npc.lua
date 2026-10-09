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

	-- 작은 핏자국 (소지품 아래로 살짝 번져 나와요)
	local function puddle(size, offset)
		part("Blood", Vector3.new(0.04, size, size * 0.8), base * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90)), rgb(95, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder).Reflectance = 0.15
	end
	puddle(2.6, Vector3.new(0.6, 0, 0.9)) -- 가방 아래에서 앞으로 번져 나와요
	puddle(1.1, Vector3.new(1.7, 0, 1.6))
	puddle(0.45, Vector3.new(2.4, 0, 0.6))
	puddle(0.3, Vector3.new(-0.4, 0, 2))

	-- 쓰러진 여행 가방 (손님 옷 색)
	local bag = base * CFrame.new(0.2, 0.42, 0) * CFrame.Angles(0, 0.3, 0)
	part("Suitcase", Vector3.new(2, 0.8, 1.4), bag, cloth:Lerp(rgb(60, 45, 35), 0.35), Enum.Material.Leather)
	part("SuitcaseStrap", Vector3.new(2.02, 0.82, 0.18), bag, rgb(90, 60, 40), Enum.Material.Leather)
	part("SuitcaseHandle", Vector3.new(0.7, 0.12, 0.12), bag * CFrame.new(0, 0.1, -0.76), rgb(40, 30, 25))
	for _, x in ipairs({ -0.75, 0.75 }) do
		part("SuitcaseLatch", Vector3.new(0.2, 0.15, 0.05), bag * CFrame.new(x, 0.25, -0.72), rgb(196, 156, 84), Enum.Material.Metal)
	end

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
