-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: TerrorRadiusController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Calculates distance to Killer and adjusts Sound/UI Vignette.
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
local PULSE_RATE_CLOSE = 0.5 -- Seconds per beat
local PULSE_RATE_FAR = 2.0

-- VFX: Red Vignette
local vignette = Lighting:FindFirstChild("TerrorVignette") or Instance.new("ColorCorrectionEffect")
vignette.Name = "TerrorVignette"
vignette.Parent = Lighting
vignette.TintColor = Color3.new(1, 1, 1) -- Normal

-- STATE
local currentSaboteur = nil
local lastPulse = 0

-- // FUNCTION: Find Saboteur
-- In a real match, we'd cache this from the GameLoop, but for now scan players
local function findSaboteur()
	for _, p in pairs(Players:GetPlayers()) do
		-- Assuming we use an Attribute "Role" = "Saboteur"
		if p:GetAttribute("Role") == "Saboteur" then
			return p
		end
	end
	return nil
end

RunService.Heartbeat:Connect(function(dt)
	-- Update Char
	if not Character or not Character.Parent then
		Character = Player.Character
		if Character then RootPart = Character:FindFirstChild("HumanoidRootPart") end
		return
	end
	
	-- Find Killer if missing
	if not currentSaboteur then
		currentSaboteur = findSaboteur()
	end
	
	if currentSaboteur and currentSaboteur.Character then
		local sabRoot = currentSaboteur.Character:FindFirstChild("HumanoidRootPart")
		if sabRoot and RootPart then
			local dist = (RootPart.Position - sabRoot.Position).Magnitude
			
			if dist <= MAX_TERROR_RADIUS then
				-- 1. Audio
				SoundManager.UpdateTerror(dist, MAX_TERROR_RADIUS)
				
				-- 2. Visual Pulse (Neon Red)
				local intensity = 1 - (dist / MAX_TERROR_RADIUS) -- 0 to 1
				local pulseSpeed = PULSE_RATE_FAR - ((PULSE_RATE_FAR - PULSE_RATE_CLOSE) * intensity)
				
				if (tick() - lastPulse) > pulseSpeed then
					lastPulse = tick()
					-- Pulse!
					local redTint = Color3.fromRGB(255, 200 - (200*intensity), 200 - (200*intensity))
					TweenService:Create(vignette, TweenInfo.new(0.1), {TintColor = redTint}):Play()
					task.delay(0.1, function()
						TweenService:Create(vignette, TweenInfo.new(0.3), {TintColor = Color3.new(1,1,1)}):Play()
					end)
				end
			else
				-- Reset
				SoundManager.UpdateTerror(100, 100) -- Fully Muffled/Silent
				vignette.TintColor = Color3.new(1,1,1)
			end
		end
	else
		-- No killer found/spawned yet
		SoundManager.UpdateTerror(100, 100)
	end
end)