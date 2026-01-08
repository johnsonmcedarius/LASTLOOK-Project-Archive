-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: TerrorRadiusController (Client - 2v8 UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Calculates dist to NEAREST Saboteur. Multi-Killer support.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local SoundManager = require(ReplicatedStorage.Modules.SoundManager)

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- CONFIG
local MAX_TERROR_RADIUS = 60
local PULSE_RATE_CLOSE = 0.5 
local PULSE_RATE_FAR = 2.0

local vignette = Lighting:FindFirstChild("TerrorVignette") or Instance.new("ColorCorrectionEffect")
vignette.Name = "TerrorVignette"
vignette.Parent = Lighting
vignette.TintColor = Color3.new(1, 1, 1)

local lastPulse = 0

-- // FUNCTION: Find Closest Saboteur
local function getClosestSaboteurDist()
	local closestDist = 9999
	
	for _, p in pairs(Players:GetPlayers()) do
		-- [UPDATED] Check Role AND ensure it's not me (if I am also a Saboteur)
		if p:GetAttribute("Role") == "Saboteur" and p ~= Player then
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (RootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
				end
			end
		end
	end
	
	return closestDist
end

RunService.Heartbeat:Connect(function(dt)
	if not Character or not Character.Parent then
		Character = Player.Character
		if Character then RootPart = Character:FindFirstChild("HumanoidRootPart") end
		return
	end
	
	-- [UPDATED] Dynamic scan every frame (optimized for < 12 players)
	local dist = getClosestSaboteurDist()
			
	if dist <= MAX_TERROR_RADIUS then
		-- 1. Audio
		SoundManager.UpdateTerror(dist, MAX_TERROR_RADIUS)
		
		-- 2. Visual Pulse
		local intensity = 1 - (dist / MAX_TERROR_RADIUS) 
		local pulseSpeed = PULSE_RATE_FAR - ((PULSE_RATE_FAR - PULSE_RATE_CLOSE) * intensity)
		
		if (tick() - lastPulse) > pulseSpeed then
			lastPulse = tick()
			local redTint = Color3.fromRGB(255, 200 - (200*intensity), 200 - (200*intensity))
			TweenService:Create(vignette, TweenInfo.new(0.1), {TintColor = redTint}):Play()
			task.delay(0.1, function()
				TweenService:Create(vignette, TweenInfo.new(0.3), {TintColor = Color3.new(1,1,1)}):Play()
			end)
		end
	else
		-- Reset
		SoundManager.UpdateTerror(100, 100) 
		vignette.TintColor = Color3.new(1,1,1)
	end
end)
