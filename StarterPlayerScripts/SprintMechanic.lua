-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SprintMechanic (Client - FIXED)
-- 🛠️ AUTH: Novae Studios & Coding Partner
-- 💡 DESC: Handles inputs and tells Server we are running.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local SprintRemote = ReplicatedStorage:WaitForChild("SprintUpdate", 10)

-- BASE SPEEDS
local SPEED_WALK = 16
local SPEED_RUN = 24
local SPEED_BOOST = 28 

local isSprintingInput = false

local function updateSpeed()
	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	
	local finalSpeed = SPEED_WALK
	
	-- 1. Check Attributes
	-- We use a local variable for input to be responsive
	local health = Player:GetAttribute("HealthState")
	local status = Player:GetAttribute("StatusEffect")
	local exhaust = Player:GetAttribute("Exhausted")
	
	-- 2. Hierarchy Logic
	if status == "SpeedBoost" then
		finalSpeed = SPEED_BOOST
	elseif isSprintingInput and not exhaust then
		finalSpeed = SPEED_RUN
	end
	
	-- 3. Apply
	hum.WalkSpeed = finalSpeed
end

local function toggleSprint(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		isSprintingInput = true
		Player:SetAttribute("IsSprinting", true)
		if SprintRemote then SprintRemote:FireServer(true) end
		
	elseif inputState == Enum.UserInputState.End then
		isSprintingInput = false
		Player:SetAttribute("IsSprinting", false)
		if SprintRemote then SprintRemote:FireServer(false) end
	end
end

-- Fixed: Changed 'true' to 'false' in BindAction to stop creating a Touch Button 
-- that might be getting clicked accidentally on PC/Mobile hybrid screens.
ContextActionService:BindAction("SprintAction", toggleSprint, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX)

RunService.Heartbeat:Connect(updateSpeed)
