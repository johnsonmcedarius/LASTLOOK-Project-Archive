-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopController (Client - NO GLOBALS)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Shop UI + Blur. Now uses BindableEvent "ShopInterface".
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- BINDABLE SETUP (Replaces _G)
local ShopInterface = ReplicatedStorage:FindFirstChild("ShopInterface")
if not ShopInterface then
	ShopInterface = Instance.new("BindableEvent")
	ShopInterface.Name = "ShopInterface"
	ShopInterface.Parent = ReplicatedStorage
end

-- CONFIG
local BLUR_SIZE = 15
local SLIDE_TIME = 0.5

-- STATE
local isShopOpen = false
local ShopUI = nil
local BlurEffect = Lighting:FindFirstChild("ShopBlur") or Instance.new("BlurEffect", Lighting)
BlurEffect.Name = "ShopBlur"
BlurEffect.Size = 0 

local function createShopUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "BoutiqueHUD"
	screen.ResetOnSpawn = false
	screen.Parent = PlayerGui
	screen.Enabled = false 
	
	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.fromScale(0.4, 1) 
	main.Position = UDim2.fromScale(-0.5, 0) 
	main.BackgroundColor3 = Color3.fromRGB(15, 15, 15) 
	main.Parent = screen
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(50, 50)
	closeBtn.Position = UDim2.fromScale(0.9, 0.05)
	closeBtn.Text = "X"
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeBtn.Parent = main
	
	closeBtn.MouseButton1Click:Connect(function()
		ShopInterface:Fire("Toggle", false)
	end)
	
	-- Placeholder containers for BoutiqueUIController to fill
	local pGrid = Instance.new("ScrollingFrame", main)
	pGrid.Name = "PerksGrid"
	pGrid.Size = UDim2.fromScale(0.9, 0.4)
	pGrid.Position = UDim2.fromScale(0.05, 0.1)
	
	local aGrid = Instance.new("ScrollingFrame", main)
	aGrid.Name = "AccessoriesGrid"
	aGrid.Size = UDim2.fromScale(0.9, 0.4)
	aGrid.Position = UDim2.fromScale(0.05, 0.55)
	
	ShopUI = screen
end

local function toggleShop(isOpen)
	if not ShopUI then createShopUI() end
	local main = ShopUI.MainFrame
	
	if isOpen then
		ShopUI.Enabled = true
		isShopOpen = true
		TweenService:Create(BlurEffect, TweenInfo.new(SLIDE_TIME), {Size = BLUR_SIZE}):Play()
		TweenService:Create(main, TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, 0)}):Play()
		
		-- Signal BoutiqueUIController to refresh data
		ShopInterface:Fire("Refresh", ShopUI)
	else
		isShopOpen = false
		TweenService:Create(BlurEffect, TweenInfo.new(SLIDE_TIME), {Size = 0}):Play()
		local t = TweenService:Create(main, TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = UDim2.fromScale(-0.5, 0)})
		t:Play()
		t.Completed:Connect(function()
			ShopUI.Enabled = false
		end)
	end
end

-- LISTEN
ShopInterface.Event:Connect(function(action, ...)
	if action == "Toggle" then
		local state = ...
		if state == nil then state = not isShopOpen end
		toggleShop(state)
	end
end)

-- INPUT TEST
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.B then 
		toggleShop(not isShopOpen)
	end
end)
