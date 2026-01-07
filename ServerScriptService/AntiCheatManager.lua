-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AntiCheatManager (Server - NEW)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: "The Sheriff". Prevents Speed Hacking (The Flash).
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIG
local MAX_SPEED_TOLERANCE = 35 -- Allow sprint + perks, but catch 50+
local CHECK_RATE = 1.0 -- Check every second
local RUBBER_BAND_FORCE = true

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
		-- 🚨 SPEED DETECTED
		print("🚨 AC: " .. player.Name .. " is moving too fast! (" .. math.floor(horizontalSpeed) .. ")")
		
		if RUBBER_BAND_FORCE then
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			-- Optional: Teleport them back to last valid position if you tracked it precisely
		end
	end
	
	-- 2. Distance Check (Average Speed over 1s)
	-- Prevents "CFrame Teleporting" which Velocity check might miss
	if lastPositions[player] then
		local dist = (root.Position - lastPositions[player]).Magnitude
		-- We allow slightly more here because of falling/flinging
		if dist > (MAX_SPEED_TOLERANCE * 1.5) then
			-- Ignore if they just spawned (Y check or time check usually needed)
			-- For Alpha, just warn
			-- warn("🚨 AC: " .. player.Name .. " teleported " .. math.floor(dist) .. " studs!")
			
			-- Hard Rubberband
			if RUBBER_BAND_FORCE then
				root.CFrame = CFrame.new(lastPositions[player])
			end
		end
	end
	
	lastPositions[player] = root.Position
end

RunService.Heartbeat:Connect(function(dt)
	-- We don't need to run this every frame. Throttle it.
	-- Or iterate through players over time.
end)

-- Loop every second
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
