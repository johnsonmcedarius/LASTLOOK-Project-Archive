-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 MODULE: ActionHandler (Server)
-- -------------------------------------------------------------------------------

local ActionHandler = {}
local CollectionService = game:GetService("CollectionService")
local StationManager = require(game.ServerScriptService.StationManager)

function ActionHandler.HandleStart(player, target)
	-- Distance Check
	if not target then return end
	local pPos = player.Character.HumanoidRootPart.Position
	local tPos = target:IsA("Model") and target.PrimaryPart.Position or target.Position
	
	if (pPos - tPos).Magnitude > 15 then return end
	
	if CollectionService:HasTag(target, "Station") then
		StationManager.AssignPlayer(player, target)
	end
end

function ActionHandler.HandleStop(player)
	StationManager.RemovePlayer(player)
end

return ActionHandler
