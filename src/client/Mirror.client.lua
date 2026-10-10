-- 복도 끝 거울 그리기
-- 로블록스에는 진짜로 비추는 거울이 없어요. 그래서 거울 앞에 있는 것들(복도, 문, 사람, 물고기...)을
-- 이 화면에서만 거울 면을 기준으로 뒤집어 복사하고, 거울 뒤 빈 공간에 놓아요.
-- 유리 너머로 그 복사본이 보이면 진짜 거울처럼 보여요. 움직이는 것도 매 프레임 따라 움직여요.
--
-- 거울 이상(Strange 속성): "back" 이면 거울 속 내가 뒤돌아 서 있고, "none" 이면 사람이 비치지 않아요.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local folder = Instance.new("Folder")
folder.Name = "MirrorReflections"
folder.Parent = camera

local mirrors = {} -- 거울 유리 파트 목록
local active = nil -- 지금 그리고 있는 거울 { glass, clones = {[원본] = 복사본}, hidden = {[파트] = true} }
local KEEP = { SpecialMesh = true, Decal = true, Texture = true, SurfaceAppearance = true, PointLight = true, SpotLight = true, SurfaceLight = true }

local function watch(inst)
	if inst:IsA("BasePart") and inst.Name == "MirrorGlass" then
		table.insert(mirrors, inst)
	end
end
for _, inst in ipairs(workspace:GetDescendants()) do
	watch(inst)
end
workspace.DescendantAdded:Connect(watch)

-- 거울 면: 유리 앞면의 위치와 바깥쪽 방향
local function plane(glass)
	local cf = glass.CFrame
	return cf.Position + cf.LookVector * (glass.Size.Z / 2), cf.LookVector
end

local function reflectVector(v, n)
	return v - n * (2 * v:Dot(n))
end

-- 파트 하나를 거울 면에 비친 자리로. 거울에 비치면 왼손·오른손이 바뀌는데,
-- 파트의 X축 하나를 뒤집으면 모양(상자·공·원기둥·쐐기)은 그대로라서 그대로 쓸 수 있어요.
local function reflectCFrame(cf, origin, n)
	local p = cf.Position
	local p2 = p - n * (2 * (p - origin):Dot(n))
	return CFrame.fromMatrix(p2, -reflectVector(cf.XVector, n), reflectVector(cf.YVector, n), reflectVector(cf.ZVector, n))
end

local function characterOf(part)
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if Players:GetPlayerFromCharacter(model) then
			return model
		end
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function makeClone(src)
	local ok, copy = pcall(function()
		local wasArchivable = src.Archivable
		src.Archivable = true
		local c = src:Clone()
		src.Archivable = wasArchivable
		return c
	end)
	if not ok or not copy then
		return nil
	end
	for _, d in ipairs(copy:GetChildren()) do
		if not KEEP[d.ClassName] then
			d:Destroy()
		end
	end
	copy.Anchored = true
	copy.CanCollide = false
	copy.CanQuery = false
	copy.CanTouch = false
	copy.CastShadow = false
	copy.Parent = folder
	return copy
end

local function stop()
	if not active then
		return
	end
	for part in pairs(active.hidden) do
		if part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
	folder:ClearAllChildren()
	active = nil
end

local function regionParams(extra)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = { folder }
	for _, m in ipairs(mirrors) do
		table.insert(list, m)
	end
	for _, e in ipairs(extra or {}) do
		table.insert(list, e)
	end
	params.FilterDescendantsInstances = list
	return params
end

