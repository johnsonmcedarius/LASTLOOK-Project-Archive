-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AntiCheatManager (Server - FIXED)
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TOLERANCE = 8 -- Slightly increased for network variance

RunService.Heartbeat:Connect(function()
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hum = char.Humanoid
			local root = char.HumanoidRootPart
			
			-- Base speed
			local allowedSpeed = hum.WalkSpeed
			
			-- Check if Server knows they are sprinting (Attribute set by SprintHandler)
			if p:GetAttribute("IsSprinting") then
				allowedSpeed = 24 -- Match your SPEED_RUN
			end
			
			-- Perks/Status modifiers
			if p:GetAttribute("StatusEffect") == "SpeedBoost" then 
				allowedSpeed = 35 
			end
			
			local maxSpeed = allowedSpeed + TOLERANCE
			local velocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
			
			if velocity > maxSpeed then
				-- Rubberband
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end)
