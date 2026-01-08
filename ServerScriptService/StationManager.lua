-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: StationManager (Server - DYNAMIC SCALING)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Progress Engine. Reads objectives from GameLoop logic.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local BalanceConfig = require(ReplicatedStorage.Modules.BalanceConfig)

-- STATE
local ActiveStations = {} 
local CompletedStationsCount = 0

-- REMOTES
local StationUpdateRemote = Instance.new("RemoteEvent")
StationUpdateRemote.Name = "StationUpdateEvent"
StationUpdateRemote.Parent = ReplicatedStorage

local SkillCheckRemote = Instance.new("RemoteEvent")
SkillCheckRemote.Name = "SkillCheckEvent"
SkillCheckRemote.Parent = ReplicatedStorage

local GlobalPowerRemote = Instance.new("RemoteEvent")
GlobalPowerRemote.Name = "GlobalPowerEvent"
GlobalPowerRemote.Parent = ReplicatedStorage

local AddScoreBindable = ServerStorage:WaitForChild("AddScore", 10)

local function playerHasPerk(player, perkName)
	local perks = player:GetAttribute("EquippedPerks") 
	if perks and string.find(perks, perkName) then return true end
	return false
end

local function setupStation(stationModel)
	if not stationModel:GetAttribute("WorkRequired") then stationModel:SetAttribute("WorkRequired", BalanceConfig.Station.BaseWorkRequired) end
	if not stationModel:GetAttribute("CurrentProgress") then stationModel:SetAttribute("CurrentProgress", 0) end
	if not stationModel:GetAttribute("Jammed") then stationModel:SetAttribute("Jammed", false) end
	
	ActiveStations[stationModel] = {
		Progress = 0,
		Max = stationModel:GetAttribute("WorkRequired"),
		Occupants = {},
		JamTime = 0,
		PendingChecks = {} 
	}
end

local function initMap()
	for _, station in pairs(CollectionService:GetTagged("Station")) do setupStation(station) end
end

local StationBindable = Instance.new("BindableFunction")
StationBindable.Name = "StationManagerFunc"
StationBindable.Parent = ServerStorage

function StationBindable.OnInvoke(action, player, station)
	if action == "Join" then
		local data = ActiveStations[station]
		if not data then return false end
		if #data.Occupants >= BalanceConfig.Station.MaxOccupants then return false end
		if not table.find(data.Occupants, player) then
			table.insert(data.Occupants, player)
			return true
		end
	elseif action == "Leave" then
		local data = ActiveStations[station]
		if not data then return end
		local idx = table.find(data.Occupants, player)
		if idx then 
			table.remove(data.Occupants, idx)
			data.PendingChecks[player] = nil 
		end
	end
	return false
end

local function completeStation(station)
	local data = ActiveStations[station]
	if not data then return end
	
	station:SetAttribute("Powered", true)
	station:SetAttribute("Jammed", false)
	
	for _, light in pairs(station:GetDescendants()) do
		if light.Name == "StatusLight" then
			light.Color = Color3.fromRGB(0, 255, 0)
			light.Material = Enum.Material.Neon
		end
	end
	
	CompletedStationsCount += 1
	
	-- [UPDATED] READ DYNAMIC OBJECTIVE
	local required = workspace:GetAttribute("RequiredStations") or BalanceConfig.Global.StationsToPower
	GlobalPowerRemote:FireAllClients(CompletedStationsCount, required)
	
	ActiveStations[station] = nil 
	
	if CompletedStationsCount >= required then
		local runwayLights = CollectionService:GetTagged("RunwayLights")
		for _, light in pairs(runwayLights) do
			light.Material = Enum.Material.Neon
			light.Color = Color3.fromRGB(255, 215, 0)
			if light:FindFirstChild("PointLight") then light.PointLight.Enabled = true end
		end
		workspace:SetAttribute("ExitPowered", true)
	end
end

-- // MAIN LOOP
task.spawn(function()
	while true do
		local dt = task.wait(0.2) 
		
		for station, data in pairs(ActiveStations) do
			if station:GetAttribute("Powered") then continue end
			
			if station:GetAttribute("Jammed") then
				data.JamTime = (data.JamTime or 0) + dt
				if data.JamTime >= BalanceConfig.Station.PassiveJamClear then
					station:SetAttribute("Jammed", false)
					data.JamTime = 0
				end
				continue 
			end
			
			local occupantCount = #data.Occupants
			
			if occupantCount > 0 then
				local rate = BalanceConfig.Station.BaseWorkRate
				if occupantCount > 1 then rate = rate * BalanceConfig.Station.DuoMultiplier end
				
				local progressAdded = rate * dt
				data.Progress = math.clamp(data.Progress + progressAdded, 0, data.Max)
				station:SetAttribute("CurrentProgress", data.Progress)
				
				if math.random() < (BalanceConfig.SkillCheck.TriggerChance * dt) then
					local victim = data.Occupants[math.random(1, occupantCount)]
					
					data.PendingChecks[victim] = true
					
					local hasSecondLook = playerHasPerk(victim, "SecondLook")
					SkillCheckRemote:FireClient(victim, station, hasSecondLook)
				end
				
				if data.Progress >= data.Max then completeStation(station) end
			end
		end
	end
end)

SkillCheckRemote.OnServerEvent:Connect(function(player, action, station, result)
	local data = ActiveStations[station]
	if not data then return end

	if action == "Result" then
		if not data.PendingChecks[player] then
			warn("🚨 EXPLOIT DETECTED: " .. player.Name)
			return 
		end
		
		data.PendingChecks[player] = nil
		
		if result == "Great" then
			data.Progress = math.clamp(data.Progress + BalanceConfig.SkillCheck.BonusProgress, 0, data.Max)
			if AddScoreBindable then AddScoreBindable:Fire(player, "GREAT_STITCH") end
		elseif result == "Good" then
			-- No Bonus
		elseif result == "Miss" then
			data.Progress = math.clamp(data.Progress - BalanceConfig.SkillCheck.MissPenalty, 0, data.Max)
			station:SetAttribute("Jammed", true)
			data.JamTime = 0 
			SkillCheckRemote:FireClient(player, "Jam", station)
		end
		station:SetAttribute("CurrentProgress", data.Progress)

	elseif action == "ClearJam" then
		station:SetAttribute("Jammed", false)
		data.JamTime = 0
	end
end)

initMap()
CollectionService:GetInstanceAddedSignal("Station"):Connect(setupStation)

-- [NEW] Listen for Game Reset to clear counters
workspace:GetAttributeChangedSignal("RequiredStations"):Connect(function()
	if not workspace:GetAttribute("RequiredStations") then
		CompletedStationsCount = 0
		initMap()
	end
end)
