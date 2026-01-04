-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SkillCheckController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Meat". Handles the spinner, 0.1s Mythic Window, and Panic VFX.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)
local DataManager = nil -- We might need this, or pass perk data in the event

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- REMOTES
local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent")
local StationUpdateRemote = ReplicatedStorage:WaitForChild("StationUpdateEvent") -- If used for feedback

-- CONFIG
local ROTATION_SPEED = 180 -- Degrees per second
local ZONE_SIZE = 45 -- Degrees (The Safe Zone)
local GREAT_SIZE = 10 -- Degrees (The Great/White Zone inside the Safe Zone)
local MYTHIC_WINDOW = 0.1 -- Seconds for "Second Look"

-- STATE
local isActive = false
local currentStation = nil
local rotation = 0
local safeZoneStart = 0
local hasSecondLook = false -- Will be passed from server
local rescueWindowActive = false
local rescueStartTime = 0

-- UI ELEMENTS (Placeholder Generator)
local SkillUI = nil
local Needle = nil
local SafeZone = nil

-- // VFX: Create "Panic" ColorCorrection
local panicCC = Instance.new("ColorCorrectionEffect")
panicCC.Name = "PanicEffect"
panicCC.Saturation = 0
panicCC.TintColor = Color3.fromRGB(255, 255, 255)
panicCC.Parent = Lighting

-- // UI SETUP: Creates the Spinner HUD
local function createSkillHUD()
	local screen = Instance.new("ScreenGui")
	screen.Name = "SkillCheckHUD"
	screen.ResetOnSpawn = false
	screen.Parent = PlayerGui
	
	local bg = Instance.new("Frame")
	bg.Name = "SpinnerBG"
	bg.Size = UDim2.fromOffset(200, 200)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.5
	bg.Visible = false
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = bg
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 3
	stroke.Parent = bg
	
	-- The Zone (Visual)
	local zone = Instance.new("Frame")
	zone.Name = "SafeZone"
	zone.Size = UDim2.fromScale(1, 1) -- Fill circle
	zone.BackgroundTransparency = 1
	-- We use a Gradient to show the zone arc (Simplified for code, Nerd handles the asset)
	-- For this script, we just rotate an invisible container with a visible slice
	-- NOTE: In production, use an ImageLabel for the zone arc.
	zone.Parent = bg
	SafeZone = zone -- Store reference
	
	-- The Needle
	local needle = Instance.new("Frame")
	needle.Name = "Needle"
	needle.Size = UDim2.new(0, 4, 0.5, 0)
	needle.AnchorPoint = Vector2.new(0.5, 1) -- Pivot at center
	needle.Position = UDim2.fromScale(0.5, 0.5)
	needle.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red Needle
	needle.BorderSizePixel = 0
	needle.Parent = bg
	Needle = needle
	
	SkillUI = bg
end

