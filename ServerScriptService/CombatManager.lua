-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: CombatManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Hitboxes (Box + Raycast), Damage, Massless Carry, and Hooking.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- CONFIG
local HITBOX_SIZE = Vector3.new(5, 6, 6) -- The "Generous" Box
local HITBOX_OFFSET = CFrame.new(0, 0, -3.5)
local WINDUP_TIME = 0.5 
local ATTACK_COOLDOWN = 2.5 
local MISS_PENALTY_SPEED = 6 
local MISS_PENALTY_DURATION = 2

-- ANIMATIONS (Server-side replication for critical states)
-- Replace with actual ID. If 0, it won't play.
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
-- Prevents hitting players through walls even if they are in the hitbox.
local function hasLineOfSight(saboteurChar, victimChar)
	local origin = saboteurChar.HumanoidRootPart.Position
	local target = victimChar.HumanoidRootPart.Position
	local direction = target - origin
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {saboteurChar, victimChar} -- Ignore people
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayResult = workspace:Raycast(origin, direction, rayParams)
	
	if rayResult then
		-- If we hit something, it's an obstacle (Wall/Prop)
		return false 
	end
	
	return true -- Clear shot
end

-- // HELPER: Toggle Massless (The "Heavy Survivor" Fix)
local function setCharacterMassless(character, isMassless)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Massless = isMassless
			if isMassless then
				part.CanCollide = false -- Extra safety to prevent floor clipping
			else
				-- Only restore collision to RootPart and Torso typically, but standard char is fine
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
		
		-- 1. Massless Fix
		setCharacterMassless(survChar, true)
		
		-- 2. Weld
		local root = survChar:FindFirstChild("HumanoidRootPart")
		local upperTorso = sabChar:FindFirstChild("UpperTorso") or sabChar:FindFirstChild("Torso")
		
		if root and upperTorso then
			survChar.Humanoid.PlatformStand = true 
			survChar.Humanoid.WalkSpeed = 0
			
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryWeld"
			weld.Part0 = upperTorso
			weld.Part1 = root
			-- Carry Pose: Over the shoulder
			root.CFrame = upperTorso.CFrame * CFrame.new(0, 0.5, 1) * CFrame.Angles(0, math.rad(90), 0)
			weld.Parent = upperTorso
			
			sabChar.Humanoid.WalkSpeed = 14 -- Carry weight penalty
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
			
			-- Restore Mass (Physics)
			setCharacterMassless(survivorChar, false)
			
			setState(survivorPlayer, "Hooked")
			
			-- Reset Saboteur
			sabChar.Humanoid.WalkSpeed = 16 
			
			-- Fire Event for UI (e.g., Update Survivor HUD)
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
			-- ⚡ LoS Check: Don't hit through walls
			if hasLineOfSight(sabChar, char) then
			
				local currentState = getState(victim)
				
				if currentState == "Healthy" then
					setState(victim, "Injured")
					hitSomething = true
					CombatRemote:FireAllClients("VFX_Injured", victim)
					break -- Single target hit
					
				elseif currentState == "Injured" then
					setState(victim, "Downed")
					hitSomething = true
					
					-- Downed Logic
					char.Humanoid.WalkSpeed = 4 -- Crawl speed
					char.Humanoid.PlatformStand = false
					
					-- Play Crawl Animation
					local animator = char.Humanoid:FindFirstChild("Animator")
					if animator and ANIM_CRAWL_ID ~= "rbxassetid://0" then
						local anim = Instance.new("Animation")
						anim.AnimationId = ANIM_CRAWL_ID
						local track = animator:LoadAnimation(anim)
						track.Priority = Enum.AnimationPriority.Movement
						track.Looped = true
						track:Play()
					end
					
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
	
	-- 1. ATTACK REQUEST
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
				-- Miss Penalty
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
		
	-- 2. INTERACT REQUEST (Pick Up)
	elseif action == "AttemptPickup" then
		if data and data:IsA("Model") then
			local survivor = Players:GetPlayerFromCharacter(data)
			if survivor then
				pickupSurvivor(player, survivor)
			end
		end
	
	-- 3. INTERACT REQUEST (Hook)
	elseif action == "AttemptHook" then
		-- ⚡ Tag Consistency Fix: Check Tag, not Name
		if data and CollectionService:HasTag(data, "MannequinStand") then
			hookSurvivor(player, data)
		end
	end
end)