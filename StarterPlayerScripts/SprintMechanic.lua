-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SprintMechanic (Client - CAM BOB ADDED)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Stamina + "Camera Bob" for movement feedback.
-- -------------------------------------------------------------------------------

local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- CONFIG
local WALK_SPEED = 16
local BASE_RUN_MULTIPLIER = PerkRegistry.GetStat("RunwayStrut", "SpeedMultiplier") or 1.35
local RUN_SPEED = WALK_SPEED * BASE_RUN_MULTIPLIER
local EXHAUSTED_SPEED = 12 

local MAX_STAMINA = 100
local STAMINA_DRAIN = 15
local STAMINA_REGEN = 10
local REGEN_DELAY = 1.5

-- BOB CONFIG
local BOB_SPEED = 14
local BOB_INTENSITY = 0.3

-- STATE
local currentStamina = MAX_STAMINA
local isSprinting = false
local isExhausted = false
local timeSinceSprint = 0

local fovSprint = TweenInfo.new(0.5, Enum.EasingStyle.Sine)
local fovNormal = TweenInfo.new(0.5, Enum.EasingStyle.Sine)

local function handleSprint(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if not isExhausted then isSprinting = true end
	elseif inputState == Enum.UserInputState.End then
		isSprinting = false
	end
end

ContextActionService:BindAction("Sprint", handleSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("Sprint", "RUN")
ContextActionService:SetPosition("Sprint", UDim2.new(0.2, 0, 0.5, 0))

RunService.Heartbeat:Connect(function(dt)
	local moving = Humanoid.MoveDirection.Magnitude > 0
	
	-- 1. STAMINA & SPEED
	if isSprinting and moving then
		currentStamina = math.clamp(currentStamina - (STAMINA_DRAIN * dt), 0, MAX_STAMINA)
		timeSinceSprint = 0
		Humanoid.WalkSpeed = RUN_SPEED
		TweenService:Create(Camera, fovSprint, {FieldOfView = 80}):Play()
		
		if currentStamina <= 0 then
			isExhausted = true
			isSprinting = false
			Humanoid.WalkSpeed = EXHAUSTED_SPEED 
		end
	else
		timeSinceSprint = timeSinceSprint + dt
		if timeSinceSprint > REGEN_DELAY then
			currentStamina = math.clamp(currentStamina + (STAMINA_REGEN * dt), 0, MAX_STAMINA)
		end
		
		if isExhausted then
			if currentStamina > 30 then 
				isExhausted = false
				Humanoid.WalkSpeed = WALK_SPEED
			else
				Humanoid.WalkSpeed = EXHAUSTED_SPEED
			end
		else
			Humanoid.WalkSpeed = WALK_SPEED
		end
		TweenService:Create(Camera, fovNormal, {FieldOfView = 70}):Play()
	end
	
	-- 2. CAMERA BOB (The Juice)
	if moving then
		local time = tick()
		-- Bob faster if sprinting
		local speed = isSprinting and (BOB_SPEED * 1.5) or BOB_SPEED
		local intensity = isSprinting and (BOB_INTENSITY * 1.5) or BOB_INTENSITY
		
		-- Simple Sine Wave on Y axis
		local bobY = math.sin(time * speed) * intensity * 0.5
		-- Slight X sway
		local bobX = math.cos(time * (speed / 2)) * intensity * 0.2
		
		-- Apply to Camera Offset (Requires CFrame manip in RenderStepped usually, 
		-- but modifying Camera.CFrame in Heartbeat works if CameraSubject is Humanoid)
		-- A cleaner way is Humanoid.CameraOffset
		Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp(Vector3.new(bobX, bobY, 0), 0.1)
	else
		Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp(Vector3.zero, 0.1)
	end
end)

Player.CharacterAdded:Connect(function(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid")
	currentStamina = MAX_STAMINA
	isExhausted = false
end)
