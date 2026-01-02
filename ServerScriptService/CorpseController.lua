--[[
    CorpseController (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-01-02 03:27:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")

local CorpseController = {}
local EVENTS = ReplicatedStorage:WaitForChild("Events")
local BodyReportedEvent = EVENTS:WaitForChild("BodyReported")

-- 🦴 CONFIG
local RAGDOLL_DENSITY = 2.5 
local FLOOR_FRICTION = 2.0 
local FRICTION_WEIGHT = 100 

-- 🛠️ RIGGING FUNCTION
local function RigRagdoll(model)
	for _, descendant in pairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			local socket = Instance.new("BallSocketConstraint")
			local a1 = Instance.new("Attachment")
			local a2 = Instance.new("Attachment")

			a1.Parent = descendant.Part0
			a2.Parent = descendant.Part1
			socket.Parent = descendant.Parent
			socket.Attachment0 = a1
			socket.Attachment1 = a2

			a1.CFrame = descendant.C0
			a2.CFrame = descendant.C1

			-- 🔓 MOVEMENT LIMITS
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.UpperAngle = 45
			socket.TwistLowerAngle = -45
			socket.TwistUpperAngle = 45

			descendant:Destroy()
		end
	end
end

-- 💀 SPAWN FUNCTION
function CorpseController.Spawn(player)
	local char = player.Character
	if not char then return end

	char.Archivable = true
	local ragdoll = char:Clone()
	ragdoll.Name = "DeadBody"

	-- 1. SETUP THE SAFETY SLAB (Modified RootPart)
	-- Instead of deleting it, we use it as a physics anchor
	local root = ragdoll:FindFirstChild("HumanoidRootPart")
	if root then 
		root.Name = "CorpseSafetySlab"
		root.Transparency = 1
		root.CanCollide = true -- CRITICAL: This catches the body if limbs clip
		root.Anchored = false

		-- Resize to a flat plate inside the chest
		-- (2 studs wide, 0.5 studs tall, 1 stud deep)
		root.Size = Vector3.new(2, 0.5, 1) 

		-- Reset Velocity
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		-- Apply specific physics to the slab
		if _G.CollisionManager then 
			_G.CollisionManager.SetRagdoll(ragdoll) 
			-- Double check the slab specifically
			if root then root.CollisionGroup = "DeadBodyGroup" end
		else
			pcall(function() root.CollisionGroup = "DeadBodyGroup" end)
		end
	end

	-- 2. HUMANOID STATE (Stop the hover!)
	local hum = ragdoll:FindFirstChild("Humanoid")
	if hum then
		hum.PlatformStand = true
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		hum.HipHeight = 0 -- 🚨 FIX: Stops invisible hovering forces
		hum:ChangeState(Enum.HumanoidStateType.Physics)
	end

	-- 3. CLEANUP JUNK
	for _, child in pairs(ragdoll:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Highlight") or child:IsA("Animate") then
			child:Destroy()
		end
	end

	-- 4. APPLY PHYSICS TO LIMBS
	for _, part in pairs(ragdoll:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Keep collisions ON for everything except accessories
			if part.Name ~= "CorpseSafetySlab" then
				part.CanCollide = true 
				part.Massless = false
				part.Anchored = false

				part.CustomPhysicalProperties = PhysicalProperties.new(
					RAGDOLL_DENSITY, 
					FLOOR_FRICTION, 
					0, 
					FRICTION_WEIGHT, 
					1
				)

				-- Safety Group
				if _G.CollisionManager then 
					_G.CollisionManager.SetRagdoll(ragdoll) 
				else
					pcall(function() part.CollisionGroup = "DeadBodyGroup" end)
				end

				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end

		-- 👜 ACCESSORIES (Disable collisions to prevent explosions)
		if part.Parent:IsA("Accessory") then
			part.CanCollide = false
			part.Massless = true
		end
	end

	-- 5. RIG IT
	RigRagdoll(ragdoll)

	-- 6. VISUALS & PROMPT
	local highlight = Instance.new("Highlight")
	highlight.Name = "CorpseGlow"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0.2
	highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
	highlight.Parent = ragdoll

	-- Attach prompt to Torso or Slab
	local promptPart = ragdoll:FindFirstChild("UpperTorso") or ragdoll:FindFirstChild("Torso") or root
	if promptPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Report Body"
		prompt.ObjectText = player.Name
		prompt.HoldDuration = 0.5
		prompt.KeyboardKeyCode = Enum.KeyCode.R
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart

		prompt.Triggered:Connect(function(reporter)
			BodyReportedEvent:Fire(reporter)
		end)
	end

	-- 7. SPAWN
	ragdoll.Parent = workspace

	-- 8. ANTI-GRAVITY (Apply to the Slab for stability)
	if root then
		local att = Instance.new("Attachment", root)
		local antiGrav = Instance.new("VectorForce")
		antiGrav.Name = "AntiGravity"
		antiGrav.Attachment0 = att

		-- Calculate total mass
		local totalMass = 0
		for _, p in pairs(ragdoll:GetDescendants()) do
			if p:IsA("BasePart") then totalMass += p:GetMass() end
		end

		-- Float slightly to let limbs settle
		antiGrav.Force = Vector3.new(0, workspace.Gravity * totalMass, 0) 
		antiGrav.RelativeTo = Enum.ActuatorRelativeTo.World
		antiGrav.Parent = root

		task.delay(0.15, function()
			if antiGrav then antiGrav:Destroy() end
		end)
	end

	return ragdoll
end

function CorpseController.ClearAll()
	for _, child in pairs(workspace:GetChildren()) do
		if child.Name == "DeadBody" then
			child:Destroy()
		end
	end
end

_G.CorpseController = CorpseController

return CorpseController