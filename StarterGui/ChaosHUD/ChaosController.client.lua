--[[
    ChaosController (LocalScript)
    Path: StarterGui → ChaosHUD
    Parent: ChaosHUD
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent

-- VALUES
local Values = ReplicatedStorage:WaitForChild("Values")
local ChaosLevel = Values:WaitForChild("ChaosLevel")
local ChaosFrozen = Values:WaitForChild("ChaosFrozen")

-- ASSETS
local CRACK_ID = "rbxassetid://13165236024"

local barFill, barLabel, crackOverlay, container

-- 🛠️ GENERATE UI
local function CreateChaosBar()
	if gui:FindFirstChild("ChaosContainer") then gui.ChaosContainer:Destroy() end

	local frame = Instance.new("Frame")
	frame.Name = "ChaosContainer"
	frame.Size = UDim2.new(0.4, 0, 0.04, 0)
	frame.Position = UDim2.new(0.5, 0, 0.08, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner", frame) corner.CornerRadius = UDim.new(0, 4)
	local stroke = Instance.new("UIStroke", frame) stroke.Color = Color3.fromRGB(20,20,20) stroke.Thickness = 2

	local fill = Instance.new("Frame", frame)
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BorderSizePixel = 0
	local fc = Instance.new("UICorner", fill) fc.CornerRadius = UDim.new(0, 4)

	local label = Instance.new("TextLabel", frame)
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.ZIndex = 2

	local crack = Instance.new("ImageLabel", gui)
	crack.Name = "CrackedScreen"
	crack.Size = UDim2.new(1, 0, 1, 0)
	crack.Image = CRACK_ID
	crack.BackgroundTransparency = 1
	crack.ImageTransparency = 1
	crack.ZIndex = 0

	return fill, label, crack, frame
end

barFill, barLabel, crackOverlay, container = CreateChaosBar()

-- 🕵️ ROLE-BASED VISUALS
local function UpdateRoleVisuals()
	local role = player:GetAttribute("Role")
	if role == "Saboteur" then
		barLabel.Text = "SYSTEM FAILURE" -- Aggressive
		container.BackgroundColor3 = Color3.fromRGB(20, 0, 0) -- Dark Red BG
	else
		barLabel.Text = "HOUSE STABILITY" -- Defensive
		container.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	end
end

-- 🎨 UPDATE LOGIC
local function UpdateChaos(val)
	local percent = math.clamp(val / 100, 0, 1)
	local role = player:GetAttribute("Role")

	-- Tween Size
	TweenService:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.new(percent, 0, 1, 0)}):Play()

	-- Color Logic
	local color
	if role == "Saboteur" then
		-- For Saboteur: Always Red/Midnight to look like a weapon
		color = Color3.fromRGB(255, 50, 50) 
	else
		-- For Designers: Green -> Red (Panic)
		if percent < 0.5 then color = Color3.fromRGB(0, 255, 150)
		elseif percent < 0.75 then color = Color3.fromRGB(255, 200, 50)
		else color = Color3.fromRGB(255, 50, 50) end
	end

	TweenService:Create(barFill, TweenInfo.new(0.5), {BackgroundColor3 = color}):Play()

	-- Cracks
	if percent >= 0.75 then
		TweenService:Create(crackOverlay, TweenInfo.new(1), {ImageTransparency = 0.3}):Play()
	else
		TweenService:Create(crackOverlay, TweenInfo.new(1), {ImageTransparency = 1}):Play()
	end
end

ChaosLevel.Changed:Connect(UpdateChaos)
player:GetAttributeChangedSignal("Role"):Connect(UpdateRoleVisuals)

-- Init
UpdateRoleVisuals()
UpdateChaos(ChaosLevel.Value)