--[[
    TaskSystem (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 14:59:28
]]
-- ServerScriptService/TaskSystem
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage") 
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULES
local corpseScript = ServerScriptService:WaitForChild("CorpseController")
if not corpseScript:IsA("ModuleScript") then
	error("🚨 SETUP ERROR: 'CorpseController' must be a ModuleScript!")
end
local CorpseController = require(corpseScript)

-- CONFIG
local TASK_FOLDER = workspace:WaitForChild("TaskNodes")
local COOLDOWN_TIME = 20 
local SABOTAGE_TIMEOUT = 45 

-- EVENTS & VALUES
local Values = ReplicatedStorage:WaitForChild("Values")
local TaskProgress = Values:WaitForChild("TaskProgress")
local GameState = Values:WaitForChild("GameState")

-- AUTO-CREATE EVENTS
local function GetRemote(name)
	local folder = ReplicatedStorage:FindFirstChild("Events")
	if not folder then folder = Instance.new("Folder", ReplicatedStorage); folder.Name = "Events" end
	local e = folder:FindFirstChild(name)
	if not e then e = Instance.new("RemoteEvent", folder); e.Name = name end
	return e
end

local TaskCompletedEvent = GetRemote("TaskCompleted")
local TaskFailedEvent = GetRemote("TaskFailed")
local SabotageSuccessEvent = GetRemote("SabotageSuccess")

-- Server Internal Events
local ServerEvents = ServerStorage:FindFirstChild("Events") or Instance.new("Folder", ServerStorage)
ServerEvents.Name = "Events"
local AddChaosBindable = ServerEvents:FindFirstChild("AddChaos") or Instance.new("BindableEvent", ServerEvents)
AddChaosBindable.Name = "AddChaos"

local function Log(msg) print("🔧 [TASK SYS] " .. msg) end

-- 🛡️ HELPER: UNIVERSAL POSITION CHECK (The Fix)
local function GetNodePosition(node)
	if node:IsA("Model") then
		if node.PrimaryPart then return node.PrimaryPart.Position end
		return node:GetPivot().Position -- Fallback for models without PrimaryPart
	elseif node:IsA("BasePart") then
		return node.Position
	end
	return Vector3.new(0,0,0) -- Fail safe
end

-- ☠️ DEATH
local function KillPlayer(player, cause)
	if not player.Character then return end
	if player:GetAttribute("IsDead") then return end

	Log("💀 " .. player.Name .. " died by: " .. cause)

	-- 1. Spawn Visual Corpse
	CorpseController.Spawn(player)

	-- 2. Update Attributes
	player:SetAttribute("IsDead", true)
	player:SetAttribute("Role", "Ghost")

	-- 3. ACTUAL DEATH
	local hum = player.Character:FindFirstChild("Humanoid")
	if hum then hum.Health = 0 end
end

-- 1️⃣ SABOTAGE SUCCESS (Saboteur Wins Minigame)
SabotageSuccessEvent.OnServerEvent:Connect(function(player, taskNode)
	if player:GetAttribute("Role") ~= "Saboteur" then return end
	if GameState.Value ~= "Playing" then return end

	-- Arm the Trap
	taskNode:SetAttribute("IsTrapped", true)
	Log("😈 " .. player.Name .. " SABOTAGED " .. taskNode.Name)

	-- 🚨 FIX: Force Enable the Designer Prompt immediately
	local prompt = taskNode:FindFirstChild("InteractionPrompt")
	if prompt then 
		prompt.Enabled = true 
	end

	-- Disable Sabotage Prompt (Cooldown for bad guy)
	local sabPrompt = taskNode:FindFirstChild("SabotagePrompt")
	if sabPrompt then 
		sabPrompt.Enabled = false 
		task.delay(10, function() sabPrompt.Enabled = true end)
	end

	-- 📉 CHAOS TIMER
	local sabotageId = os.time()
	taskNode:SetAttribute("SabotageID", sabotageId)

	task.delay(SABOTAGE_TIMEOUT, function()
		if taskNode:GetAttribute("IsTrapped") == true and taskNode:GetAttribute("SabotageID") == sabotageId then
			Log("💥 SABOTAGE TIMEOUT! " .. taskNode.Name .. " caused chaos.")
			AddChaosBindable:Fire(15, "Ignored Sabotage: " .. taskNode.Name)
		end
	end)
end)

-- 2️⃣ TASK COMPLETED (Designer Wins Minigame)
TaskCompletedEvent.OnServerEvent:Connect(function(player, taskNode)
	if GameState.Value ~= "Playing" then return end
	if player:GetAttribute("IsDead") then return end

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- 🛡️ FIX: Use Safe Position Check
	local nodePos = GetNodePosition(taskNode)
	if (root.Position - nodePos).Magnitude > 25 then
		warn("⚠️ " .. player.Name .. " too far from task!")
		return 
	end

	-- 💣 TRAP CHECK (Disarm Logic)
	if taskNode:GetAttribute("IsTrapped") == true then
		Log("🔧 " .. player.Name .. " DISARMED " .. taskNode.Name)
		taskNode:SetAttribute("IsTrapped", false)
		return
	end

	-- ✅ NORMAL SUCCESS
	Log(player.Name .. " COMPLETED " .. taskNode.Name)
	TaskProgress.Value += 1
	taskNode.Color = Color3.fromRGB(0, 255, 0) 

	-- Cooldown Logic
	local prompt = taskNode:FindFirstChild("InteractionPrompt")
	local sabPrompt = taskNode:FindFirstChild("SabotagePrompt")

	if prompt then prompt.Enabled = false end
	if sabPrompt then sabPrompt.Enabled = false end 

	task.delay(COOLDOWN_TIME, function()
		if prompt then prompt.Enabled = true end
		if sabPrompt then sabPrompt.Enabled = true end
		taskNode.Color = Color3.fromRGB(0, 100, 255) 
	end)
end)

-- 3️⃣ TASK FAILED (Client lost minigame)
TaskFailedEvent.OnServerEvent:Connect(function(player, taskNode)
	if GameState.Value ~= "Playing" then return end
	if player:GetAttribute("IsDead") then return end

	-- 💀 LETHAL TRAP CHECK
	if taskNode:GetAttribute("IsTrapped") == true then
		taskNode:SetAttribute("IsTrapped", false) -- Trap consumes the victim

		task.wait(1.5) 
		KillPlayer(player, "Failed Sabotage Repair: " .. taskNode.Name)
	end
end)

-- 4️⃣ INIT
local function SetupTasks()
	-- Just validation, events handle interaction
	print("✅ Task System Loaded")
end

SetupTasks()