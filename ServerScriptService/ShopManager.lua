-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopManager (Server - MONETIZATION UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Boutique". Weekly Drops, Influence, & UPDATED GamePasses.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataManager = require(game.ServerScriptService.DataManager)
local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local AccessoryRegistry = require(ReplicatedStorage.Modules.AccessoryRegistry)

-- EVENTS
local ShopRemote = Instance.new("RemoteEvent")
ShopRemote.Name = "ShopEvent"
ShopRemote.Parent = ReplicatedStorage

-- CONFIG
local WEEKLY_SEED_OFFSET = 12345 

local PRODUCT_IDS = {
	SMALL_SPOOLS = 123456, 
	INFLUENCE_PACK = 654321
}

-- [UPDATED] Replaced Fast Walk with the Money Makers
local GAMEPASS_IDS = {
	VIP_FRONT_ROW = 000000, -- 649 R$
	SEASON_1 = 000000,      -- 399 R$
	DOUBLE_XP = 000000,     -- 299 R$
	DOUBLE_SPOOLS = 000000, -- 499 R$ [NEW]
	POSE_PACK = 000000,     -- 199 R$ [NEW]
	EXTRA_SLOTS = 000000    -- 99 R$  [NEW]
}

-- // FUNCTION: Get Weekly "Featured 4"
local function getWeeklyStock()
	local weekNum = math.floor(os.time() / 604800) 
	local rng = Random.new(WEEKLY_SEED_OFFSET + weekNum) 
	
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
	
	if action == "GetFeatured" then
		local stock = getWeeklyStock()
		ShopRemote:FireClient(player, "FeaturedData", stock)
		
	elseif action == "BuyItem" then
		local itemId, category = ... 
		local data = DataManager:Get(player)
		if not data then return end
		
		if table.find(data.Inventory, itemId) then
			ShopRemote:FireClient(player, "PurchaseFailed", "Already Owned")
			return 
		end
		
		local itemData = nil
		local cost = 0
		local currency = "Spools"
		
		if category == "Perk" then
			itemData = PerkRegistry.GetPerk(itemId)
			if itemData then 
				cost = itemData.Price 
				currency = "Influence" 
			end
		elseif category == "Accessory" then
			itemData = AccessoryRegistry.GetItem(itemId)
			if itemData then 
				cost = itemData.Price 
				currency = "Spools" 
			end
		end
		
		if not itemData then return end
		
		if currency == "Influence" then
			if (data.Influence or 0) >= cost then
				data.Influence -= cost
				table.insert(data.Inventory, itemId)
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				player:SetAttribute("Inventory", table.concat(data.Inventory, ","))
			else
				ShopRemote:FireClient(player, "PurchaseFailed", "Not enough Influence")
			end
			
		elseif currency == "Spools" then
			if data.Spools >= cost then
				data.Spools -= cost
				table.insert(data.Inventory, itemId)
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				player:SetAttribute("Inventory", table.concat(data.Inventory, ","))
			else
				ShopRemote:FireClient(player, "PurchaseFailed", "Not enough Spools")
			end
		end
	end
end)

-- // MARKETPLACE HANDLING
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	local data = DataManager:Get(player)
	if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	if receiptInfo.ProductId == PRODUCT_IDS.INFLUENCE_PACK then
		data.Influence = (data.Influence or 0) + 5
		print("💸 " .. player.Name .. " bought 5 Influence!")
		
	elseif receiptInfo.ProductId == PRODUCT_IDS.SMALL_SPOOLS then
		data.Spools = data.Spools + 1500
		print("💸 " .. player.Name .. " bought Spools!")
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- [UPDATED] GamePass Handler
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		local data = DataManager:Get(player)
		if data then
			if passId == GAMEPASS_IDS.DOUBLE_XP then
				data.GamePasses.TwoTimesXP = true
				print("🎟️ " .. player.Name .. " bought 2x XP!")
			elseif passId == GAMEPASS_IDS.DOUBLE_SPOOLS then
				data.GamePasses.DoubleSpools = true
				print("🧵 " .. player.Name .. " bought 2x Spools!")
			elseif passId == GAMEPASS_IDS.POSE_PACK then
				data.GamePasses.PosePack = true
				print("📸 " .. player.Name .. " bought Pose Pack!")
			elseif passId == GAMEPASS_IDS.EXTRA_SLOTS then
				data.GamePasses.ExtraSlots = true
				print("👗 " .. player.Name .. " bought Extra Wardrobe Slots!")
				-- Trigger immediate refresh if needed
			end
		end
	end
end)
