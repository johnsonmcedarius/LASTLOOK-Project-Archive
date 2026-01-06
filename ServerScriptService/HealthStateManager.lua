-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: HealthStateManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles "Hooked" decay and Anti-Camp Proximity Logic.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- CONFIG
local HOOK_DURATION = 60 -- Seconds to die on hook
local CAMP_RADIUS = 15 -- Studs
local CAMP_SLOWDOWN = 0.5 -- 50% slower decay if camped
local TICK_RATE = 1 -- Update every second

-- EVENTS
local CombatRemote = ReplicatedStorage:FindFirstChild("CombatEvent")

-- STATE
local lastTick = 0

-- // HELPER: Find Saboteur
local function findSaboteur()
	for _, p in pairs(Players:GetPlayers()) do
		if p:GetAttribute("Role") == "Saboteur" then
			return p
		end
	end
	return nil
end

-- // CORE LOOP
RunService.Heartbeat:Connect(function(dt)
	lastTick += dt
	if lastTick < TICK_RATE then return end
	lastTick = 0
	
	local saboteur = findSaboteur()
	local sabPos = nil
	if saboteur and saboteur.Character and saboteur.Character:FindFirstChild("HumanoidRootPart") then
		sabPos = saboteur.Character.HumanoidRootPart.Position
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		-- Only process Hooked players
		if player:GetAttribute("HealthState") == "Hooked" then
			
			local currentHP = player:GetAttribute("HookHealth") or HOOK_DURATION
			local decay = 1
			
			-- ANTI-CAMP LOGIC
			if sabPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (player.Character.HumanoidRootPart.Position - sabPos).Magnitude
				if dist < CAMP_RADIUS then
					decay = CAMP_SLOWDOWN
					-- Optional: Visual feedback for "Anti-Camp Active"
					-- player:SetAttribute("CampProtection", true)
				else
					-- player:SetAttribute("CampProtection", false)
				end
			end
			
			-- Apply Decay
			currentHP -= decay
			player:SetAttribute("HookHealth", currentHP)
			
			-- Check Death
			if currentHP <= 0 then
				player:SetAttribute("HealthState", "Scrapped")
				print("💀 " .. player.Name .. " has been Scrapped (Time Out).")
				
				if CombatRemote then
					CombatRemote:FireAllClients("VFX_Scrapped", player)
				end
				
				-- Hide body / Spectate logic handled by client
				if player.Character then
					player.Character:PivotTo(CFrame.new(0, -500, 0)) -- Grave
				end
			end
		else
			-- Reset health if not hooked so it's fresh for next time
			if player:GetAttribute("HealthState") == "Healthy" then
				player:SetAttribute("HookHealth", HOOK_DURATION)
			end
		end
	end
end)