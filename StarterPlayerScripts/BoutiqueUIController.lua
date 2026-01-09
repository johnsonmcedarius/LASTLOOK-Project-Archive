-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: BoutiqueUIController (Client - NO GLOBALS)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Listens to BindableEvent to populate the grid.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local AccessoryRegistry = require(ReplicatedStorage.Modules.AccessoryRegistry)

local ShopRemote = ReplicatedStorage:WaitForChild("ShopEvent")
local ShopInterface = ReplicatedStorage:WaitForChild("ShopInterface") -- Bindable

local BODONI = Enum.Font.Bodoni 
local BoutiqueHUD = nil 

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

local function buildGrid(targetFrame, category, filterText)
	if not targetFrame then return end
	filterText = filterText or ""
	
	for _, child in pairs(targetFrame:GetChildren()) do
		if child:IsA("ImageButton") then child:Destroy() end
	end
	
	local source = (category == "Perk") and PerkRegistry.Definitions or AccessoryRegistry.Definitions
	local invString = Player:GetAttribute("Inventory") or ""
	
	-- Need a template. Creating one in code if missing for robustness.
	local template = targetFrame:FindFirstChild("CardTemplate")
	if not template then
		template = Instance.new("ImageButton")
		template.Name = "CardTemplate"
		template.Visible = false
		local l = Instance.new("TextLabel", template)
		l.Name = "ItemName"
		l.Size = UDim2.fromScale(1, 0.2)
		local p = Instance.new("TextLabel", template)
		p.Name = "PriceTag"
		p.Size = UDim2.fromScale(1, 0.2)
		p.Position = UDim2.fromScale(0, 0.8)
	end
	
	for id, info in pairs(source) do
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
				if priceLbl then priceLbl.Text = "OWNED" end
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

local function refreshBoutique(screenGui)
	BoutiqueHUD = screenGui
	local perksFrame = BoutiqueHUD:FindFirstChild("PerksGrid", true)
	local accFrame = BoutiqueHUD:FindFirstChild("AccessoriesGrid", true)
	
	if perksFrame then buildGrid(perksFrame, "Perk", "") end
	if accFrame then buildGrid(accFrame, "Accessory", "") end
end

ShopRemote.OnClientEvent:Connect(function(action, data)
	if action == "PurchaseSuccess" and BoutiqueHUD then
		refreshBoutique(BoutiqueHUD)
	end
end)

-- LISTENER (Replaces _G.RefreshBoutique)
ShopInterface.Event:Connect(function(action, data)
	if action == "Refresh" then
		refreshBoutique(data)
	end
end)
