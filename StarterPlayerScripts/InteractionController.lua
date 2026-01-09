-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionController (Client - AUDIO FIX)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Handshake, Glow, and Loop Sound.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local InteractionRemote = ReplicatedStorage:WaitForChild("InteractionEvent")

-- CONFIG
local INTERACTION_RADIUS = 8
local CHECK_RATE = 0.1 
local GLOW_COLOR = Color3.fromRGB(0, 255, 127)
local RESCUE_COLOR = Color3.fromRGB(255, 215, 0)

-- STATE
local lastCheckTime = 0
local currentTarget = nil
local actionButton = nil 
local loopSound = nil -- [NEW]

-- // SETUP UI
local function setupContextUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InteractionHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = Player:WaitForChild("PlayerGui")
	
	local btn = Instance.new("TextButton")
	btn.Name = "ActionButton"
	btn.Size = UDim2.fromOffset(120, 60)
	btn.Position = UDim2.new(1, -120, 1, -180) -- Mobile Friendly
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

-- // AUDIO MANAGER
local function playLoopSound(pitchStart)
	if not loopSound then
		loopSound = Instance.new("Sound")
		loopSound.SoundId = "rbxassetid://12221967" -- Replace with Sewing/Repair Loop
		loopSound.Looped = true
		loopSound.Volume = 0.5
		loopSound.Parent = RootPart
	end
	loopSound.PlaybackSpeed = pitchStart or 0.8
	loopSound:Play()
end

local function stopLoopSound()
	if loopSound then loopSound:Stop() end
end

local function updateSoundPitch(progressRatio)
	if loopSound and loopSound.IsPlaying then
		-- Pitch rises from 0.8 to 1.5 as you finish
		loopSound.PlaybackSpeed = 0.8 + (0.7 * progressRatio)
	end
end

-- // VISUALS
local function setHighlight(object, active)
	if not object then return end
	local highlight = object:FindFirstChild("InteractionHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "InteractionHighlight"
		highlight.FillTransparency = 1 
		highlight.Parent = object
	end
	
	local text = "USE"
	local color = GLOW_COLOR
	
	if CollectionService:HasTag(object, "Station") then text = "DESIGN"
	elseif CollectionService:HasTag(object, "MannequinStand") then 
		text = "RESCUE" 
		color = RESCUE_COLOR
	elseif CollectionService:HasTag(object, "ExitGate") then
		text = workspace:GetAttribute("ExitPowered") and "OPEN" or "LOCKED"
		if text == "LOCKED" then color = Color3.fromRGB(100,100,100) end
	end
	
	highlight.OutlineColor = color
	highlight.Enabled = active
	
	if actionButton then 
		actionButton.Text = text
		actionButton.TextColor3 = color
		actionButton.UIStroke.Color = color
		actionButton.Visible = active 
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

	local allTargets = {}
	for _, t in pairs(CollectionService:GetTagged("Station")) do table.insert(allTargets, t) end
	for _, t in pairs(CollectionService:GetTagged("ExitGate")) do table.insert(allTargets, t) end
	for _, t in pairs(CollectionService:GetTagged("MannequinStand")) do table.insert(allTargets, t) end
	
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

-- REMOTE LISTENER FOR SOUND
InteractionRemote.OnClientEvent:Connect(function(action, data)
	if action == "TaskStarted" then
		playLoopSound(0.8)
		-- If you have a StationUIConnector, it can call updateSoundPitch
		-- Or listen to attribute changes here:
		if data and data:IsA("Model") then
			data:GetAttributeChangedSignal("CurrentProgress"):Connect(function()
				local cur = data:GetAttribute("CurrentProgress") or 0
				local max = data:GetAttribute("WorkRequired") or 100
				updateSoundPitch(cur/max)
			end)
		end
	elseif action == "TaskStopped" or action == "TaskFailed" then
		stopLoopSound()
	end
end)

if Player.PlayerGui then setupContextUI() end
