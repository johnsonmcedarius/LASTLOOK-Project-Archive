-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: GameLoop (Server - LOBBY)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles 1vDesigner or 2v8 scaling.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")

local MIN_PLAYERS = 2 -- Lowered for testing
local roundActive = false

local function startGame()
	local all = Players:GetPlayers()
	if #all < MIN_PLAYERS then return end
	
	roundActive = true
	
	-- Logic: 2 Killers if > 6 players, else 1
	local killerCount = (#all >= 6) and 2 or 1
	
	-- Shuffle
	for i = #all, 2, -1 do
		local j = math.random(i)
		all[i], all[j] = all[j], all[i]
	end
	
	-- Assign Roles
	for i, p in ipairs(all) do
		if i <= killerCount then
			p:SetAttribute("Role", "Saboteur")
			-- Check AFK: If LastInputTime > 5 mins, skip? (Implied)
		else
			p:SetAttribute("Role", "Designer")
		end
		p:LoadCharacter() -- Respawn with new roles
	end
	
	print("Game Started. Killers: " .. killerCount)
end

while true do
	task.wait(5)
	if not roundActive and #Players:GetPlayers() >= MIN_PLAYERS then
		-- Intermission Logic
		print("Starting in 10...")
		task.wait(10)
		startGame()
	end
end
