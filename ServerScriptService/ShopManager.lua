-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopManager (Server - INFLUENCE UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Boutique Backend. IDs fixed.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local DataManager = require(game.ServerScriptService.DataManager)
local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local AccessoryRegistry = require(ReplicatedStorage.Modules.AccessoryRegistry)

local ShopRemote = Instance.new("RemoteEvent")
ShopRemote.Name = "ShopEvent"
ShopRemote.Parent = ReplicatedStorage

local WEEKLY_SEED_OFFSET = 12345 

local GP_IDS = {
	VIP = 1663577257,
	SEASON_PASS = 1663591190,
	DOUBLE_XP = 1663637133,
	DOUBLE_SPOOLS = 1660067874,
	EDITORIAL_PACK = 1662801472, 
	EXTRA_SLOTS = 1662161370
}

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
	return {
		Perks = pickRandom(PerkRegistry.Definitions, 2),
		Accessories = pickRandom(AccessoryRegistry.Definitions, 2),
		WeekNumber = weekNum
	}
end

ShopRemote.OnServerEvent:Connect(function(player, action, ...)
	if action == "GetFeatured" then
		ShopRemote:FireClient(player, "FeaturedData", getWeeklyStock())
		
	elseif action == "BuyItem" then
		local itemId, category = ... 
		local data = DataManager:Get(player)
		if not data then return end
		
		if table.find(data.Inventory, itemId) then return end
		
		local cost = 0
		local currency = "Spools"
		
		if category == "Perk" then
			local d = PerkRegistry.GetPerk(itemId)
			if d then cost, currency = d.Price, "Influence" end
		elseif category == "Accessory" then
			local d = AccessoryRegistry.GetItem(itemId)
			if d then cost, currency = d.Price, "Spools" end
		end
		
		if currency == "Influence" then
			if (data.Influence or 0) >= cost then
				data.Influence -= cost
				table.insert(data.Inventory, itemId)
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				player:SetAttribute("Inventory", table.concat(data.Inventory, ","))
			end
		else
			if data.Spools >= cost then
				data.Spools -= cost
				table.insert(data.Inventory, itemId)
				ShopRemote:FireClient(player, "PurchaseSuccess", itemId)
				player:SetAttribute("Inventory", table.concat(data.Inventory, ","))
			end
		end
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if wasPurchased then
		local data = DataManager:Get(player)
		if data then
			if passId == GP_IDS.DOUBLE_XP then data.GamePasses.TwoTimesXP = true
			elseif passId == GP_IDS.DOUBLE_SPOOLS then data.GamePasses.DoubleSpools = true
			elseif passId == GP_IDS.EDITORIAL_PACK then data.GamePasses.EditorialPack = true
			elseif passId == GP_IDS.EXTRA_SLOTS then data.GamePasses.ExtraSlots = true
			elseif passId == GP_IDS.VIP then data.GamePasses.VIP = true
			elseif passId == GP_IDS.SEASON_PASS then data.GamePasses.SeasonPass = true
			end
		end
	end
end)
