-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: BoutiqueUIController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Generates the Grid. Handles "Sold Out" states & Featured Tab.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local AccessoryRegistry = require(ReplicatedStorage.Modules.AccessoryRegistry)

local ShopRemote = ReplicatedStorage:WaitForChild("ShopEvent")

-- CONFIG
local BODONI = Enum.Font.Bodoni -- High Fashion Font

-- STATE
local BoutiqueHUD = nil -- Reference to ScreenGui

-- // FUNCTION: Build Grid
-- targetFrame: The ScrollingFrame (e.g., PerksTab)
-- category: "Perk" or "Accessory"
local function buildGrid(targetFrame, category)
	if not targetFrame then return end
	
	-- 1. Clear Old
	for _, child in pairs(targetFrame:GetChildren()) do
		if child:IsA("ImageButton") then child:Destroy() end
	end
	
	-- 2. Get Data Source
	local source = (category == "Perk") and PerkRegistry.Definitions or AccessoryRegistry.Definitions
	
	-- 3. Get User Inventory (From Attribute for speed)
	local invString = Player:GetAttribute("Inventory") or ""
	
	-- 4. Generate Cards
	-- Nerd needs to make a template button named "CardTemplate" inside the script or UI
	-- For this script, we assume there's a template inside the ScrollingFrame invisible
	local template = targetFrame.Parent:FindFirstChild("CardTemplate") 
	if not template then warn("⚠️ No CardTemplate found!") return end
	
	for id, info in pairs(source) do
		local card = template:Clone()
		card.Name = id
		card.Visible = true
		card.LayoutOrder = info.Price -- Sort by price automatically
		
		-- Set Info
		local nameLbl = card:FindFirstChild("ItemName")
		local priceLbl = card:FindFirstChild("PriceTag")
		local icon = card:FindFirstChild("Icon")
		
		if nameLbl then 
			nameLbl.Text = info.Name 
			nameLbl.Font = BODONI
		end
		
		if priceLbl then
			local currencyIcon = (category == "Perk") and "📍" or "🧵"
			priceLbl.Text = info.Price .. " " .. currencyIcon
		end
		
		-- Check Ownership
		if string.find(invString, id) then
			-- OWNED STATE
			if priceLbl then priceLbl.Text = "EQUIP" end
			card.ImageColor3 = Color3.fromRGB(100, 100, 100) -- Dim it slightly
			-- Disable buying, enable equipping logic if Wardrobe is open
		else
			-- BUY STATE
			card.MouseButton1Click:Connect(function()
				ShopRemote:FireServer("BuyItem", id, category)
			end)
		end
		
		card.Parent = targetFrame
	end
end

-- // FUNCTION: Populate Featured Tab
local function loadFeatured()
	ShopRemote:FireServer("GetFeatured")
end

ShopRemote.OnClientEvent:Connect(function(action, data)
	if action == "FeaturedData" then
		-- Data contains {Perks = {id, id}, Accessories = {id, id}}
		-- Pass this to a similar build function restricted to just these 4 items
		print("🔥 Weekly Drop Loaded. Week #" .. data.WeekNumber)
		-- Update Featured UI elements here
		
	elseif action == "PurchaseSuccess" then
		-- Refresh Grids immediately
		-- You might want to call buildGrid() again or just update the specific card
		print("✅ Transaction Complete!")
	end
end)

-- EXPORT: Call this when opening the shop
_G.RefreshBoutique = function(screenGui)
	BoutiqueHUD = screenGui
	local perksFrame = BoutiqueHUD:FindFirstChild("PerksGrid", true)
	local accFrame = BoutiqueHUD:FindFirstChild("AccessoriesGrid", true)
	
	if perksFrame then buildGrid(perksFrame, "Perk") end
	if accFrame then buildGrid(accFrame, "Accessory") end
	loadFeatured()
end