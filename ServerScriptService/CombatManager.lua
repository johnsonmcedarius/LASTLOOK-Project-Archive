-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: CombatManager (Server - TRUSTED CLIENT)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Validates client hits. Applies "Hit Stop" freeze.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local CombatRemote = ReplicatedStorage:FindFirstChild("CombatEvent") or Instance.new("RemoteEvent")
CombatRemote.Name = "CombatEvent"
CombatRemote.Parent = ReplicatedStorage

local MAX_HIT_DIST = 10 -- Generous for lag, strictly checked
local ATTACK_COOLDOWN = 2

local function applyHitStop(killer)
	if killer.Character and killer.Character.PrimaryPart then
		killer.Character.PrimaryPart.Anchored = true
		task.wait(0.15) -- The "Crunch" feel
		killer.Character.PrimaryPart.Anchored = false
	end
end

CombatRemote.OnServerEvent:Connect(function(player, action, target)
	-- // HIT VALIDATION
	if action == "Hit" then
		if player:GetAttribute("Role") ~= "Saboteur" then return end
		
		-- 1. Cooldown Check
		local lastAtk = player:GetAttribute("LastAttack") or 0
		if (os.clock() - lastAtk) < ATTACK_COOLDOWN then return end
		player:SetAttribute("LastAttack", os.clock())
		
		-- 2. Target Check
		local victim = target
		if not victim or not victim:IsA("Player") then return end
		
		local pChar = player.Character
		local vChar = victim.Character
		if not pChar or not vChar then return end
		
		-- 3. Distance Check (Sanity)
		local dist = (pChar.PrimaryPart.Position - vChar.PrimaryPart.Position).Magnitude
		if dist > MAX_HIT_DIST then 
			warn("🚨 SUSPICIOUS HIT: " .. player.Name .. " hit from " .. dist .. " studs.")
			return 
		end
		
		-- 4. Apply Damage
		local currentState = victim:GetAttribute("HealthState")
		local isExposed = victim:GetAttribute("IsExposed") == true
		
		local newState = "Injured"
		if currentState == "Injured" or isExposed then
			newState = "Downed"
		end
		
		victim:SetAttribute("HealthState", newState)
		
		-- 5. Effects
		applyHitStop(player)
		CombatRemote:FireAllClients("VFX_Hit", victim, newState)
		
		-- Speed Boost for Victim (Mercy)
		victim:SetAttribute("StatusEffect", "SpeedBoost")
		task.delay(3, function() victim:SetAttribute("StatusEffect", nil) end)
	end
end)
