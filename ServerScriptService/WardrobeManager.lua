-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: WardrobeManager (Server - IDS UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Slot Unlocking.
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataManager = require(game.ServerScriptService.DataManager)

local WardrobeRemote = Instance.new("RemoteEvent")
WardrobeRemote.Name = "WardrobeEvent"
WardrobeRemote.Parent = ReplicatedStorage

local SLOT_COSTS = {
	[2] = {Level = 10, Spools = 2500},
	[3] = {Level = 25, Spools = 10000}
}

WardrobeRemote.OnServerEvent:Connect(function(player, action, payload)
	local data = DataManager:Get(player)
	if not data then return end
	
	if action == "Equip" then
		local perkId = payload.PerkId
		local slotNum = payload.SlotNum
		
		if not table.find(data.Inventory, perkId) then return end
		
		local allowed = false
		if slotNum == 1 then allowed = true
		elseif slotNum == 2 or slotNum == 3 then
			if DataManager:HasPass(player, "ExtraSlots") then
				allowed = true
			else
				if data.Level >= SLOT_COSTS[slotNum].Level then allowed = true end
			end
		end
		
		if allowed then
			data.EquippedPerks[slotNum] = perkId
			local perkString = ""
			for _, p in pairs(data.EquippedPerks) do perkString = perkString .. p .. "," end
			player:SetAttribute("EquippedPerks", perkString)
			WardrobeRemote:FireClient(player, "EquipSuccess", data.EquippedPerks)
		end
		
	elseif action == "UnlockSlot" then
		local slotNum = payload.SlotNum
		local cost = SLOT_COSTS[slotNum]
		if not cost then return end
		
		if DataManager:HasPass(player, "ExtraSlots") then
			WardrobeRemote:FireClient(player, "UnlockSuccess", slotNum)
			return
		end
		
		if data.Level >= cost.Level and data.Spools >= cost.Spools then
			data.Spools = data.Spools - cost.Spools
			WardrobeRemote:FireClient(player, "UnlockSuccess", slotNum)
		end
	end
end)
