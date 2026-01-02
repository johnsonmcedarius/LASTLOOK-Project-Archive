--[[
    CollisionManager (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 14:59:28
]]
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local CollisionManager = {}

-- GROUP NAMES (Must match exactly)
local GROUP_GHOST = "GhostGroup"
local GROUP_EXTERIOR = "ExteriorGroup"
local GROUP_INTERIOR = "InteriorGroup"
local GROUP_BODY = "DeadBodyGroup"

-- 1. SETUP FUNCTION
local function SetupGroups()
	-- Helper to safely register groups
	local function safeRegister(name)
		local success, err = pcall(function() 
			PhysicsService:RegisterCollisionGroup(name) 
		end)
		if not success and not string.find(err, "already exists") then
			warn("⚠️ [COLLISION MGR] Error registering " .. name .. ": " .. err)
		end
	end

	safeRegister(GROUP_GHOST)
	safeRegister(GROUP_EXTERIOR)
	safeRegister(GROUP_INTERIOR)
	safeRegister(GROUP_BODY)

	print("☢️ [COLLISION MGR] NUCLEAR OPTION: Bodies will hit EVERYTHING.")

	-- 2. THE NUCLEAR LOOP (The "Hit Everything" Logic)
	local allGroups = PhysicsService:GetRegisteredCollisionGroups()

	for _, groupInfo in pairs(allGroups) do
		local groupName = groupInfo.name

		-- Skip the body itself (prevents self-explosion)
		if groupName == GROUP_BODY then
			PhysicsService:CollisionGroupSetCollidable(GROUP_BODY, GROUP_BODY, false)

			-- Skip Ghosts (prevents tripping players)
		elseif groupName == GROUP_GHOST then
			PhysicsService:CollisionGroupSetCollidable(GROUP_BODY, GROUP_GHOST, false)

		else
			-- FOR EVERYTHING ELSE (Default, Interior, Exterior, RandomGroups):
			-- FORCE COLLISION TO TRUE
			PhysicsService:CollisionGroupSetCollidable(GROUP_BODY, groupName, true)
			print("✅ Body now hits: " .. groupName)
		end
	end

	-- 3. GHOST RULES (Keep these for your ghost mechanics)
	PhysicsService:CollisionGroupSetCollidable(GROUP_GHOST, GROUP_INTERIOR, false)
	PhysicsService:CollisionGroupSetCollidable(GROUP_GHOST, GROUP_EXTERIOR, true)
end

-- 3. APPLY TO CHARACTERS
function CollisionManager.SetGhost(char)
	if not char then return end
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = GROUP_GHOST
		end
	end
end

function CollisionManager.SetRagdoll(model)
	if not model then return end
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = GROUP_BODY
			part.CanCollide = true -- Force Physics ON
		end
	end
end

-- 4. AUTO-TAG MAP (Ghosts still need this)
local function AutoTagMap()
	local extFolder = Workspace:WaitForChild("Exterior", 30)
	local intFolder = Workspace:WaitForChild("Interior", 30)

	local function tagExterior(part)
		if part:IsA("BasePart") then part.CollisionGroup = GROUP_EXTERIOR end
	end

	local function tagInterior(part)
		if part:IsA("BasePart") then part.CollisionGroup = GROUP_INTERIOR end
	end

	if extFolder then
		for _, part in pairs(extFolder:GetDescendants()) do tagExterior(part) end
		extFolder.DescendantAdded:Connect(tagExterior)
	end

	if intFolder then
		for _, part in pairs(intFolder:GetDescendants()) do tagInterior(part) end
		intFolder.DescendantAdded:Connect(tagInterior)
	end
end

-- Run immediately
SetupGroups()
task.defer(AutoTagMap)

_G.CollisionManager = CollisionManager

return CollisionManager