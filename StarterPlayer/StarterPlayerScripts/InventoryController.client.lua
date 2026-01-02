--[[
    InventoryController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("👗 [CLIENT] Inventory Controller (UI Fix) Starting...")

-- EVENTS (Safe Wait)
local Events = ReplicatedStorage:WaitForChild("Events", 30)
if not Events then warn("❌ Inventory UI Failed: No Events Folder") return end

local EquipItem = Events:WaitForChild("EquipItem", 10)
local GetInventoryData = Events:WaitForChild("GetInventoryData", 10)

if not EquipItem or not GetInventoryData then 
	warn("❌ Inventory UI Failed: Missing Remotes") 
	return 
end

-- COLORS
local COLORS = {
	Midnight = Color3.fromRGB(25, 25, 35),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(255, 215, 0),
	Grey = Color3.fromRGB(60, 60, 65)
}

local isOpen = false
local mainFrame, gridContainer

-- UI BUILDER
local function CreateWardrobeUI()
	if playerGui:FindFirstChild("WardrobeUI") then playerGui.WardrobeUI:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "WardrobeUI"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 10
	screen.Parent = playerGui

	-- OPEN BUTTON
	local openBtn = Instance.new("TextButton", screen)
	openBtn.Name = "OpenWardrobe"
	openBtn.Text = "WARDROBE 👗"
	openBtn.Font = Enum.Font.GothamBlack
	openBtn.TextSize = 14
	openBtn.TextColor3 = COLORS.Midnight
	openBtn.BackgroundColor3 = COLORS.Cream
	openBtn.Size = UDim2.new(0.08, 0, 0.05, 0)
	openBtn.Position = UDim2.new(0.91, 0, 0.5, 0)
	local oc = Instance.new("UICorner", openBtn) oc.CornerRadius = UDim.new(0, 8)
	local os = Instance.new("UIStroke", openBtn) os.Color = COLORS.Gold os.Thickness = 2

	-- MAIN FRAME
	mainFrame = Instance.new("Frame", screen)
	mainFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
	mainFrame.Position = UDim2.new(0.5, 0, -0.7, 0) -- Off screen top
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = COLORS.Midnight
	local mc = Instance.new("UICorner", mainFrame) mc.CornerRadius = UDim.new(0, 12)
	local ms = Instance.new("UIStroke", mainFrame) ms.Color = COLORS.Cream ms.Thickness = 2

	-- Header
	local title = Instance.new("TextLabel", mainFrame)
	title.Text = "MY CLOSET"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = COLORS.Gold
	title.TextSize = 20
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1

	local close = Instance.new("TextButton", mainFrame)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 50, 50)
	close.TextSize = 30
	close.BackgroundTransparency = 1
	close.Size = UDim2.new(0.1, 0, 0.15, 0)
	close.Position = UDim2.new(0.9, 0, 0, 0)

	-- GRID
	gridContainer = Instance.new("ScrollingFrame", mainFrame)
	gridContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
	gridContainer.Position = UDim2.new(0.05, 0, 0.15, 0)
	gridContainer.BackgroundTransparency = 1
	gridContainer.ScrollBarThickness = 4

	-- 🚨 THE FIX: AUTO SIZE
	gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gridContainer.CanvasSize = UDim2.new(0,0,0,0) 

	local gl = Instance.new("UIGridLayout", gridContainer)
	gl.CellSize = UDim2.new(0.3, 0, 0.25, 0)
	gl.CellPadding = UDim2.new(0.03, 0, 0.03, 0)

	return openBtn, close
end

local openBtn, closeBtn = CreateWardrobeUI()

-- REFRESH (Protected Call)
local function RefreshInventory()
	for _, c in pairs(gridContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	-- 🛡️ SAFE FETCH
	local success, inventory = pcall(function()
		return GetInventoryData:InvokeServer()
	end)

	if not success then
		warn("⚠️ Failed to fetch inventory: " .. tostring(inventory))
		return
	end

	inventory = inventory or {}
	print("👗 Loaded " .. #inventory .. " items.")

	local unique = {}
	for _, name in ipairs(inventory) do unique[name] = true end

	for name, _ in pairs(unique) do
		local btn = Instance.new("TextButton", gridContainer)
		btn.BackgroundColor3 = COLORS.Grey
		btn.Text = ""
		local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(0, 8)

		local lbl = Instance.new("TextLabel", btn)
		lbl.Text = name
		lbl.Size = UDim2.new(0.9, 0, 0.8, 0)
		lbl.Position = UDim2.new(0.05, 0, 0.1, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = COLORS.Cream
		lbl.TextWrapped = true
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12

		btn.MouseButton1Click:Connect(function()
			EquipItem:FireServer(name)
			btn.BackgroundColor3 = COLORS.Gold
			lbl.TextColor3 = COLORS.Midnight
			task.wait(0.2)
			btn.BackgroundColor3 = COLORS.Grey
			lbl.TextColor3 = COLORS.Cream
		end)
	end
end

-- TOGGLE
local function ToggleWardrobe()
	isOpen = not isOpen
	if isOpen then RefreshInventory() end
	local targetY = isOpen and 0.5 or -0.7
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, targetY, 0)}):Play()
end

openBtn.MouseButton1Click:Connect(ToggleWardrobe)
closeBtn.MouseButton1Click:Connect(ToggleWardrobe)