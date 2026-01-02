--[[
    TaskSystem (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage") 
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULES
local corpseScript = ServerScriptService:WaitForChild("CorpseController")
local CorpseController = require(corpseScript)

-- CONFIG
local TASK_FOLDER = workspace:WaitForChild("TaskNodes")
local COOLDOWN_TIME = 20 
local SABOTAGE_TIMEOUT = 45 

-- EVENTS & VALUES
local Values = ReplicatedStorage:WaitForChild("Values")
local TaskProgress = Values:WaitForChild("TaskProgress")
local GameState = Values:WaitForChild("GameState")

local Events = ReplicatedStorage:WaitForChild("Events")
local TaskCompletedEvent = Events:WaitForChild("TaskCompleted")
local TaskFailedEvent = Events:WaitForChild("TaskFailed")

-- Server Internal
local ServerEvents = ServerStorage:FindFirstChild("Events") or Instance.new("Folder", ServerStorage)
ServerEvents.Name = "Events"
local AddChaosBindable = ServerEvents:FindFirstChild("AddChaos") or Instance.new("BindableEvent", ServerEvents)
AddChaosBindable.Name = "AddChaos"

local function Log(msg) print("🔧 [TASK SYS] " .. msg) end

-- ☠️ DEATH LOGIC
local function KillPlayer(player, cause)
	if not player.Character then return end
	if player:GetAttribute("IsDead") then return end

	Log("💀 " .. player.Name .. " died by: " .. cause)
	CorpseController.Spawn(player)
	player:SetAttribute("IsDead", true)
	player:SetAttribute("Role", "Ghost")

	local char = player.Character
	if char then
		if _G.CollisionManager then _G.CollisionManager.SetGhost(char) end
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Massless = true
				part.CanCollide = true 
				if part.Name == "HumanoidRootPart" then part.Transparency = 1 end
			end
		end
	end
end

-- 1️⃣ SABOTAGE TRIGGER
local function OnSabotage(player, prompt, part)
	-- 🛑 STATE CHECK (Prevents premature interaction)
	if GameState.Value ~= "Playing" then return end
	if player:GetAttribute("IsDead") then return end
	if player:GetAttribute("Role") ~= "Saboteur" then return end

	-- Apply Trap
	part:SetAttribute("IsTrapped", true)

	-- Disable Sabotage Prompt (Cooldown)
	prompt.Enabled = false 

	-- Note: We do NOT touch InteractionPrompt.Enabled here on Server.
	-- The Client script handles visibility. We just need it to be interactable physically.

	Log("😈 " .. player.Name .. " RIGGED " .. part.Name)

	-- Reset Sabotage availability later
	task.delay(10, function()
		prompt.Enabled = true
	end)

	-- Chaos Timeout
	local sabotageId = os.time()
	part:SetAttribute("SabotageID", sabotageId)

	task.delay(SABOTAGE_TIMEOUT, function()
		if part:GetAttribute("IsTrapped") == true and part:GetAttribute("SabotageID") == sabotageId then
			Log("💥 SABOTAGE TIMEOUT! " .. part.Name .. " caused chaos.")
			AddChaosBindable:Fire(15, "Ignored Sabotage: " .. part.Name)
			part:SetAttribute("IsTrapped", false)
		end
	end)
end

-- 2️⃣ TASK COMPLETION
TaskCompletedEvent.OnServerEvent:Connect(function(player, taskNode)
	if GameState.Value ~= "Playing" then return end -- 🛑 LOCK
	if player:GetAttribute("IsDead") then return end

	-- Distance Check
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if (root.Position - taskNode.PrimaryPart.Position).Magnitude > 25 then return end

	-- 💣 TRAP CHECK
	if taskNode:GetAttribute("IsTrapped") == true then
		KillPlayer(player, "Sabotaged " .. taskNode.Name)
		taskNode:SetAttribute("IsTrapped", false)
		taskNode.Color = Color3.fromRGB(0, 100, 255)
		return
	end

	-- SUCCESS
	Log(player.Name .. " COMPLETED " .. taskNode.Name)
	TaskProgress.Value += 1
	taskNode.Color = Color3.fromRGB(0, 255, 0) 

	-- Cooldown logic (Locally disable task prompt)
	local prompt = taskNode:FindFirstChild("InteractionPrompt")
	if prompt then prompt.Enabled = false end

	task.delay(COOLDOWN_TIME, function()
		if prompt then prompt.Enabled = true end
		taskNode.Color = Color3.fromRGB(0, 100, 255)
	end)
end)

-- 3️⃣ TASK FAILURE
TaskFailedEvent.OnServerEvent:Connect(function(player, taskNode)
	if GameState.Value ~= "Playing" then return end
	if player:GetAttribute("IsDead") then return end

	if taskNode:GetAttribute("IsTrapped") == true then
		KillPlayer(player, "Failed Sabotage Repair: " .. taskNode.Name)
		taskNode:SetAttribute("IsTrapped", false)
	end
end)

-- 4️⃣ SETUP
local function SetupTasks()
	for _, taskNode in pairs(TASK_FOLDER:GetChildren()) do
		local sabPrompt = taskNode:FindFirstChild("SabotagePrompt")
		if sabPrompt then
			sabPrompt.Triggered:Connect(function(plr) OnSabotage(plr, sabPrompt, taskNode) end)
		end
	end
end

SetupTasks()