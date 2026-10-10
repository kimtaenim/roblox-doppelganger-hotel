-- 복도 거울 그리기 (층마다 복도 끝 하나, 양쪽 벽에 하나씩)
-- 로블록스에는 진짜로 비추는 거울이 없어요. 그래서 거울 앞에 있는 것들(복도, 문, 사람, 물고기...)을
-- 이 화면에서만 거울 면을 기준으로 뒤집어 복사하고, 거울 뒤 빈 공간에 놓아요.
-- 유리 너머로 그 복사본이 보이면 진짜 거울처럼 보여요. 움직이는 것도 매 프레임 따라 움직여요.
--
-- 거울 유리의 속성
--   MirrorDepth: 거울 앞 얼마나 멀리까지 비출지 / MirrorHalfWidth: 거울 앞 좌우로 얼마나 비출지
--   MirrorHide: 거울 뒤에 원래 있던 것(건물 바깥벽 등)을 이 화면에서 숨겨요
--   MirrorClip: 거울 너비 밖으로는 그리지 않고 양옆을 검은 칸막이로 막아요 (거울 뒤가 객실일 때)
--   Strange: 거울 속 내가 나와 다르게 움직여요.
--     "late"   이면 거울 속 내가 1초 늦게 따라 움직여요
--     "wander" 이면 내가 가만히 있어도 거울 속 나는 혼자 옆으로 왔다 갔다 해요
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local root = Instance.new("Folder")
root.Name = "MirrorReflections"
root.Parent = camera

local mirrors = {} -- 거울 유리 파트 목록
local actives = {} -- [유리] = { folder, clones = {[원본] = 복사본}, hidden = {[파트] = true}, lastRefresh }
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

-- 거울 면: 유리 앞면의 위치와 바깥쪽 방향, 그리고 거울의 오른쪽 방향
local function plane(glass)
	local cf = glass.CFrame
	return cf.Position + cf.LookVector * (glass.Size.Z / 2), cf.LookVector, cf.RightVector
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

local function makeClone(src, parent)
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
	copy.Parent = parent
	return copy
end

local function darkPart(parent, size, cf)
	local part = Instance.new("Part")
	part.Name = "MirrorVoid"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Color = Color3.new(0, 0, 0)
	part.Material = Enum.Material.SmoothPlastic
	part.Size = size
	part.CFrame = cf
	part.Parent = parent
	return part
end

local function stop(glass)
	local state = actives[glass]
	if not state then
		return
	end
	for part in pairs(state.hidden) do
		if part.Parent then
			part.LocalTransparencyModifier = 0
		end
	end
	state.folder:Destroy()
	actives[glass] = nil
end

local function regionParams()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = { root }
	for _, m in ipairs(mirrors) do
		table.insert(list, m)
	end
	params.FilterDescendantsInstances = list
	return params
end

local function settings(glass)
	return glass:GetAttribute("MirrorDepth") or 26, glass:GetAttribute("MirrorHalfWidth") or 6, glass:GetAttribute("MirrorHeight") or 13
end

-- 거울 앞의 것들을 다시 모아요 (새로 생긴 것, 사라진 것)
local function refresh(glass, state)
	local origin, n = plane(glass)
	local depth, halfWidth, height = settings(glass)
	local floorY = glass.Position.Y - glass.Size.Y / 2 - 0.6
	local look = CFrame.lookAt(origin, origin + n)
	local base = CFrame.new(origin.X, floorY + height / 2, origin.Z) * (look - look.Position)
	local found = workspace:GetPartBoundsInBox(base * CFrame.new(0, 0, -depth / 2 - 0.02), Vector3.new(halfWidth * 2, height, depth), regionParams())
	local seen = {}
	for _, src in ipairs(found) do
		if src.Parent and not src:IsDescendantOf(camera) then
			seen[src] = true
			if state.clones[src] == nil then
				state.clones[src] = makeClone(src, state.folder) or false
			end
		end
	end
	for src, copy in pairs(state.clones) do
		if not seen[src] then
			if copy then
				copy:Destroy()
			end
			state.clones[src] = nil
			state.history[src] = nil
		end
	end
	-- 거울 속 저 멀리(와 양옆)는 깜깜해요. 이 화면에만 있는 검은 벽이에요.
	if not state.void then
		state.void = darkPart(state.folder, Vector3.new(halfWidth * 2 + 4, height + 2, 0.5), base * CFrame.new(0, 0, depth + 1.5))
		if glass:GetAttribute("MirrorClip") then
			for _, sx in ipairs({ -1, 1 }) do
				darkPart(state.folder, Vector3.new(0.1, height, depth + 1.5), base * CFrame.new(sx * (halfWidth + 0.05), 0, depth / 2 + 0.8))
			end
			darkPart(state.folder, Vector3.new(halfWidth * 2 + 0.2, 0.1, depth + 1.5), base * CFrame.new(0, height / 2, depth / 2 + 0.8))
			darkPart(state.folder, Vector3.new(halfWidth * 2 + 0.2, 0.1, depth + 1.5), base * CFrame.new(0, -height / 2, depth / 2 + 0.8))
		end
	end
	-- 거울 뒤쪽(복사본이 놓이는 곳)에 원래 있던 것(건물 바깥벽 등)은 이 화면에서만 숨겨요.
	if glass:GetAttribute("MirrorHide") then
		local blockers = workspace:GetPartBoundsInBox(base * CFrame.new(0, 0, depth / 2 + 0.5), Vector3.new(halfWidth * 2, height, depth), regionParams())
		for _, part in ipairs(blockers) do
			if not state.hidden[part] and not part:IsDescendantOf(camera) then
				state.hidden[part] = true
				part.LocalTransparencyModifier = 1
			end
		end
	end
	-- 색, 투명도, 불빛 같은 느린 변화도 맞춰요.
	for src, copy in pairs(state.clones) do
		if copy then
			copy.Color = src.Color
			-- 1인칭으로 보면 내 몸이 내 화면에서 투명해지지만, 거울 속 나는 그대로 보여야 해요.
			copy.Transparency = characterOf(src) and src.Transparency or math.max(src.Transparency, src.LocalTransparencyModifier)
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

