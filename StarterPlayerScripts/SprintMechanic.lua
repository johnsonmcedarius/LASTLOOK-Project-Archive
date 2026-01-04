-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SprintMechanic (Client - MASTER)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles "Runway Strut" stamina, FOV changes, and movement states.
-- -------------------------------------------------------------------------------

local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry) -- The Brain

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- CONFIG (Now pulled partly from Perks)
local WALK_SPEED = 16
-- We get run speed from Registry to make it easy to update later
local BASE_RUN_MULTIPLIER = PerkRegistry.GetStat("RunwayStrut", "SpeedMultiplier") or 1.35
local RUN_SPEED = WALK_SPEED * BASE_RUN_MULTIPLIER
local EXHAUSTED_SPEED = 12 

local MAX_STAMINA = 100
local STAMINA_DRAIN = 15 -- Per second
local STAMINA_REGEN = 10 -- Per second (when not running)
local REGEN_DELAY = 1.5 -- Seconds to wait before regen starts

-- STATE
local currentStamina = MAX_STAMINA
local isSprinting = false
local isExhausted = false
local timeSinceSprint = 0

-- TWEENS
local fovSprint = TweenInfo.new(0.5, Enum.EasingStyle.Sine)
local fovNormal = TweenInfo.new(0.5, Enum.EasingStyle.Sine)

-- // UPDATE UI
local function updateStaminaUI()
	-- Connect to Nerd's UI here later
	-- e.g., MyHUD.UpdateStamina(currentStamina / MAX_STAMINA)
end

-- // INPUT HANDLER
local function handleSprint(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		if not isExhausted then
			isSprinting = true
		end
	elseif inputState == Enum.UserInputState.End then
		isSprinting = false
	end
end

-- Bind Shift (PC) and create a touch button later
ContextActionService:BindAction("Sprint", handleSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX)
-- Set button title/image for mobile:
ContextActionService:SetTitle("Sprint", "RUN")
ContextActionService:SetPosition("Sprint", UDim2.new(0.2, 0, 0.5, 0))

-- // GAME LOOP
RunService.Heartbeat:Connect(function(dt)
	-- Dynamic check in case we want to support perks mid-game later
	local currentRunSpeed = RUN_SPEED 
	
	-- Handle Stamina Math
	if isSprinting and Humanoid.MoveDirection.Magnitude > 0 then
		-- Draining
		currentStamina = math.clamp(currentStamina - (STAMINA_DRAIN * dt), 0, MAX_STAMINA)
		timeSinceSprint = 0
		
		-- Apply Speed
		Humanoid.WalkSpeed = currentRunSpeed
		TweenService:Create(Camera, fovSprint, {FieldOfView = 80}):Play() -- Slight zoom out
		
		-- Check Exhaustion
		if currentStamina <= 0 then
			isExhausted = true
			isSprinting = false
			Humanoid.WalkSpeed = EXHAUSTED_SPEED 
			-- TODO: Play "Heavy Breathing" Audio
		end
		
	else
		-- Regenerating
		timeSinceSprint = timeSinceSprint + dt
		if timeSinceSprint > REGEN_DELAY then
			currentStamina = math.clamp(currentStamina + (STAMINA_REGEN * dt), 0, MAX_STAMINA)
		end
		
		-- Reset Speed
		if isExhausted then
			if currentStamina > 30 then -- Must recover 30% to run again
				isExhausted = false
				Humanoid.WalkSpeed = WALK_SPEED
			else
				Humanoid.WalkSpeed = EXHAUSTED_SPEED
			end
		else
			Humanoid.WalkSpeed = WALK_SPEED
		end
		
		TweenService:Create(Camera, fovNormal, {FieldOfView = 70}):Play() -- Normal FOV
	end
	
	updateStaminaUI()
end)

-- Update char references on respawn
Player.CharacterAdded:Connect(function(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid")
	currentStamina = MAX_STAMINA
	isExhausted = false
end)