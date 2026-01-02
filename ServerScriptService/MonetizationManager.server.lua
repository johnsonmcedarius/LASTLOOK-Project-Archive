--[[
    MonetizationManager (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 💵 IDS
local PASS_IDS = {
	VIP = 1234567,       
	MUSE = 2345678,      
	SEASON = 3456789     
}

local PRODUCT_IDS = {
	TIER_1 = 111111,     -- 500 Spools
	TIER_2 = 222222,     -- 2200 Spools
	TIER_3 = 333333,     -- 6000 Spools
	TIER_4 = 444444,     -- 20000 Spools
	DAILY  = 555555      -- Daily Deal
}

local SPOOL_AMOUNTS = {
	[PRODUCT_IDS.TIER_1] = 500,
	[PRODUCT_IDS.TIER_2] = 2200,
	[PRODUCT_IDS.TIER_3] = 6000,
	[PRODUCT_IDS.TIER_4] = 20000,
	[PRODUCT_IDS.DAILY]  = 1000 
}

-- MODULES (Wait for the ModuleScript!)
local EconomySystem = require(ServerScriptService:WaitForChild("EconomySystem")) 

print("💳 [SERVER] Monetization Manager Loading...")

-- PERKS
local function ApplyVIP(player)
	player:SetAttribute("IsVIP", true)
	print("✨ VIP Applied: " .. player.Name)
end

local function ApplyMuse(player)
	player:SetAttribute("HasMusePass", true)
end

local function ApplySeasonPass(player)
	player:SetAttribute("HasSeasonPass", true)
end

-- GAMEPASS LOGIC
local function CheckPasses(player)
	local function check(id, func)
		local s, res = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id) end)
		if s and res then func(player) end
	end
	check(PASS_IDS.VIP, ApplyVIP)
	check(PASS_IDS.MUSE, ApplyMuse)
	check(PASS_IDS.SEASON, ApplySeasonPass)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then return end
	if passId == PASS_IDS.VIP then ApplyVIP(player)
	elseif passId == PASS_IDS.MUSE then ApplyMuse(player)
	elseif passId == PASS_IDS.SEASON then ApplySeasonPass(player) end
end)

-- DEV PRODUCTS (SPOOLS)
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local productId = receiptInfo.ProductId
	local amount = SPOOL_AMOUNTS[productId]

	if amount then
		EconomySystem.AddSpools(player, amount)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

Players.PlayerAdded:Connect(CheckPasses)
for _, p in ipairs(Players:GetPlayers()) do CheckPasses(p) end

return {}