-- 거울 너비 밖으로 삐져나가는 긴 판(바닥, 천장, 맞은편 벽)은 거울 너비만큼만 잘라요.
local AXES = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }
local function clip(cf, size, src, center, right, halfWidth)
	if not (src:IsA("Part") and src.Shape == Enum.PartType.Block and not src:FindFirstChildOfClass("SpecialMesh")) then
		return cf, size
	end
	local vectors = { cf.XVector, cf.YVector, cf.ZVector }
	for i, v in ipairs(vectors) do
		if math.abs(v:Dot(right)) > 0.999 then
			local half = size[({ "X", "Y", "Z" })[i]] / 2
			local t = (cf.Position - center):Dot(right)
			local lo, hi = math.max(t - half, -halfWidth), math.min(t + half, halfWidth)
			if hi <= lo then
				return nil
			end
			local newSize = size * (Vector3.one - AXES[i]) + AXES[i] * (hi - lo)
			return cf + right * ((lo + hi) / 2 - t), newSize
		end
	end
	return cf, size
end

local function update(glass, state)
	local origin, n, right = plane(glass)
	local _, halfWidth = settings(glass)
	local clipping = glass:GetAttribute("MirrorClip")
	local strange = glass:GetAttribute("Strange")
	local parts, cframes = {}, {}
	for src, copy in pairs(state.clones) do
		if copy and src.Parent then
			local cf = reflectCFrame(src.CFrame, origin, n)
			local size = src.Size
			local charModel = characterOf(src)
			if charModel then
				-- 사람의 지난 1.5초 움직임을 기억해 둬요 ("late" 에 써요)
				local now = os.clock()
				local history = state.history[src]
				if not history then
					history = {}
					state.history[src] = history
				end
				table.insert(history, { t = now, cf = src.CFrame })
				while #history > 2 and history[2].t < now - 1.5 do
					table.remove(history, 1)
				end
				if strange == "late" then
					-- 거울 속 내가 1초 늦게 따라 해요
					local past = history[1].cf
					for _, h in ipairs(history) do
						if h.t <= now - 1 then
							past = h.cf
						else
							break
						end
					end
					cf = reflectCFrame(past, origin, n)
				elseif strange == "wander" then
					-- 내가 가만히 있어도 거울 속 나는 혼자 옆으로 왔다 갔다 해요
					local swing = math.sin(now * 0.8) * (clipping and 1.2 or 2.5)
					cf = cf + right * swing
				end
			elseif clipping then
				cf, size = clip(cf, size, src, origin, right, halfWidth)
				if not cf then
					cf, size = CFrame.new(0, -1000, 0), src.Size
				end
			end
			if copy.Size ~= size then
				copy.Size = size
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
end

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	for _, glass in ipairs(mirrors) do
		-- 같은 층, 거울 앞에 있을 때만 그려요.
		local near = false
		if hrp and glass.Parent then
			local origin, n, right = plane(glass)
			local depth = settings(glass)
			local rel = hrp.Position - origin
			local ahead = rel:Dot(n)
			local reach = glass:GetAttribute("MirrorClip") and 18 or 60
			near = math.abs(rel.Y) < 9 and ahead > -1 and ahead < math.max(depth, reach) and math.abs(rel:Dot(right)) < reach
		end
		if near then
			local state = actives[glass]
			if not state then
				local folder = Instance.new("Folder")
				folder.Name = "Mirror"
				folder.Parent = root
				state = { folder = folder, clones = {}, hidden = {}, history = {}, lastRefresh = 0 }
				actives[glass] = state
			end
			local now = os.clock()
			if now - state.lastRefresh > 0.3 then
				state.lastRefresh = now
				refresh(glass, state)
			end
			update(glass, state)
		elseif actives[glass] then
			stop(glass)
		end
	end
end)
