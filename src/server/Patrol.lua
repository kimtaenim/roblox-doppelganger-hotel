-- 손님을 다 받은 뒤의 밤 활동: 야간 순찰 + 룸서비스 배달
--
-- [야간 순찰] 오늘 받은 손님들의 방을 층마다 돌며 문 앞에서 확인해요.
--   멀쩡한 방이면 "이상 없음"(E), 수상한 방이면 "이상 보고"(R).
--   낮에 실수로 받은 도플갱어의 방은 문이 살짝 열려 있거나, 피가 새어 나오거나, 긁힌 자국이 있어요.
--   제대로 보고하면 경비팀이 방을 봉쇄해서 그 밤의 희생을 막아요.
--   멀쩡한 방을 보고하면 손님이 화를 내요(벌금). 도플갱어 방에 "이상 없음"을 누르면 깜짝 놀라요.
--
-- [룸서비스] 순찰 중에 프런트 전화가 울려요. 받으면 주문한 방으로 쟁반을 들고 가서 노크(F)해요.
--   손님이 체인을 건 채 문을 빼꼼 열면, 숙박부 사진과 비교해서 건네줄지 문 앞에 두고 갈지 골라요.
--   진짜 손님이면 팁, 가짜(도플갱어)거나 아무도 묵지 않는 빈방이면 깜짝 놀라요.
--
-- 도플갱어는 겁만 주고 쫓아오지는 않아요.
local Patrol = {}

local rgb = Color3.fromRGB
local V = Vector3.new

local ITEMS = { "따뜻한 우유", "수건 두 장", "샌드위치", "푹신한 베개", "얼음물", "따뜻한 코코아" }
local ORDER_LINES = {
	"%d호예요. %s 좀 갖다 주세요.",
	"여보세요? %d호인데요... %s 부탁해요.",
	"%d호예요. 늦은 시간에 죄송하지만 %s 좀...",
}
local SIGN_KINDS = { "ajar", "blood", "scratch", "hands", "sign" }

local ctx -- Patrol.init 에서 받아요
local current = nil -- 지금 진행 중인 순찰 상태

