--[[
    ShopController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🛒 [CLIENT] Shop Controller (Spool System) Starting...")

-- WAIT FOR SERVER
local Events = ReplicatedStorage:WaitForChild("Events", 10)
local RequestSpin = Events:WaitForChild("RequestSpin", 10)

-- 💵 DEV PRODUCTS
local PROD_IDS = {
	TIER_1 = 111111, -- 500
	TIER_2 = 222222, -- 2200
	TIER_3 = 333333, -- 6000
	TIER_4 = 444444, -- 20000
	DAILY  = 555555  -- Daily
}

-- 🎨 COLORS
local COLORS = {
	Midnight = Color3.fromRGB(20, 20, 30),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(255, 215, 0),
	Red = Color3.fromRGB(255, 60, 60),
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(50, 200, 100),
	Rare = Color3.fromRGB(50, 150, 255),
	Epic = Color3.fromRGB(200, 50, 255),
	Legendary = Color3.fromRGB(255, 170, 0)
}

local gui, mainFrame, resultContainer
local isOpen = false

-- 🛠️ UI BUILDER
local function CreateShopUI()
	if playerGui:FindFirstChild("AtelierShop") then playerGui.AtelierShop:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "AtelierShop"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 5
	screen.Parent = playerGui

	-- 1. OPEN BUTTON
	local openBtn = Instance.new("TextButton", screen)
	openBtn.Name = "OpenShop"
	openBtn.Text = "SHOP 🧵"
	openBtn.Font = Enum.Font.GothamBlack
	openBtn.TextSize = 14
	openBtn.TextColor3 = COLORS.Midnight
	openBtn.BackgroundColor3 = COLORS.Gold
	openBtn.Size = UDim2.new(0.08, 0, 0.05, 0)
	openBtn.Position = UDim2.new(0.01, 0, 0.5, 0)
	local oc = Instance.new("UICorner", openBtn) oc.CornerRadius = UDim.new(0, 8)
	local os = Instance.new("UIStroke", openBtn) os.Color = COLORS.Cream os.Thickness = 2

	-- 2. MAIN FRAME
	mainFrame = Instance.new("Frame", screen)
	mainFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = COLORS.Midnight
	local mc = Instance.new("UICorner", mainFrame) mc.CornerRadius = UDim.new(0, 12)
	local ms = Instance.new("UIStroke", mainFrame) ms.Color = COLORS.Gold ms.Thickness = 2

	-- Header
	local title = Instance.new("TextLabel", mainFrame)
	title.Text = "THE ATELIER // SPOOLS & SPINS"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = COLORS.Cream
	title.TextSize = 24
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.BackgroundTransparency = 1

	local close = Instance.new("TextButton", mainFrame)
	close.Text = "×"
	close.TextColor3 = COLORS.Red
	close.TextSize = 30
	close.BackgroundTransparency = 1
	close.Size = UDim2.new(0.05, 0, 0.1, 0)
	close.Position = UDim2.new(0.95, 0, 0, 0)

	-- 3. LEFT SIDE: SPOOL PACKS (Robux)
	local packsFrame = Instance.new("Frame", mainFrame)
	packsFrame.Size = UDim2.new(0.3, 0, 0.85, 0)
	packsFrame.Position = UDim2.new(0.02, 0, 0.12, 0)
	packsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	local pc = Instance.new("UICorner", packsFrame) pc.CornerRadius = UDim.new(0, 8)

	local packList = Instance.new("UIListLayout", packsFrame)
	packList.Padding = UDim.new(0.02, 0)
	packList.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Helper: Create Pack Button
	local function CreatePack(name, spools, price, id, isDaily)
		local btn = Instance.new("TextButton", packsFrame)
		btn.BackgroundColor3 = isDaily and COLORS.Red or COLORS.Cream
		btn.Size = UDim2.new(0.9, 0, 0.18, 0)
		btn.Text = ""
		local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(0, 6)

		local lbl = Instance.new("TextLabel", btn)
		lbl.Text = name
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextColor3 = COLORS.Midnight
		lbl.Size = UDim2.new(1,0,0.3,0)
		lbl.BackgroundTransparency = 1

		local amt = Instance.new("TextLabel", btn)
		amt.Text = "🧵 " .. spools
		amt.Font = Enum.Font.GothamBlack
		amt.TextSize = 16
		amt.TextColor3 = COLORS.Midnight
		amt.Size = UDim2.new(1,0,0.3,0)
		amt.Position = UDim2.new(0,0,0.3,0)
		amt.BackgroundTransparency = 1

		local cost = Instance.new("TextLabel", btn)
		cost.Text = price .. " R$"
		cost.Font = Enum.Font.Gotham
		cost.TextSize = 12
		cost.TextColor3 = COLORS.Midnight
		cost.Size = UDim2.new(1,0,0.3,0)
		cost.Position = UDim2.new(0,0,0.6,0)
		cost.BackgroundTransparency = 1

		if isDaily then
			lbl.TextColor3 = COLORS.Cream
			amt.TextColor3 = COLORS.Cream
			cost.TextColor3 = COLORS.Cream
			local t = Instance.new("TextLabel", btn)
			t.Text = "DAILY DEAL!"
			t.TextColor3 = COLORS.Gold
			t.Position = UDim2.new(0,0,-0.3,0)
			t.Size = UDim2.new(1,0,0.3,0)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.GothamBlack
		end

		btn.MouseButton1Click:Connect(function()
			MarketplaceService:PromptProductPurchase(player, id)
		end)
	end

	CreatePack("EMERGENCY STASH", "500", "49", PROD_IDS.TIER_1)
	CreatePack("INTERN'S STASH", "2,200", "199", PROD_IDS.TIER_2)
	CreatePack("DESIGNER'S KIT", "6,000", "499", PROD_IDS.TIER_3)
	CreatePack("ATELIER CRATE", "20,000", "1,499", PROD_IDS.TIER_4)
	CreatePack("FLASH SALE", "1,000", "80", PROD_IDS.DAILY, true)

	-- 4. RIGHT SIDE: SPINS (Spools)
	local spinArea = Instance.new("Frame", mainFrame)
	spinArea.Size = UDim2.new(0.65, 0, 0.2, 0)
	spinArea.Position = UDim2.new(0.33, 0, 0.75, 0)
	spinArea.BackgroundTransparency = 1

	local spinLayout = Instance.new("UIListLayout", spinArea)
	spinLayout.FillDirection = Enum.FillDirection.Horizontal
	spinLayout.Padding = UDim.new(0.05, 0)

	local function CreateSpinBtn(spins, cost)
		local btn = Instance.new("TextButton", spinArea)
		btn.BackgroundColor3 = COLORS.Gold
		btn.Size = UDim2.new(0.3, 0, 1, 0)
		btn.Text = ""
		local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(0, 8)

		local top = Instance.new("TextLabel", btn)
		top.Text = spins .. " SPIN" .. (spins > 1 and "S" or "")
		top.Font = Enum.Font.GothamBlack
		top.TextSize = 16
		top.Size = UDim2.new(1,0,0.5,0)
		top.BackgroundTransparency = 1
		top.TextColor3 = COLORS.Midnight

		local bot = Instance.new("TextLabel", btn)
		bot.Text = "🧵 " .. cost
		bot.Font = Enum.Font.Gotham
		bot.TextSize = 14
		bot.Size = UDim2.new(1,0,0.5,0)
		bot.Position = UDim2.new(0,0,0.5,0)
		bot.BackgroundTransparency = 1
		bot.TextColor3 = COLORS.Midnight

		return btn
	end

	local b1 = CreateSpinBtn(1, 500)
	local b5 = CreateSpinBtn(5, 2500)
	local b10 = CreateSpinBtn(10, 5000)

	-- 5. RESULT CONTAINER
	resultContainer = Instance.new("ScrollingFrame", mainFrame)
	resultContainer.Size = UDim2.new(0.65, 0, 0.55, 0)
	resultContainer.Position = UDim2.new(0.33, 0, 0.15, 0)
	resultContainer.BackgroundTransparency = 1
	resultContainer.ScrollBarThickness = 4
	local gl = Instance.new("UIGridLayout", resultContainer)
	gl.CellSize = UDim2.new(0.28, 0, 0.45, 0)
	gl.CellPadding = UDim2.new(0.05, 0, 0.05, 0)

	return openBtn, close, {b1, b5, b10}
end

local openBtn, closeBtn, spinBtns = CreateShopUI()

-- 🎞️ ANIMATION
local function ToggleShop()
	isOpen = not isOpen
	local targetY = isOpen and 0.5 or 1.5
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, targetY, 0)}):Play()
end

