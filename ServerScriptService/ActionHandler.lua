-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 MODULE: ActionHandler (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles validation for starting/stopping tasks.
-- -------------------------------------------------------------------------------

local ActionHandler = {}
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

-- We require StationManager from the parent service (Root)
local StationManager = require(ServerScriptService.StationManager)

function ActionHandler.HandleStart(player, target)
	-- 1. Sanity Check
	if not target then return end
	if not player.Character then return end
	
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local tPos = target:IsA("Model") and target:GetPivot().Position or target.Position
	local dist = (root.Position - tPos).Magnitude
	
	-- 2. Distance Validation (Server sees truth)
	if dist > 15 then 
		warn(player.Name .. " tried to interact from too far ("..math.floor(dist).." studs).")
		return 
	end
	
	-- 3. Route to Manager
	if CollectionService:HasTag(target, "Station") then
		StationManager.AssignPlayer(player, target)
	elseif CollectionService:HasTag(target, "MannequinStand") then
		-- Trigger Rescue Logic (If you moved rescue to a module, call it here)
		-- For now, InteractionServer might handle rescue directly, or we can add RescueManager later.
	end
end

function ActionHandler.HandleStop(player)
	StationManager.RemovePlayer(player)
end

return ActionHandler
