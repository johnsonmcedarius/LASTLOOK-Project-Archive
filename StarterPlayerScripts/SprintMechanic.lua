-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SprintMechanic (Client - ATTRIBUTE SYSTEM)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Brain" of movement. Calculates speed from ALL attributes.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- BASE SPEEDS
local SPEED_WALK = 16
local SPEED_RUN = 24
local SPEED_LIMPY = 12
local SPEED_BOOST = 28 -- Mercy hit speed

local function updateSpeed()
	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	
	local finalSpeed = SPEED_WALK
	
	-- 1. Check Attributes
	local isSprinting = Player:GetAttribute("IsSprinting")
	local health = Player:GetAttribute("HealthState")
	local status = Player:GetAttribute("StatusEffect")
	local exhaust = Player:GetAttribute("Exhausted")
	
	-- 2. Hierarchy Logic
	if status == "SpeedBoost" then
		finalSpeed = SPEED_BOOST
	elseif isSprinting and not exhaust then
		finalSpeed = SPEED_RUN
	elseif health == "Injured" and not isSprinting then
		-- Optional: Limp when injured? Or keep standard?
		-- finalSpeed = SPEED_WALK 
	end
	
	-- 3. Apply
	hum.WalkSpeed = finalSpeed
end

local function toggleSprint(name, state)
	if state == Enum.UserInputState.Begin then
		Player:SetAttribute("IsSprinting", true)
	elseif state == Enum.UserInputState.End then
		Player:SetAttribute("IsSprinting", false)
	end
end

ContextActionService:BindAction("SprintAction", toggleSprint, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX)

RunService.Heartbeat:Connect(updateSpeed)
