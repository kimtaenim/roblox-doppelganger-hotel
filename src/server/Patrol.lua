-- 손님을 다 받은 뒤의 밤 활동: 야간 순찰 + 룸서비스 배달
--
-- [야간 순찰] 엘리베이터로 2~4층 복도를 둘러봐요.
--   복도에는 꽃병, 거울 세 개, 객실 문, 천장 조명, 층 표시판, 의자가 있어요.
--   아무도 없는 층의 것들이 몰래 이상하게 바뀌고, 도플갱어가 묵는 방 문에는 섬뜩한 흔적이 있어요.
--   물건마다 보고할 필요는 없어요. 층을 떠나려고 엘리베이터 버튼을 누르면
--   "이 층에 이상한 게 있었나요?" 하고 물어봐요. 있다 / 없다 로만 답해요.
--     - 이상이 있는데 "있다" → 엘리베이터 문이 닫히면 그 층의 이상한 일이 사라지고, 도플갱어 방 문은 잠겨서 오늘 밤 실종을 막아요. (수당)
--     - 이상이 있는데 "없다" → 무언가를 놓쳤어요... 정신력이 떨어져요.
--     - 아무 이상 없는데 "있다" → 헛보고 벌금
--
-- [룸서비스] 순찰 중에 프런트 전화가 울려요. 받으면 주문한 방으로 쟁반을 들고 가서 노크(F)해요.
--   손님이 체인을 건 채 문을 열면, 문틈으로 보이는 얼굴과 손님의 말을 보고 판단해요.
--   도플갱어는 얼굴이 확 이상하고(검은 눈, 이빨, 찢어진 입) 말도 이상해요.
--     - 방에 들어가서 건네기: 진짜 손님이면 팁! 도플갱어면 정신력 크게 떨어져요.
--     - 팁을 포기하고 문 앞에 두기: 안전하지만 팁은 없어요.
--
-- 할 일을 다 하면 프런트의 종 앞에서 "퇴근하기". 시간이 다 돼도 끝나요.
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
local SIGN_KINDS = { "ajar", "blood", "scratch", "sign", "redeyes", "grin" }

