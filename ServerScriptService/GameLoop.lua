-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: GameLoop (Server - WITH DEV COMMANDS)
-- 🛠️ AUTH: Coding Partner
-- 💡 DESC: Handles Lobby -> Map teleport, Timers, and Force Start.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- // CONFIG
local MIN_PLAYERS = 2 -- Default. /start command overrides this temporarily.
local INTERMISSION_TIME = 15
local ROUND_TIME = 300 

-- // EVENTS
local ForceStartEvent = ServerStorage:WaitForChild("DevForceStart", 5)
local TriggerEndGame = ServerStorage:FindFirstChild("TriggerEndGame")

-- // REPLICATED VALUES
local GameValues = ReplicatedStorage:FindFirstChild("GameValues")
if not GameValues then
	GameValues = Instance.new("Folder")
	GameValues.Name = "GameValues"
	GameValues.Parent = ReplicatedStorage
end

local StatusVal = GameValues:FindFirstChild("Status") or Instance.new("StringValue", GameValues)
StatusVal.Name = "Status"
local TimerVal = GameValues:FindFirstChild("TimeRemaining") or Instance.new("IntValue", GameValues)
TimerVal.Name = "TimeRemaining"

-- // MAP SETUP
local MapSpawns = workspace:FindFirstChild("MapSpawns") or workspace:WaitForChild("Spawns", 5)
local LobbySpawns = workspace:FindFirstChild("LobbySpawns")

-- // HELPER: Give Shears
local function equipSaboteur(player)
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid", 5)
	
	if hum then
		local shears = ServerStorage:FindFirstChild("Shears")
		if shears then
			player.Backpack:ClearAllChildren()
			local clone = shears:Clone()
			clone.Parent = player.Backpack
			hum:EquipTool(clone) 
			clone.CanBeDropped = false
		end
	end
end

local function spawnPlayers(locationFolder)
	if not locationFolder then return end
	local spawns = locationFolder:GetChildren()
	if #spawns == 0 then return end
	
	for i, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local spawnPoint = spawns[math.random(1, #spawns)]
			player.Character.HumanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
		end
	end
end

local function startGame()
	StatusVal.Value = "InGame"
	print("🎬 STARTING GAME...")
	
	local all = Players:GetPlayers()
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
		else
			p:SetAttribute("Role", "Designer")
		end
		
		p:LoadCharacter() 
		
		if p:GetAttribute("Role") == "Saboteur" then
			task.delay(0.5, function() equipSaboteur(p) end)
		end
	end
	
	task.wait(2)
	spawnPlayers(MapSpawns)
end

local function endGame(winner)
	StatusVal.Value = "RoundOver"
	TimerVal.Value = 0
	
	local rem = ReplicatedStorage:FindFirstChild("RoundOverEvent")
	if rem then rem:FireAllClients(winner, {}, nil) end
	
	task.wait(8)
	
	for _, p in pairs(Players:GetPlayers()) do
		p:SetAttribute("Role", "None")
		if p.Backpack then p.Backpack:ClearAllChildren() end
		p:LoadCharacter()
	end
	
	task.wait(2)
	spawnPlayers(LobbySpawns)
end

-- // LOOP
local forceStartTriggered = false

if ForceStartEvent then
	ForceStartEvent.Event:Connect(function()
		forceStartTriggered = true
	end)
end

task.spawn(function()
	while true do
		forceStartTriggered = false
		
		-- 1. INTERMISSION
		StatusVal.Value = "Intermission"
		for i = INTERMISSION_TIME, 0, -1 do
			if forceStartTriggered then break end -- Break loop if /start used
			
			TimerVal.Value = i
			
			-- Wait for players logic
			if #Players:GetPlayers() < MIN_PLAYERS and not forceStartTriggered then
				StatusVal.Value = "WaitingForPlayers"
				repeat 
					task.wait(1) 
					if forceStartTriggered then break end -- Break wait if /start used
				until #Players:GetPlayers() >= MIN_PLAYERS
				
				if not forceStartTriggered then
					StatusVal.Value = "Intermission"
					i = INTERMISSION_TIME -- Reset timer when enough players join
				end
			end
			task.wait(1)
		end
		
		-- 2. START
		startGame()
		
		-- 3. GAMEPLAY
		local roundTimer = ROUND_TIME
		local gameRunning = true
		
		-- Listen for external end game (from /win command)
		local endConnection
		if TriggerEndGame then
			endConnection = TriggerEndGame.Event:Connect(function(winner)
				gameRunning = false
			end)
		end
		
		while roundTimer > 0 and gameRunning do
			roundTimer -= 1
			TimerVal.Value = roundTimer
			task.wait(1)
		end
		
		if endConnection then endConnection:Disconnect() end
		
		-- 4. END
		endGame("TimeUp")
		task.wait(2)
	end
end)
