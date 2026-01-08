-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: GameLoop (Server - SMART LOBBY & SCALING)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Dynamic 1v4 / 2v8 Scaling based on player count.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

-- CONFIG
local MIN_PLAYERS = 3 -- [UPDATED] Can start with 1v2
local INTERMISSION_TIME = 20
local ROUND_TIME = 900 
local END_GAME_TIME = 10

-- STATES
local GameState = {
	WAITING = "Waiting for Models...",
	INTERMISSION = "Next Runway Show in...",
	IN_ROUND = "SURVIVE",
	ENDING = "Runway Closed"
}

local CurrentState = GameState.WAITING
local Timer = 0
local currentSaboteurs = {} 
local respawnListeners = {}

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

local function broadcastStatus(state, timeRemaining)
	StatusRemote:FireAllClients(state, timeRemaining)
end

local function cleanupWeapons()
	for _, player in pairs(Players:GetPlayers()) do
		task.defer(function()
			-- 1. Remove Weapons
			if player.Backpack:FindFirstChild("Shears") then player.Backpack.Shears:Destroy() end
			if player.Character and player.Character:FindFirstChild("Shears") then player.Character.Shears:Destroy() end
			
			-- 2. [FIX] Cleanup Carry Welds & Stances
			if player.Character then
				local char = player.Character
				
				-- A. If I am the Carrier (Saboteur), destroy the weld
				local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
				if torso then
					local weld = torso:FindFirstChild("CarryWeld")
					if weld then
						local victimPart = weld.Part1
						if victimPart and victimPart.Parent then
							local victimHum = victimPart.Parent:FindFirstChild("Humanoid")
							if victimHum then
								victimHum.PlatformStand = false
								victimHum.WalkSpeed = 16
							end
							local victimPlayer = Players:GetPlayerFromCharacter(victimPart.Parent)
							if victimPlayer then
								victimPlayer:SetAttribute("CarriedBy", nil)
							end
						end
						weld:Destroy()
					end
				end
				
				-- B. If I was the Victim (Safety Check), reset humanoid
				local hum = char:FindFirstChild("Humanoid")
				if hum then
					if hum.PlatformStand then hum.PlatformStand = false end
					if hum.WalkSpeed == 0 then hum.WalkSpeed = 16 end
				end
				
				player:SetAttribute("CarriedBy", nil)
			end
		end)
	end
end

local function giveShears(player)
	local shears = ServerStorage:FindFirstChild("Shears")
	if shears and player then
		if not player.Backpack:FindFirstChild("Shears") then
			shears:Clone().Parent = player.Backpack
		end
	end
end

-- // FUNCTION: Smart Objective Scaling
local function calculateObjectives(survivorCount, killerCount)
	-- The "Among Us" / FtF Formula
	if killerCount == 1 then
		-- Classic 1v4 scaling: Usually (Survivors + 1)
		return math.clamp(survivorCount + 1, 3, 5) 
	else
		-- 2v8 Chaos scaling
		-- 8 Survivors -> Need ~7-8 Gens to prevent rush
		-- Formula: Survivors - 1 (min 6, max 10)
		return math.clamp(survivorCount, 6, 12)
	end
end

local function checkWinConditions()
	local saboteursInGame = 0
	for _, sab in pairs(currentSaboteurs) do
		if Players:FindFirstChild(sab.Name) then saboteursInGame += 1 end
	end
	
	if saboteursInGame == 0 then return "Designers (Saboteur Quit)" end

	local designersAlive = 0
	local totalDesigners = 0
	
	for _, player in pairs(Players:GetPlayers()) do
		if player:GetAttribute("Role") == "Designer" then
			totalDesigners += 1
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
				if player:GetAttribute("HealthState") ~= "Scrapped" and not player:GetAttribute("Escaped") then
					designersAlive += 1
				end
			end
		end
	end

	if totalDesigners > 0 and designersAlive == 0 then return "Saboteurs" end
	return nil
end

