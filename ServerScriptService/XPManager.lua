-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: XPManager (Server - SCAM PROOF)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Leveling, XP Curves, Influence, and GAMEPASS MULTIPLIERS.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(game.ServerScriptService.DataManager)

-- CONFIG
local BASE_XP = 1000 -- XP needed for Level 2
local XP_MULTIPLIER = 1.2 -- Curve
local GAMEPASS_MULT = 2 -- The 2x Multiplier

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
	
	-- [CRITICAL FIX] CHECK FOR 2X XP PASS
	-- If we don't do this, the 299 R$ gamepass is a donation.
	if DataManager:HasPass(player, "TwoTimesXP") then
		amount = amount * GAMEPASS_MULT
		-- print("🎟️ 2x XP Applied for " .. player.Name) -- Uncomment for debug
	end
	
	data.XP += amount
	-- print("✨ " .. player.Name .. " gained " .. amount .. " XP")
	
	-- Level Up Loop
	local maxXP = getMaxXP(data.Level)
	
	while data.XP >= maxXP do
		data.XP -= maxXP
		data.Level += 1
		
		-- AWARD INFLUENCE (📍)
		data.Influence = (data.Influence or 0) + 1
		
		print("🆙 LEVEL UP! " .. player.Name .. " is now Level " .. data.Level)
		
		-- Notify Client for VFX
		LevelUpRemote:FireClient(player, data.Level, 1) 
		
		maxXP = getMaxXP(data.Level)
	end
end)
