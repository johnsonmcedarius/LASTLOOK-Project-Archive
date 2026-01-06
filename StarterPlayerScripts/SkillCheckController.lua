-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SkillCheckController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Meat". Mythic Window Buffed.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local PerkRegistry = require(ReplicatedStorage.Modules.PerkRegistry)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent")

-- CONFIG
local ROTATION_SPEED = 180 
local ZONE_SIZE = 45 
local GREAT_SIZE = 10 
local MYTHIC_WINDOW = 0.2 -- [UPDATED] Buffed from 0.1s for Lag Tolerance

-- STATE
local isActive = false
local currentStation = nil
local rotation = 0
local safeZoneStart = 0
local hasSecondLook = false 
local rescueWindowActive = false
local rescueStartTime = 0

local SkillUI = nil
local Needle = nil
local SafeZone = nil

local panicCC = Instance.new("ColorCorrectionEffect")
panicCC.Name = "PanicEffect"
panicCC.Saturation = 0
panicCC.TintColor = Color3.fromRGB(255, 255, 255)
panicCC.Parent = Lighting

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
	
	local zone = Instance.new("Frame")
	zone.Name = "SafeZone"
	zone.Size = UDim2.fromScale(1, 1) 
	zone.BackgroundTransparency = 1
	zone.Parent = bg
	SafeZone = zone 
	
	local needle = Instance.new("Frame")
	needle.Name = "Needle"
	needle.Size = UDim2.new(0, 4, 0.5, 0)
	needle.AnchorPoint = Vector2.new(0.5, 1) 
	needle.Position = UDim2.fromScale(0.5, 0.5)
	needle.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
	needle.BorderSizePixel = 0
	needle.Parent = bg
	Needle = needle
	
	SkillUI = bg
end

local function triggerFailSequence()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://12221967" 
	sound.Parent = PlayerGui
	sound:Play()
	game.Debris:AddItem(sound, 2)
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	TweenService:Create(panicCC, tweenInfo, {TintColor = Color3.fromRGB(255, 100, 100)}):Play()
	
	task.delay(0.2, function()
		TweenService:Create(panicCC, TweenInfo.new(1), {TintColor = Color3.fromRGB(255, 255, 255)}):Play()
	end)
end

local function checkSkill(isRescueTap)
	if not isActive and not rescueWindowActive then return end
	
	local currentRot = rotation % 360
	
	local hit = false
	local isGreat = false
	
	if currentRot >= safeZoneStart and currentRot <= (safeZoneStart + ZONE_SIZE) then
		hit = true
		local greatStart = safeZoneStart + (ZONE_SIZE/2) - (GREAT_SIZE/2)
		if currentRot >= greatStart and currentRot <= (greatStart + GREAT_SIZE) then
			isGreat = true
		end
	end
	
	if hit then
		if isRescueTap then print("✨ SECOND LOOK SAVE!") end
		
		local resultType = isGreat and "Great" or "Good"
		SkillCheckRemote:FireServer("Result", currentStation, resultType)
		
		Needle.BackgroundColor3 = Color3.fromRGB(0, 255, 0) 
		task.wait(0.2)
		stopSkillCheck()
	else
		if hasSecondLook and not isRescueTap then
			print("⚠️ MISSED! " .. MYTHIC_WINDOW .. "s RESCUE WINDOW OPEN!")
			rescueWindowActive = true
			rescueStartTime = tick()
			Needle.BackgroundColor3 = Color3.fromRGB(255, 255, 0) 
		else
			triggerFailSequence()
			SkillCheckRemote:FireServer("Result", currentStation, "Miss")
			stopSkillCheck()
		end
	end
end

local function startSkillCheck(station, perkFlag)
	if isActive then return end
	
	isActive = true
	currentStation = station
	hasSecondLook = perkFlag or false
	rescueWindowActive = false
	
	rotation = 0
	safeZoneStart = math.random(45, 315)
	
	if not SkillUI then createSkillHUD() end
	SkillUI.Visible = true
	Needle.Rotation = 0
	Needle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
end

function stopSkillCheck()
	isActive = false
	rescueWindowActive = false
	if SkillUI then SkillUI.Visible = false end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		if isActive then
			checkSkill(false) 
		elseif rescueWindowActive then
			local delta = tick() - rescueStartTime
			if delta <= MYTHIC_WINDOW then
				checkSkill(true) 
			else
				stopSkillCheck()
			end
		end
	elseif input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isActive then checkSkill(false) 
		elseif rescueWindowActive and (tick() - rescueStartTime <= MYTHIC_WINDOW) then checkSkill(true) end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if isActive then
		rotation = rotation + (ROTATION_SPEED * dt)
		if rotation >= 360 then
			triggerFailSequence()
			SkillCheckRemote:FireServer("Result", currentStation, "Miss")
			stopSkillCheck()
			rotation = 0
		end
		
		if Needle then Needle.Rotation = rotation end
	end
	
	if rescueWindowActive then
		if (tick() - rescueStartTime) > MYTHIC_WINDOW then
			triggerFailSequence()
			SkillCheckRemote:FireServer("Result", currentStation, "Miss")
			stopSkillCheck()
		end
	end
end)

SkillCheckRemote.OnClientEvent:Connect(function(station, perkData)
	startSkillCheck(station, perkData)
end)

createSkillHUD()