-- 🎰 SPIN LOGIC
local function PerformSpin(amount)
	-- Clear old
	for _, c in pairs(resultContainer:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local response = RequestSpin:InvokeServer(amount)

	if not response.Success then
		-- Flash Red if broke
		spinBtns[1].BackgroundColor3 = COLORS.Red
		task.wait(0.2)
		spinBtns[1].BackgroundColor3 = COLORS.Gold
		print(response.Msg)
		return
	end

	-- Show Items
	for i, item in ipairs(response.Results) do
		task.wait(0.15)
		local card = Instance.new("Frame", resultContainer)
		card.BackgroundColor3 = COLORS.Midnight
		card.BorderSizePixel = 0
		local cc = Instance.new("UICorner", card) cc.CornerRadius = UDim.new(0, 6)
		local cs = Instance.new("UIStroke", card) cs.Color = COLORS[item.Rarity] or COLORS.Common cs.Thickness = 2

		local name = Instance.new("TextLabel", card)
		name.Text = item.Name
		name.Size = UDim2.new(0.9, 0, 0.4, 0)
		name.Position = UDim2.new(0.05, 0, 0.55, 0)
		name.BackgroundTransparency = 1
		name.TextColor3 = COLORS.Cream
		name.Font = Enum.Font.GothamBold
		name.TextSize = 10
		name.TextWrapped = true

		local rar = Instance.new("TextLabel", card)
		rar.Text = item.Rarity
		rar.Size = UDim2.new(1, 0, 0.2, 0)
		rar.TextColor3 = COLORS[item.Rarity]
		rar.BackgroundTransparency = 1
		rar.Font = Enum.Font.Code
		rar.TextSize = 9

		card.BackgroundTransparency = 1
		TweenService:Create(card, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	end
end

openBtn.MouseButton1Click:Connect(ToggleShop)
closeBtn.MouseButton1Click:Connect(ToggleShop)
spinBtns[1].MouseButton1Click:Connect(function() PerformSpin(1) end)
spinBtns[2].MouseButton1Click:Connect(function() PerformSpin(5) end)
spinBtns[3].MouseButton1Click:Connect(function() PerformSpin(10) end)