-- 문을 연 손님의 말. 진짜 손님은 평범하게, 도플갱어는 어딘가 이상하게 말해요.
local GENUINE_LINES = {
	"아, %s! 기다렸어요. 고마워요~",
	"늦은 시간에 죄송해요. %s 여기 주세요.",
	"와, 빨리 왔네요! %s 맞죠? 고마워요.",
	"%s 감사합니다. 이제 푹 잘 수 있겠어요.",
	"앗, 잠옷 바람이라... %s 고마워요!",
}
local DOPPEL_LINES = {
	function()
		return "데자뷔! 데자뷔! 우리 전에 만난 적 있죠? 히히히."
	end,
	function(call)
		return ("데자뷔... %s 아까도 가져왔잖아요. 아까도. 아까도."):format(call.item)
	end,
	function(call)
		return ("...%s? 난 고기를 시켰는데. 날고기."):format(call.item)
	end,
	function()
		return "들어와요... 안쪽 깊숙이 놓아 주세요. 더 안쪽에."
	end,
	function()
		return "고마워요 고마워요 고마워요 고마워요 고마워요"
	end,
	function()
		return "벌써 아침이에요? 해가... 왜 안 뜨죠?"
	end,
	function(call)
		return ("저는 %s... 아니, 그 사람은 이제 여기 없어요."):format(call.guest and call.guest.name or "손님")
	end,
	function(call, player)
		return ("%s 씨죠? 들어와서 같이 있어요. 오래오래."):format(player.DisplayName)
	end,
	function()
		return "...요세주 어들 로으안" -- 거꾸로 말해요
	end,
	function(call)
		return ("%d호? 여긴 원래 아무도 없는 방인데요. 히히."):format(call.room)
	end,
	function(call)
		return ("%s... %s... 맛있는 냄새. 쟁반 말고, 당신한테서요."):format(call.item, call.item)
	end,
	function()
		return "어? 방금 복도에 당신이 지나갔는데. 그럼 당신은 누구예요?"
	end,
	function()
		return "똑똑. 아, 제가 노크하는 거예요. 안에서요. 똑똑."
	end,
	function(call, player)
		return ("%s 씨, 내일 아침 근무는 제가 대신 할게요. 얼굴도 대신 할게요."):format(player.DisplayName)
	end,
	function()
		return "시계가 거꾸로 가요. 같이 어제로 갈래요?"
	end,
	function()
		return "데자뷔! 우리 이 대화 벌써 백 번째예요."
	end,
	function(call)
		return ("지금 몇 시예요? 아, 몰라도 돼요. 여기선 시간이 안 가거든요. %s 거기 두세요."):format(call.item)
	end,
	function()
		return "쉿, 옆방 손님 깨우지 마세요. 옆방 손님은... 저예요."
	end,
}
local EMPTY_LINES = {
	"......들어와.",
	"(문 너머에서 숨소리만 들려요...)",
	"쟁반은... 필요 없어. 너만 들어오면 돼.",
}

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
	elseif kind == "redeyes" or kind == "grin" then
		-- 살짝 열린 문틈 어둠 속에서 빨간 눈이 빛나거나, 피 묻은 입이 히죽 웃어요.
		floors.openDoor(room, 22)
		local gap = room.closedPivot * CFrame.new(-room.swing * 1.1, 1.6, 1.4) -- 문틈 바로 안쪽, 얼굴 높이
		if kind == "redeyes" then
			for _, dx in ipairs({ -0.28, 0.28 }) do
				local eye = newPart(room.extras, "RedEye", V(0.22, 0.14, 0.05), gap * CFrame.new(dx, 0, 0), rgb(255, 20, 20), Enum.Material.Neon)
				Instance.new("SpecialMesh", eye).MeshType = Enum.MeshType.Sphere
			end
			local glow = newPart(room.extras, "EyeGlow", V(0.2, 0.2, 0.2), gap * CFrame.new(0, 0, 0.3), rgb(255, 0, 0), Enum.Material.Neon, { Transparency = 1 })
			local light = Instance.new("PointLight")
			light.Color = rgb(255, 30, 20)
			light.Range = 5
			light.Brightness = 1.5
			light.Parent = glow
		else
			local mouth = newPart(room.extras, "Grin", V(0.9, 0.35, 0.05), gap * CFrame.new(0, -0.5, 0), rgb(40, 0, 0))
			Instance.new("SpecialMesh", mouth).MeshType = Enum.MeshType.Sphere
			for i = -3, 3 do
				local tooth = newPart(room.extras, "GrinTooth", V(0.03, 0.12, 0.08), gap * CFrame.new(i * 0.11, -0.4, -0.03) * CFrame.Angles(0, math.rad(90), math.pi), rgb(235, 230, 200))
				tooth.Shape = Enum.PartType.Block
			end
			for _, dx in ipairs({ -0.25, 0.1, 0.3 }) do
				newPart(room.extras, "GrinBlood", V(0.06, 0.6, 0.04), gap * CFrame.new(dx, -0.95, -0.02), rgb(130, 0, 0))
			end
		end
		room.strip.Color = rgb(10, 8, 8)
		room.strip.Material = Enum.Material.SmoothPlastic
	else -- sign
		-- 삐뚤빼뚤한 빨간 글씨 문고리 걸이
		doorHanger(room, "들어와", rgb(30, 20, 20), rgb(200, 20, 20))
	end
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


---------------------------------------------------------------- 상태 보내기
local CALL_TEXT = {
	ringing = "📞 전화 울리는 중",
	carrying = "🛎 배달 중",
	done = "완료",
	missed = "놓침",
}

local function sendState(s, state)
	local floors = {}
	for _, floor in ipairs(ctx.floors.List) do
		table.insert(floors, { floor = floor, inspected = state.inspected[floor] == true })
	end
	local guests = {}
	local residents = 0
	for _, guest in ipairs(state.guests) do
		if guest.resident then
			residents += 1
		else
			table.insert(guests, { room = guest.room, label = ("%s (%s)"):format(guest.name, guest.animalName) })
		end
	end
	table.sort(guests, function(a, b)
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
		floors = floors,
		guests = guests,
		residents = residents,
		calls = calls,
		callsLeft = state.callsTotal - #state.calls,
		found = state.found,
		canLeave = state.canLeave,
	})
end

---------------------------------------------------------------- 층마다 이상한 것 세기
local function anomaliesOn(state, floor)
	local count = 0
	if ctx.floors.events[floor].kind ~= "normal" then
		count += 1
	end
	for _, entry in ipairs(state.doppelRooms) do
		if entry.room.floor == floor and not entry.sealed then
			count += 1
		end
	end
	return count
end

