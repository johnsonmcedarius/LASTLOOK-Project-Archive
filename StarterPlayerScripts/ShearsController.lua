-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShearsController (Client - LUNGE & WALL HIT)
-- 🛠️ AUTH: Coding Partner
-- 💡 DESC: Detects hits, handles Lunge physics, Wall Clanking, and Trails.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local CombatRemote = ReplicatedStorage:WaitForChild("CombatEvent")

local canSwing = true
local LUNGE_FORCE = 60 -- Adjust for how far you want them to fly
local WALL_HIT_DIST = 4

-- SOUNDS (Replace IDs)
local SWING_SOUND = "rbxassetid://12222216" -- Swoosh
local CLANK_SOUND = "rbxassetid://12222200" -- Metal Hit
local HIT_SOUND = "rbxassetid://12221967"   -- Flesh Hit

local function playSound(id, pos)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 1
	sound.Parent = Player.Character.HumanoidRootPart
	sound:Play()
	Debris:AddItem(sound, 2)
end

local function performAttack(actionName, inputState)
	if inputState == Enum.UserInputState.Begin and canSwing then
		local char = Player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")
		local tool = char:FindFirstChildOfClass("Tool") -- The Shears
		
		-- Only attack if holding shears
		if not tool or tool.Name ~= "Shears" then return end
		
		canSwing = false
		
		-- 1. WALL DETECTION (The Clank)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {char}
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local rayOrigin = root.Position
		local rayDir = root.CFrame.LookVector * WALL_HIT_DIST
		
		local wallHit = workspace:Raycast(rayOrigin, rayDir, rayParams)
		
		if wallHit and wallHit.Instance.CanCollide then
			-- HIT A WALL!
			playSound(CLANK_SOUND)
			
			-- Stun Animation (Optional: Camera Shake)
			-- hum.WalkSpeed = 2 -- Slow them down briefly
			
			task.wait(1.5) -- Penalty Cooldown
			-- hum.WalkSpeed = 24 -- Reset speed (handled by SprintScript usually)
			canSwing = true
			return
		end
		
		-- 2. LUNGE (The Chase Closer)
		-- Apply an impulse forward
		root:ApplyImpulse(root.CFrame.LookVector * LUNGE_FORCE * root.AssemblyMass)
		
		-- 3. TRAIL (The Swoosh)
		-- We look recursively in case the Trail is inside the Handle
		local trail = tool:FindFirstChild("Trail", true) 
		if trail then
			trail.Enabled = true
			task.delay(0.3, function() trail.Enabled = false end)
		else
			warn("⚠️ Trail not found in Shears! Check setup.") -- Added debug warning
		end
		
		playSound(SWING_SOUND)
		
		-- 4. HITBOX (Overlap)
		local hitParams = OverlapParams.new()
		hitParams.FilterDescendantsInstances = {char}
		hitParams.FilterType = Enum.RaycastFilterType.Exclude
		
		-- Box offset forward by 3 studs
		local hits = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0,0,-3), Vector3.new(5,5,5), hitParams)
		
		for _, part in pairs(hits) do
			local h = part.Parent:FindFirstChild("Humanoid")
			if h then
				local victim = Players:GetPlayerFromCharacter(part.Parent)
				if victim and victim ~= Player then
					CombatRemote:FireServer("Hit", victim)
					playSound(HIT_SOUND)
					break 
				end
			end
		end
		
		-- 5. ANIMATION
		-- local animator = hum:FindFirstChild("Animator")
		-- local track = animator:LoadAnimation(AnimationObj)
		-- track:Play()
		
		task.wait(1.5) -- Attack Speed Cooldown
		canSwing = true
	end
end

ContextActionService:BindAction("Attack", performAttack, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
