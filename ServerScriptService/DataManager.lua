-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: DataManager (Module)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Vault". Handles Data, Daily Rewards, and allows other scripts access.
-- -------------------------------------------------------------------------------

local DataManager = {} -- The Module Table

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DATA_VERSION = "v2_LastLook_Alpha_02"
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_" .. DATA_VERSION)

-- Create Remote if it doesn't exist (Singleton pattern)
local DailyRewardRemote = ReplicatedStorage:FindFirstChild("DailyRewardEvent")
if not DailyRewardRemote then
	DailyRewardRemote = Instance.new("RemoteEvent")
	DailyRewardRemote.Name = "DailyRewardEvent"
	DailyRewardRemote.Parent = ReplicatedStorage
end

-- // CONFIG: DAILY REWARDS
local REWARD_TABLE = {
	[1] = {Spools = 50, Sigils = 0},
	[2] = {Spools = 100, Sigils = 0},
	[3] = {Spools = 200, Sigils = 0},
	[4] = {Spools = 350, Sigils = 0},
	[5] = {Spools = 0, Sigils = 1},
	[6] = {Spools = 500, Sigils = 0},
	[7] = {Spools = 1000, Sigils = 2},
}

-- Default Data Template
local DEFAULT_DATA = {
	Spools = 0,
	Sigils = 0,
	XP = 0,
	Level = 1,
	Inventory = {},
	EquippedPerks = {},
	DailyLogin = {
		Streak = 0,
		LastLoginTime = 0 
	},
	Settings = {
		MusicVolume = 1,
		SFXVolume = 1
	}
}

-- PRIVATE STATE (The Vault)
local sessionData = {}

-- // HELPER: Deep Copy
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then v = deepCopy(v) end
		copy[k] = v
	end
	return copy
end

-- // HELPER: Reconcile Data
local function reconcile(data)
	for key, value in pairs(DEFAULT_DATA) do
		if data[key] == nil then data[key] = value end
	end
	if not data.DailyLogin then data.DailyLogin = deepCopy(DEFAULT_DATA.DailyLogin) end
	return data
end

-- // CORE: Process Daily Login (Private)
local function processDailyLogin(player, data)
	local lastTime = data.DailyLogin.LastLoginTime
	local now = os.time()
	local timeDiff = now - lastTime
	
	-- 22 Hours (79200s) to 48 Hours (172800s) logic
	local streak = data.DailyLogin.Streak
	
	if lastTime == 0 then
		streak = 1 -- First time
	elseif timeDiff >= 172800 then
		streak = 1 -- Streak lost
		print("📅 Streak Reset for " .. player.Name)
	elseif timeDiff >= 79200 then
		streak = math.min(streak + 1, 7) -- Level up streak
		if streak > 7 then streak = 1 end
	else
		return -- Too early
	end
	
	local rewardData = REWARD_TABLE[streak]
	if rewardData then
		data.Spools += rewardData.Spools
		data.Sigils += rewardData.Sigils
		data.DailyLogin.Streak = streak
		data.DailyLogin.LastLoginTime = now
		
		task.defer(function()
			DailyRewardRemote:FireClient(player, streak, rewardData)
		end)
		print("💰 " .. player.Name .. " claimed Day " .. streak)
	end
end

-- // INTERNAL: Load Data
local function setupPlayer(player)
	if sessionData[player.UserId] then return end -- Already loaded

	local success, result = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	if success then
		if result then
			sessionData[player.UserId] = reconcile(result)
		else
			sessionData[player.UserId] = deepCopy(DEFAULT_DATA)
		end
	else
		warn("⚠️ Failed to load data for " .. player.Name)
		player:Kick("Data Load Error. Rejoin.")
		return
	end
	
	processDailyLogin(player, sessionData[player.UserId])
end

-- // INTERNAL: Save Data
local function savePlayer(player)
	if not sessionData[player.UserId] then return end
	local userId = player.UserId
	local dataToSave = sessionData[userId]

	pcall(function()
		PlayerDataStore:UpdateAsync(userId, function() return dataToSave end)
	end)
	sessionData[userId] = nil
end

-- // --------------------------------------------------------------------------
-- // 🔓 PUBLIC API (The methods other scripts can call)
-- // --------------------------------------------------------------------------

-- Get a player's data table.
-- Usage: local data = DataManager:Get(player)
function DataManager:Get(player)
	if sessionData[player.UserId] then
		return sessionData[player.UserId]
	else
		warn("⚠️ Attempted to access data for " .. player.Name .. " before it loaded.")
		return nil
	end
end

-- Manually adjust Spools (for Shop/Rewards scripts)
function DataManager:AdjustSpools(player, amount)
	local data = self:Get(player)
	if data then
		data.Spools = data.Spools + amount
		return data.Spools
	end
	return nil
end

-- // --------------------------------------------------------------------------
-- // 🔌 INITIALIZATION
-- // --------------------------------------------------------------------------

-- Hook up Events
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(savePlayer)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(savePlayer, player)
	end
	task.wait(2)
end)

-- Catch players who joined before this module ran (just in case)
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

return DataManager