-- 이상을 알아차린 층: 이상한 일은 사라지고, 도플갱어 방 문은 잠겨요.
local function cleanFloor(state, floor)
	ctx.floors.setEvent(floor, "normal")
	local sealed = 0
	for _, entry in ipairs(state.doppelRooms) do
		local room = entry.room
		if room.floor == floor and not entry.sealed then
			entry.sealed = true
			sealed += 1
			state.isolated[entry.guest.id] = true
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
		end
	end
	return sealed
end

---------------------------------------------------------------- 전화
local function makeCall(s, state)
	local normals, doppels = {}, {}
	for _, guest in ipairs(state.guests) do
		if guest.isDoppel then
			if not state.isolated[guest.id] then
				table.insert(doppels, guest)
			end
		else
			table.insert(normals, guest)
		end
	end

	-- 진짜 손님 / 도플갱어 / 아무도 없는 빈방
	local roll = math.random()
	local kind
	if s.day <= ctx.Config.PracticeDays then
		kind = "normal"
	elseif roll < 0.5 then
		kind = "normal"
	elseif roll < 0.85 then
		kind = "doppel"
	else
		kind = "empty"
	end
	if kind == "normal" and #normals == 0 then
		kind = #doppels > 0 and "doppel" or "empty"
	end
	if kind == "doppel" and #doppels == 0 and #normals == 0 then
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
		call.visual = { id = 999, name = "?", animal = pick(ctx.Animals.List), fur = rgb(14, 13, 16), cloth = rgb(14, 13, 16) }
		call.visualKind = "eyes"
	elseif kind == "doppel" then
		-- 낮에 받은 도플갱어가 있으면 그 방, 없으면 멀쩡한 손님 방에 숨어든 도플갱어
		local guest = #doppels > 0 and pick(doppels) or pick(normals)
		call.room = guest.room
		call.guest = guest
		call.visual = guest
		-- 도플갱어는 문틈으로 보면 얼굴이 바로 이상하고, 말도 이상해요.
		-- 문틈으로 바로 알아볼 수 있는 얼굴 모습 (오늘까지 나타난 것 중에서)
		local FACE_KINDS = { eyes = true, teeth = true, mouth = true, noface = true, manyeyes = true, upside = true, bigeye = true, twohead = true, zipper = true }
		local kinds = {}
		for _, kind in ipairs(ctx.Config.unlocked("doppel", math.max(s.day, 2))) do
			if FACE_KINDS[kind] then
				table.insert(kinds, kind)
			end
		end
		local guestKind = guest.anomaly and guest.anomaly.kind
		call.visualKind = table.find(kinds, guestKind) and guestKind or pick(kinds)
	else
		local guest = pick(normals)
		call.room = guest.room
		call.guest = guest
		call.visual = guest
	end
	call.line = pick(ORDER_LINES):format(call.room, call.item)
	table.insert(state.calls, call)
	state.ringing = call
	state.phonePrompt.Enabled = true
	if state.ringSound then
		state.ringSound:Play()
	end
	ctx.fire(s, ctx.remotes.Toast, { text = "📻 치직... 무전이 왔어요! 2번 키나 가방의 무전기로 받아요.", kind = "warn" })
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
		guests = {},
		calls = {},
		lurkers = {},
		figures = {},
		occupied = {},
		isolated = {},
		doppelRooms = {},
		inspected = {},
		asks = {},
		tips = 0,
		bonus = 0,
		penalty = 0,
		served = 0,
		missedCalls = 0,
		found = 0,
		missed = 0,
		falseReports = 0,
		spawned = 0,
		-- 첫날(연습)은 복도가 안전해요. 둘째 날부터도 멀쩡한 밤이 꽤 있어요.
		-- (10번 중 4번은 아무 일 없는 밤, 나머지는 1~2개 층만 바뀌어요. 날이 갈수록 조금씩 늘어요)
		spawnMax = (s.day <= ctx.Config.PracticeDays or math.random() < 0.4) and 0
			or math.random(1, math.min(1 + math.floor(s.day / 4), 3)),
		canLeave = false,
		leave = false,
		deadline = os.clock() + Config.PatrolTime,
		callsTotal = s.day <= 1 and 1 or (s.day <= 3 and 2 or 3),
		phonePrompt = ctx.phonePrompt,
		ringSound = ctx.ringSound,
		leavePrompt = ctx.leavePrompt,
		s = s,
	}
	current = state

	-- 오늘 받은 손님들의 방: 문 밑 불빛, 도플갱어 방의 흔적
	-- 묵고 있는 모든 손님: 며칠째 묵는 투숙객 + 오늘 체크인한 손님
	local occupants = table.clone(s.residents or {})
	for _, guest in ipairs(s.accepted) do
		table.insert(occupants, guest)
	end
	for _, guest in ipairs(occupants) do
		local room = floors.rooms[guest.room]
		if room and not state.occupied[guest.room] then
			state.occupied[guest.room] = true
			table.insert(state.guests, guest)
			floors.setOccupied(room, true)
			if guest.isDoppel then
				decorateDoppel(state, room, guest)
				table.insert(state.doppelRooms, { room = room, guest = guest, sealed = false })
			else
				decorateNormal(room)
			end
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
		text = "🔦 야간 순찰! 엘리베이터로 2~4층 복도를 둘러보고, 이상한 게 있었는지 기억하세요.",
		kind = "info",
	})
	ctx.fire(s, ctx.remotes.NightFx, { kind = "guide", topic = "patrol" })
	sendState(s, state)

	local nextCallAt = os.clock() + 20 -- 전화: 20초 뒤부터, 50초마다
	local nextOddityAt = os.clock() + 15 -- 몰래 바뀌기: 15초 뒤부터, 30~45초마다
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
			state.missedCalls += 1
			finishCall(s, state, state.ringing, "missed")
			ctx.fire(s, ctx.remotes.Toast, { text = "📞 ...전화가 끊겼어요. 손님이 불만을 남겼어요.", kind = "info" })
		end
		-- 배달하던 직원이 쓰러지거나 나가면 그 주문은 놓쳐요.
		for _, call in ipairs(state.calls) do
			if call.state == "carrying" and not table.find(s.players, call.player) then
				state.missedCalls += 1
				finishCall(s, state, call, "missed")
			end
		end

		-- 아무도 없는 층 전체가 몰래 확 바뀌어요. (피의 강, 눈알 꽃, 뒤집힌 복도, 빨간 조명, 활짝 열린 문, 검은 형체들)
		if state.spawned < state.spawnMax and now >= nextOddityAt and state.deadline - now > 30 then
			local occupiedFloors = {}
			for _, player in ipairs(s.players) do
				local root = rootOf(player)
				if root then
					occupiedFloors[math.floor(root.Position.Y / 14) + 1] = true
				end
			end
			local candidates = {}
			for _, floor in ipairs(floors.List) do
				if floors.events[floor].kind == "normal" and not occupiedFloors[floor] then
					table.insert(candidates, floor)
				end
			end
			if #candidates > 0 then
				floors.setEvent(pick(candidates), pick(ctx.Config.unlocked("floor", s.day))) -- 오늘까지 나타난 이상 중에서
				state.spawned += 1
				nextOddityAt = now + math.random(30, 45)
			else
				nextOddityAt = now + 5
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
						ctx.fireTo(player, ctx.remotes.Toast, { text = "🗣 \"데자뷔!!\"", kind = "warn", shake = true })
						ctx.changeSanity(s, player, -4)
						break
					end
				end
			end
		end
		-- 다 끝났는지: 2~4층을 한 번씩 다 둘러보고, 전화도 다 끝나면 퇴근할 수 있어요.
		local allInspected = true
		for _, floor in ipairs(floors.List) do
			allInspected = allInspected and state.inspected[floor] == true
		end
		local callsDone = #state.calls >= state.callsTotal
		for _, call in ipairs(state.calls) do
			callsDone = callsDone and (call.state == "done" or call.state == "missed")
		end
		if allInspected and callsDone and not state.canLeave then
			state.canLeave = true
			state.leavePrompt.Enabled = true
			ctx.fire(s, ctx.remotes.Toast, {
				text = "✅ 모든 층을 둘러보고 배달도 끝! 더 둘러봐도 되고, 프런트 종 앞에서 퇴근해도 돼요.",
				kind = "accept",
			})
			sendState(s, state)
		end
		if state.leave then
			ctx.fire(s, ctx.remotes.Toast, { text = "🛎 퇴근! 수고했어요. 프런트로 돌아가요...", kind = "accept" })
			task.wait(2)
			finished = true
		elseif now >= state.deadline then
			ctx.fire(s, ctx.remotes.Toast, { text = "⏰ 순찰 시간이 끝났어요. 정리하지 못한 층은 그대로 밤을 맞아요...", kind = "warn" })
			for _, call in ipairs(state.calls) do
				if call.state == "ringing" or call.state == "carrying" then
					state.missedCalls += 1
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
	state.leavePrompt.Enabled = false
	for _, call in ipairs(state.calls) do
		if call.tray then
			call.tray:Destroy()
		end
	end
	for _, player in ipairs(s.players) do
		local head = player.Character and player.Character:FindFirstChild("Head")
		local light = head and head:FindFirstChild("PatrolFlashlight")
		if light then
			light:Destroy()
		end
		ctx.fireTo(player, ctx.remotes.AskFloor, { close = true })
	end
	local saved = 0
	for _, entry in ipairs(state.doppelRooms) do
		if entry.sealed then
			saved += 1
		end
	end
	floors.resetAll()
	ctx.fire(s, ctx.remotes.PatrolState, { active = false })

	return {
		isolated = state.isolated,
		saved = saved,
		tips = state.tips,
		bonus = state.bonus,
		penalty = state.penalty,
		served = state.served,
		missed = state.missedCalls,
		falseReports = state.falseReports,
		portraitsFound = state.found,
		portraitsMissed = state.missed,
	}
