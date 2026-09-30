-- 손님 NPC를 걷게 하고, 밤에 사체를 놓는 기능이에요.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))

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

-- 도플갱어에게 당한 손님의 사체를 바닥에 눕혀 놓아요.
function Npc.spawnCorpse(data, position, parent)
	local body = Animals.build(data, nil)
	body.Name = "Corpse_" .. (data.name or "Guest")

	for _, part in ipairs(body:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Color = part.Color:Lerp(Color3.fromRGB(120, 120, 125), 0.45)
		end
	end

	-- 등을 대고 누운 모습
	local yaw = CFrame.Angles(0, math.random() * math.pi * 2, 0)
	body:PivotTo(CFrame.new(position + Vector3.new(0, 1.2, 0)) * yaw * CFrame.Angles(math.rad(90), 0, 0))

	-- 핏자국
	local center = position + yaw:VectorToWorldSpace(Vector3.new(0, 0, 3))
	local function puddle(size, offset)
		local part = Instance.new("Part")
		part.Name = "Blood"
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.05, size, size)
		part.CFrame = CFrame.new(center.X + offset.X, position.Y + 0.03, center.Z + offset.Z)
			* CFrame.Angles(0, 0, math.rad(90))
		part.Color = Color3.fromRGB(100, 0, 0)
		part.Material = Enum.Material.SmoothPlastic
		part.Reflectance = 0.1
		part.Anchored = true
		part.CanCollide = false
		part.Parent = body
	end
	puddle(7, Vector3.zero)
	for _ = 1, 3 do
		puddle(1 + math.random() * 1.5, Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
	end

	body.Parent = parent
	return body
end

return Npc
