-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: WardrobeController (Client - AUTO BUILD VERSION)
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local WardrobeRemote = ReplicatedStorage:WaitForChild("WardrobeEvent")

local selectedSlot = 1
local WardrobeHUD = nil
local InventoryGrid = nil

-- 1. AUTO-BUILD UI
local function createWardrobeUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "WardrobeGUI"
	screen.ResetOnSpawn = false
	screen.Enabled = false -- Start closed
	screen.Parent = PlayerGui
	WardrobeHUD = screen

	-- Main BG
	local main = Instance.new("Frame")
	main.Size = UDim2.fromOffset(500, 400)
	main.Position = UDim2.fromScale(0.5, 0.5)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	main.Parent = screen
	
	-- Close Button (Press M to toggle, but here is a button too)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(30, 30)
	closeBtn.Position = UDim2.fromScale(1, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Text = "X"
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Parent = main
	closeBtn.MouseButton1Click:Connect(function() screen.Enabled = false end)

	-- 3 Slots at the top
	for i = 1, 3 do
		local slot = Instance.new("TextButton")
		slot.Name = "Slot"..i
		slot.Size = UDim2.fromOffset(100, 100)
		slot.Position = UDim2.fromOffset(20 + ((i-1)*120), 20)
		slot.Text = "SLOT " .. i
		slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		slot.Parent = main
		
		-- Helper Logic for clicking a slot
		slot.MouseButton1Click:Connect(function()
			selectedSlot = i
			print("Selected Slot " .. i)
			-- Visual feedback
			for j=1,3 do main["Slot"..j].BorderColor3 = Color3.new(0,0,0) end
			slot.BorderColor3 = Color3.new(1,1,0) -- Yellow highlight
		end)
	end
	
	-- Inventory Grid (Bottom half)
	InventoryGrid = Instance.new("ScrollingFrame")
	InventoryGrid.Name = "InventoryGrid"
	InventoryGrid.Size = UDim2.fromScale(0.9, 0.5)
	InventoryGrid.Position = UDim2.fromScale(0.05, 0.45)
	InventoryGrid.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	InventoryGrid.Parent = main
	
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(80, 80)
	layout.Parent = InventoryGrid
end

-- 2. LOGIC
local function buildInventory()
	if not InventoryGrid then return end
	
	-- Clear old items
	for _, child in pairs(InventoryGrid:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	
	local invString = Player:GetAttribute("Inventory") or ""
	
	for id, info in pairs(PerkRegistry.Definitions) do
		-- Only show owned items
		if string.find(invString, id) then
			local btn = Instance.new("TextButton")
			btn.Name = id
			btn.Text = info.Name
			btn.TextWrapped = true
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			btn.Parent = InventoryGrid
			
			btn.MouseButton1Click:Connect(function()
				WardrobeRemote:FireServer("Equip", { PerkId = id, SlotNum = selectedSlot })
			end)
		end
	end
end

local function updateSlots()
	local equippedRaw = Player:GetAttribute("EquippedPerks") or ""
	local equipped = string.split(equippedRaw, ",")
	
	if WardrobeHUD then
		local main = WardrobeHUD:FindFirstChild("Frame")
		for i = 1, 3 do
			local slotBtn = main:FindFirstChild("Slot"..i)
			if slotBtn then
				local perkId = equipped[i]
				if perkId and perkId ~= "" and PerkRegistry.GetPerk(perkId) then
					slotBtn.Text = PerkRegistry.GetPerk(perkId).Name
				else
					slotBtn.Text = "EMPTY"
				end
			end
		end
	end
end

-- Events
WardrobeRemote.OnClientEvent:Connect(function(action)
	if action == "EquipSuccess" or action == "UnlockSuccess" then
		updateSlots()
	end
end)

-- Init
createWardrobeUI()

-- Input to Open (Press M)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		WardrobeHUD.Enabled = not WardrobeHUD.Enabled
		if WardrobeHUD.Enabled then
			updateSlots()
			buildInventory()
		end
	end
end)
