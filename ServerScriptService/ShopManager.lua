-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Boutique". Weekly Drops, Influence Spending, Gamepasses.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- MODULES
local DataManager = require(game.ServerScriptService.DataManager)
local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)

-- EVENTS
local ShopRemote = Instance.new("RemoteEvent")
ShopRemote.Name = "ShopEvent"
ShopRemote.Parent = ReplicatedStorage

-- CONFIG
-- ⚠️ REPLACE THESE NUMBERS WITH YOUR REAL DEV PRODUCT IDs FROM ROBLOX DASHBOARD
local PRODUCT_IDS = {
	SMALL_SPOOLS = 123456, 
	INFLUENCE_PACK = 654321
}

-- // FUNCTION: Process Purchase (Influence/Spools)
ShopRemote.OnServerEvent:Connect(function(player, action, itemId, currencyType)
	if action == "BuyItem" then
		local data = DataManager:Get(player)
		if not data then return end
		
		-- CHECK 1: Already Owned?
		if table.find(data.Inventory, itemId) then
			ShopRemote:FireClient(player, "PurchaseFailed", "Already Owned")
			return 
		end
		
		-- CHECK 2: Get Price from Registry
		local perkData = PerkRegistry.GetPerk(itemId)
		if not perkData then 
			warn("⚠️ Item " .. itemId .. " not found in Registry!")
			return 
		end
		
		-- Dynamic Pricing based on Rarity (Centralized Logic)
		local price = 0
		if perkData.Rarity == "Common" then price = 5
		elseif perkData.Rarity == "Rare" then price = 10
		elseif perkData.Rarity == "Legendary" then price = 15
		elseif perkData.Rarity == "Mythic" then price = 25
		end
		
		-- CHECK 3: Transaction
		if currencyType == "Influence" then
			if (data.Influence or 0) >= price then
				data.Influence -= price
				table.insert(data.Inventory, itemId)
				
				-- Notify Client
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				print("🛍️ " .. player.Name .. " bought " .. itemId .. " for " .. price .. " Influence")
			else
				ShopRemote:FireClient(player, "PurchaseFailed", "Not enough Influence")
			end
		else
			-- Handle Spools logic here if you add Spool items later
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
		-- Fire UI update via Remote if needed
		
	elseif receiptInfo.ProductId == PRODUCT_IDS.SMALL_SPOOLS then
		data.Spools = data.Spools + 1500
		print("💸 " .. player.Name .. " bought Spools!")
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end