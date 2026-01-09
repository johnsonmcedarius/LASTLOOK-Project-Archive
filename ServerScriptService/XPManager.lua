-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: XPManager (Server - INFLUENCE UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Awards Influence (📍) on Level Up. 
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(game.ServerScriptService.DataManager)

-- CONFIG
local BASE_XP = 1000 
local XP_MULTIPLIER = 1.2 
local GAMEPASS_MULT = 2 

local LevelUpRemote = Instance.new("RemoteEvent")
LevelUpRemote.Name = "LevelUpEvent"
LevelUpRemote.Parent = ReplicatedStorage

local AddXPBindable = Instance.new("BindableEvent")
AddXPBindable.Name = "AddXP"
AddXPBindable.Parent = ServerStorage

local function getMaxXP(level)
	return math.floor(BASE_XP * (level ^ XP_MULTIPLIER))
end

AddXPBindable.Event:Connect(function(player, amount)
	if not player then return end
	
	local data = DataManager:Get(player)
	if not data then return end
	
	if DataManager:HasPass(player, "TwoTimesXP") then
		amount = amount * GAMEPASS_MULT
	end
	
	data.XP += amount
	
	local maxXP = getMaxXP(data.Level)
	while data.XP >= maxXP do
		data.XP -= maxXP
		data.Level += 1
		
		-- AWARD INFLUENCE
		data.Influence = (data.Influence or 0) + 1
		print("🆙 LEVEL UP! +1 Influence for " .. player.Name)
		
		LevelUpRemote:FireClient(player, data.Level, 1) 
		maxXP = getMaxXP(data.Level)
	end
end)
