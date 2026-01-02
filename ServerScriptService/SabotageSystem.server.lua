--[[
    SabotageSystem (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events")
-- Create RemoteEvent if missing
local TabletEvent = Events:FindFirstChild("SabotageTabletAction") or Instance.new("RemoteEvent", Events)
TabletEvent.Name = "SabotageTabletAction"

-- VALUES
local ChaosFrozen = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ChaosFrozen")
local ChaosLevel = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ChaosLevel")

-- CONFIG
local COOLDOWNS = {
	ValveOverride = 45,
	ChaosUnfreeze = 60,
	ShadowWalk = 30
}

local playerCooldowns = {}

-- ACTIONS
local Actions = {}

function Actions.ValveOverride(player)
	print("😈 " .. player.Name .. " triggered REMOTE VALVE OVERRIDE")
	-- Logic: Find a random SteamValve prompt and disable it remotely / break it
	-- Ideally, this calls a function in TaskSystem to trigger a specific sabotage
	-- For now, we simulate the effect:
	-- _G.TaskSystem.TriggerRandomSabotage("SteamValve") 
end

function Actions.ChaosUnfreeze(player)
	if ChaosFrozen.Value == true then
		ChaosFrozen.Value = false
		print("🔥 " .. player.Name .. " MELTED the Muse Freeze!")
		-- Add a chaos spike for the audacity
		ChaosLevel.Value = math.min(ChaosLevel.Value + 5, 100)
	else
		print("⚠️ Chaos wasn't frozen, ability wasted.")
	end
end

function Actions.ShadowWalk(player)
	print("👻 " .. player.Name .. " entered SHADOW WALK")
	local char = player.Character
	if char then
		-- 1. Hide Name
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

		-- 2. Ghost Transparency
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				-- Tween transparency locally would be smoother, but server set is reliable
				part.Transparency = 0.8
				part.Material = Enum.Material.ForceField
			end
		end

		-- 3. Restore
		task.delay(5, function()
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
					part.Material = Enum.Material.Plastic -- Reset material
				end
			end
		end)
	end
end

-- 🛡️ SECURITY CHECK
TabletEvent.OnServerEvent:Connect(function(player, actionName)
	-- 1. Role Check
	if player:GetAttribute("Role") ~= "Saboteur" then 
		warn("⛔ Cheater detected: " .. player.Name .. " tried to use Sabotage Tablet.")
		return 
	end

	-- 2. Level Check
	if (player:GetAttribute("Level") or 1) < 5 then return end

	-- 3. Cooldown Check
	local t = os.time()
	local pData = playerCooldowns[player.UserId] or {}
	local lastUse = pData[actionName] or 0
	local cd = COOLDOWNS[actionName] or 10

	if (t - lastUse) < cd then return end -- Silently ignore spam

	-- 4. Execute
	if Actions[actionName] then
		pData[actionName] = t
		playerCooldowns[player.UserId] = pData
		Actions[actionName](player)
	end
end)local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events")
-- Create RemoteEvent if missing
local TabletEvent = Events:FindFirstChild("SabotageTabletAction") or Instance.new("RemoteEvent", Events)
TabletEvent.Name = "SabotageTabletAction"

-- VALUES
local ChaosFrozen = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ChaosFrozen")
local ChaosLevel = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ChaosLevel")

-- CONFIG
local COOLDOWNS = {
	ValveOverride = 45,
	ChaosUnfreeze = 60,
	ShadowWalk = 30
}

local playerCooldowns = {}

-- ACTIONS
local Actions = {}

function Actions.ValveOverride(player)
	print("😈 " .. player.Name .. " triggered REMOTE VALVE OVERRIDE")
	-- Logic: Find a random SteamValve prompt and disable it remotely / break it
	-- Ideally, this calls a function in TaskSystem to trigger a specific sabotage
	-- For now, we simulate the effect:
	-- _G.TaskSystem.TriggerRandomSabotage("SteamValve") 
end

function Actions.ChaosUnfreeze(player)
	if ChaosFrozen.Value == true then
		ChaosFrozen.Value = false
		print("🔥 " .. player.Name .. " MELTED the Muse Freeze!")
		-- Add a chaos spike for the audacity
		ChaosLevel.Value = math.min(ChaosLevel.Value + 5, 100)
	else
		print("⚠️ Chaos wasn't frozen, ability wasted.")
	end
end

function Actions.ShadowWalk(player)
	print("👻 " .. player.Name .. " entered SHADOW WALK")
	local char = player.Character
	if char then
		-- 1. Hide Name
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

		-- 2. Ghost Transparency
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				-- Tween transparency locally would be smoother, but server set is reliable
				part.Transparency = 0.8
				part.Material = Enum.Material.ForceField
			end
		end

		-- 3. Restore
		task.delay(5, function()
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer end
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
					part.Material = Enum.Material.Plastic -- Reset material
				end
			end
		end)
	end
end

-- 🛡️ SECURITY CHECK
TabletEvent.OnServerEvent:Connect(function(player, actionName)
	-- 1. Role Check
	if player:GetAttribute("Role") ~= "Saboteur" then 
		warn("⛔ Cheater detected: " .. player.Name .. " tried to use Sabotage Tablet.")
		return 
	end

	-- 2. Level Check
	if (player:GetAttribute("Level") or 1) < 5 then return end

	-- 3. Cooldown Check
	local t = os.time()
	local pData = playerCooldowns[player.UserId] or {}
	local lastUse = pData[actionName] or 0
	local cd = COOLDOWNS[actionName] or 10

	if (t - lastUse) < cd then return end -- Silently ignore spam

	-- 4. Execute
	if Actions[actionName] then
		pData[actionName] = t
		playerCooldowns[player.UserId] = pData
		Actions[actionName](player)
	end
end)