-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SprintHandler (Server)
-- 🛠️ AUTH: Coding Partner
-- 💡 DESC: Replicates sprint state to Server so Anti-Cheat doesn't rubberband.
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create Remote if missing
local SprintRemote = ReplicatedStorage:FindFirstChild("SprintUpdate")
if not SprintRemote then
	SprintRemote = Instance.new("RemoteEvent")
	SprintRemote.Name = "SprintUpdate"
	SprintRemote.Parent = ReplicatedStorage
end

SprintRemote.OnServerEvent:Connect(function(player, isSprinting)
	-- Update the attribute on the Player object so Anti-Cheat can see it
	player:SetAttribute("IsSprinting", isSprinting)
	
	-- Optional: You can force WalkSpeed here for security, 
	-- but letting Client handle physics is smoother for the runner.
	-- We just update the attribute to whitelist the speed in AntiCheat.
end)
