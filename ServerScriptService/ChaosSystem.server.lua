--[[
    ChaosSystem (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 14:59:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

print("📉 [SERVER] Chaos System Initializing...")

-- ============================================================================
-- 1. SETUP & SAFETY CHECKS
-- ============================================================================

-- Ensure Events Folder Exists
local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
	Events = Instance.new("Folder", ReplicatedStorage)
	Events.Name = "Events"
end

-- Ensure RemoteEvents Exist
local function GetEvent(name)
	local e = Events:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent", Events)
		e.Name = name
	end
	return e
end

local TaskFailedEvent = GetEvent("TaskFailed")
local MuseFreezeEvent = GetEvent("MuseFreeze")
local GhostActionEvent = GetEvent("GhostAction")

-- Ensure Values Exist
local Values = ReplicatedStorage:WaitForChild("Values")
local ChaosLevel = Values:WaitForChild("ChaosLevel")
local ChaosFrozen = Values:WaitForChild("ChaosFrozen")
local GameState = Values:WaitForChild("GameState")
local Status = Values:WaitForChild("Status")

-- ============================================================================
-- 2. CONFIGURATION
-- ============================================================================

local MAX_CHAOS = 100
local PASSIVE_TICK_RATE = 20
local PASSIVE_AMOUNT = 1

-- Penalties
local FAIL_PENALTY = 5      -- Failing a minigame
local DEATH_PENALTY = 15    -- Designer dying

-- Ghost Buffs
local GHOST_CLEANUP = -2    -- Ghost reducing chaos
local MUSE_FREEZE_TIME = 30 -- Seconds to pause chaos

-- Anti-Spam (Debounce)
local chaosCooldowns = {} 

-- ============================================================================
-- 3. CORE LOGIC
-- ============================================================================

-- The Main Function to Change Chaos
local function AddChaos(amount, reason)
	-- 1. Game State Check
	if GameState.Value ~= "Playing" then 
		-- Ignore chaos changes during Lobby/Meetings
		return 
	end

	-- 2. Muse Protection (Only blocks POSITIVE chaos)
	if ChaosFrozen.Value == true and amount > 0 then 
		print("🛡️ CHAOS BLOCKED BY MUSE! (" .. reason .. ")")
		return 
	end

	-- 3. Apply Math
	local oldVal = ChaosLevel.Value
	local newVal = math.clamp(oldVal + amount, 0, MAX_CHAOS)

	-- Optimization: Don't update if no change
	if newVal == oldVal and amount > 0 then return end 

	ChaosLevel.Value = newVal

	-- Logging
	local symbol = amount > 0 and "🔺" or "🔻"
	print(symbol .. " CHAOS: " .. math.floor(newVal) .. "% [" .. reason .. "]")

	-- 4. Check Loss Condition
	if newVal >= MAX_CHAOS then
		print("💀 MAX CHAOS REACHED! GAME OVER.")
		GameState.Value = "GameOver"
		Status.Value = "THE HOUSE COLLAPSED. CHAOS WINS."
	end
end

-- Function to Activate Muse Freeze
local function TriggerMuseFreeze(player)
	if ChaosFrozen.Value then return end -- Already frozen

	ChaosFrozen.Value = true
	print("✨ MUSE INTERVENTION by " .. player.Name)

	-- Optional: Send a visual alert to all clients here

	task.delay(MUSE_FREEZE_TIME, function()
		if GameState.Value == "Playing" then
			ChaosFrozen.Value = false
			print("❄️ Muse Effect Ended. Chaos resuming.")
		end
	end)
end

-- ============================================================================
-- 4. EVENT LISTENERS
-- ============================================================================

-- A. Internal Calls (Sabotage Timeout, etc)
task.spawn(function()
	local ServerEvents = ServerStorage:WaitForChild("Events", 5)
	if ServerEvents then
		local AddChaosBindable = ServerEvents:WaitForChild("AddChaos", 5)
		if AddChaosBindable then
			AddChaosBindable.Event:Connect(AddChaos)
			print("✅ Chaos Bindable Connected")
		end
	end
end)

-- B. Task Failures (From Minigames) - 🛡️ STRICT DEBOUNCE
TaskFailedEvent.OnServerEvent:Connect(function(player)
	local t = os.clock()
	local lastFail = chaosCooldowns[player.UserId] or 0

	-- If failed less than 2.5 seconds ago, IGNORE.
	if (t - lastFail) < 2.5 then
		warn("🛡️ Spam blocked from " .. player.Name)
		return
	end

	chaosCooldowns[player.UserId] = t
	AddChaos(FAIL_PENALTY, "Task Failed by " .. player.Name)
end)

-- C. Ghost Actions (Clean Up / Muse)
GhostActionEvent.OnServerEvent:Connect(function(player, actionType)
	-- Security: Must actually be dead
	if not player:GetAttribute("IsDead") then 
		warn("⚠️ Living player " .. player.Name .. " tried to use Ghost Actions!")
		return 
	end

	if actionType == "CleanUp" then
		AddChaos(GHOST_CLEANUP, "Ghost Assist: " .. player.Name)

	elseif actionType == "MuseFreeze" then
		TriggerMuseFreeze(player)
	end
end)

-- D. Player Deaths
Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("IsDead"):Connect(function()
		-- Only count death if they JUST died and game is playing
		if player:GetAttribute("IsDead") == true and GameState.Value == "Playing" then
			AddChaos(DEATH_PENALTY, "Designer Cut: " .. player.Name)
		end
	end)
end)

-- E. Muse Ability (Legacy Event Support)
MuseFreezeEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("Role") == "Ghost" or player:GetAttribute("IsDead") then
		TriggerMuseFreeze(player)
	end
end)

-- ============================================================================
-- 5. LOOPS & RESETS
-- ============================================================================

-- Passive Panic Loop (Ticks up every 20s)
task.spawn(function()
	while true do
		task.wait(PASSIVE_TICK_RATE)
		if GameState.Value == "Playing" and not ChaosFrozen.Value then
			AddChaos(PASSIVE_AMOUNT, "Passive Panic")
		end
	end
end)

-- Reset on Lobby
GameState.Changed:Connect(function(newState)
	if newState == "Lobby" or newState == "Intermission" then
		ChaosLevel.Value = 0
		ChaosFrozen.Value = false
		chaosCooldowns = {} -- Clear spam filters
		print("🔄 Chaos System Reset for New Round")
	end
end)

print("✅ Chaos System Live.")