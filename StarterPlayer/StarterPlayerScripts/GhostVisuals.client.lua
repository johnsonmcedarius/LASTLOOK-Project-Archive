--[[
    GhostVisuals (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = script.Parent -- This script runs INSIDE the character

-- 👻 INSTANT GHOST FIX
-- This runs the millisecond the character spawns, faster than any server script.
if player:GetAttribute("IsDead") then

	-- 1. Force Ghost Appearance Immediately
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 0.6
				part.Material = Enum.Material.ForceField -- Ghostly texture
				part.CastShadow = false
				part.Color = Color3.fromRGB(150, 255, 255) -- Ghost Blue
				part.CanCollide = false -- Client-side noclip start
			end
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle then 
				handle.Transparency = 0.6 
				handle.Material = Enum.Material.ForceField
				handle.Color = Color3.fromRGB(150, 255, 255)
			end
		elseif part:IsA("FaceControls") or part:IsA("Decal") then
			part:Destroy() -- Remove face for spooky faceless look
		end
	end

	-- 2. Disable default sounds (Footsteps/Landing) so you are silent locally
	local root = char:WaitForChild("HumanoidRootPart")
	if root then
		for _, sound in pairs(root:GetChildren()) do
			if sound:IsA("Sound") then sound:Stop(); sound.Volume = 0 end
		end
	end
end