end

---------------------------------------------------------------- 버튼 처리 (한 번만 연결해요)
local function isMember(state, player)
	return table.find(state.s.players, player) ~= nil
end

-- 엘리베이터에서 "이 층에 이상한 게 있었나요?" 에 대한 대답
local function judgeFloor(state, player, floor, saw)
	local s = state.s
	local Config = ctx.Config
	state.inspected[floor] = true
	local count = anomaliesOn(state, floor)
	if saw and count > 0 then
		state.found += count
		state.bonus += Config.FloorReportBonus
		local sealed = cleanFloor(state, floor)
		local extra = sealed > 0 and (" 도플갱어 방 문 %d곳이 잠겼어요!"):format(sealed) or ""
		ctx.fire(s, ctx.remotes.Toast, {
			text = ("✅ 맞았어요! %d층의 이상한 일이 사라졌어요 (%s).%s (수당 +%d)"):format(floor, player.DisplayName, extra, Config.FloorReportBonus),
			kind = "accept",
		})
	elseif saw then
		state.falseReports += 1
		state.penalty += Config.FloorFalsePenalty
		ctx.fireTo(player, ctx.remotes.Toast, {
			text = ("...%d층엔 아무 이상도 없었어요. (헛보고 -%d)"):format(floor, Config.FloorFalsePenalty),
			kind = "warn",
		})
	elseif count > 0 then
		state.missed += count
		ctx.fireTo(player, ctx.remotes.NightFx, { kind = "whisper" })
		ctx.changeSanity(s, player, -Config.FloorMissLoss * count)
		ctx.fireTo(player, ctx.remotes.Toast, {
			text = "😨 엘리베이터 문이 닫히는 순간... 무언가 놓친 것 같은 기분이 들어요.",
			kind = "warn",
		})
	else
		ctx.fireTo(player, ctx.remotes.Toast, { text = ("✓ %d층 이상 없음"):format(floor), kind = "accept" })
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
	ctx.fireTo(player, ctx.remotes.NightFx, { kind = "guide", topic = "roomservice", room = call.room, item = call.item, line = call.line })
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
			-- 손님의 말: 진짜 손님은 평범하게, 도플갱어는 (말 단서일 때) 이상하게
			local line
			if call.kind == "empty" then
				line = pick(EMPTY_LINES)
			elseif call.kind == "doppel" then
				line = pick(DOPPEL_LINES)(call, player)
			else
				line = pick(GENUINE_LINES):format(call.item)
			end
			local guest = call.guest
			ctx.fireTo(player, ctx.remotes.Peephole, {
				callId = call.id,
				room = call.room,
				item = call.item,
				line = line,
				-- 숙박부 사진 (빈방이면 없어요)
				register = guest and {
					id = guest.id,
					name = guest.name,
					animal = guest.animal,
					animalName = guest.animalName,
					fur = guest.fur,
					cloth = guest.cloth,
				} or nil,
				visual = {
					id = call.visual.id,
					animal = call.visual.animal,
					fur = call.visual.fur,
					cloth = call.visual.cloth,
				},
				-- 도플갱어의 이상한 얼굴 (진짜 손님이면 없어요)
				visualKind = call.kind == "doppel" and call.visualKind or nil,
				empty = call.kind == "empty",
			})
			return
		end
	end
