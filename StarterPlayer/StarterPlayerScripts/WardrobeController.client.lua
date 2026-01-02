--[[
    WardrobeController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

print("👗 [CLIENT] Wardrobe Controller (Fixed Rotation) Starting...")

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events", 30)
local EquipItem = Events:WaitForChild("EquipItem", 10)
local GetInventoryData = Events:WaitForChild("GetInventoryData", 10)

-- COLORS
local COLORS = {
	Midnight = Color3.fromRGB(20, 20, 30),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(255, 215, 0),
	Grey = Color3.fromRGB(60, 60, 65)
}

local isOpen = false
local mainFrame, itemContainer
local dofEffect -- Replaces Blur for that "Portrait Mode" look
local characterRotation = 0
local isDragging = false
local lastMouseX = 0

-- 🛠️ UI BUILDER
local function CreateWardrobeUI()
	if playerGui:FindFirstChild("WardrobeUI") then playerGui.WardrobeUI:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "WardrobeUI"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 10
	screen.Parent = playerGui

	-- 1. OPEN BUTTON
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

	-- 2. ITEM PANEL
	mainFrame = Instance.new("Frame", screen)
	mainFrame.Name = "ItemPanel"
	mainFrame.Size = UDim2.new(0.25, 0, 1, 0)
	mainFrame.Position = UDim2.new(1.2, 0, 0, 0)
	mainFrame.BackgroundColor3 = COLORS.Midnight
	mainFrame.BorderSizePixel = 0

	local grad = Instance.new("UIGradient", mainFrame)
	grad.Rotation = 90
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, COLORS.Midnight),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
	}

	-- Header
	local header = Instance.new("Frame", mainFrame)
	header.Size = UDim2.new(1, 0, 0.1, 0)
	header.BackgroundTransparency = 1

	local title = Instance.new("TextLabel", header)
	title.Text = "MY COLLECTION"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = COLORS.Gold
	title.TextSize = 24
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.Position = UDim2.new(0, 0, 0.25, 0)
	title.BackgroundTransparency = 1

	local close = Instance.new("TextButton", header)
	close.Text = "×"
	close.TextColor3 = Color3.fromRGB(255, 80, 80)
	close.Font = Enum.Font.Gotham
	close.TextSize = 32
	close.BackgroundTransparency = 1
	close.Size = UDim2.new(0.2, 0, 1, 0)
	close.Position = UDim2.new(0.8, 0, 0, 0)

	-- Item Grid
	itemContainer = Instance.new("ScrollingFrame", mainFrame)
	itemContainer.Size = UDim2.new(0.9, 0, 0.85, 0)
	itemContainer.Position = UDim2.new(0.05, 0, 0.12, 0)
	itemContainer.BackgroundTransparency = 1
	itemContainer.ScrollBarThickness = 2
	itemContainer.ScrollBarImageColor3 = COLORS.Gold

	local grid = Instance.new("UIGridLayout", itemContainer)
	grid.CellSize = UDim2.new(0.45, 0, 0.15, 0)
	grid.CellPadding = UDim2.new(0.05, 0, 0.02, 0)

	-- 3. ROTATION ZONE
	local dragZone = Instance.new("TextButton", screen)
	dragZone.Name = "RotateZone"
	dragZone.Text = ""
	dragZone.BackgroundTransparency = 1
	dragZone.Size = UDim2.new(0.75, 0, 1, 0)
	dragZone.Visible = false

	-- DRAG LOGIC
	dragZone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			lastMouseX = input.Position.X
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position.X - lastMouseX
			characterRotation = characterRotation - (delta * 0.01)
			lastMouseX = input.Position.X
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)

	return openBtn, close, dragZone
end

local openBtn, closeBtn, dragZone = CreateWardrobeUI()

-- 🔄 REFRESH
local function RefreshInventory()
	for _, c in pairs(itemContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	local success, inventory = pcall(function() return GetInventoryData:InvokeServer() end)
	if not success then return end
	inventory = inventory or {}

	local unique = {}
	for _, name in ipairs(inventory) do unique[name] = true end

	for name, _ in pairs(unique) do
		local btn = Instance.new("TextButton", itemContainer)
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

		local char = player.Character
		if char and char:FindFirstChild(name) then
			btn.BackgroundColor3 = COLORS.Gold
			lbl.TextColor3 = COLORS.Midnight
		end

		btn.MouseButton1Click:Connect(function()
			EquipItem:FireServer(name)
			if btn.BackgroundColor3 == COLORS.Gold then
				btn.BackgroundColor3 = COLORS.Grey
				lbl.TextColor3 = COLORS.Cream
			else
				btn.BackgroundColor3 = COLORS.Gold
				lbl.TextColor3 = COLORS.Midnight
			end
		end)
	end
end

-- 🎥 CAMERA & MOVEMENT LOCK
local function UpdateCamera()
	if not isOpen then return end
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- 🚨 FIXED MATH: Relative to Player's Body
	local dist = 7
	-- We use root.CFrame to ensure "0" rotation means "Front of Body"
	-- 0, 2, -dist places camera slightly up and in FRONT (Z is negative forward in Roblox object space)
	local offset = CFrame.Angles(0, characterRotation, 0) * CFrame.new(0, 2, -dist)

	-- Convert that local offset to world space based on player's current facing direction
	local newCF = root.CFrame:ToWorldSpace(offset)

	-- Force camera to look back at the chest/head area
	newCF = CFrame.lookAt(newCF.Position, root.Position + Vector3.new(0, 0.5, 0))

	camera.CFrame = camera.CFrame:Lerp(newCF, 0.2)

	-- 📸 FOCUS
	if dofEffect then
		dofEffect.FocusDistance = dist
	end
end

local function FreezeCharacter(freeze)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")

	if freeze then
		if hum then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	else
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
	end
end

-- 🎞️ TOGGLE LOGIC
local function ToggleWardrobe()
	isOpen = not isOpen

	if isOpen then
		-- 1. ACTIVATE
		FreezeCharacter(true)
		camera.CameraType = Enum.CameraType.Scriptable
		dragZone.Visible = true
		RefreshInventory()

		-- 2. DEPTH OF FIELD
		dofEffect = Instance.new("DepthOfFieldEffect", Lighting)
		dofEffect.Name = "WardrobeDoF"
		dofEffect.FarIntensity = 0.8
		dofEffect.NearIntensity = 0
		dofEffect.InFocusRadius = 8

		-- 3. UI
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.75, 0, 0, 0)
		}):Play()

		-- 🚨 RESET ROTATION TO 0 (FRONT FACE)
		characterRotation = 0 
		RunService:BindToRenderStep("WardrobeCam", Enum.RenderPriority.Camera.Value, UpdateCamera)

	else
		-- 1. DEACTIVATE
		if dofEffect then dofEffect:Destroy() end
		dragZone.Visible = false
		RunService:UnbindFromRenderStep("WardrobeCam")
		camera.CameraType = Enum.CameraType.Custom
		FreezeCharacter(false)

		-- 2. UI
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1.2, 0, 0, 0)
		}):Play()
	end
end

openBtn.MouseButton1Click:Connect(ToggleWardrobe)
closeBtn.MouseButton1Click:Connect(ToggleWardrobe)