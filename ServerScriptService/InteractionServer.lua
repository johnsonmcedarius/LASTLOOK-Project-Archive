-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionServer (Server - DEBUG MODE)
-- 🛠️ AUTH: Novae Studios
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InteractionRemote = ReplicatedStorage:FindFirstChild("InteractionEvent")
if not InteractionRemote then
	InteractionRemote = Instance.new("RemoteEvent")
	InteractionRemote.Name = "InteractionEvent"
	InteractionRemote.Parent = ReplicatedStorage
end

-- Ensure GlobalPowerEvent exists to prevent Infinite Yields
if not ReplicatedStorage:FindFirstChild("GlobalPowerEvent") then
	local gpe = Instance.new("RemoteEvent")
	gpe.Name = "GlobalPowerEvent"
	gpe.Parent = ReplicatedStorage
	print("⚠️ Auto-Created missing 'GlobalPowerEvent'")
end

-- Load Modules
local ActionHandler = require(ServerScriptService.Modules.ActionHandler)
local HealingManager = require(ServerScriptService.Modules.HealingManager)

InteractionRemote.OnServerEvent:Connect(function(player, action, ...)
	if action == "StartTask" then
		print("📡 Server: Received StartTask from " .. player.Name) -- DEBUG
		ActionHandler.HandleStart(player, ...)
	elseif action == "StopTask" then
		ActionHandler.HandleStop(player)
	elseif action == "Heal" then
		HealingManager.ProcessHeal(player, ...)
	end
end)
