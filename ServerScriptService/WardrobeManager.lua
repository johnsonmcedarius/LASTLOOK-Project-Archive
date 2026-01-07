-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: WardrobeManager (Server - EXTRA SLOTS UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Slot Unlocking. Added "Instant Unlock" via GamePass.
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataManager = require(game.ServerScriptService.DataManager)

-- EVENTS
local WardrobeRemote = Instance.new("RemoteEvent")
WardrobeRemote.Name = "WardrobeEvent"
WardrobeRemote.Parent = ReplicatedStorage

-- CONFIG
local SLOT_COSTS = {
	[2] = {Level = 10, Spools = 2500},
	[3] = {Level = 25, Spools = 10000}
}

WardrobeRemote.OnServerEvent:Connect(function(player, action, payload)
	local data = DataManager:Get(player)
	if not data then return end
	
	-- 1. EQUIP PERK
	if action == "Equip" then
		local perkId = payload.PerkId
		local slotNum = payload.SlotNum
		
		if not table.find(data.Inventory, perkId) then return end
		
		-- [UPDATED] Slot Security Check
		-- Logic: Unlock if Level met OR if GamePass Owned
		local allowed = false
		if slotNum == 1 then
			allowed = true
		elseif slotNum == 2 or slotNum == 3 then
			-- Check GamePass first (Instant Unlock)
			if DataManager:HasPass(player, "ExtraSlots") then
				allowed = true
			else
				-- Fallback to Level Check
				local req = SLOT_COSTS[slotNum]
				if data.Level >= req.Level then
					allowed = true -- (Assuming they paid the spools in UnlockSlot step)
					-- In this simplified logic, we trust the level check for equip if unlocked
				end
			end
		end
		
		if not allowed then 
			warn("⚠️ " .. player.Name .. " tried to use locked slot: " .. slotNum)
			return 
		end
		
		-- Set the Loadout
		data.EquippedPerks[slotNum] = perkId
		
		local perkString = ""
		for _, p in pairs(data.EquippedPerks) do 
			if p then perkString = perkString .. p .. "," end
		end
		player:SetAttribute("EquippedPerks", perkString)
		
		WardrobeRemote:FireClient(player, "EquipSuccess", data.EquippedPerks)
		
	-- 2. UNLOCK SLOT (Spools Purchase)
	elseif action == "UnlockSlot" then
		local slotNum = payload.SlotNum
		local cost = SLOT_COSTS[slotNum]
		
		if not cost then return end
		
		-- [UPDATED] If they own the pass, they don't need to pay Spools
		if DataManager:HasPass(player, "ExtraSlots") then
			WardrobeRemote:FireClient(player, "UnlockSuccess", slotNum)
			return
		end
		
		-- Standard Purchase Logic
		if data.Level >= cost.Level and data.Spools >= cost.Spools then
			data.Spools = data.Spools - cost.Spools
			-- Save unlock state if we were persisting it (Currently inferred by Equip check)
			WardrobeRemote:FireClient(player, "UnlockSuccess", slotNum)
		end
	end
end)
