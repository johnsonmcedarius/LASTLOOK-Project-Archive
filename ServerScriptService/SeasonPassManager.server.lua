--[[
    SeasonPassManager (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULES
local EconomySystem = require(ServerScriptService:WaitForChild("EconomySystem"))

-- EVENTS
local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then Events = Instance.new("Folder", ReplicatedStorage) Events.Name = "Events" end

local ClaimRewardFunc = Events:FindFirstChild("ClaimReward") or Instance.new("RemoteFunction", Events)
ClaimRewardFunc.Name = "ClaimReward"

local GetRewardsFunc = Events:FindFirstChild("GetSeasonRewards") or Instance.new("RemoteFunction", Events)
GetRewardsFunc.Name = "GetSeasonRewards"

-- DATA
local ClaimedData = {} -- {UserId = { [Level] = {Free = true, Premium = false} }}

-- 📖 THE LOOKBOOK (REWARDS)
local REWARDS = {}
for i = 1, 50 do
	local freeReward = {Type = "Spools", Amount = 100 + (i * 10)}
	local premReward = {Type = "Spools", Amount = 500 + (i * 20)}

	-- Milestones
	if i % 5 == 0 then
		premReward = {Type = "Item", Name = "Designer Shades"} 
	end
	if i == 50 then
		premReward = {Type = "Item", Name = "Mythic Halo"} 
	end

	REWARDS[i] = {Free = freeReward, Premium = premReward}
end

print("📖 [SERVER] Season Pass Manager Loaded.")

-- HELPER: Get Claim Status
local function GetClaimStatus(player, level)
	if not ClaimedData[player.UserId] then ClaimedData[player.UserId] = {} end
	return ClaimedData[player.UserId][level] or {Free = false, Premium = false}
end

-- HELPER: Give Reward
local function GrantReward(player, rewardData)
	if rewardData.Type == "Spools" then
		EconomySystem.AddSpools(player, rewardData.Amount)
		return true
	elseif rewardData.Type == "Item" then
		if EconomySystem.AddItem then
			EconomySystem.AddItem(player, rewardData.Name)
			return true
		else
			warn("⚠️ EconomySystem missing AddItem function!")
			return false
		end
	end
	return false
end

-- 📡 CLIENT REQUEST
function ClaimRewardFunc.OnServerInvoke(player, level, track) -- track: "Free" or "Premium"
	local currentLvl = player:GetAttribute("Level") or 1
	local hasPass = player:GetAttribute("HasSeasonPass")

	-- 1. Check Level
	if currentLvl < level then return {Success = false, Msg = "Level too low!"} end

	-- 2. Check Pass
	if track == "Premium" and not hasPass then return {Success = false, Msg = "Buy Season Pass!"} end

	-- 3. Check Duplicate
	local status = GetClaimStatus(player, level)
	if status[track] then return {Success = false, Msg = "Already Claimed!"} end

	-- 4. Grant
	local reward = REWARDS[level][track]
	local success = GrantReward(player, reward)

	if success then
		if not ClaimedData[player.UserId][level] then ClaimedData[player.UserId][level] = {} end
		ClaimedData[player.UserId][level][track] = true
		print("✅ " .. player.Name .. " claimed Lvl " .. level .. " (" .. track .. ")")
		return {Success = true}
	else
		return {Success = false, Msg = "System Error"}
	end
end

-- EXPORT REWARDS LIST
function GetRewardsFunc.OnServerInvoke(player)
	return {
		Rewards = REWARDS,
		Claims = ClaimedData[player.UserId] or {}
	}
end

Players.PlayerRemoving:Connect(function(player)
	ClaimedData[player.UserId] = nil
end)

return {}