-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShearsController (Client - INSTANT HIT)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Detects hits locally. Sends to server. Handles Lunge.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local CombatRemote = ReplicatedStorage:WaitForChild("CombatEvent")

local canSwing = true
local LUNGE_FORCE = 50

local function performAttack(actionName, inputState)
	if inputState == Enum.UserInputState.Begin and canSwing then
		canSwing = false
		local char = Player.Character
		local root = char.HumanoidRootPart
		
		-- 1. Lunge (Velocity Impulse)
		root:ApplyImpulse(root.CFrame.LookVector * LUNGE_FORCE * root.AssemblyMass)
		
		-- 2. Hitbox (Raycast/Overlap)
		local hitParams = OverlapParams.new()
		hitParams.FilterDescendantsInstances = {char}
		hitParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local hits = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0,0,-3), Vector3.new(5,5,5), hitParams)
		
		for _, part in pairs(hits) do
			local hum = part.Parent:FindFirstChild("Humanoid")
			if hum then
				local victim = Players:GetPlayerFromCharacter(part.Parent)
				if victim and victim ~= Player then
					-- Found a victim!
					CombatRemote:FireServer("Hit", victim)
					break -- Only hit one person per swing
				end
			end
		end
		
		-- 3. Play Animation & Trail here
		-- (User implements Anim logic)
		
		task.wait(2) -- Cooldown
		canSwing = true
	end
end

ContextActionService:BindAction("Attack", performAttack, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
