-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: DataManager (Module - ROBUST EDITION)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Vault". Retry Logic + GamePass Support.
-- -------------------------------------------------------------------------------

local DataManager = {} 

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DATA_VERSION = "v2_LastLook_Alpha_03" -- [UPDATED] Bumped version
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_" .. DATA_VERSION)

-- GAMEPASS IDs (For persistent checks)
local GP_2X_XP = 000000 -- REPLACE ID

local DailyRewardRemote = ReplicatedStorage:FindFirstChild("DailyRewardEvent")
if not DailyRewardRemote then
	DailyRewardRemote = Instance.new("RemoteEvent")
	DailyRewardRemote.Name = "DailyRewardEvent"
	DailyRewardRemote.Parent = ReplicatedStorage
end

local REWARD_TABLE = {
	[1] = {Spools = 50, Sigils = 0},
	[2] = {Spools = 100, Sigils = 0},
	[3] = {Spools = 200, Sigils = 0},
	[4] = {Spools = 350, Sigils = 0},
	[5] = {Spools = 0, Sigils = 1},
	[6] = {Spools = 500, Sigils = 0},
	[7] = {Spools = 1000, Sigils = 2},
}

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
	},
	GamePasses = { -- [NEW] Cache GamePasses
		TwoTimesXP = false
	}
}

local sessionData = {}

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then v = deepCopy(v) end
		copy[k] = v
	end
	return copy
end

local function reconcile(data)
	for key, value in pairs(DEFAULT_DATA) do
		if data[key] == nil then data[key] = value end
	end
	if not data.GamePasses then data.GamePasses = {} end
	return data
end

-- // CORE: Process Daily Login
local function processDailyLogin(player, data)
	local lastTime = data.DailyLogin.LastLoginTime
	local now = os.time()
	local timeDiff = now - lastTime
	
	local streak = data.DailyLogin.Streak
	
	if lastTime == 0 then
		streak = 1 
	elseif timeDiff >= 172800 then
		streak = 1 
		print("📅 Streak Reset for " .. player.Name)
	elseif timeDiff >= 79200 then
		streak = math.min(streak + 1, 7)
		if streak > 7 then streak = 1 end
	else
		return 
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

-- // INTERNAL: Load Data (Retry Logic)
local function setupPlayer(player)
	if sessionData[player.UserId] then return end 

	local success, result = false, nil
	local retries = 0
	
	-- [UPDATED] Poor man's ProfileService retry loop
	repeat
		success, result = pcall(function()
			return PlayerDataStore:GetAsync(player.UserId)
		end)
		if not success then 
			retries += 1 
			task.wait(2)
		end
	until success or retries >= 3

	if success then
		if result then
			sessionData[player.UserId] = reconcile(result)
		else
			sessionData[player.UserId] = deepCopy(DEFAULT_DATA)
		end
		
		-- Check GamePass ownership on join (Sync)
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_2X_XP) then
			sessionData[player.UserId].GamePasses.TwoTimesXP = true
		end
		
	else
		warn("⚠️ Failed to load data for " .. player.Name .. " after retries.")
		player:Kick("Data Load Error. Please Rejoin.")
		return
	end
	
	processDailyLogin(player, sessionData[player.UserId])
end

-- // INTERNAL: Save Data (Retry Logic)
local function savePlayer(player)
	if not sessionData[player.UserId] then return end
	local userId = player.UserId
	local dataToSave = sessionData[userId]

	local success = false
	local retries = 0
	
	repeat
		success = pcall(function()
			PlayerDataStore:UpdateAsync(userId, function() return dataToSave end)
		end)
		if not success then
			retries += 1
			task.wait(1)
		end
	until success or retries >= 3
	
	if not success then
		warn("CRITICAL: Failed to save data for " .. player.Name)
	end
	
	sessionData[userId] = nil
end

-- // PUBLIC API
function DataManager:Get(player)
	if sessionData[player.UserId] then
		return sessionData[player.UserId]
	else
		return nil
	end
end

function DataManager:AdjustSpools(player, amount)
	local data = self:Get(player)
	if data then
		data.Spools = data.Spools + amount
		return data.Spools
	end
	return nil
end

function DataManager:HasPass(player, passName)
	local data = self:Get(player)
	if data and data.GamePasses then
		return data.GamePasses[passName]
	end
	return false
end

-- // INITIALIZATION
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(savePlayer)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(savePlayer, player)
	end
	task.wait(3)
end)

return DataManager
