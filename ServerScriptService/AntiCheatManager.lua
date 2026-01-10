-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AntiCheatManager (Server - DYNAMIC)
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TOLERANCE = 5

RunService.Heartbeat:Connect(function()
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hum = char.Humanoid
			local root = char.HumanoidRootPart
			
			-- Dynamic Max Speed Calculation
			local maxSpeed = hum.WalkSpeed + TOLERANCE
			
			-- Perks/Status modifiers
			if p:GetAttribute("StatusEffect") == "SpeedBoost" then maxSpeed = 35 end
			
			local velocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
			
			if velocity > maxSpeed then
				-- Rubberband
				root.AssemblyLinearVelocity = Vector3.zero
				-- Optionally teleport back slightly
			end
		end
	end
end)
