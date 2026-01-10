-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SkillCheckController (Client - TASK A: TIMING)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Dead by Daylight" style spinner.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent")

-- // CONFIG
local ROTATION_SPEED = 180 -- Degrees per second
local PERFECT_ZONE_SIZE = 15

-- // STATE
local isActive = false
local currentStation = nil
local rotation = 0
local targetZoneStart = 0
local isClockwise = true

-- // UI REFS (Make sure these exist in StarterGui!)
local HUD = PlayerGui:WaitForChild("SkillCheckHUD")
local GameFrame = HUD:WaitForChild("SpinGame")
local Needle = GameFrame:WaitForChild("Needle")
local SafeZone = GameFrame:WaitForChild("SafeZone")

HUD.Enabled = false

local function stopGame(result)
	isActive = false
	HUD.Enabled = false
	ContextActionService:UnbindAction("HitSkillCheck")
	
	if result then
		SkillCheckRemote:FireServer("Result", currentStation, result)
	end
end

local function onInput(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin and isActive then
		-- Calculate hit
		local hitRotation = rotation % 360
		local zoneEnd = (targetZoneStart + PERFECT_ZONE_SIZE) % 360
		
		-- Simple angle check (handles 0/360 wrap logic implicitly if careful, but simple bounds here)
		-- For robustness, we check if angle is between Start and End
		local hit = false
		
		if targetZoneStart < zoneEnd then
			hit = (hitRotation >= targetZoneStart and hitRotation <= zoneEnd)
		else
			-- Wraps around 360
			hit = (hitRotation >= targetZoneStart or hitRotation <= zoneEnd)
		end
		
		if hit then
			-- Flash Green
			Needle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			stopGame("Great")
		else
			-- Flash Red
			Needle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			stopGame("Miss")
		end
	end
end

local function startGame(station, difficultyMult)
	if isActive then return end
	isActive = true
	currentStation = station
	rotation = 0
	isClockwise = math.random() > 0.5
	
	-- Randomize Zone
	targetZoneStart = math.random(45, 315)
	
	-- Setup UI
	SafeZone.Rotation = targetZoneStart
	Needle.Rotation = 0
	Needle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HUD.Enabled = true
	GameFrame.Visible = true
	HUD:WaitForChild("WireGame").Visible = false -- Hide the other game
	
	-- Bind Input (Console Support: ButtonA, PC: Space, Mobile: Touch)
	ContextActionService:BindAction("HitSkillCheck", onInput, true, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	ContextActionService:SetTitle("HitSkillCheck", "HIT")
end

RunService.RenderStepped:Connect(function(dt)
	if isActive then
		local change = ROTATION_SPEED * dt
		rotation = rotation + (isClockwise and change or -change)
		
		if rotation >= 360 or rotation <= -360 then
			-- Full rotation missed
			stopGame("Miss")
		end
		
		Needle.Rotation = rotation
	end
end)

SkillCheckRemote.OnClientEvent:Connect(function(action, station)
	if action == "TriggerSpin" then
		startGame(station, 1)
	end
end)
