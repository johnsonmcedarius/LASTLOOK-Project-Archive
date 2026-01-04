-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: StationManager (Server - PLATINUM MASTER)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Progress Engine + Skill Checks + Jam Logic + Scoring + Runway Reveal.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local BalanceConfig = require(ReplicatedStorage.Modules.BalanceConfig)

-- STATE
local ActiveStations = {} -- [Model] = {Progress = 0, Occupants = {Player1, Player2}}
local CompletedStationsCount = 0

-- REMOTES / EVENTS
local StationUpdateRemote = Instance.new("RemoteEvent")
StationUpdateRemote.Name = "StationUpdateEvent"
StationUpdateRemote.Parent = ReplicatedStorage

local SkillCheckRemote = Instance.new("RemoteEvent")
SkillCheckRemote.Name = "SkillCheckEvent"
SkillCheckRemote.Parent = ReplicatedStorage

local GlobalPowerRemote = Instance.new("RemoteEvent")
GlobalPowerRemote.Name = "GlobalPowerEvent"
GlobalPowerRemote.Parent = ReplicatedStorage

-- BINDABLES (Output for Scoring)
-- We use WaitForChild because RoundEndManager creates this
local AddScoreBindable = ServerStorage:WaitForChild("AddScore", 10)

-- // HELPER: Check Player Perks (For Second Look)
local function playerHasPerk(player, perkName)
	-- Checks Attribute on player (set by DataManager/Lobby)
	local perks = player:GetAttribute("EquippedPerks") 
	if perks and string.find(perks, perkName) then
		return true
	end
	return false
end

-- // HELPER: Initialize Station Attributes
local function setupStation(stationModel)
	if not stationModel:GetAttribute("WorkRequired") then
		stationModel:SetAttribute("WorkRequired", BalanceConfig.Station.BaseWorkRequired)
	end
	if not stationModel:GetAttribute("CurrentProgress") then
		stationModel:SetAttribute("CurrentProgress", 0)
	end
	if not stationModel:GetAttribute("Jammed") then
		stationModel:SetAttribute("Jammed", false)
	end
	
	ActiveStations[stationModel] = {
		Progress = 0,
		Max = stationModel:GetAttribute("WorkRequired"),
		Occupants = {} 
	}
end

-- // INITIALIZE MAP
local function initMap()
	for _, station in pairs(CollectionService:GetTagged("Station")) do
		setupStation(station)
	end
end

-- // EXPOSED FUNCTION: Add Player to Station (Invoked by InteractionServer)
local StationBindable = Instance.new("BindableFunction")
StationBindable.Name = "StationManagerFunc"
StationBindable.Parent = ServerStorage

function StationBindable.OnInvoke(action, player, station)
	if action == "Join" then
		local data = ActiveStations[station]
		if not data then return false end
		
		-- Max Occupants Check
		if #data.Occupants >= BalanceConfig.Station.MaxOccupants then
			return false 
		end
		
		if not table.find(data.Occupants, player) then
			table.insert(data.Occupants, player)
			print("🧵 " .. player.Name .. " started working on " .. station.Name)
			return true
		end
		
	elseif action == "Leave" then
		local data = ActiveStations[station]
		if not data then return end
		
		local idx = table.find(data.Occupants, player)
		if idx then
			table.remove(data.Occupants, idx)
			print("🛑 " .. player.Name .. " stopped working.")
		end
	end
	return false
end

