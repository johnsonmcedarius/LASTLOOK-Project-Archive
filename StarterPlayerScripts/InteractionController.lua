-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionController (Client - MASTER UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles "Handshake" (Glow + Context UI). Now with Context Text.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local InteractionRemote = ReplicatedStorage:WaitForChild("InteractionEvent")

-- CONFIG
local INTERACTION_RADIUS = 8
local CHECK_RATE = 0.1 
local GLOW_COLOR = Color3.fromRGB(0, 255, 127) -- Neon Green
local RESCUE_COLOR = Color3.fromRGB(255, 215, 0) -- Gold

-- STATE
local lastCheckTime = 0
local currentTarget = nil
local actionButton = nil 

-- // UI SETUP: Context Button
local function setupContextUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InteractionHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = Player:WaitForChild("PlayerGui")
	
	local btn = Instance.new("TextButton")
	btn.Name = "ActionButton"
	btn.Size = UDim2.fromOffset(120, 60) -- Wider for text
	btn.Position = UDim2.new(1, -120, 1, -100) 
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	btn.TextColor3 = GLOW_COLOR
	btn.Text = "USE"
	btn.TextSize = 20
	btn.Font = Enum.Font.GothamBold
	btn.Visible = false 
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = btn
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = GLOW_COLOR
	stroke.Thickness = 2
	stroke.Parent = btn
	
	btn.Parent = screenGui
	actionButton = btn
	
	btn.MouseButton1Click:Connect(function()
		if currentTarget then
			InteractionRemote:FireServer("StartTask", currentTarget)
		end
	end)
end

-- // HELPER: Get Action Text based on Target
local function getContextInfo(object)
	if CollectionService:HasTag(object, "Station") then
		return "DESIGN", GLOW_COLOR
	elseif CollectionService:HasTag(object, "ExitGate") then
		if workspace:GetAttribute("ExitPowered") then
			return "OPEN GATE", GLOW_COLOR
		else
			return "LOCKED", Color3.fromRGB(100, 100, 100)
		end
	elseif CollectionService:HasTag(object, "MannequinStand") then
		-- Check if occupied? For now just show rescue
		return "RESCUE", RESCUE_COLOR
	end
	return "USE", GLOW_COLOR
end

-- // VISUALS: Manage Highlight
local function setHighlight(object, active)
	if not object then return end
	
	local highlight = object:FindFirstChild("InteractionHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "InteractionHighlight"
		highlight.FillTransparency = 1 
		highlight.OutlineColor = GLOW_COLOR
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = object
	end
	
	local text, color = getContextInfo(object)
	
	if active then
		highlight.OutlineColor = color
		highlight.Enabled = true
		highlight.OutlineTransparency = 0
		
		if actionButton then 
			actionButton.Text = text
			actionButton.TextColor3 = color
			actionButton.UIStroke.Color = color
			actionButton.Visible = true 
		end
	else
		highlight.Enabled = false
		if actionButton then actionButton.Visible = false end
	end
end

-- // CORE LOOP
RunService.Heartbeat:Connect(function(dt)
	lastCheckTime += dt
	if lastCheckTime < CHECK_RATE then return end
	lastCheckTime = 0

	if not Character or not Character.Parent then
		Character = Player.Character
		if Character then RootPart = Character:FindFirstChild("HumanoidRootPart") end
		return
	end

	local closestObject = nil
	local closestDist = INTERACTION_RADIUS

	-- Check All Interactables
	local stations = CollectionService:GetTagged("Station")
	local exits = CollectionService:GetTagged("ExitGate")
	local mannequins = CollectionService:GetTagged("MannequinStand")
	
	local allTargets = {}
	-- Merge tables (Simple utility)
	for _, v in pairs(stations) do table.insert(allTargets, v) end
	for _, v in pairs(exits) do table.insert(allTargets, v) end
	for _, v in pairs(mannequins) do table.insert(allTargets, v) end
	
	for _, object in pairs(allTargets) do
		local targetPart = object:IsA("Model") and object.PrimaryPart or object
		if targetPart then
			local dist = (RootPart.Position - targetPart.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestObject = object
			end
		end
	end

	if closestObject ~= currentTarget then
		if currentTarget then setHighlight(currentTarget, false) end
		if closestObject then setHighlight(closestObject, true) end
		currentTarget = closestObject
	end
end)

if Player.PlayerGui then setupContextUI() end