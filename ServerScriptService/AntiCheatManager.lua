-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AntiCheatManager (Server - SOFT CORRECT)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: "The Sheriff". Swapped hard rubber-banding for "Cancel Move".
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIG
local MAX_SPEED_TOLERANCE = 35 
local CHECK_RATE = 0.5 

-- STATE
local lastPositions = {} -- [Player] = Vector3

local function checkPlayer(player)
	if not player.Character then return end
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	-- 1. Velocity Check (Instantaneous Speed)
	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	
	if horizontalSpeed > MAX_SPEED_TOLERANCE then
		-- 🚨 SOFT CORRECT: Kill momentum, don't teleport.
		-- This feels like "tripping" rather than glitching back.
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		-- print("🚨 AC: Speed Limit - Momentum Reset for " .. player.Name)
	end
	
	-- 2. Distance Check (Average Speed)
	if lastPositions[player] then
		local dist = (root.Position - lastPositions[player]).Magnitude
		
		-- If they moved an impossible amount in 0.5s
		if dist > (MAX_SPEED_TOLERANCE * CHECK_RATE * 1.5) then
			-- 🚨 HARDER CORRECT: Cancel Move
			-- Instead of "Yanking", we just reset them to the last VALID spot.
			-- It feels like hitting a wall, not an elastic band.
			root.CFrame = CFrame.new(lastPositions[player])
			root.AssemblyLinearVelocity = Vector3.zero
		else
			-- Valid move, update position
			lastPositions[player] = root.Position
		end
	else
		lastPositions[player] = root.Position
	end
end

-- Loop
task.spawn(function()
	while true do
		task.wait(CHECK_RATE)
		for _, player in pairs(Players:GetPlayers()) do
			checkPlayer(player)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastPositions[player] = nil
end)
