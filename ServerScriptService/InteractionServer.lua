-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionServer (Server - GOLD MASTER)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Stations, Exits, Rescues (Mannequins), and Healing.
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local DataManager = require(game.ServerScriptService.DataManager)

-- Ensure remote exists
local InteractionRemote = ReplicatedStorage:FindFirstChild("InteractionEvent")
if not InteractionRemote then
	InteractionRemote = Instance.new("RemoteEvent")
	InteractionRemote.Name = "InteractionEvent"
	InteractionRemote.Parent = ReplicatedStorage
end

local MAX_DISTANCE = 12
local INTERACT_COOLDOWN = 0.5
local UNHOOK_SPEED_BOOST = 22 -- Rescue Strut speed

local playerCooldowns = {}
local playerActiveTasks = {} 

-- CONNECTIONS TO MANAGERS
local StationManagerFunc = ServerStorage:WaitForChild("StationManagerFunc", 10)
local ExitGateFunc = ServerStorage:WaitForChild("ExitGateFunc", 10)
local AddScoreBindable = ServerStorage:WaitForChild("AddScore", 10)

-- // HELPER: Rescue Logic (Mannequin)
local function attemptRescue(rescuer, mannequin)
	-- Find the Victim attached to this mannequin area
	local victim = nil
	for _, p in pairs(Players:GetPlayers()) do
		if p:GetAttribute("HealthState") == "Hooked" and p.Character then
			local dist = (p.Character.HumanoidRootPart.Position - mannequin.Position).Magnitude
			if dist < 10 then -- Generous check
				victim = p
				break
			end
		end
	end
	
	if victim then
		print("✨ " .. rescuer.Name .. " is rescuing " .. victim.Name)
		
		-- 1. Reset Victim State
		victim:SetAttribute("HealthState", "Injured")
		victim:SetAttribute("IsProtected", true) -- ENDURANCE
		
		-- 2. Free Victim Physics
		if victim.Character and victim.Character:FindFirstChild("HumanoidRootPart") then
			victim.Character.HumanoidRootPart.Anchored = false
			victim.Character.Humanoid.PlatformStand = false
		end
		
		-- 3. Rewards (Hero Bonus)
		DataManager:AdjustSpools(rescuer, 50) 
		if AddScoreBindable then AddScoreBindable:Fire(rescuer, "RESCUE", 50) end
		
		-- 4. Speed Boosts (Rescue Strut)
		local rescuerHum = rescuer.Character and rescuer.Character:FindFirstChild("Humanoid")
		local victimHum = victim.Character and victim.Character:FindFirstChild("Humanoid")
		
		if rescuerHum then rescuerHum.WalkSpeed = UNHOOK_SPEED_BOOST end
		if victimHum then victimHum.WalkSpeed = UNHOOK_SPEED_BOOST end
		
		task.delay(3, function()
			if rescuerHum then rescuerHum.WalkSpeed = 16 end
			if victimHum then victimHum.WalkSpeed = 16 end
			victim:SetAttribute("IsProtected", false)
		end)
		
		-- 5. VFX
		InteractionRemote:FireAllClients("RescueVFX", mannequin)
	end
end

-- // MAIN EVENT LISTENER
InteractionRemote.OnServerEvent:Connect(function(player, action, targetObject)
	if not targetObject or not targetObject:IsDescendantOf(workspace) then return end
	
	-- Cooldown & Dist Check
	local now = tick()
	if playerCooldowns[player.UserId] and (now - playerCooldowns[player.UserId]) < INTERACT_COOLDOWN then return end
	playerCooldowns[player.UserId] = now
	
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local targetPos = targetObject:IsA("Model") and targetObject:GetPivot().Position or targetObject.Position
	if (root.Position - targetPos).Magnitude > MAX_DISTANCE then return end

	-- /// ACTION HANDLER ///
	
	-- 1. START TASK (Stations & Gates)
	if action == "StartTask" then
		
		-- A. STATION
		if CollectionService:HasTag(targetObject, "Station") then
			if StationManagerFunc and StationManagerFunc:Invoke("Join", player, targetObject) then
				playerActiveTasks[player.UserId] = targetObject
				InteractionRemote:FireClient(player, "TaskStarted", targetObject)
			else
				InteractionRemote:FireClient(player, "TaskFailed", "Station Full")
			end
			
		-- B. EXIT GATE
		elseif CollectionService:HasTag(targetObject, "ExitGate") then
			if workspace:GetAttribute("ExitPowered") then
				playerActiveTasks[player.UserId] = targetObject
				InteractionRemote:FireClient(player, "TaskStarted", targetObject)
				
				-- Gate Progress Loop
				task.spawn(function()
					while playerActiveTasks[player.UserId] == targetObject do
						if ExitGateFunc then
							local done = ExitGateFunc:Invoke("Open", player, targetObject)
							if not done then break end
						end
						task.wait(0.5)
					end
				end)
			else
				InteractionRemote:FireClient(player, "TaskFailed", "Power Required")
			end
			
		-- C. RESCUE (Mannequin)
		elseif CollectionService:HasTag(targetObject, "MannequinStand") then
			attemptRescue(player, targetObject)
		end
		
	-- 2. STOP TASK
	elseif action == "StopTask" then
		local currentStation = playerActiveTasks[player.UserId]
		
		if currentStation then
			if CollectionService:HasTag(currentStation, "Station") and StationManagerFunc then
				StationManagerFunc:Invoke("Leave", player, currentStation)
			end
			playerActiveTasks[player.UserId] = nil
			InteractionRemote:FireClient(player, "TaskStopped")
		end

	-- 3. HEAL PLAYER (New Logic)
	elseif action == "HealPlayer" then
		local targetChar = targetObject
		local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
		
		if targetPlayer and targetPlayer:GetAttribute("HealthState") == "Injured" then
			playerActiveTasks[player.UserId] = targetChar
			InteractionRemote:FireClient(player, "TaskStarted", targetChar) -- Reuses Station Bar
			
			-- Healing Loop
			task.spawn(function()
				local progress = 0
				local needed = 10 -- 10 seconds base
				
				while playerActiveTasks[player.UserId] == targetChar do
					task.wait(0.2)
					
					-- Break conditions
					if (player.Character.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude > 8 then break end
					if targetPlayer:GetAttribute("HealthState") ~= "Injured" then break end -- Already healed
					
					progress += 0.2
					
					if progress >= needed then
						-- HEAL COMPLETE
						targetPlayer:SetAttribute("HealthState", "Healthy")
						InteractionRemote:FireAllClients("HealVFX", targetChar)
						
						if AddScoreBindable then AddScoreBindable:Fire(player, "RESCUE", 30) end -- Points!
						break
					end
				end
				
				playerActiveTasks[player.UserId] = nil
				InteractionRemote:FireClient(player, "TaskStopped")
			end)
		else
			InteractionRemote:FireClient(player, "TaskFailed", "Target Healthy")
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerActiveTasks[player.UserId] = nil 
	-- StationManager handles leave logic via its own bindable if needed
end)