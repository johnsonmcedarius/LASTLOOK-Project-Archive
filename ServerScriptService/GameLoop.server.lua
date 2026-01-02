--[[
    GameLoop (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 14:59:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- MODULES
local RoleManager = require(script.Parent:WaitForChild("RoleManager"))
local CorpseController = require(script.Parent:WaitForChild("CorpseController"))

-- CONFIG
local MIN_PLAYERS = 1 -- 🚨 Set to 4 for release, 1 for testing
local ROUND_DURATION = 420 -- 7 Minutes
local INTERMISSION_DURATION = 30 -- 30 Seconds Lobby Time
local BASE_PAY = 100 
local WIN_BONUS = 50 
local LOW_CHAOS_MULTIPLIER = 1.5 

-- EVENTS
local EVENTS = ReplicatedStorage:FindFirstChild("Events")
if not EVENTS then EVENTS = Instance.new("Folder", ReplicatedStorage); EVENTS.Name = "Events" end

local EndRoundEvent = EVENTS:FindFirstChild("EndRound") or Instance.new("RemoteEvent", EVENTS)
EndRoundEvent.Name = "EndRound"

local BodyReportedEvent = EVENTS:FindFirstChild("BodyReported") or Instance.new("BindableEvent", EVENTS)
BodyReportedEvent.Name = "BodyReported"

local EjectionReveal = EVENTS:FindFirstChild("EjectionReveal") or Instance.new("RemoteEvent", EVENTS)
EjectionReveal.Name = "EjectionReveal"

-- DEV FORCE START EVENT (From DevCommands)
local ServerEvents = ServerStorage:FindFirstChild("Events") or Instance.new("Folder", ServerStorage)
if ServerEvents.Name ~= "Events" then ServerEvents.Name = "Events" end
local ForceStartEvent = ServerEvents:FindFirstChild("ForceStart") or Instance.new("BindableEvent", ServerEvents)
ForceStartEvent.Name = "ForceStart"

-- VALUES
local Values = ReplicatedStorage:WaitForChild("Values")
local GameState = Values:WaitForChild("GameState")
local TimerEnd = Values:WaitForChild("TimerEnd")
local Status = Values:WaitForChild("Status")
local TaskProgress = Values:WaitForChild("TaskProgress")
local TotalTasksNeeded = Values:WaitForChild("TotalTasksNeeded")
local ChaosLevel = Values:WaitForChild("ChaosLevel")

-- HELPERS
local function Log(msg) print("🧠 [GAME LOOP] " .. msg) end
local function SetState(s) GameState.Value = s; Log("State: " .. s) end

-- 📍 SPAWN HELPER (Force player to specific zone)
local function SpawnAtLobby(player)
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart", 5)

	if root then
		local lobbyFolder = workspace:FindFirstChild("Spawns") and workspace.Spawns:FindFirstChild("Lobby")
		if lobbyFolder then
			local spawns = lobbyFolder:GetChildren()
			if #spawns > 0 then
				local spawnPart = spawns[math.random(1, #spawns)]
				-- Handle Model vs Part
				local targetCF = spawnPart:IsA("Model") and spawnPart.PrimaryPart.CFrame or spawnPart.CFrame
				root.CFrame = targetCF + Vector3.new(0, 4, 0)
			end
		end
	end
end

-- 📍 MASS TELEPORT
local function TeleportAll(locationName)
	local spawnFolder = workspace:WaitForChild("Spawns"):FindFirstChild(locationName)
	if not spawnFolder then warn("❌ Missing Spawns/"..locationName); return end

	local points = spawnFolder:GetChildren()
	if #points == 0 then warn("❌ No points in "..locationName); return end

	for i, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local spawnNode = points[math.random(1, #points)]
			local targetCF = spawnNode:IsA("Model") and spawnNode.PrimaryPart.CFrame or spawnNode.CFrame

			-- Teleport + slight random offset to prevent stacking
			player.Character:SetPrimaryPartCFrame(targetCF + Vector3.new(math.random(-2,2), 3, math.random(-2,2)))
		end
	end
end

-- 🧼 CLEANUP
local function ClearBodies()
	if _G.CorpseController then _G.CorpseController.ClearAll() end
	for _, child in pairs(workspace:GetChildren()) do
		if child.Name == "DeadBody" then child:Destroy() end
	end
end

local function CleanUpRound()
	Log("🧹 Cleaning up map...")
	for _, player in pairs(Players:GetPlayers()) do
		player:SetAttribute("Role", nil)
		player:SetAttribute("IsDead", nil)
		player:SetAttribute("HasMusePass", nil)
		player:LoadCharacter() -- Triggers respawn/reset
	end
	TaskProgress.Value = 0
	ChaosLevel.Value = 0
	ClearBodies()
end

-- 💰 REWARDS
local function DistributeRewards(winningTeam)
	local chaos = ChaosLevel.Value
	local isCleanRun = (chaos < 50)

	for _, player in pairs(Players:GetPlayers()) do
		local role = player:GetAttribute("Role")
		local team = (role == "Saboteur") and "Saboteurs" or "Designers"
		local spools = BASE_PAY
		local xp = 100

		local didWin = (team == winningTeam)
		if didWin then spools += WIN_BONUS; xp += 50 end
		if isCleanRun and winningTeam == "Designers" then spools = math.floor(spools * LOW_CHAOS_MULTIPLIER) end
		if player:GetAttribute("IsVIP") then spools = math.floor(spools * 1.2); xp = math.floor(xp * 1.2) end

		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("SewingSpools") then stats.SewingSpools.Value += spools end
		if _G.LevelManager then _G.LevelManager.AddXP(player, xp) end

		EndRoundEvent:FireClient(player, {Winner = winningTeam, Spools = spools, XP = xp, Chaos = chaos, IsClean = isCleanRun, DidWin = didWin})
	end
end

-- 🔗 DYNAMIC SPAWN LISTENER
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2) -- Wait for physics
		local root = char:WaitForChild("HumanoidRootPart")

		if GameState.Value == "Playing" then
			-- If joining mid-game or respawning as ghost, go to MAP
			if player:GetAttribute("IsDead") then
				-- Ghost Spawn (Random Map Spot)
				local mapSpawns = workspace.Spawns.Map:GetChildren()
				if #mapSpawns > 0 then
					local spawn = mapSpawns[math.random(1, #mapSpawns)]
					local cf = spawn:IsA("Model") and spawn.PrimaryPart.CFrame or spawn.CFrame
					root.CFrame = cf + Vector3.new(0, 5, 0)
				end
			else
				-- Late living joiner -> Map
				local mapSpawns = workspace.Spawns.Map:GetChildren()
				if #mapSpawns > 0 then
					local spawn = mapSpawns[math.random(1, #mapSpawns)]
					local cf = spawn:IsA("Model") and spawn.PrimaryPart.CFrame or spawn.CFrame
					root.CFrame = cf
				end
			end
		elseif GameState.Value == "Lobby" or GameState.Value == "Intermission" then
			-- Always go to Lobby
			SpawnAtLobby(player)
		end
	end)
end)

-- 🎬 MAIN LOOP
local function StartRound()
	-- 1. INTERMISSION
	SetState("Intermission")
	TeleportAll("Lobby")

	Status.Value = "NEXT SHOW STARTS IN..."

	-- Wait loop with Skip check
	local skipped = false
	local skipConn
	skipConn = ForceStartEvent.Event:Connect(function() skipped = true end)

	for i = INTERMISSION_DURATION, 1, -1 do
		if skipped then break end
		Status.Value = "RUNWAY PREP: " .. i
		task.wait(1)
		if #Players:GetPlayers() < MIN_PLAYERS then 
			SetState("Lobby"); Status.Value = "WAITING FOR PLAYERS..."; 
			if skipConn then skipConn:Disconnect() end; return 
		end
	end
	if skipConn then skipConn:Disconnect() end

	-- 2. START GAME
	SetState("Playing")
	Status.Value = "ASSIGNING ROLES..."
	TeleportAll("Map")
	task.wait(2) 

	RoleManager.AssignRoles(Players:GetPlayers())
	Status.Value = "COMPLETE THE COLLECTION" -- ✅ Status Fix

	-- Setup Goals
	local designerCount = 0
	for _, p in pairs(Players:GetPlayers()) do
		if p:GetAttribute("Role") ~= "Saboteur" then designerCount += 1 end
	end
	TotalTasksNeeded.Value = math.max(10, designerCount * 6)

	TimerEnd.Value = workspace:GetServerTimeNow() + ROUND_DURATION
	ChaosLevel.Value = 0
	TaskProgress.Value = 0

	local winner = nil
	local reason = ""

	-- 3. GAMEPLAY
	while GameState.Value == "Playing" or GameState.Value == "Meeting" do
		if GameState.Value == "Playing" then
			-- Win Conditions
			if workspace:GetServerTimeNow() >= TimerEnd.Value then winner = "Saboteurs"; reason = "TIME EXPIRED"; break end
			if ChaosLevel.Value >= 100 then winner = "Saboteurs"; reason = "HOUSE COLLAPSED"; break end
			if TaskProgress.Value >= TotalTasksNeeded.Value then winner = "Designers"; reason = "COLLECTION SECURED"; break end

			if #Players:GetPlayers() > 1 then 
				local result = RoleManager.CheckWinCondition()
				if result == "SaboteursWin" then winner = "Saboteurs"; reason = "DESIGNERS ELIMINATED"; break
				elseif result == "DesignersWin" then winner = "Designers"; reason = "SABOTEURS EJECTED"; break end
			end
		end
		task.wait(1)
	end

	-- 4. END
	SetState("GameOver")
	Status.Value = reason
	DistributeRewards(winner)
	task.wait(8)

	CleanUpRound()
end

-- LOBBY LOOP
SetState("Lobby")
while true do
	if GameState.Value == "Lobby" then
		if #Players:GetPlayers() >= MIN_PLAYERS then
			StartRound()
		else
			Status.Value = "WAITING FOR PLAYERS (".. #Players:GetPlayers() .."/"..MIN_PLAYERS..")"
		end
	end
	task.wait(1)
end