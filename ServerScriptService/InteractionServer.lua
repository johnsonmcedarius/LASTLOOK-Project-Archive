-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionServer (Server - DELEGATOR)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The Main Switchboard. Delegates logic to modules.
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local InteractionRemote = ReplicatedStorage:FindFirstChild("InteractionEvent") or Instance.new("RemoteEvent")
InteractionRemote.Name = "InteractionEvent"
InteractionRemote.Parent = ReplicatedStorage

-- Load Modules
local ActionHandler = require(ServerScriptService.Modules.ActionHandler)
local HealingManager = require(ServerScriptService.Modules.HealingManager)

InteractionRemote.OnServerEvent:Connect(function(player, action, ...)
	if action == "StartTask" then
		ActionHandler.HandleStart(player, ...)
	elseif action == "StopTask" then
		ActionHandler.HandleStop(player)
	elseif action == "Heal" then
		HealingManager.ProcessHeal(player, ...)
	end
end)