local function startRound()
	print("🎬 LIGHTS. CAMERA. ACTION.")
	CurrentState = GameState.IN_ROUND
	Timer = ROUND_TIME
	
	local activePlayers = Players:GetPlayers()
	local playerCount = #activePlayers
	
	if playerCount < MIN_PLAYERS then
		CurrentState = GameState.WAITING
		return
	end
	
	-- // 🧠 SMART LOBBY LOGIC //
	local killerCount = 1
	if playerCount >= 6 then
		killerCount = 2 -- Double Trouble Mode
		print("🔥 CHAOS MODE: 2 Saboteurs Selected.")
	else
		print("🕶️ CLASSIC MODE: 1 Saboteur Selected.")
	end
	
	-- Shuffle & Assign
	for i = playerCount, 2, -1 do
		local j = math.random(i)
		activePlayers[i], activePlayers[j] = activePlayers[j], activePlayers[i]
	end
	
	currentSaboteurs = {}
	
	for i = 1, killerCount do
		local sab = activePlayers[i]
		table.insert(currentSaboteurs, sab)
		sab:SetAttribute("Role", "Saboteur")
	end
	
	local designers = {}
	for i = killerCount + 1, playerCount do
		local p = activePlayers[i]
		p:SetAttribute("Role", "Designer")
		p:SetAttribute("HealthState", "Healthy")
		p:SetAttribute("Escaped", false)
		table.insert(designers, p)
	end
	
	-- // SCALE OBJECTIVES //
	local objectivesNeeded = calculateObjectives(#designers, killerCount)
	workspace:SetAttribute("RequiredStations", objectivesNeeded)
	print("📊 Objectives Set: " .. objectivesNeeded .. " Stations needed.")
	
	-- SETUP SABOTEURS
	local killerSpawns = workspace:WaitForChild("Spawns"):WaitForChild("Killer"):GetChildren()
	for _, sab in pairs(currentSaboteurs) do
		task.spawn(function() 
			if sab.Character then
				if #killerSpawns > 0 then
					sab.Character:PivotTo(killerSpawns[math.random(1, #killerSpawns)].CFrame + Vector3.new(0, 3, 0))
				end
				giveShears(sab)
			end
			local conn = sab.CharacterAdded:Connect(function(newChar)
				if CurrentState == GameState.IN_ROUND then
					task.wait(0.5)
					giveShears(sab)
				end
			end)
			table.insert(respawnListeners, conn)
		end)
	end
	
	-- SETUP DESIGNERS
	local survivorSpawns = workspace:WaitForChild("Spawns"):WaitForChild("Survivors"):GetChildren()
	for _, designer in pairs(designers) do
		if designer.Character then
			if #survivorSpawns > 0 then
				designer.Character:PivotTo(survivorSpawns[math.random(1, #survivorSpawns)].CFrame + Vector3.new(0, 3, 0))
			end
		end
	end
end

local function endRound(winner)
	CurrentState = GameState.ENDING
	Timer = END_GAME_TIME
	for _, conn in pairs(respawnListeners) do conn:Disconnect() end
	respawnListeners = {}
	currentSaboteurs = {}
	cleanupWeapons()
	TriggerEndGame:Fire(winner)
end

task.spawn(function()
	while true do
		task.wait(1)
		if CurrentState == GameState.WAITING then
			if #Players:GetPlayers() >= MIN_PLAYERS then
				CurrentState = GameState.INTERMISSION
				Timer = INTERMISSION_TIME
			else
				broadcastStatus("Waiting for models...", 0)
			end
		elseif CurrentState == GameState.INTERMISSION then
			Timer = Timer - 1
			broadcastStatus("Starting in...", Timer)
			if Timer <= 0 then startRound() end
		elseif CurrentState == GameState.IN_ROUND then
			Timer = Timer - 1
			local earlyWinner = checkWinConditions()
			if earlyWinner then endRound(earlyWinner)
			elseif Timer <= 0 then endRound("Designers") end
		elseif CurrentState == GameState.ENDING then
			Timer = Timer - 1
			broadcastStatus("Show's Over", Timer)
			if Timer <= 0 then
				cleanupWeapons()
				local lobbySpawns = workspace.Spawns:FindFirstChild("Lobby") 
				if lobbySpawns then
					local spawns = lobbySpawns:GetChildren()
					for _, p in pairs(Players:GetPlayers()) do
						if p.Character then
							p.Character:PivotTo(spawns[math.random(1, #spawns)].CFrame)
							p:SetAttribute("Role", nil)
						end
					end
				end
				CurrentState = GameState.WAITING
			end
		end
	end
end)