end

local function onPeepholeChoice(player, callId, choice)
	local state = current
	if not state or not isMember(state, player) or (choice ~= "enter" and choice ~= "leave") then
		return
	end
	local s = state.s
	local call = state.calls[callId]
	if not call or call.state ~= "carrying" or call.player ~= player or not call.knocked then
		return
	end
	local Config = ctx.Config
	local genuine = call.kind == "normal"
	if choice == "enter" then
		if genuine then
			state.tips += Config.RoomServiceTip
			state.served += 1
			ctx.changeSanity(s, player, 4)
			ctx.fireTo(player, ctx.remotes.Toast, { text = ("💰 \"고마워요~\" 팁 +%d"):format(Config.RoomServiceTip), kind = "accept" })
		else
			local kind = call.visualKind or "mouth"
			if kind == "moving" then
				kind = "mouth"
			end
			ctx.fireTo(player, ctx.remotes.NightFx, { kind = "scare", data = call.visual, anomaly = kind })
			ctx.changeSanity(s, player, -Config.RoomServiceScareLoss)
			local text = call.kind == "empty" and ("...%d호는 아무도 묵지 않는 방이었어요."):format(call.room)
				or "...방 안에 있던 건 손님이 아니었어요."
			ctx.fireTo(player, ctx.remotes.Toast, { text = text, kind = "warn" })
		end
	else
		if genuine then
			ctx.fireTo(player, ctx.remotes.Toast, { text = "쟁반을 문 앞에 두고 왔어요. (팁 없음)", kind = "info" })
		else
			local text = call.kind == "empty" and ("...%d호는 빈방이었어요. 잘 피했어요."):format(call.room)
				or "문 너머에서 긁는 소리가 나요... 잘 피했어요."
			ctx.fireTo(player, ctx.remotes.Toast, { text = text, kind = "accept" })
		end
	end
	finishCall(s, state, call, "done")
