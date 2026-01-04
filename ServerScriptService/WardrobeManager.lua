-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: WardrobeManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Slot Unlocking and Equipping Perks (Loadouts).
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataManager = require(game.ServerScriptService.DataManager)

-- EVENTS
local WardrobeRemote = Instance.new("RemoteEvent")
WardrobeRemote.Name = "WardrobeEvent"
WardrobeRemote.Parent = ReplicatedStorage

-- CONFIG
-- How much it costs to open the extra slots
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
		
		-- Security A: Does the player actually own this perk?
		if not table.find(data.Inventory, perkId) then 
			warn("⚠️ " .. player.Name .. " tried to equip unowned perk: " .. perkId)
			return 
		end
		
		-- Security B: Is the slot actually unlocked?
		-- Logic: Slot 1 is always open. Slot 2 needs Level 10. Slot 3 needs Level 25.
		-- (Ideally, you'd save an 'UnlockedSlots' table in Data, but Level check works for now)
		if slotNum == 2 and data.Level < 10 then return end
		if slotNum == 3 and data.Level < 25 then return end
		
		-- Set the Loadout in Data
		data.EquippedPerks[slotNum] = perkId
		
		-- CRITICAL: Update Player Attributes 
		-- This allows client scripts (like SprintMechanic) to read perks instantly without asking the server
		local perkString = ""
		for _, p in pairs(data.EquippedPerks) do 
			if p then perkString = perkString .. p .. "," end
		end
		player:SetAttribute("EquippedPerks", perkString)
		
		-- Tell UI to update
		WardrobeRemote:FireClient(player, "EquipSuccess", data.EquippedPerks)
		print("👗 " .. player.Name .. " equipped " .. perkId .. " in Slot " .. slotNum)
		
	-- 2. UNLOCK SLOT
	elseif action == "UnlockSlot" then
		local slotNum = payload.SlotNum
		local cost = SLOT_COSTS[slotNum]
		
		if not cost then return end
		
		-- Check Requirements
		if data.Level >= cost.Level and data.Spools >= cost.Spools then
			-- Pay up
			data.Spools = data.Spools - cost.Spools
			
			-- In a full game, you'd save {Slot2 = true} in data.UnlockedSlots here.
			
			WardrobeRemote:FireClient(player, "UnlockSuccess", slotNum)
			print("🔓 " .. player.Name .. " unlocked Wardrobe Slot " .. slotNum)
		else
			print("❌ " .. player.Name .. " failed to unlock slot (Not enough Level/Spools)")
		end
	end
end)