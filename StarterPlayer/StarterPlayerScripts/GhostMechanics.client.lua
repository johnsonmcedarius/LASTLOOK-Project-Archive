--[[
    GhostMechanics (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local character = nil
local humanoid = nil
local rootPart = nil

-- MOVEMENT OBJECTS
local mover = nil -- LinearVelocity
local aligner = nil -- AlignOrientation
local attachment = nil

-- CONFIG
local FLIGHT_SPEED = 40 -- Increased slightly for better feel
local TURN_SPEED = 20

-- STATE
local IS_GHOST = false

-- 👻 VISUALS (Keep this same as yours)
local function ApplyGhostVisuals()
	if not character then return end

	-- 1. Apply Transparency
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "HumanoidRootPart" then
				part.Transparency = 1
			else
				part.Transparency = 0.6
				part.Material = Enum.Material.ForceField
				part.CastShadow = false
			end
			-- We KEEP CanCollide true on the parts, 
			-- so the CollisionGroup in ServerScriptService can do its job!
			part.CanCollide = true 
		elseif part:IsA("Accessory") then
			local handle = part:FindFirstChild("Handle")
			if handle then 
				handle.Transparency = 0.6 
				handle.Material = Enum.Material.ForceField
			end
		end
	end
end

-- 🛠️ SETUP PHYSICS MOVERS
local function SetupMovers()
	if not rootPart then return end

	-- Destroy old ones if they exist
	if rootPart:FindFirstChild("GhostMover") then rootPart.GhostMover:Destroy() end
	if rootPart:FindFirstChild("GhostAligner") then rootPart.GhostAligner:Destroy() end
	if rootPart:FindFirstChild("GhostAtt") then rootPart.GhostAtt:Destroy() end

	-- Create Attachment
	attachment = Instance.new("Attachment")
	attachment.Name = "GhostAtt"
	attachment.Parent = rootPart

	-- LinearVelocity (Moves us)
	mover = Instance.new("LinearVelocity")
	mover.Name = "GhostMover"
	mover.MaxForce = math.huge
	mover.VectorVelocity = Vector3.zero
	mover.Attachment0 = attachment
	mover.Parent = rootPart

	-- AlignOrientation (Turns us)
	aligner = Instance.new("AlignOrientation")
	aligner.Name = "GhostAligner"
	aligner.Mode = Enum.OrientationAlignmentMode.OneAttachment
	aligner.Attachment0 = attachment
	aligner.Responsiveness = 200
	aligner.RigidityEnabled = false
	aligner.MaxTorque = math.huge
	aligner.Parent = rootPart
end

-- 🕹️ INPUT LOOP
local function UpdateMovement()
	if not IS_GHOST or not rootPart or not mover then return end

	local moveDir = Vector3.zero
	local lookVector = camera.CFrame.LookVector
	local rightVector = camera.CFrame.RightVector

	-- Flatten vectors for WASD so we don't fly down when looking down automatically
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
	local flatRight = Vector3.new(rightVector.X, 0, rightVector.Z).Unit

	-- WASD (Relative to Camera)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += flatLook end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= flatLook end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= flatRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += flatRight end

	-- Up/Down (World Space)
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

	-- APPLY VELOCITY
	if moveDir.Magnitude > 0 then
		mover.VectorVelocity = moveDir.Unit * FLIGHT_SPEED

		-- Turn character to face movement direction (Optional, looks nice)
		-- But for ghosts, usually better to face camera direction
		aligner.CFrame = CFrame.lookAt(Vector3.zero, lookVector)
	else
		mover.VectorVelocity = Vector3.zero
		aligner.CFrame = CFrame.lookAt(Vector3.zero, lookVector)
	end
end

-- ⚡ ACTIVATE GHOST MODE
local function EnableGhostMode()
	IS_GHOST = true
	if humanoid then
		humanoid.PlatformStand = true -- Disables default walking physics
		humanoid.AutoRotate = false   -- Let our script handle rotation
	end

	SetupMovers()
	ApplyGhostVisuals()

	-- 🚨 IMPORTANT: Send signal to server to set Collision Group if not done yet
	-- (Usually handled by your TaskSystem, but good to ensure)
end

local function OnCharacterAdded(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")

	-- Check if we are already dead on respawn
	if player:GetAttribute("IsDead") then 
		task.wait(0.5) -- Give server a sec to load
		EnableGhostMode() 
	end
end

-- LISTENERS
player.CharacterAdded:Connect(OnCharacterAdded)

player:GetAttributeChangedSignal("IsDead"):Connect(function()
	if player:GetAttribute("IsDead") then
		EnableGhostMode()
	end
end)

RunService.Heartbeat:Connect(UpdateMovement)

-- Init check
if player.Character then OnCharacterAdded(player.Character) end