-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopManager (Server - DEV PRODUCTS)
-- -------------------------------------------------------------------------------

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local DataManager = require(game.ServerScriptService.DataManager)

-- PRODUCT IDs (Replace with your actual IDs)
local PRODUCTS = {
	[12345] = {Type = "Spools", Amount = 500},
	[12346] = {Type = "Influence", Amount = 10}
}

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	
	local product = PRODUCTS[receiptInfo.ProductId]
	if product then
		local data = DataManager:Get(player)
		if product.Type == "Spools" then
			data.Spools = data.Spools + product.Amount
		elseif product.Type == "Influence" then
			data.Influence = (data.Influence or 0) + product.Amount
		end
		
		-- Chat Flex
		if product.Amount >= 5000 then
			game.TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(player.Name .. " just bought the Black Card! 💅")
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end