end

local function onLeave(player)
	local state = current
	if state and isMember(state, player) and state.canLeave then
		state.leave = true
	end
end

local askCounter = 0

-- 서버가 처음 켜질 때 한 번 불러요.
function Patrol.init(context)
	ctx = context
	for _, room in pairs(ctx.floors.rooms) do
		room.knockPrompt.Triggered:Connect(function(player)
			onKnock(room, player)
		end)
	end
	ctx.leavePrompt.Triggered:Connect(onLeave)
	ctx.phonePrompt.Triggered:Connect(onPhone)
	ctx.remotes.PeepholeChoice.OnServerEvent:Connect(onPeepholeChoice)
	-- 무전기: 어디서든 프런트 전화를 받을 수 있어요.
	ctx.remotes.AnswerRadio.OnServerEvent:Connect(onPhone)

	-- 엘리베이터: "엘리베이터 타기"를 누르면 화면에 층 고르기 창이 떠요.
	-- 2~4층에서 떠날 때는 같은 창에서 "이 층에 이상한 게 있었나요?"도 함께 물어봐요.
	for _, entry in ipairs(ctx.floors.elevatorPrompts) do
		entry.prompt.Triggered:Connect(function(player)
			local state = current
			if not state or not isMember(state, player) then
				return
			end
			askCounter += 1
			local askAnomaly = entry.floor >= 2
			state.asks[player] = { id = askCounter, floor = entry.floor, askAnomaly = askAnomaly }
			ctx.fireTo(player, ctx.remotes.AskFloor, { id = askCounter, floor = entry.floor, askAnomaly = askAnomaly })
		end)
	end

	ctx.remotes.AskFloorAnswer.OnServerEvent:Connect(function(player, askId, target, saw)
		local state = current
		local ask = state and state.asks[player]
		if not ask or ask.id ~= askId then
			return
		end
		if target == nil then
			state.asks[player] = nil -- 창을 닫았어요 (그대로 머물러요)
			return
		end
		if typeof(target) ~= "number" or not ctx.floors.exits[target] or target == ask.floor then
			return
		end
		if ask.askAnomaly and typeof(saw) ~= "boolean" then
			return
		end
		state.asks[player] = nil
		if ask.askAnomaly then
			judgeFloor(state, player, ask.floor, saw)
		end
		ctx.fireTo(player, ctx.remotes.NightFx, { kind = "fade" })
		task.wait(0.35)
		ctx.teleport(player, ctx.floors.exits[target])
		ctx.fireTo(player, ctx.remotes.Toast, { text = target == 1 and "🛎 로비" or ("🛎 %d층"):format(target), kind = "info" })
	end)
end

return Patrol
