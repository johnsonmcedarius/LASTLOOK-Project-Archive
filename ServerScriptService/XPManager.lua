-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: XPManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Leveling, XP Curves, and awarding Influence (📍).
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(game.ServerScriptService.DataManager)

-- CONFIG
local BASE_XP = 1000 -- XP needed for Level 2
local XP_MULTIPLIER = 1.2 -- Curve (Level 3 needs 1200, etc.)

-- REMOTES
local LevelUpRemote = Instance.new("RemoteEvent")
LevelUpRemote.Name = "LevelUpEvent"
LevelUpRemote.Parent = ReplicatedStorage

-- BINDABLE (Listen for Round End)
local AddXPBindable = Instance.new("BindableEvent")
AddXPBindable.Name = "AddXP"
AddXPBindable.Parent = ServerStorage

-- // HELPER: Calculate Max XP for a Level
local function getMaxXP(level)
	return math.floor(BASE_XP * (level ^ XP_MULTIPLIER))
end

-- // CORE: Process XP
AddXPBindable.Event:Connect(function(player, amount)
	if not player then return end
	
	local data = DataManager:Get(player)
	if not data then return end
	
	data.XP += amount
	print("✨ " .. player.Name .. " gained " .. amount .. " XP")
	
	-- Level Up Loop (In case they gained enough for 2 levels)
	local maxXP = getMaxXP(data.Level)
	
	while data.XP >= maxXP do
		data.XP -= maxXP
		data.Level += 1
		
		-- AWARD INFLUENCE (📍)
		data.Influence = (data.Influence or 0) + 1
		
		print("🆙 LEVEL UP! " .. player.Name .. " is now Level " .. data.Level)
		
		-- Notify Client for VFX
		LevelUpRemote:FireClient(player, data.Level, 1) -- 1 is amount of Influence gained
		
		-- Recalculate for next loop
		maxXP = getMaxXP(data.Level)
	end
end)

-- Hook into RoundEndManager? 
-- You should modify RoundEndManager to fire this Bindable instead of just Spools.