-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopManager (Server - PLATINUM MASTER)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Boutique". Weekly Drops, Influence Spending, Gamepasses.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- MODULES
local DataManager = require(game.ServerScriptService.DataManager)
local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local AccessoryRegistry = require(ReplicatedStorage.Modules.AccessoryRegistry)

-- EVENTS
local ShopRemote = Instance.new("RemoteEvent")
ShopRemote.Name = "ShopEvent"
ShopRemote.Parent = ReplicatedStorage

-- CONFIG
local WEEKLY_SEED_OFFSET = 12345 
-- ⚠️ REPLACE WITH REAL ROBLOX PRODUCT IDs
local PRODUCT_IDS = {
	SMALL_SPOOLS = 123456, 
	INFLUENCE_PACK = 654321
}

-- // FUNCTION: Get Weekly "Featured 4"
-- Returns 2 Perks and 2 Accessories based on the current week
local function getWeeklyStock()
	local weekNum = math.floor(os.time() / 604800) -- Weeks since epoch (1970)
	local rng = Random.new(WEEKLY_SEED_OFFSET + weekNum) -- Seed changes every Sunday
	
	-- Helper to pick random keys from a table
	local function pickRandom(dictionary, count)
		local keys = {}
		for k in pairs(dictionary) do table.insert(keys, k) end
		local result = {}
		for i = 1, count do
			if #keys == 0 then break end
			local idx = rng:NextInteger(1, #keys)
			table.insert(result, keys[idx])
			table.remove(keys, idx)
		end
		return result
	end
	
	local perks = pickRandom(PerkRegistry.Definitions, 2)
	local accessories = pickRandom(AccessoryRegistry.Definitions, 2)
	
	return {
		Perks = perks,
		Accessories = accessories,
		WeekNumber = weekNum
	}
end

-- // CLIENT REQUESTS
ShopRemote.OnServerEvent:Connect(function(player, action, ...)
	
	-- 1. GET WEEKLY FEATURED
	if action == "GetFeatured" then
		local stock = getWeeklyStock()
		ShopRemote:FireClient(player, "FeaturedData", stock)
		
	-- 2. BUY ITEM
	elseif action == "BuyItem" then
		local itemId, category = ... -- Client sends "Perk" or "Accessory"
		local data = DataManager:Get(player)
		if not data then return end
		
		-- CHECK 1: Already Owned?
		if table.find(data.Inventory, itemId) then
			ShopRemote:FireClient(player, "PurchaseFailed", "Already Owned")
			return 
		end
		
		-- CHECK 2: Get Price & Currency Type
		local itemData = nil
		local cost = 0
		local currency = "Spools" -- Default
		
		if category == "Perk" then
			itemData = PerkRegistry.GetPerk(itemId)
			if itemData then 
				cost = itemData.Price 
				currency = "Influence" -- Perks cost Influence (📍)
			end
		elseif category == "Accessory" then
			itemData = AccessoryRegistry.GetItem(itemId)
			if itemData then 
				cost = itemData.Price 
				currency = "Spools" -- Accessories cost Spools (🧵)
			end
		end
		
		if not itemData then 
			warn("⚠️ Item data not found: " .. itemId)
			return 
		end
		
		-- CHECK 3: Transaction
		if currency == "Influence" then
			if (data.Influence or 0) >= cost then
				data.Influence -= cost
				table.insert(data.Inventory, itemId)
				
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				print("🛍️ " .. player.Name .. " bought Perk " .. itemId)
				
				-- IMPORTANT: Update Client Attribute immediately for UI
				player:SetAttribute("Inventory", table.concat(data.Inventory, ","))
			else
				ShopRemote:FireClient(player, "PurchaseFailed", "Not enough Influence")
			end
			
		elseif currency == "Spools" then
			if data.Spools >= cost then
				data.Spools -= cost
				table.insert(data.Inventory, itemId)
				
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				print("👜 " .. player.Name .. " bought Accessory " .. itemId)
				
				player:SetAttribute("Inventory", table.concat(data.Inventory, ","))
			else
				ShopRemote:FireClient(player, "PurchaseFailed", "Not enough Spools")
			end
		end
	end
end)

-- // MARKETPLACE HANDLING (Robux Transactions)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	
	-- If player left, tell Roblox to try again later
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	local data = DataManager:Get(player)
	if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	-- HANDLE PRODUCTS
	if receiptInfo.ProductId == PRODUCT_IDS.INFLUENCE_PACK then
		data.Influence = (data.Influence or 0) + 5
		print("💸 " .. player.Name .. " bought 5 Influence!")
		
		-- Update Attribute if needed (though DataManager saves usually handle re-init)
		-- Fire specific UI remote if you want a popup
		
	elseif receiptInfo.ProductId == PRODUCT_IDS.SMALL_SPOOLS then
		data.Spools = data.Spools + 1500
		print("💸 " .. player.Name .. " bought Spools!")
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