local function pick(list)
	return list[math.random(#list)]
end

-- 사진·문틈에서 보이는 무서운 모습 ("moving" 은 사진에서만 움직이는 거라 다른 모습으로 바꿔요)
local function visibleKind(kind)
	if kind == nil or kind == "moving" then
		return "mouth"
	end
	return kind
end

local function newPart(parent, name, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
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

local function textOn(part, face, text, color, font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = font or Enum.Font.Garamond
	label.Text = text
	label.TextColor3 = color
	label.Parent = gui
end

local function noCollide(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
		end
	end
end

local function rootOf(player)
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------- 문 앞 표시
-- "방해하지 마세요" 같은 문고리 걸이 (멀쩡한 방에도 가끔 걸려 있어요)
local function doorHanger(room, text, color, textColor)
	local floors = ctx.floors
	local cf = floors.onDoor(room, room.swing * -1.3, 0.3) * CFrame.new(0, -0.45, -0.05)
	local card = newPart(room.extras, "DoorHanger", V(0.55, 0.9, 0.04), cf, color)
	textOn(card, Enum.NormalId.Front, text, textColor, Enum.Font.GothamBold)
end

-- 멀쩡한 방에도 가끔 소품을 둬요. (소품이 있다고 다 도플갱어는 아니에요!)
local function decorateNormal(room)
	local roll = math.random()
	if roll < 0.2 then
		doorHanger(room, "방해하지\n마세요", rgb(235, 225, 200), rgb(60, 40, 30))
	elseif roll < 0.32 then
		-- 문 앞에 내놓은 빈 접시 쟁반
		local base = room.spot.Position - V(0, 2.95, 0) + V(0.8, 0, 0)
		newPart(room.extras, "LeftTray", V(1.3, 0.08, 0.9), CFrame.new(base), rgb(190, 190, 195), Enum.Material.Metal)
		local plate = newPart(room.extras, "LeftPlate", V(0.06, 0.7, 0.7), CFrame.new(base + V(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(245, 245, 240))
		plate.Shape = Enum.PartType.Cylinder
	elseif roll < 0.42 then
		-- 문 앞에 벗어 둔 구두
		local base = room.spot.Position - V(0, 2.9, 0)
		for _, dx in ipairs({ -0.35, 0.35 }) do
			newPart(room.extras, "Shoe", V(0.45, 0.35, 1), CFrame.new(base + V(dx - 0.6, 0, 0)), rgb(40, 28, 22), Enum.Material.Leather)
		end
	end
end

-- 도플갱어가 묵는 방: 문 앞에 섬뜩한 흔적이 남아요.
local function decorateDoppel(state, room, guest)
	local floors = ctx.floors
	local kind = pick(SIGN_KINDS)
	if kind == "ajar" then
		-- 문이 살짝 열려 있고, 안쪽에 등을 돌린 채 서 있어요. 가까이 가면 휙 돌아봐요.
		floors.openDoor(room, 38)
		local model = ctx.Animals.build(guest, visibleKind(guest.anomaly and guest.anomaly.kind))
		noCollide(model)
		model:PivotTo(room.insideCF)
		model.Parent = room.extras
		local glow = newPart(room.extras, "RoomGlow", V(0.4, 0.4, 0.4), room.insideCF * CFrame.new(0, 9, -3), rgb(120, 0, 0), Enum.Material.Neon, { Transparency = 1 })
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 40, 30)
		light.Range = 14
		light.Brightness = 1.2
		light.Parent = glow
		table.insert(state.lurkers, { room = room, model = model, turned = false })
		room.strip.Color = rgb(150, 10, 10)
	elseif kind == "blood" then
		-- 문 밑으로 피가 새어 나와 복도까지 번져요.
		room.strip.Color = rgb(160, 15, 15)
		local base = room.spot.Position - V(0, 2.97, 0)
		local toCorridor = V(0, 0, -room.side)
		for i = 1, 5 do
			local size = 2.6 - i * 0.35
			local p = newPart(room.extras, "Blood", V(0.05, size, size * 0.8), CFrame.new(base - toCorridor * (1.3 - i * 0.35) + V((math.random() - 0.5) * 1.2, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)), rgb(95, 0, 0), Enum.Material.SmoothPlastic, { Reflectance = 0.15 })
			p.Shape = Enum.PartType.Cylinder
		end
	elseif kind == "scratch" then
		-- 문에 안쪽에서 긁은 듯한 깊은 자국
		for i = 1, 5 do
			newPart(room.extras, "Scratch", V(0.07, 2.4, 0.05), floors.onDoor(room, -0.9 + i * 0.3, -0.5 + (i % 2) * 0.3) * CFrame.Angles(0, 0, math.rad(18)), rgb(25, 15, 10))
		end
		room.strip.Color = rgb(20, 16, 14)
		room.strip.Material = Enum.Material.SmoothPlastic
	elseif kind == "hands" then
		-- 피 묻은 손바닥 자국
		for i = 1, 3 do
			local cf = floors.onDoor(room, -0.8 + i * 0.45, 1.6 - i * 0.9 + math.random() * 0.4) * CFrame.Angles(0, 0, (math.random() - 0.5) * 0.8)
			local palm = newPart(room.extras, "HandPrint", V(0.42, 0.5, 0.03), cf, rgb(120, 0, 0))
			Instance.new("SpecialMesh", palm).MeshType = Enum.MeshType.Sphere
			for f = -2, 2 do
				local finger = newPart(room.extras, "HandPrint", V(0.08, 0.3, 0.03), cf * CFrame.new(f * 0.09, 0.36 - math.abs(f) * 0.04, 0) * CFrame.Angles(0, 0, f * 0.15), rgb(120, 0, 0))
				Instance.new("SpecialMesh", finger).MeshType = Enum.MeshType.Sphere
			end
		end
	else -- sign
		-- 삐뚤빼뚤한 빨간 글씨 문고리 걸이
		doorHanger(room, "들어와", rgb(30, 20, 20), rgb(200, 20, 20))
	end
end

---------------------------------------------------------------- 상태 보내기
local STATUS_TEXT = {
	pending = "확인 전",
	ok = "✓ 이상 없음",
	reported = "🚨 보고함",
	wrong = "😠 헛보고",
	scared = "✓ 확인",
}
local CALL_TEXT = {
	ringing = "📞 전화 울리는 중",
	carrying = "🛎 배달 중",
	done = "완료",
	missed = "놓침",
}

local function sendState(s, state)
	local checks = {}
	for _, entry in ipairs(state.checks) do
		table.insert(checks, {
			room = entry.room.number,
			label = ("%s (%s)"):format(entry.guest.name, entry.guest.animalName),
			status = entry.status,
			statusText = STATUS_TEXT[entry.status],
		})
	end
	table.sort(checks, function(a, b)
		return a.room < b.room
	end)
	local calls = {}
	for _, call in ipairs(state.calls) do
		table.insert(calls, {
			room = call.state ~= "ringing" and call.room or nil,
			item = call.state ~= "ringing" and call.item or nil,
			state = call.state,
			stateText = CALL_TEXT[call.state],
			who = call.player and call.player.DisplayName or nil,
		})
	end
	ctx.fire(s, ctx.remotes.PatrolState, {
		active = true,
		timeLeft = math.max(0, math.floor(state.deadline - os.clock())),
		checks = checks,
		calls = calls,
		callsLeft = state.callsTotal - #state.calls,
	})
end

---------------------------------------------------------------- 쟁반 (배달하는 동안 손에 들어요)
local function giveTray(player, item)
	local root = rootOf(player)
	if not root then
		return nil
	end
	local tray = Instance.new("Model")
	tray.Name = "ServiceTray"
	local plate = newPart(tray, "Tray", V(1.6, 0.1, 1.1), root.CFrame * CFrame.new(0, 0.2, -1.3), rgb(200, 200, 205), Enum.Material.Metal)
	local cover = newPart(tray, "Cloche", V(0.9, 0.9, 0.9), plate.CFrame * CFrame.new(0, 0.3, 0), rgb(215, 215, 220), Enum.Material.Metal)
	cover.Shape = Enum.PartType.Ball
	newPart(tray, "ClocheKnob", V(0.18, 0.18, 0.18), plate.CFrame * CFrame.new(0, 0.78, 0), rgb(196, 156, 84), Enum.Material.Metal).Shape = Enum.PartType.Ball
	tray:SetAttribute("Item", item)
	for _, p in ipairs(tray:GetChildren()) do
		p.Anchored = false
		p.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
	end
	tray.Parent = player.Character
	return tray
end

---------------------------------------------------------------- 전화
local function makeCall(s, state)
	local normals, doppels = {}, {}
	for _, entry in ipairs(state.checks) do
		if entry.guest.isDoppel then
			if entry.status ~= "reported" then
				table.insert(doppels, entry)
			end
		elseif entry.status ~= "wrong" then
			table.insert(normals, entry)
		end
	end

	local roll = math.random()
	local kind
	if s.day <= ctx.Config.PracticeDays then
		kind = #normals > 0 and "normal" or "empty"
	elseif roll < 0.45 then
		kind = "normal"
	elseif roll < 0.65 then
		kind = "impostor"
	elseif roll < 0.8 then
		kind = "doppel"
	else
		kind = "empty"
	end
	if kind == "doppel" and #doppels == 0 then
		kind = "impostor"
	end
	if (kind == "normal" or kind == "impostor") and #normals == 0 then
		kind = "empty"
	end

	local call = { id = #state.calls + 1, kind = kind, item = pick(ITEMS), state = "ringing", ringStart = os.clock() }
	if kind == "empty" then
		local free = {}
		for number in pairs(ctx.floors.rooms) do
			if not state.occupied[number] then
				table.insert(free, number)
			end
		end
		call.room = pick(free)
		-- 아무도 없는 방: 문틈엔 어둠 속의 무언가가...
		call.visual = { id = 999, name = "?", animal = pick(ctx.Animals.List), fur = rgb(14, 13, 16), cloth = rgb(14, 13, 16) }
		call.visualKind = "eyes"
	else
		local entry = kind == "doppel" and pick(doppels) or pick(normals)
		call.room = entry.room.number
		call.guest = entry.guest
		local visual = table.clone(entry.guest)
		local visualKind = nil
		if kind == "doppel" then
			visualKind = visibleKind(entry.guest.anomaly and entry.guest.anomaly.kind)
		elseif kind == "impostor" then
			-- 그 방 손님인 척하는 가짜: 털 색이 다르거나, 다른 동물이거나, 얼굴이 이상해요.
			local variant = pick({ "fur", "animal", "eyes", "teeth", "mouth" })
			if variant == "fur" then
				local def = ctx.Animals.Types[visual.animal]
				local others = {}
				for _, fur in ipairs(def.furs) do
					if fur ~= visual.fur then
						table.insert(others, fur)
					end
				end
				visual.fur = #others > 0 and pick(others) or visual.fur:Lerp(rgb(90, 90, 95), 0.5)
			elseif variant == "animal" then
				local others = {}
				for _, animal in ipairs(ctx.Animals.List) do
					if animal ~= visual.animal then
						table.insert(others, animal)
					end
				end
				visual.animal = pick(others)
				local def = ctx.Animals.Types[visual.animal]
				visual.fur = def.furs[math.random(#def.furs)]
			else
				visualKind = variant
			end
			call.variant = variant
		end
		call.visual = visual
		call.visualKind = visualKind
	end
	call.line = pick(ORDER_LINES):format(call.room, call.item)
	table.insert(state.calls, call)
	state.ringing = call
	state.phonePrompt.Enabled = true
	if state.ringSound then
		state.ringSound:Play()
	end
	ctx.fire(s, ctx.remotes.Toast, { text = "📞 따르릉... 프런트 전화가 울려요! 전화기 앞에서 E", kind = "warn" })
	sendState(s, state)
end

local function finishCall(s, state, call, how)
	call.state = how
	if call.tray then
		call.tray:Destroy()
		call.tray = nil
	end
	local room = ctx.floors.rooms[call.room]
	if room then
		room.knockPrompt.Enabled = false
	end
	if state.ringing == call then
		state.ringing = nil
		state.phonePrompt.Enabled = false
		if state.ringSound then
			state.ringSound:Stop()
		end
	end
	sendState(s, state)
end

---------------------------------------------------------------- 한 번의 순찰
function Patrol.run(s)
	local floors = ctx.floors
	local Config = ctx.Config
	floors.resetAll()
	floors.setElevators(true)

	local state = {
		checks = {},
		calls = {},
		lurkers = {},
		figures = {},
		occupied = {},
		isolated = {},
		tips = 0,
		penalty = 0,
		served = 0,
		missed = 0,
		falseReports = 0,
		saved = 0,
		deadline = os.clock() + Config.PatrolTime,
		callsTotal = s.day <= 1 and 1 or (s.day <= 3 and 2 or 3),
		phonePrompt = ctx.phonePrompt,
		ringSound = ctx.ringSound,
		s = s,
	}
	current = state

	-- 오늘 받은 손님들의 방
	for _, guest in ipairs(s.accepted) do
		local room = floors.rooms[guest.room]
		if room and not state.occupied[guest.room] then
			state.occupied[guest.room] = true
			floors.setOccupied(room, true)
			room.okPrompt.Enabled = true
			room.reportPrompt.Enabled = true
			table.insert(state.checks, { room = room, guest = guest, status = "pending" })
			if guest.isDoppel then
				decorateDoppel(state, room, guest)
			else
				decorateNormal(room)
			end
		end
	end

	-- 복도 끝에 서 있는 그림자 (다가가면 사라져요)
	for _, floor in ipairs(floors.List) do
		if math.random() < 0.5 then
			local data = { id = math.random(1000, 9999), name = "?", animal = pick(ctx.Animals.List), fur = rgb(12, 11, 14), cloth = rgb(12, 11, 14) }
			local figure = ctx.Animals.build(data, nil)
			for _, d in ipairs(figure:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Color = rgb(10, 9, 12)
					d.CanCollide = false
					d.CanQuery = false
				end
			end
			figure:PivotTo(floors.figures[floor])
			figure.Parent = workspace
			table.insert(state.figures, { model = figure, floor = floor })
		end
	end

	-- 손전등
	for _, player in ipairs(s.players) do
		local head = player.Character and player.Character:FindFirstChild("Head")
		if head and not head:FindFirstChild("PatrolFlashlight") then
			local light = Instance.new("SpotLight")
			light.Name = "PatrolFlashlight"
			light.Brightness = 3
			light.Range = 45
			light.Angle = 55
			light.Face = Enum.NormalId.Front
			light.Shadows = true
			light.Color = rgb(255, 240, 210)
			light.Parent = head
		end
	end

	ctx.fire(s, ctx.remotes.Toast, {
		text = "🔦 야간 순찰 시간! 직원 출입구 옆 엘리베이터로 2~4층 손님 방을 확인하세요.",
		kind = "info",
	})
	sendState(s, state)

	-- 전화 시간표: 순찰 시작 20초 뒤부터, 50초마다
	local nextCallAt = os.clock() + 20
	local lastSend = 0
	local finished = false
	while s.active and not finished do
		task.wait(0.2)
		local now = os.clock()

		-- 새 전화
		if #state.calls < state.callsTotal and not state.ringing and now >= nextCallAt then
			local busy = false
			for _, call in ipairs(state.calls) do
				busy = busy or call.state == "carrying"
			end
			if not busy then
				makeCall(s, state)
				nextCallAt = now + 50
			end
		end
		-- 아무도 안 받은 전화는 끊겨요.
		if state.ringing and now - state.ringing.ringStart > Config.CallRingTime then
			local call = state.ringing
			state.missed += 1
			finishCall(s, state, call, "missed")
			ctx.fire(s, ctx.remotes.Toast, { text = "📞 ...전화가 끊겼어요. 손님이 불만을 남겼어요.", kind = "info" })
		end
		-- 배달하던 직원이 쓰러지거나 나가면 그 주문은 놓쳐요.
		for _, call in ipairs(state.calls) do
			if call.state == "carrying" and not table.find(s.players, call.player) then
				state.missed += 1
				finishCall(s, state, call, "missed")
			end
		end

		-- 열린 문 안의 도플갱어: 가까이 가면 휙 돌아봐요. (쫓아오지는 않아요)
		for _, lurker in ipairs(state.lurkers) do
			if not lurker.turned and lurker.model.Parent then
				for _, player in ipairs(s.players) do
					local root = rootOf(player)
					if root and (root.Position - lurker.room.spot.Position).Magnitude < 8 then
						lurker.turned = true
						lurker.model:PivotTo(lurker.model:GetPivot() * CFrame.Angles(0, math.pi, 0))
						ctx.fireTo(player, ctx.remotes.NightFx, { kind = "sting" })
						ctx.changeSanity(s, player, -4)
						break
					end
				end
			end
		end
		-- 복도 끝 그림자: 다가가면 사라져요.
		for _, figure in ipairs(state.figures) do
			if figure.model.Parent then
				local pos = figure.model:GetPivot().Position
				for _, player in ipairs(s.players) do
					local root = rootOf(player)
					if root and math.abs(root.Position.Y - pos.Y) < 8 and (root.Position - pos).Magnitude < 17 then
						figure.model:Destroy()
						ctx.fireTo(player, ctx.remotes.NightFx, { kind = "whisper" })
						ctx.changeSanity(s, player, -3)
						break
					end
				end
			end
		end

		-- 다 끝났는지
		local allChecked = true
		for _, entry in ipairs(state.checks) do
			allChecked = allChecked and entry.status ~= "pending"
		end
		local callsDone = #state.calls >= state.callsTotal
		for _, call in ipairs(state.calls) do
			callsDone = callsDone and (call.state == "done" or call.state == "missed")
		end
		if allChecked and callsDone then
			ctx.fire(s, ctx.remotes.Toast, { text = "✅ 순찰 완료! 수고했어요. 프런트로 돌아가요...", kind = "accept" })
			task.wait(3)
			finished = true
		elseif now >= state.deadline then
			ctx.fire(s, ctx.remotes.Toast, { text = "⏰ 순찰 시간이 끝났어요. 확인하지 못한 방은 그대로 밤을 맞아요...", kind = "warn" })
			for _, call in ipairs(state.calls) do
				if call.state == "ringing" or call.state == "carrying" then
					state.missed += 1
					finishCall(s, state, call, "missed")
				end
			end
			task.wait(3)
			finished = true
		elseif now - lastSend >= 1 then
			lastSend = now
			sendState(s, state)
		end
	end

	-- 정리
	current = nil
	if state.ringSound then
		state.ringSound:Stop()
	end
	state.phonePrompt.Enabled = false
	for _, call in ipairs(state.calls) do
		if call.tray then
			call.tray:Destroy()
		end
	end
	for _, figure in ipairs(state.figures) do
		if figure.model.Parent then
			figure.model:Destroy()
		end
	end
	for _, player in ipairs(s.players) do
		local head = player.Character and player.Character:FindFirstChild("Head")
		local light = head and head:FindFirstChild("PatrolFlashlight")
		if light then
			light:Destroy()
		end
	end
	floors.resetAll()
	ctx.fire(s, ctx.remotes.PatrolState, { active = false })

	return {
		isolated = state.isolated,
		saved = state.saved,
		tips = state.tips,
		penalty = state.penalty,
		served = state.served,
		missed = state.missed,
		falseReports = state.falseReports,
	}
end

---------------------------------------------------------------- 버튼 처리 (한 번만 연결해요)
local function entryFor(state, room)
	for _, entry in ipairs(state.checks) do
		if entry.room == room then
			return entry
		end
	end
	return nil
end

local function isMember(state, player)
	return table.find(state.s.players, player) ~= nil
end

local function onCheck(room, player, report)
	local state = current
	if not state or not isMember(state, player) then
		return
	end
	local s = state.s
	local entry = entryFor(state, room)
	if not entry or entry.status ~= "pending" then
		return
	end
	room.okPrompt.Enabled = false
	room.reportPrompt.Enabled = false
	local guest = entry.guest
	if report then
		if guest.isDoppel then
			entry.status = "reported"
			state.isolated[guest.id] = true
			state.saved += 1
			-- 경비팀이 방을 봉쇄해요: 문이 쾅 닫히고 흔적이 사라져요.
			for i = #state.lurkers, 1, -1 do
				if state.lurkers[i].room == room then
					table.remove(state.lurkers, i)
				end
			end
			room.extras:ClearAllChildren()
			ctx.floors.closeDoor(room)
			ctx.floors.setOccupied(room, false)
			local seal = newPart(room.extras, "SealTape", V(4, 0.35, 0.05), ctx.floors.onDoor(room, 0, 0.5) * CFrame.new(0, 0, -0.05) * CFrame.Angles(0, 0, math.rad(12)), rgb(240, 200, 40), Enum.Material.Neon)
			textOn(seal, Enum.NormalId.Front, "출입 금지", rgb(30, 20, 10), Enum.Font.GothamBlack)
			ctx.fire(s, ctx.remotes.Toast, {
				text = ("🚨 %d호 이상 보고! 경비팀이 방을 봉쇄했어요. 오늘 밤 희생을 막았어요."):format(room.number),
				kind = "accept",
			})
		else
			entry.status = "wrong"
			state.falseReports += 1
			state.penalty += ctx.Config.FalseReportPenalty
			ctx.fire(s, ctx.remotes.Toast, {
				text = ("😠 %d호 %s 님: \"한밤중에 무슨 소란이에요?!\" (헛보고 벌금 -%d)"):format(room.number, guest.name, ctx.Config.FalseReportPenalty),
				kind = "warn",
			})
		end
	else
		if guest.isDoppel then
			-- 이상한데 그냥 지나치려는 순간...
			entry.status = "scared"
			ctx.fireTo(player, ctx.remotes.NightFx, {
				kind = "scare",
				data = guest,
				anomaly = visibleKind(guest.anomaly and guest.anomaly.kind),
			})
			ctx.changeSanity(s, player, -ctx.Config.PatrolScareLoss)
			ctx.fire(s, ctx.remotes.Toast, { text = ("...%d호 문 너머에서 무언가 낄낄 웃어요."):format(room.number), kind = "warn" })
		else
			entry.status = "ok"
			ctx.fireTo(player, ctx.remotes.Toast, { text = ("✓ %d호 이상 없음"):format(room.number), kind = "accept" })
		end
	end
	sendState(s, state)
end

local function onPhone(player)
	local state = current
	if not state or not isMember(state, player) or not state.ringing then
		return
	end
	local s = state.s
	for _, call in ipairs(state.calls) do
		if call.state == "carrying" and call.player == player then
			ctx.fireTo(player, ctx.remotes.Toast, { text = "먼저 들고 있는 주문부터 배달해요.", kind = "info" })
			return
		end
	end
	local call = state.ringing
	state.ringing = nil
	state.phonePrompt.Enabled = false
	if state.ringSound then
		state.ringSound:Stop()
	end
	call.state = "carrying"
	call.player = player
	call.tray = giveTray(player, call.item)
	local room = ctx.floors.rooms[call.room]
	if room then
		room.knockPrompt.Enabled = true
	end
	ctx.fireTo(player, ctx.remotes.Toast, {
		text = ("📞 \"%s\"  → %d층 %d호 앞에서 노크(F)"):format(call.line, math.floor(call.room / 100), call.room),
		kind = "info",
	})
	for _, other in ipairs(s.players) do
		if other ~= player then
			ctx.fireTo(other, ctx.remotes.Toast, { text = ("📞 %s 님이 %d호 주문을 받았어요."):format(player.DisplayName, call.room), kind = "info" })
		end
	end
	sendState(s, state)
end

local function onKnock(room, player)
	local state = current
	if not state or not isMember(state, player) then
		return
	end
	for _, call in ipairs(state.calls) do
		if call.state == "carrying" and call.room == room.number then
			if call.player ~= player then
				ctx.fireTo(player, ctx.remotes.Toast, { text = ("이 주문은 %s 님이 들고 있어요."):format(call.player.DisplayName), kind = "info" })
				return
			end
			if call.knocked then
				return
			end
			call.knocked = true
			room.knockPrompt.Enabled = false
			ctx.fireTo(player, ctx.remotes.Peephole, {
				callId = call.id,
				room = call.room,
				item = call.item,
				-- 숙박부 사진 (빈방이면 없어요)
				register = call.guest and {
					id = call.guest.id,
					name = call.guest.name,
					animal = call.guest.animal,
					animalName = call.guest.animalName,
					fur = call.guest.fur,
					cloth = call.guest.cloth,
				} or nil,
				visual = call.visual,
				visualKind = call.visualKind,
				empty = call.kind == "empty",
			})
			return
		end
	end
end

local function onPeepholeChoice(player, callId, choice)
	local state = current
	if not state or not isMember(state, player) or (choice ~= "give" and choice ~= "leave") then
		return
	end
	local s = state.s
	local call = state.calls[callId]
	if not call or call.state ~= "carrying" or call.player ~= player or not call.knocked then
		return
	end
	local Config = ctx.Config
	local genuine = call.kind == "normal"
	if choice == "give" then
		if genuine then
			state.tips += Config.RoomServiceTip
			state.served += 1
			ctx.changeSanity(s, player, 4)
			ctx.fireTo(player, ctx.remotes.Toast, { text = ("💰 \"고마워요~\" 팁 +%d"):format(Config.RoomServiceTip), kind = "accept" })
		else
			ctx.fireTo(player, ctx.remotes.NightFx, { kind = "scare", data = call.visual, anomaly = call.visualKind or "mouth" })
			ctx.changeSanity(s, player, -Config.RoomServiceScareLoss)
			local text = call.kind == "empty" and ("...%d호는 아무도 묵지 않는 방이었어요."):format(call.room)
				or "...그건 손님이 아니었어요."
			ctx.fireTo(player, ctx.remotes.Toast, { text = text, kind = "warn" })
		end
	else
		if genuine then
			ctx.fireTo(player, ctx.remotes.Toast, { text = "손님이 문 앞의 쟁반을 가져갔어요. (팁 없음)", kind = "info" })
		else
			local text = call.kind == "empty" and ("...%d호는 빈방이었어요. 잘 피했어요."):format(call.room)
				or "문 너머에서 긁는 소리가 나요... 잘 피했어요."
			ctx.fireTo(player, ctx.remotes.Toast, { text = text, kind = "accept" })
		end
	end
	finishCall(s, state, call, "done")
end

-- 서버가 처음 켜질 때 한 번 불러요.
function Patrol.init(context)
	ctx = context
	for _, room in pairs(ctx.floors.rooms) do
		room.okPrompt.Triggered:Connect(function(player)
			onCheck(room, player, false)
		end)
		room.reportPrompt.Triggered:Connect(function(player)
			onCheck(room, player, true)
		end)
		room.knockPrompt.Triggered:Connect(function(player)
			onKnock(room, player)
		end)
	end
	ctx.phonePrompt.Triggered:Connect(onPhone)
	ctx.remotes.PeepholeChoice.OnServerEvent:Connect(onPeepholeChoice)

	-- 엘리베이터: 순찰 중인 직원만 타요.
	for _, entry in ipairs(ctx.floors.elevatorPrompts) do
		entry.prompt.Triggered:Connect(function(player)
			local state = current
			if not state or not isMember(state, player) then
				return
			end
			local exit = ctx.floors.exits[entry.target]
			if not exit then
				return
			end
			ctx.fireTo(player, ctx.remotes.NightFx, { kind = "fade" })
			task.wait(0.35)
			ctx.teleport(player, exit)
			ctx.fireTo(player, ctx.remotes.Toast, { text = entry.target == 1 and "🛎 로비" or ("🛎 %d층"):format(entry.target), kind = "info" })
		end)
	end
end

return Patrol
