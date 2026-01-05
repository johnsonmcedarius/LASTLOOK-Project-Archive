-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: WardrobeController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles the Loadout UI (Equipping/Unlocking Slots).
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local WardrobeRemote = ReplicatedStorage:WaitForChild("WardrobeEvent")

-- CONFIG
local SLOT_PRICES = {
	[2] = "Level 10 + 2,500 🧵",
	[3] = "Level 25 + 10,000 🧵"
}

-- STATE
local selectedSlot = 1 -- Default to first slot
local WardrobeHUD = nil

-- // HELPER: Get Perk Info
local function getPerkName(id)
	if not id or id == "" then return "EMPTY" end
	local def = PerkRegistry.GetPerk(id)
	return def and def.Name or "Unknown"
end

-- // FUNCTION: Update Slots Visuals
local function updateSlots()
	if not WardrobeHUD then return end
	
	-- Get current loadout from Attribute (Fast read from Server update)
	local equippedRaw = Player:GetAttribute("EquippedPerks") or ""
	local equipped = string.split(equippedRaw, ",")
	
	-- Update Slot UI Elements (Tell Nerd to name buttons Slot1, Slot2, Slot3)
	for i = 1, 3 do
		local slotBtn = WardrobeHUD:FindFirstChild("Slot" .. i, true)
		if slotBtn then
			local perkId = equipped[i]
			local label = slotBtn:FindFirstChild("PerkName")
			local icon = slotBtn:FindFirstChild("Icon")
			local lock = slotBtn:FindFirstChild("LockOverlay")
			
			-- 1. Check Unlock Status (UI Simulation)
			local isLocked = false
			local playerLevel = Player:GetAttribute("Level") or 1
			
			if i == 2 and playerLevel < 10 then isLocked = true end
			if i == 3 and playerLevel < 25 then isLocked = true end
			
			if isLocked then
				if label then label.Text = "LOCKED" end
				if lock then 
					lock.Visible = true 
					local costLbl = lock:FindFirstChild("CostLabel")
					if costLbl then costLbl.Text = SLOT_PRICES[i] end
				end
				
				-- Click to Unlock
				slotBtn.MouseButton1Click:Connect(function()
					WardrobeRemote:FireServer("UnlockSlot", {SlotNum = i})
				end)
			else
				if lock then lock.Visible = false end
				if label then label.Text = getPerkName(perkId) end
				
				-- Selection Logic
				slotBtn.MouseButton1Click:Connect(function()
					selectedSlot = i
					print("Selected Slot " .. i)
					-- Tell Nerd to add a "SelectedBorder" frame to toggle visible here
				end)
			end
		end
	end
end

-- // FUNCTION: Build Inventory Grid (For equipping)
local function buildInventory()
	if not WardrobeHUD then return end
	local grid = WardrobeHUD:FindFirstChild("InventoryGrid", true)
	if not grid then return end
	
	-- Clear old
	for _, child in pairs(grid:GetChildren()) do
		if child:IsA("ImageButton") then child:Destroy() end
	end
	
	-- Get Inventory from Attribute
	local invString = Player:GetAttribute("Inventory") or ""
	
	-- Template
	local template = grid.Parent:FindFirstChild("CardTemplate")
	if not template then return end
	
	-- Loop through Registry to show Owned Items
	for id, info in pairs(PerkRegistry.Definitions) do
		-- Only show owned perks
		if string.find(invString, id) then
			local card = template:Clone()
			card.Name = id
			card.Visible = true
			
			local nameLbl = card:FindFirstChild("ItemName")
			if nameLbl then nameLbl.Text = info.Name end
			
			-- Equip Click
			card.MouseButton1Click:Connect(function()
				print("Attempting to equip " .. id .. " to Slot " .. selectedSlot)
				WardrobeRemote:FireServer("Equip", {
					PerkId = id,
					SlotNum = selectedSlot
				})
			end)
			
			card.Parent = grid
		end
	end
end

-- // EVENTS
WardrobeRemote.OnClientEvent:Connect(function(action, data)
	if action == "EquipSuccess" or action == "UnlockSuccess" then
		updateSlots()
		-- Optional: Play a "Snap" sound effect here
	end
end)

-- // EXPORT: Open Wardrobe
-- Call this function when the Wardrobe Button is clicked in the main menu
_G.OpenWardrobe = function(screenGui)
	WardrobeHUD = screenGui
	updateSlots()
	buildInventory()
end
