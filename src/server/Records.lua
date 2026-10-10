-- 최고 기록: 플레이어마다 "가장 오래 버틴 날"과 "가장 많이 번 돈"을 저장해요.
-- 플레이어 목록(오른쪽 위)에 "최고 일차"로 보이고, 광장의 명예의 전당 게시판에 상위 5명이 떠요.
-- (Studio에서 저장하려면: 홈 → 게임 설정 → 보안 → "API 서비스에 대한 Studio 액세스 사용" 을 켜 주세요.
--  꺼져 있어도 게임은 그대로 돌아가고, 기록만 저장되지 않아요.)
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Records = {}

local store, board = nil, nil
pcall(function()
	store = DataStoreService:GetDataStore("DoppelHotelRecords")
	board = DataStoreService:GetOrderedDataStore("DoppelHotelBestDay")
end)

local cache = {} -- [player] = { bestDay, bestMoney }

local function key(player)
	return "player_" .. player.UserId
end

local function setLeaderstat(player, record)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	local day = stats:FindFirstChild("최고 일차") or Instance.new("IntValue")
	day.Name = "최고 일차"
	day.Value = record.bestDay
	day.Parent = stats
end

function Records.get(player)
	return cache[player] or { bestDay = 0, bestMoney = 0 }
end

function Records.load(player)
	local record = { bestDay = 0, bestMoney = 0 }
	if store then
		local ok, data = pcall(function()
			return store:GetAsync(key(player))
		end)
		if ok and type(data) == "table" then
			record.bestDay = tonumber(data.bestDay) or 0
			record.bestMoney = tonumber(data.bestMoney) or 0
		end
	end
	cache[player] = record
	setLeaderstat(player, record)
	return record
end

-- 이번 판 결과를 기록해요. 새 기록이 있으면 { day = true, money = true } 처럼 돌려줘요.
function Records.submit(player, day, money)
	local record = cache[player] or Records.load(player)
	local broke = {}
	if day > record.bestDay then
		record.bestDay = day
		broke.day = true
	end
	if money > record.bestMoney then
		record.bestMoney = money
		broke.money = true
	end
	if broke.day or broke.money then
		setLeaderstat(player, record)
		task.spawn(function()
			if store then
				pcall(function()
					store:SetAsync(key(player), { bestDay = record.bestDay, bestMoney = record.bestMoney })
				end)
			end
			if board and broke.day then
				pcall(function()
					board:SetAsync(key(player), record.bestDay)
				end)
			end
		end)
	end
	return broke
end

-- 명예의 전당 상위 5명 { { name, day }, ... }
function Records.top()
	local list = {}
	if not board then
		return list
	end
	local ok, pages = pcall(function()
		return board:GetSortedAsync(false, 5)
	end)
	if not ok or not pages then
		return list
	end
	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(tostring(entry.key):match("%d+"))
		local name = "?"
		if userId then
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
		end
		table.insert(list, { name = name, day = entry.value })
	end
	return list
end

Players.PlayerRemoving:Connect(function(player)
	cache[player] = nil
end)

return Records
