-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: TerrorRadiusController (Client - NOIR VIBE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Noir Horror visuals. Saturation drops + Contrast spikes near killer.
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

local vignette = Lighting:FindFirstChild("TerrorFilter") or Instance.new("ColorCorrectionEffect")
vignette.Name = "TerrorFilter"
vignette.Parent = Lighting
vignette.Saturation = 0
vignette.Contrast = 0
vignette.TintColor = Color3.new(1, 1, 1)

-- // FUNCTION: Find Closest Saboteur
local function getClosestSaboteurDist()
	local closestDist = 9999
	for _, p in pairs(Players:GetPlayers()) do
		if p:GetAttribute("Role") == "Saboteur" and p ~= Player then
			if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (RootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
				if dist < closestDist then closestDist = dist end
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
	
	local dist = getClosestSaboteurDist()
			
	if dist <= MAX_TERROR_RADIUS then
		local intensity = 1 - (dist / MAX_TERROR_RADIUS) -- 0 to 1 (1 is super close)
		
		-- 1. AUDIO
		SoundManager.UpdateTerror(dist, MAX_TERROR_RADIUS)
		
		-- 2. VISUALS (The Noir Effect)
		-- Desaturate the world (Go Black & White)
		local satTarget = -1 * intensity 
		-- Increase Contrast (Make shadows harsh)
		local conTarget = 0.5 * intensity
		-- Tint slightly Red (Blood Noir)
		local tintVal = 255 - (50 * intensity)
		local tintTarget = Color3.fromRGB(255, tintVal, tintVal)
		
		TweenService:Create(vignette, TweenInfo.new(0.5), {
			Saturation = satTarget,
			Contrast = conTarget,
			TintColor = tintTarget
		}):Play()
	else
		-- Reset
		SoundManager.UpdateTerror(100, 100) 
		TweenService:Create(vignette, TweenInfo.new(1), {
			Saturation = 0,
			Contrast = 0,
			TintColor = Color3.new(1,1,1)
		}):Play()
	end
end)