-- 거울 앞의 것들을 다시 모아요 (새로 생긴 것, 사라진 것)
local function refresh()
	local glass = active.glass
	local origin, n = plane(glass)
	local depth = glass:GetAttribute("MirrorDepth") or 26
	local halfWidth = glass:GetAttribute("MirrorHalfWidth") or 6
	local height = glass:GetAttribute("MirrorHeight") or 13
	local floorY = glass.Position.Y - glass.Size.Y / 2 - 0.6
	local look = CFrame.lookAt(origin, origin + n)
	local size = Vector3.new(halfWidth * 2, height, depth)
	local front = CFrame.new(origin.X, floorY + height / 2, origin.Z) * (look - look.Position) * CFrame.new(0, 0, -depth / 2 - 0.02)
	local found = workspace:GetPartBoundsInBox(front, size, regionParams())
	local seen = {}
	for _, src in ipairs(found) do
		if src.Parent and not src:IsDescendantOf(camera) then
			seen[src] = true
			if not active.clones[src] then
				active.clones[src] = makeClone(src) or false
			end
		end
	end
	for src, copy in pairs(active.clones) do
		if not seen[src] then
			if copy then
				copy:Destroy()
			end
			active.clones[src] = nil
		end
	end
	-- 거울 속 저 멀리는 깜깜해요 (이 화면에만 있는 검은 벽)
	if not active.void or not active.void.Parent then
		local void = Instance.new("Part")
		void.Name = "MirrorVoid"
		void.Anchored = true
		void.CanCollide = false
		void.CanQuery = false
		void.CanTouch = false
		void.Color = Color3.new(0, 0, 0)
		void.Material = Enum.Material.SmoothPlastic
		void.Size = Vector3.new(halfWidth * 2 + 4, height + 2, 0.5)
		void.CFrame = CFrame.new(origin.X, floorY + height / 2, origin.Z) * (look - look.Position) * CFrame.new(0, 0, depth + 1.5)
		void.Parent = folder
		active.void = void
	end
	-- 거울 뒤쪽(복사본이 놓이는 곳)에 원래 있던 것(건물 바깥벽 등)은 이 화면에서만 숨겨요.
	local behind = CFrame.new(origin.X, floorY + height / 2, origin.Z) * (look - look.Position) * CFrame.new(0, 0, depth / 2 + 0.5)
	local blockers = workspace:GetPartBoundsInBox(behind, Vector3.new(halfWidth * 2, height, depth), regionParams())
	for _, part in ipairs(blockers) do
		if part.Name ~= "MirrorVoid" and not active.hidden[part] and not part:IsDescendantOf(camera) then
			active.hidden[part] = true
			part.LocalTransparencyModifier = 1
		end
	end
	-- 색, 투명도, 불빛 같은 느린 변화도 맞춰요.
	for src, copy in pairs(active.clones) do
		if copy then
			copy.Color = src.Color
			copy.Transparency = math.max(src.Transparency, src.LocalTransparencyModifier)
			copy.Size = src.Size
			for _, light in ipairs(copy:GetChildren()) do
				if light:IsA("Light") then
					local orig = src:FindFirstChild(light.Name)
					if orig and orig:IsA("Light") then
						light.Enabled = orig.Enabled
					end
				end
			end
		end
	end
end

local lastRefresh = 0
RunService.RenderStepped:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		stop()
		return
	end
	-- 같은 층, 거울 앞 복도에 있을 때만 그려요.
	local best = nil
	for _, glass in ipairs(mirrors) do
		if glass.Parent then
			local origin, n = plane(glass)
			local rel = root.Position - origin
			local ahead = rel:Dot(n)
			if math.abs(rel.Y) < 9 and ahead > -1 and ahead < 60 then
				best = glass
			end
		end
	end
	if not best then
		stop()
		return
	end
	if not active or active.glass ~= best then
		stop()
		active = { glass = best, clones = {}, hidden = {} }
		lastRefresh = 0
	end
	local now = os.clock()
	if now - lastRefresh > 0.3 then
		lastRefresh = now
		refresh()
	end

	local origin, n = plane(best)
	local strange = best:GetAttribute("Strange")
	local parts, cframes = {}, {}
	for src, copy in pairs(active.clones) do
		if copy and src.Parent then
			local cf = reflectCFrame(src.CFrame, origin, n)
			local charModel = characterOf(src)
			if charModel then
				if strange == "none" then
					cf = CFrame.new(0, -1000, 0) -- 사람은 비치지 않아요
				elseif strange == "back" then
					-- 거울 속 내가 뒤돌아 서 있어요 (몸 중심을 축으로 반 바퀴)
					local hrp = charModel:FindFirstChild("HumanoidRootPart")
					if hrp then
						local center = reflectCFrame(hrp.CFrame, origin, n).Position
						cf = CFrame.new(center) * CFrame.Angles(0, math.pi, 0) * CFrame.new(-center) * cf
					end
				end
			end
			if copy.CFrame ~= cf then
				table.insert(parts, copy)
				table.insert(cframes, cf)
			end
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end)
