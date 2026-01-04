-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: GameLoop (Server - GOLD MASTER)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Manages Round State, Win Conditions, Data Loading, and Red Carpet.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Load Data Module to ensure it initializes
local DataManager = require(game.ServerScriptService.DataManager)

-- CONFIG
local MIN_PLAYERS = 2 
local INTERMISSION_TIME = 20
local ROUND_TIME = 600 -- 10 Minutes
local END_GAME_TIME = 10

-- STATES
local GameState = {
	WAITING = "Waiting for Designers...",
	INTERMISSION = "Next show starts in...",
	IN_ROUND = "SURVIVE",
	ENDING = "Show's Over"
}

local CurrentState = GameState.WAITING
local Timer = 0
local currentSaboteur = nil
local saboteurRespawnListener = nil 

-- EVENTS
local StatusRemote = ReplicatedStorage:FindFirstChild("GameStatusUpdate") or Instance.new("RemoteEvent")
StatusRemote.Name = "GameStatusUpdate"
StatusRemote.Parent = ReplicatedStorage

local TriggerEndGame = ServerStorage:FindFirstChild("TriggerEndGame")
if not TriggerEndGame then
	TriggerEndGame = Instance.new("BindableEvent")
	TriggerEndGame.Name = "TriggerEndGame"
	TriggerEndGame.Parent = ServerStorage
end

-- // HELPER: Shuffle
local function shufflePlayers(playerTable)
	for i = #playerTable, 2, -1 do
		local j = math.random(i)
		playerTable[i], playerTable[j] = playerTable[j], playerTable[i]
	end
	return playerTable
end

-- // HELPER: Broadcast
local function broadcastStatus(state, timeRemaining)
	StatusRemote:FireAllClients(state, timeRemaining)
end

-- // HELPER: Cleanup Weapons
local function cleanupWeapons()
	for _, player in pairs(Players:GetPlayers()) do
		task.defer(function()
			if player.Backpack:FindFirstChild("Shears") then player.Backpack.Shears:Destroy() end
			if player.Character and player.Character:FindFirstChild("Shears") then player.Character.Shears:Destroy() end
		end)
	end
end

-- // HELPER: Give Weapon
local function giveShears(player)
	local shears = ServerStorage:FindFirstChild("Shears")
	if shears and player then
		cleanupWeapons()
		shears:Clone().Parent = player.Backpack
	end
end

-- // FUNCTION: Check Win Conditions
local function checkWinConditions()
	if not currentSaboteur or not Players:FindFirstChild(currentSaboteur.Name) then
		return "Designers (Saboteur FF)"
	end

	local designersAlive = 0
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= currentSaboteur then
			local char = player.Character
			-- Check if they are alive (and not Scrapped)
			if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				if player:GetAttribute("HealthState") ~= "Scrapped" and not player:GetAttribute("Escaped") then
					designersAlive += 1
				end
			end
		end
	end

	if designersAlive == 0 then
		return "Saboteur"
	end
	
	-- Check Escapes (Optional: End if everyone escaped/died)
	
	return nil
end

-- // FUNCTION: Start Round
local function startRound()
	print("🎬 LIGHTS. CAMERA. ACTION.")
	CurrentState = GameState.IN_ROUND
	Timer = ROUND_TIME
	
	local activePlayers = Players:GetPlayers()
	
	if #activePlayers < MIN_PLAYERS then
		print("⚠️ Not enough players. Resetting.")
		CurrentState = GameState.WAITING
		return
	end
	
	activePlayers = shufflePlayers(activePlayers)
	
	local saboteur = activePlayers[1]
	currentSaboteur = saboteur 
	saboteur:SetAttribute("Role", "Saboteur")
	
	local designers = {}
	for i = 2, #activePlayers do
		local p = activePlayers[i]
		p:SetAttribute("Role", "Designer")
		p:SetAttribute("HealthState", "Healthy")
		p:SetAttribute("Escaped", false)
		table.insert(designers, p)
	end
	
	print("✂️ Saboteur is: " .. saboteur.Name)
	
	-- SETUP SABOTEUR
	if saboteur then
		task.spawn(function() 
			if saboteur.Character then
				local killerSpawns = workspace:WaitForChild("Spawns"):WaitForChild("Killer"):GetChildren()
				if #killerSpawns > 0 then
					local randomSpawn = killerSpawns[math.random(1, #killerSpawns)]
					saboteur.Character:PivotTo(randomSpawn.CFrame + Vector3.new(0, 3, 0))
				end
				giveShears(saboteur)
			end
		end)
		
		-- Weapon Persistence
		saboteurRespawnListener = saboteur.CharacterAdded:Connect(function(newChar)
			if CurrentState == GameState.IN_ROUND then
				task.wait(0.5)
				giveShears(saboteur)
			end
		end)
	end
	
	-- SETUP DESIGNERS
	local survivorSpawns = workspace:WaitForChild("Spawns"):WaitForChild("Survivors"):GetChildren()
	for _, designer in pairs(designers) do
		if designer.Character then
			if #survivorSpawns > 0 then
				local randomSpawn = survivorSpawns[math.random(1, #survivorSpawns)]
				designer.Character:PivotTo(randomSpawn.CFrame + Vector3.new(0, 3, 0))
			end
		end
	end
end

-- // FUNCTION: End Round
local function endRound(winner)
	print("🏁 CUT! Winner: " .. winner)
	CurrentState = GameState.ENDING
	Timer = END_GAME_TIME
	
	if saboteurRespawnListener then
		saboteurRespawnListener:Disconnect()
		saboteurRespawnListener = nil
	end
	currentSaboteur = nil
	cleanupWeapons()
	
	-- ⚡ THE RED CARPET TRIGGER
	TriggerEndGame:Fire(winner)
end

-- // MAIN SERVER HEARTBEAT
task.spawn(function()
	while true do
		task.wait(1)
		
		if CurrentState == GameState.WAITING then
			if #Players:GetPlayers() >= MIN_PLAYERS then
				CurrentState = GameState.INTERMISSION
				Timer = INTERMISSION_TIME
			else
				broadcastStatus("Waiting for " .. (MIN_PLAYERS - #Players:GetPlayers()) .. " more...", 0)
			end
			
		elseif CurrentState == GameState.INTERMISSION then
			Timer = Timer - 1
			broadcastStatus("Intermission", Timer)
			if Timer <= 0 then
				startRound()
			end
			
		elseif CurrentState == GameState.IN_ROUND then
			Timer = Timer - 1
			
			local earlyWinner = checkWinConditions()
			if earlyWinner then
				endRound(earlyWinner)
			elseif Timer <= 0 then
				endRound("Designers")
			end
			
		elseif CurrentState == GameState.ENDING then
			Timer = Timer - 1
			broadcastStatus("Game Over", Timer)
			if Timer <= 0 then
				cleanupWeapons()
				
				-- Return to Lobby
				local lobbySpawns = workspace.Spawns:FindFirstChild("Lobby") 
				if lobbySpawns then
					local spawns = lobbySpawns:GetChildren()
					for _, p in pairs(Players:GetPlayers()) do
						if p.Character then
							p.Character:PivotTo(spawns[math.random(1, #spawns)].CFrame)
							p:SetAttribute("Role", nil) -- Reset Role
						end
					end
				end
				CurrentState = GameState.WAITING
			end
		end
	end
end)