-- // FUNCTION: Trigger Completion (Runway Reveal)
local function completeStation(station)
	local data = ActiveStations[station]
	if not data then return end
	
	station:SetAttribute("Powered", true)
	station:SetAttribute("Jammed", false) -- Clear jams if it finishes
	
	-- Visuals (Neon Lights On)
	for _, light in pairs(station:GetDescendants()) do
		if light.Name == "StatusLight" then
			light.Color = Color3.fromRGB(0, 255, 0) -- Green
			light.Material = Enum.Material.Neon
		end
	end
	
	-- Global Counter
	CompletedStationsCount += 1
	GlobalPowerRemote:FireAllClients(CompletedStationsCount, BalanceConfig.Global.StationsToPower)
	
	print("💡 STATION POWERED! (" .. CompletedStationsCount .. "/" .. BalanceConfig.Global.StationsToPower .. ")")
	
	ActiveStations[station] = nil -- Stop tracking logic for this station
	
	-- THE RUNWAY REVEAL
	if CompletedStationsCount >= BalanceConfig.Global.StationsToPower then
		print("🚪 EXIT GATES POWERED! RUN!")
		
		-- 1. Turn on Runway Lights
		local runwayLights = CollectionService:GetTagged("RunwayLights")
		for _, light in pairs(runwayLights) do
			light.Material = Enum.Material.Neon
			light.Color = Color3.fromRGB(255, 215, 0) -- Gold
			if light:FindFirstChild("PointLight") then
				light.PointLight.Enabled = true
			end
		end
		
		-- 2. Unlock Exits (Sets global state for ExitGateManager)
		workspace:SetAttribute("ExitPowered", true)
	end
end

-- // MAIN LOOP (The Heartbeat)
task.spawn(function()
	while true do
		local dt = task.wait(0.2) 
		
		for station, data in pairs(ActiveStations) do
			if station:GetAttribute("Powered") then continue end
			
			-- ⚡ JAM LOGIC: If jammed, skip all progress
			if station:GetAttribute("Jammed") then
				continue 
			end
			
			local occupantCount = #data.Occupants
			
			if occupantCount > 0 then
				-- Calculate Rate
				local rate = BalanceConfig.Station.BaseWorkRate
				if occupantCount > 1 then
					rate = rate * BalanceConfig.Station.DuoMultiplier
				end
				
				-- Apply Progress
				local progressAdded = rate * dt
				data.Progress = math.clamp(data.Progress + progressAdded, 0, data.Max)
				station:SetAttribute("CurrentProgress", data.Progress)
				
				-- RNG Skill Check Trigger
				if math.random() < (BalanceConfig.SkillCheck.TriggerChance * dt) then
					local victim = data.Occupants[math.random(1, occupantCount)]
					-- Check for Mythic Perk
					local hasSecondLook = playerHasPerk(victim, "SecondLook")
					SkillCheckRemote:FireClient(victim, station, hasSecondLook)
				end
				
				-- Check Completion
				if data.Progress >= data.Max then
					completeStation(station)
				end
			end
		end
	end
end)

-- // ⚡ THE HANDSHAKE (Receive Results from Client)
SkillCheckRemote.OnServerEvent:Connect(function(player, action, station, result)
	local data = ActiveStations[station]
	if not data then return end

	-- 1. SKILL CHECK RESULT
	if action == "Result" then
		if result == "Great" then
			-- Bonus Progress
			data.Progress = math.clamp(data.Progress + BalanceConfig.SkillCheck.BonusProgress, 0, data.Max)
			
			-- 💰 SCORE: Award Points for Great Stitch
			if AddScoreBindable then
				AddScoreBindable:Fire(player, "GREAT_STITCH")
			end
			
		elseif result == "Good" then
			-- No Bonus, clean pass
			
		elseif result == "Miss" then
			-- Penalty
			data.Progress = math.clamp(data.Progress - BalanceConfig.SkillCheck.MissPenalty, 0, data.Max)
			
			-- ⚡ TRIGGER JAM (Minigame B)
			station:SetAttribute("Jammed", true)
			
			-- Tell specific client (and maybe others?) to start Jam Game
			-- For now, just the person who messed up cleans it
			SkillCheckRemote:FireClient(player, "Jam", station)
			
			print("💥 " .. player.Name .. " JAMMED the machine!")
		end
		
		-- Sync Visuals
		station:SetAttribute("CurrentProgress", data.Progress)

	-- 2. CLEAR JAM
	elseif action == "ClearJam" then
		station:SetAttribute("Jammed", false)
		print("🧵 " .. player.Name .. " cleared the thread jam!")
	end
end)

-- Init
initMap()
CollectionService:GetInstanceAddedSignal("Station"):Connect(setupStation)