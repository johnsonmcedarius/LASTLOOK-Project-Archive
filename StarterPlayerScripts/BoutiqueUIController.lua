-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: BoutiqueUIController (Client - SEARCH BAR ADDED)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Generates Grid + Search & Tag Filter Logic.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local AccessoryRegistry = require(ReplicatedStorage.Modules.AccessoryRegistry)

local ShopRemote = ReplicatedStorage:WaitForChild("ShopEvent")

local BODONI = Enum.Font.Bodoni 
local BoutiqueHUD = nil 

-- // HELPER: Matches Search?
local function matchesSearch(data, searchText)
	if searchText == "" then return true end
	
	searchText = string.lower(searchText)
	local name = string.lower(data.Name)
	
	if string.find(name, searchText) then return true end
	
	if data.Tags then
		for _, tag in pairs(data.Tags) do
			if string.find(string.lower(tag), searchText) then return true end
		end
	end
	
	return false
end

-- // FUNCTION: Build Grid (With Search Filter)
local function buildGrid(targetFrame, category, filterText)
	if not targetFrame then return end
	filterText = filterText or ""
	
	for _, child in pairs(targetFrame:GetChildren()) do
		if child:IsA("ImageButton") then child:Destroy() end
	end
	
	local source = (category == "Perk") and PerkRegistry.Definitions or AccessoryRegistry.Definitions
	local invString = Player:GetAttribute("Inventory") or ""
	
	local template = targetFrame.Parent:FindFirstChild("CardTemplate") 
	if not template then return end
	
	for id, info in pairs(source) do
		-- SEARCH FILTER
		if matchesSearch(info, filterText) then
			local card = template:Clone()
			card.Name = id
			card.Visible = true
			card.LayoutOrder = info.Price 
			
			local nameLbl = card:FindFirstChild("ItemName")
			local priceLbl = card:FindFirstChild("PriceTag")
			
			if nameLbl then 
				nameLbl.Text = info.Name 
				nameLbl.Font = BODONI
			end
			
			if priceLbl then
				local currencyIcon = (category == "Perk") and "📍" or "🧵"
				priceLbl.Text = info.Price .. " " .. currencyIcon
			end
			
			if string.find(invString, id) then
				if priceLbl then priceLbl.Text = "EQUIP" end
				card.ImageColor3 = Color3.fromRGB(100, 100, 100) 
			else
				card.MouseButton1Click:Connect(function()
					ShopRemote:FireServer("BuyItem", id, category)
				end)
			end
			
			card.Parent = targetFrame
		end
	end
end

-- // SETUP: Search Input Listener
local function setupSearchListeners()
	if not BoutiqueHUD then return end
	
	local searchBar = BoutiqueHUD:FindFirstChild("SearchBar", true)
	if searchBar then
		searchBar:GetPropertyChangedSignal("Text"):Connect(function()
			local text = searchBar.Text
			-- Refresh both grids live
			local perksFrame = BoutiqueHUD:FindFirstChild("PerksGrid", true)
			local accFrame = BoutiqueHUD:FindFirstChild("AccessoriesGrid", true)
			
			if perksFrame then buildGrid(perksFrame, "Perk", text) end
			if accFrame then buildGrid(accFrame, "Accessory", text) end
		end)
	end
end

local function loadFeatured()
	ShopRemote:FireServer("GetFeatured")
end

ShopRemote.OnClientEvent:Connect(function(action, data)
	if action == "FeaturedData" then
		print("🔥 Weekly Drop Loaded.")
	elseif action == "PurchaseSuccess" then
		_G.RefreshBoutique(BoutiqueHUD) -- Rebuild to show "Equip"
	end
end)

_G.RefreshBoutique = function(screenGui)
	BoutiqueHUD = screenGui
	
	local perksFrame = BoutiqueHUD:FindFirstChild("PerksGrid", true)
	local accFrame = BoutiqueHUD:FindFirstChild("AccessoriesGrid", true)
	
	local currentSearch = ""
	local searchBar = BoutiqueHUD:FindFirstChild("SearchBar", true)
	if searchBar then currentSearch = searchBar.Text end
	
	if perksFrame then buildGrid(perksFrame, "Perk", currentSearch) end
	if accFrame then buildGrid(accFrame, "Accessory", currentSearch) end
	
	loadFeatured()
	setupSearchListeners() -- Ensure connected
end
