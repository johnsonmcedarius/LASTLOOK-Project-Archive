-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ExitGateManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Manages Exit Gate Logic, Opening Timers, and Escapes.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local BalanceConfig = require(ReplicatedStorage.Modules.BalanceConfig)
local DataManager = require(game.ServerScriptService.DataManager)

-- CONFIG
local GATE_OPEN_TIME = 15 -- Seconds
local SKILL_CHECK_THRESHOLD = 0.5 -- 50% progress triggers skill check (logic placeholder)

-- EVENTS
local GlobalPowerRemote = ReplicatedStorage:WaitForChild("GlobalPowerEvent")
local GateUpdateRemote = Instance.new("RemoteEvent")
GateUpdateRemote.Name = "GateUpdateEvent"
GateUpdateRemote.Parent = ReplicatedStorage

-- STATE
local areGatesPowered = false
local GateStates = {} -- [Model] = {Progress = 0, IsOpen = false}

-- // HELPER: Setup Gate
local function setupGate(gateModel)
	GateStates[gateModel] = {Progress = 0, IsOpen = false}
	gateModel:SetAttribute("CurrentProgress", 0)
	gateModel:SetAttribute("WorkRequired", GATE_OPEN_TIME)
	
	-- Setup Escape Zone (Win Trigger)
	local winZone = gateModel:FindFirstChild("WinZone")
	if winZone then
		winZone.Touched:Connect(function(hit)
			if not GateStates[gateModel].IsOpen then return end
			
			local char = hit.Parent
			local player = Players:GetPlayerFromCharacter(char)
			
			if player and not player:GetAttribute("Escaped") then
				player:SetAttribute("Escaped", true)
				print("✨ " .. player.Name .. " HAS ESCAPED THE ATELIER!")
				
				-- Award Spools (Win Bonus)
				DataManager:AdjustSpools(player, 150)
				
				-- Hide Character (or move to spectator box)
				char:PivotTo(CFrame.new(0, 5000, 0)) -- Yeet them away for now
				
				-- Fire UI Event (Win Screen)
				-- WinRemote:FireClient(player)
			end
		end)
	else
		warn("⚠️ Exit Gate " .. gateModel.Name .. " is missing a 'WinZone' part!")
	end
end

-- // HELPER: Open The Gate (Visuals)
local function openGate(gateModel)
	GateStates[gateModel].IsOpen = true
	gateModel:SetAttribute("IsOpen", true)
	
	-- Play Animation / Tween Door
	local door = gateModel:FindFirstChild("Door")
	if door then
		-- Slide door up or open
		local goal = {CFrame = door.CFrame * CFrame.new(0, 10, 0)} -- Slide Up 10 studs
		local info = TweenInfo.new(2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
		TweenService:Create(door, info, goal):Play()
	end
	
	print("🚪 GATE OPENED: " .. gateModel.Name)
end

-- // LISTENER: Global Power (Runway Reveal)
GlobalPowerRemote.OnServerEvent:Connect(function(completed, total)
	-- Note: This is usually fired by Client? Wait, StationManager fires FireAllClients.
	-- We need an internal Bindable or just listen to the Attribute on Workspace.
end)

-- Better approach: Listen to workspace attribute set by StationManager
workspace:GetAttributeChangedSignal("ExitPowered"):Connect(function()
	if workspace:GetAttribute("ExitPowered") then
		areGatesPowered = true
		print("🔌 GATES POWERED. PULL THE LEVER!")
		-- Maybe turn on Red lights on the switch?
	end
end)

-- // EXPOSED FUNCTION: Process Lever Pull
-- Called by InteractionServer
local ExitBindable = Instance.new("BindableFunction")
ExitBindable.Name = "ExitGateFunc"
ExitBindable.Parent = game.ServerStorage

function ExitBindable.OnInvoke(action, player, gateModel)
	if not areGatesPowered then return false end
	if GateStates[gateModel].IsOpen then return false end
	
	if action == "Open" then
		-- Add Progress
		local state = GateStates[gateModel]
		local progressStep = 1 -- 1 second per tick (Logic handled in Interaction loop ideally, but for now simple increment)
		
		-- NOTE: Ideally, InteractionServer should handle the "Holding" loop. 
		-- Since we are doing a "click to toggle" or "hold" interaction, let's assume hold.
		-- For this alpha, we'll increment progress here.
		
		state.Progress = math.min(state.Progress + 0.5, GATE_OPEN_TIME) -- Called every ~0.5s
		gateModel:SetAttribute("CurrentProgress", state.Progress)
		
		if state.Progress >= GATE_OPEN_TIME then
			openGate(gateModel)
		end
		
		return true
	end
	return false
end

-- Init
for _, gate in pairs(CollectionService:GetTagged("ExitGate")) do
	setupGate(gate)
end
CollectionService:GetInstanceAddedSignal("ExitGate"):Connect(setupGate)