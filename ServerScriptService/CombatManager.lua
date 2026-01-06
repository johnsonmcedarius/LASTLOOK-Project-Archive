-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: CombatManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Hitboxes, Damage, Carry, Hooking, and "Trend Forecast" Audio.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- CONFIG
local HITBOX_SIZE = Vector3.new(4, 5, 5) -- [UPDATED] Tighter box. No more "Lag Hits".
local HITBOX_OFFSET = CFrame.new(0, 0, -3) -- Pulled in slightly
local WINDUP_TIME = 0.5 
local ATTACK_COOLDOWN = 2.5 
local MISS_PENALTY_SPEED = 6 
local MISS_PENALTY_DURATION = 2

-- ANIMATIONS
local ANIM_CRAWL_ID = "rbxassetid://0" 

-- REMOTES
local CombatRemote = ReplicatedStorage:FindFirstChild("CombatEvent") or Instance.new("RemoteEvent")
CombatRemote.Name = "CombatEvent"
CombatRemote.Parent = ReplicatedStorage

-- // HELPER: Get/Set State
local function getState(player)
	return player:GetAttribute("HealthState") or "Healthy"
end

local function setState(player, newState)
	player:SetAttribute("HealthState", newState)
	print("🩸 Status Update: " .. player.Name .. " is now " .. newState)
end

-- // HELPER: Line of Sight (LoS) Check
-- [UPDATED] Added slight tolerance for corners
local function hasLineOfSight(saboteurChar, victimChar)
	local origin = saboteurChar.HumanoidRootPart.Position
	local target = victimChar.HumanoidRootPart.Position
	local direction = target - origin
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {saboteurChar, victimChar}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayResult = workspace:Raycast(origin, direction, rayParams)
	
	if rayResult then
		-- If we hit something, it's an obstacle
		return false 
	end
	
	return true 
end

-- // HELPER: Toggle Massless
local function setCharacterMassless(character, isMassless)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Massless = isMassless
			if isMassless then
				part.CanCollide = false
			else
				if part.Name == "HumanoidRootPart" then part.CanCollide = true end
			end
		end
	end
end

-- // FUNCTION: Carry Survivor
local function pickupSurvivor(saboteur, survivor)
	if getState(survivor) ~= "Downed" then return end
	
	local sabChar = saboteur.Character
	local survChar = survivor.Character
	
	if sabChar and survChar then
		setState(survivor, "Carried")
		setCharacterMassless(survChar, true)
		
		local root = survChar:FindFirstChild("HumanoidRootPart")
		local upperTorso = sabChar:FindFirstChild("UpperTorso") or sabChar:FindFirstChild("Torso")
		
		if root and upperTorso then
			survChar.Humanoid.PlatformStand = true 
			survChar.Humanoid.WalkSpeed = 0
			
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryWeld"
			weld.Part0 = upperTorso
			weld.Part1 = root
			root.CFrame = upperTorso.CFrame * CFrame.new(0, 0.5, 1) * CFrame.Angles(0, math.rad(90), 0)
			weld.Parent = upperTorso
			
			sabChar.Humanoid.WalkSpeed = 14
		end
	end
end

-- // FUNCTION: Hook Survivor
local function hookSurvivor(saboteur, mannequin)
	local sabChar = saboteur.Character
	local torso = sabChar:FindFirstChild("UpperTorso") or sabChar:FindFirstChild("Torso")
	local weld = torso:FindFirstChild("CarryWeld")
	
	if weld and weld.Part1 then
		local survivorRoot = weld.Part1
		local survivorChar = survivorRoot.Parent
		local survivorPlayer = Players:GetPlayerFromCharacter(survivorChar)
		
		if survivorPlayer then
			weld:Destroy()
			
			-- Snap to Mannequin
			survivorRoot.CFrame = mannequin.CFrame * CFrame.new(0, 2, -1)
			survivorRoot.Anchored = true
			
			setCharacterMassless(survivorChar, false)
			setState(survivorPlayer, "Hooked")
			
			-- Reset Saboteur
			sabChar.Humanoid.WalkSpeed = 16 
			
			CombatRemote:FireAllClients("UpdateHookUI", survivorPlayer)
		end
	end
end

-- // FUNCTION: Process Hit
local function processHit(saboteur, hitList)
	local hitSomething = false
	local sabChar = saboteur.Character
	
	for _, part in pairs(hitList) do
		local char = part.Parent
		local victim = Players:GetPlayerFromCharacter(char)
		
		if victim and victim ~= saboteur then
			if hasLineOfSight(sabChar, char) then
			
				local currentState = getState(victim)
				
				if currentState == "Healthy" then
					setState(victim, "Injured")
					hitSomething = true
					CombatRemote:FireAllClients("VFX_Injured", victim)
					
					-- [UPDATED] Trend Forecast Audio Trigger
					if saboteur:GetAttribute("TrendForecast") then
						CombatRemote:FireClient(victim, "PlaySound", "Heartbeat") -- Scary audio cue
					end
					
					break 
					
				elseif currentState == "Injured" then
					setState(victim, "Downed")
					hitSomething = true
					
					char.Humanoid.WalkSpeed = 4
					char.Humanoid.PlatformStand = false
					
					CombatRemote:FireAllClients("VFX_Downed", victim)
					break
				end
			end
		end
	end
	
	return hitSomething
end

-- // MAIN HANDLER
CombatRemote.OnServerEvent:Connect(function(player, action, data)
	local char = player.Character
	if not char then return end
	
	if action == "SwingShears" then
		if player:GetAttribute("IsAttacking") then return end
		player:SetAttribute("IsAttacking", true)
		
		task.wait(WINDUP_TIME)
		
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local boxCFrame = root.CFrame * HITBOX_OFFSET
			local overlapParams = OverlapParams.new()
			overlapParams.FilterDescendantsInstances = {char}
			overlapParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local partsInBox = workspace:GetPartBoundsInBox(boxCFrame, HITBOX_SIZE, overlapParams)
			local didHit = processHit(player, partsInBox)
			
			if not didHit then
				local hum = char:FindFirstChild("Humanoid")
				if hum then
					local oldSpeed = hum.WalkSpeed
					hum.WalkSpeed = MISS_PENALTY_SPEED
					task.delay(MISS_PENALTY_DURATION, function()
						hum.WalkSpeed = oldSpeed
					end)
				end
			end
		end
		
		task.wait(ATTACK_COOLDOWN - WINDUP_TIME)
		player:SetAttribute("IsAttacking", false)
		
	elseif action == "AttemptPickup" then
		if data and data:IsA("Model") then
			local survivor = Players:GetPlayerFromCharacter(data)
			if survivor then
				pickupSurvivor(player, survivor)
			end
		end
	
	elseif action == "AttemptHook" then
		if data and CollectionService:HasTag(data, "MannequinStand") then
			hookSurvivor(player, data)
		end
	end
end)
