-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: DataManager (Module - INFLUENCE UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Vault". Updated GamePass IDs and Terminology.
-- -------------------------------------------------------------------------------

local DataManager = {} 

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DATA_VERSION = "v2_LastLook_Alpha_05" 
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_" .. DATA_VERSION)

-- [UPDATED] GAMEPASS IDs
local GP_IDS = {
	VIP = 1663577257,
	SEASON_PASS = 1663591190,
	DOUBLE_XP = 1663637133,
	DOUBLE_SPOOLS = 1660067874,
	EDITORIAL_PACK = 1662801472, -- Formerly Pose Pack
	EXTRA_SLOTS = 1662161370
}

local DailyRewardRemote = ReplicatedStorage:FindFirstChild("DailyRewardEvent")
if not DailyRewardRemote then
	DailyRewardRemote = Instance.new("RemoteEvent")
	DailyRewardRemote.Name = "DailyRewardEvent"
	DailyRewardRemote.Parent = ReplicatedStorage
end

local REWARD_TABLE = {
	[1] = {Spools = 50, Influence = 0},
	[2] = {Spools = 100, Influence = 0},
	[3] = {Spools = 200, Influence = 0},
	[4] = {Spools = 350, Influence = 0},
	[5] = {Spools = 0, Influence = 1},
	[6] = {Spools = 500, Influence = 0},
	[7] = {Spools = 1000, Influence = 2},
}

local DEFAULT_DATA = {
	Spools = 0,
	Influence = 0, -- [UPDATED] Was Sigils
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
	GamePasses = { 
		TwoTimesXP = false,
		DoubleSpools = false,
		EditorialPack = false,
		ExtraSlots = false,
		VIP = false,
		SeasonPass = false
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
	
	-- Migration: Sigils -> Influence
	if data.Sigils then
		data.Influence = (data.Influence or 0) + data.Sigils
		data.Sigils = nil
	end
	
	if not data.GamePasses then data.GamePasses = deepCopy(DEFAULT_DATA.GamePasses) end
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
		data.Influence += rewardData.Influence
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
	if sessionData[player.UserId] then return end 

	local success, result = false, nil
	local retries = 0
	
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
		
		-- [UPDATED] Sync GamePasses
		local data = sessionData[player.UserId]
		
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_IDS.DOUBLE_XP) then data.GamePasses.TwoTimesXP = true end
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_IDS.DOUBLE_SPOOLS) then data.GamePasses.DoubleSpools = true end
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_IDS.EDITORIAL_PACK) then data.GamePasses.EditorialPack = true end
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_IDS.EXTRA_SLOTS) then data.GamePasses.ExtraSlots = true end
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_IDS.VIP) then data.GamePasses.VIP = true end
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GP_IDS.SEASON_PASS) then data.GamePasses.SeasonPass = true end
		
	else
		player:Kick("Data Load Error. Please Rejoin.")
		return
	end
	
	processDailyLogin(player, sessionData[player.UserId])
end

-- // INTERNAL: Save Data
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
	
	sessionData[userId] = nil
end

-- // PUBLIC API
function DataManager:Get(player)
	return sessionData[player.UserId]
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
