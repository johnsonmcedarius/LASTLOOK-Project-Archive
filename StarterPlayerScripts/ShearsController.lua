-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShearsController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles input, animations, and local feedback for the Killer Weapon.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local CombatRemote = ReplicatedStorage:WaitForChild("CombatEvent")

-- CONFIG
local ATTACK_COOLDOWN = 2.5
local canAttack = true

-- ANIMATIONS (Replace with your Asset IDs)
local ANIM_SWING = "rbxassetid://000000000" -- Wind up + Snap
local ANIM_WIPE = "rbxassetid://000000000" -- The "Miss" animation
local ANIM_IDLE = "rbxassetid://000000000"

local loadedAnims = {}

-- // HELPER: Play Animation
local function playAnim(animName)
	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator")
	
	if not loadedAnims[animName] then
		local anim = Instance.new("Animation")
		anim.AnimationId = animName -- Assuming variable holds ID
		loadedAnims[animName] = animator:LoadAnimation(anim)
	end
	
	loadedAnims[animName]:Play()
end

-- // FUNCTION: Attack
local function onAttackInput(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		-- 1. Check if holding Shears
		local char = Player.Character
		if not char then return end
		local shears = char:FindFirstChild("Shears")
		if not shears then return end -- Don't punch air
		
		-- 2. Check Debounce
		if not canAttack then return end
		canAttack = false
		
		-- 3. Visuals
		-- playAnim(ANIM_SWING) -- Enable when you have IDs
		
		-- 4. Tell Server
		CombatRemote:FireServer("SwingShears")
		
		-- 5. Cooldown Logic
		task.wait(ATTACK_COOLDOWN)
		canAttack = true
	end
end

-- // FUNCTION: Pick Up (Bound to a key, or handled by your Context UI)
local function requestPickup()
	-- This function should be called by your "InteractionController" 
	-- when the prompt for "Pick Up" is clicked.
	-- CombatRemote:FireServer("AttemptPickup", targetCharacter)
end

-- // BIND INPUTS
-- Bind Left Click (PC) and Touch Tap (Mobile)
ContextActionService:BindAction("ShearsAttack", onAttackInput, true, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

-- // LISTENER FOR DOWNED STATE VISUALS
CombatRemote.OnClientEvent:Connect(function(action, targetPlayer)
	if action == "VFX_Downed" and targetPlayer == Player then
		-- Shake camera, turn screen red, blur, etc.
		print("🩸 I have been scrapped!")
	end
end)