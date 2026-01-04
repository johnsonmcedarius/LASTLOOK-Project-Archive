-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShopController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles the "Slide-In" UI, Blur, and Camera focus for the Boutique.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- CONFIG
local BLUR_SIZE = 15
local SLIDE_TIME = 0.5

-- STATE
local isShopOpen = false
local ShopUI = nil
local BlurEffect = Lighting:FindFirstChild("ShopBlur") or Instance.new("BlurEffect", Lighting)
BlurEffect.Name = "ShopBlur"
BlurEffect.Size = 0 -- Start clear

-- // SETUP UI (Placeholder for Nerd's Design)
local function createShopUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "BoutiqueHUD"
	screen.ResetOnSpawn = false
	screen.Parent = PlayerGui
	screen.Enabled = false -- Hidden initially
	
	-- Main Container (Start Position: Off-Screen Left)
	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.fromScale(0.4, 1) -- Takes up 40% of screen width
	main.Position = UDim2.fromScale(-0.5, 0) -- Hidden to the left
	main.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Dark luxury bg
	main.BorderSizePixel = 0
	main.Parent = screen
	
	-- Add a Close Button for testing
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(50, 50)
	closeBtn.Position = UDim2.fromScale(0.9, 0.05)
	closeBtn.Text = "X"
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeBtn.Parent = main
	
	closeBtn.MouseButton1Click:Connect(function()
		_G.ToggleBoutique(false)
	end)
	
	ShopUI = screen
end

-- // ANIMATION: Toggle Shop
local function toggleShop(isOpen)
	if not ShopUI then createShopUI() end
	local main = ShopUI.MainFrame
	
	if isOpen then
		ShopUI.Enabled = true
		isShopOpen = true
		
		-- 1. Blur World
		TweenService:Create(BlurEffect, TweenInfo.new(SLIDE_TIME), {Size = BLUR_SIZE}):Play()
		
		-- 2. Slide In (EaseOut for smooth entry)
		TweenService:Create(main, TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, 0)}):Play()
		
		-- 3. Optional: Hide other HUD elements?
		-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		
	else
		isShopOpen = false
		
		-- 1. Unblur
		TweenService:Create(BlurEffect, TweenInfo.new(SLIDE_TIME), {Size = 0}):Play()
		
		-- 2. Slide Out (EaseIn for quick exit)
		local t = TweenService:Create(main, TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = UDim2.fromScale(-0.5, 0)})
		t:Play()
		
		-- 3. Disable GUI after animation finishes
		t.Completed:Connect(function()
			ShopUI.Enabled = false
			-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
end

-- // EXPORT GLOBAL FUNCTION
-- This allows your Main Menu button or "B" key script to just call _G.ToggleBoutique(true)
_G.ToggleBoutique = toggleShop

-- // INPUT TEST (Optional - Remove before shipping)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.B then -- Press B to open store
		toggleShop(not isShopOpen)
	end
end)