-- // FUNCTION: Trigger Fail Sequence (The "Neon Red" Panic)
local function triggerFailSequence()
	-- 1. Sound (Placeholder)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967" -- Generic error sound
	sound.Parent = PlayerGui
	sound:Play()
	game.Debris:AddItem(sound, 2)
	
	-- 2. Vignette Pulse
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	TweenService:Create(panicCC, tweenInfo, {TintColor = Color3.fromRGB(255, 100, 100)}):Play()
	
	task.delay(0.2, function()
		TweenService:Create(panicCC, TweenInfo.new(1), {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	end)
	
	-- 3. Camera Glitch (Optional - Shake)
	local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
	if hum then
		local original = hum.CameraOffset
		hum.CameraOffset = Vector3.new(0.5, 0, 0)
		task.wait(0.05)
		hum.CameraOffset = Vector3.new(-0.5, 0, 0)
		task.wait(0.05)
		hum.CameraOffset = original
	end
end

-- // FUNCTION: Check Result
local function checkSkill(isRescueTap)
	if not isActive and not rescueWindowActive then return end
	
	-- Normalize rotation to 0-360
	local currentRot = rotation % 360
	
	-- Calculate Hit
	-- Simple logic: Is needle inside [Start, Start + Size]?
	-- Note: Handling wrap-around (350 to 10 degrees) requires math, 
	-- but we'll keep SafeZoneStart random within safe bounds (10 to 300) to avoid wrap math for now.
	
	local hit = false
	local isGreat = false
	
	if currentRot >= safeZoneStart and currentRot <= (safeZoneStart + ZONE_SIZE) then
		hit = true
		-- Great Check (Middle of zone)
		local greatStart = safeZoneStart + (ZONE_SIZE/2) - (GREAT_SIZE/2)
		if currentRot >= greatStart and currentRot <= (greatStart + GREAT_SIZE) then
			isGreat = true
		end
	end
	
	if hit then
		-- SUCCESS
		if isRescueTap then print("✨ SECOND LOOK SAVE! FASHION SAVED!") end
		
		local resultType = isGreat and "Great" or "Good"
		SkillCheckRemote:FireServer("Result", currentStation, resultType)
		
		-- Visual Feedback
		Needle.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
		task.wait(0.2)
		stopSkillCheck()
	else
		-- FAIL
		if hasSecondLook and not isRescueTap then
			-- TRIGGER RESCUE WINDOW (Mythic Logic)
			print("⚠️ MISSED! 0.1s RESCUE WINDOW OPEN!")
			rescueWindowActive = true
			rescueStartTime = tick()
			-- Maybe turn UI Yellow to indicate chance?
			Needle.BackgroundColor3 = Color3.fromRGB(255, 255, 0) 
		else
			-- HARD FAIL
			triggerFailSequence()
			SkillCheckRemote:FireServer("Result", currentStation, "Miss")
			stopSkillCheck()
		end
	end
end

-- // FUNCTION: Start Minigame
local function startSkillCheck(station, perkFlag)
	if isActive then return end
	
	isActive = true
	currentStation = station
	hasSecondLook = perkFlag or false
	rescueWindowActive = false
	
	rotation = 0
	-- Randomize Zone (Keep away from 0/360 boundary for simple math)
	safeZoneStart = math.random(45, 315)
	
	-- Reset UI
	if not SkillUI then createSkillHUD() end
	SkillUI.Visible = true
	Needle.Rotation = 0
	Needle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	
	-- Show Zone (Need a rotation prop for the visual container)
	-- In a real UI, you'd rotate the image. Here we just assume knowledge of where it is.
end

-- // FUNCTION: Stop Minigame
function stopSkillCheck()
	isActive = false
	rescueWindowActive = false
	if SkillUI then SkillUI.Visible = false end
end

-- // INPUT LISTENER
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		if isActive then
			checkSkill(false) -- Normal Tap
		elseif rescueWindowActive then
			-- Rescue Tap Logic
			local delta = tick() - rescueStartTime
			if delta <= MYTHIC_WINDOW then
				checkSkill(true) -- It's a rescue!
			else
				-- Too slow
				stopSkillCheck()
			end
		end
	elseif input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Mobile Support
		if isActive then checkSkill(false) 
		elseif rescueWindowActive and (tick() - rescueStartTime <= MYTHIC_WINDOW) then checkSkill(true) end
	end
end)

-- // RENDER LOOP (The Spin)
RunService.RenderStepped:Connect(function(dt)
	if isActive then
		rotation = rotation + (ROTATION_SPEED * dt)
		if rotation >= 360 then
			-- Auto Fail if it does a full loop without input
			triggerFailSequence()
			SkillCheckRemote:FireServer("Result", currentStation, "Miss")
			stopSkillCheck()
			rotation = 0
		end
		
		if Needle then Needle.Rotation = rotation end
	end
	
	-- Handle Rescue Timeout
	if rescueWindowActive then
		if (tick() - rescueStartTime) > MYTHIC_WINDOW then
			-- Time's up, you missed the rescue
			triggerFailSequence()
			SkillCheckRemote:FireServer("Result", currentStation, "Miss")
			stopSkillCheck()
		end
	end
end)

-- // EVENT LISTENER (From Server)
SkillCheckRemote.OnClientEvent:Connect(function(station, perkData)
	startSkillCheck(station, perkData)
end)

-- Init
createSkillHUD()