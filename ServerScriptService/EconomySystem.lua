--[[
    EconomySystem (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("💰 [SERVER] Economy System (Final Master v5) Loading...")

local Exported = {}

-- ============================================================================
-- 1. SETUP REMOTES
-- ============================================================================
local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
	Events = Instance.new("Folder", ReplicatedStorage)
	Events.Name = "Events"
end

local RequestSpinFunc = Events:FindFirstChild("RequestSpin")
if not RequestSpinFunc then
	RequestSpinFunc = Instance.new("RemoteFunction", Events)
	RequestSpinFunc.Name = "RequestSpin"
end

-- ============================================================================
-- 2. DATA & CONFIG
-- ============================================================================
local PlayerData = {} -- Stores Inventory & Pity Counter per session

local ITEMS = {
	Common = {"Basic Scarf", "Canvas Tote", "Stud Earrings", "Beanie", "Face Mask"},
	Uncommon = {"Designer Shades", "Silk Tie", "Leather Gloves", "Choker", "Silver Ring"},
	Rare = {"Fur Stole", "Gold Chain", "Platform Boots", "Cat Ears", "Tech Visor"},
	Epic = {"Neon Wings", "Ghost Aura", "Diamond Grillz", "Floating Crown"},
	Legendary = {"Mythic Halo", "Glitch Effect", "Void Cape"}
}

local SPIN_COST = 500
local PITY_THRESHOLD = 10 -- 11th spin (or 10th in a pack) is lucky

-- ============================================================================
-- 3. CORE FUNCTIONS
-- ============================================================================

-- SETUP PLAYER (Fixes Duplicates)
local function SetupPlayer(player)
	-- 1. Cleanup Duplicate Leaderstats
	local folders = {}
	for _, c in pairs(player:GetChildren()) do
		if c.Name == "leaderstats" then table.insert(folders, c) end
	end

	local leaderstats
	if #folders > 0 then
		leaderstats = folders[1] -- Keep the first one
		-- Destroy extras
		for i = 2, #folders do folders[i]:Destroy() end
	else
		leaderstats = Instance.new("Folder", player)
		leaderstats.Name = "leaderstats"
	end

	-- 2. Ensure Spools Exist
	local spools = leaderstats:FindFirstChild("SewingSpools")
	if not spools then
		spools = Instance.new("IntValue", leaderstats)
		spools.Name = "SewingSpools"
		spools.Value = 5000 -- Starting Cash
	end

	-- 3. Init Session Data
	if not PlayerData[player.UserId] then
		PlayerData[player.UserId] = {
			Inventory = {"Basic Scarf"}, -- Starter Item
			PityCounter = 0
		}
	end
end

-- RNG ENGINE
local function RollRarity(userId, forceGood)
	local data = PlayerData[userId]
	local roll = math.random(1, 100)

	-- Pity Check or Forced Luck
	if forceGood or (data and data.PityCounter >= PITY_THRESHOLD) then
		if data then data.PityCounter = 0 end -- Reset pity

		local pityRoll = math.random(1, 20) -- Weights: Rare(12) + Epic(6) + Leg(2)
		if pityRoll <= 12 then return "Rare"
		elseif pityRoll <= 18 then return "Epic"
		else return "Legendary" end
	end

	-- Standard Roll
	local result = "Common"
	if roll <= 50 then result = "Common"
	elseif roll <= 80 then result = "Uncommon"
	elseif roll <= 92 then result = "Rare"
	elseif roll <= 98 then result = "Epic"
	else result = "Legendary" end

	-- Update Pity
	if data then
		if result == "Common" then data.PityCounter += 1
		elseif result ~= "Uncommon" then data.PityCounter = 0 end -- Rare+ resets pity
	end

	return result
end

local function GetItem(rarity)
	local pool = ITEMS[rarity]
	if not pool then return "Glitch Item" end
	return pool[math.random(1, #pool)]
end

-- ============================================================================
-- 4. EXPORTED API (FOR OTHER SCRIPTS)
-- ============================================================================

-- Give Money (GameLoop / Monetization)
function Exported.AddSpools(player, amt)
	SetupPlayer(player)
	if player.leaderstats and player.leaderstats:FindFirstChild("SewingSpools") then
		player.leaderstats.SewingSpools.Value += amt
		print("💰 Added " .. amt .. " Spools to " .. player.Name)
	end
end

-- Read Inventory (Wardrobe)
function Exported.GetInventory(player)
	SetupPlayer(player)
	if PlayerData[player.UserId] then
		return PlayerData[player.UserId].Inventory
	end
	return {}
end

-- Add Specific Item (Season Pass)
function Exported.AddItem(player, itemName)
	SetupPlayer(player)
	if PlayerData[player.UserId] then
		table.insert(PlayerData[player.UserId].Inventory, itemName)
		print("🎒 Added " .. itemName .. " to " .. player.Name .. "'s inventory")
	end
end

-- Manual Spin (Called by Monetization for Robux Spins)
function Exported.PerformSpin(player, amount)
	SetupPlayer(player)
	local results = {}
	for i = 1, amount do
		local forceGood = (amount == 10 and i == 10)
		local rarity = RollRarity(player.UserId, forceGood)
		local itemName = GetItem(rarity)

		table.insert(results, {Name = itemName, Rarity = rarity})
		table.insert(PlayerData[player.UserId].Inventory, itemName)
	end
	return results
end

-- ============================================================================
-- 5. CLIENT TRANSACTION HANDLER
-- ============================================================================
function RequestSpinFunc.OnServerInvoke(player, amount)
	SetupPlayer(player)

	-- 🚨 FIX: Force Convert to Number
	amount = tonumber(amount)

	local stats = player:FindFirstChild("leaderstats")
	local spools = stats and stats:FindFirstChild("SewingSpools")
	if not spools then return {Success = false, Msg = "Data Error"} end

	-- Validate Amount & Cost
	local totalCost = 0
	if amount == 1 then totalCost = 500
	elseif amount == 5 then totalCost = 2500
	elseif amount == 10 then totalCost = 5000
	else return {Success = false, Msg = "Invalid Amount"} end

	-- Check Balance
	if spools.Value < totalCost then
		return {Success = false, Msg = "Need " .. (totalCost - spools.Value) .. " more Spools!"}
	end

	-- Pay
	spools.Value -= totalCost

	-- Spin using the exported logic
	local results = Exported.PerformSpin(player, amount)

	return {Success = true, Results = results}
end

-- Init
Players.PlayerAdded:Connect(SetupPlayer)
for _, p in ipairs(Players:GetPlayers()) do SetupPlayer(p) end

_G.EconomySystem = Exported
return Exported