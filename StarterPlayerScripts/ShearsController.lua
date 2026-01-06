-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ShearsController (Client - SKINS UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles input, animations, and Skin Mesh Swapping.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Player = Players.LocalPlayer
local CombatRemote = ReplicatedStorage:WaitForChild("CombatEvent")

local ATTACK_COOLDOWN = 2.5
local canAttack = true

local loadedAnims = {}

local function playAnim(animName)
	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator")
	
	if not loadedAnims[animName] then
		local anim = Instance.new("Animation")
		anim.AnimationId = animName 
		loadedAnims[animName] = animator:LoadAnimation(anim)
	end
	
	loadedAnims[animName]:Play()
end

-- // HELPER: Apply Skin (MeshID)
-- [NEW] This should be called when character spawns or skin changes
local function applyShearsSkin()
	local char = Player.Character
	if not char then return end
	local shears = char:FindFirstChild("Shears")
	if not shears then return end
	
	-- Look for attribute or data
	local skinMeshId = Player:GetAttribute("EquippedShearsSkin") 
	-- If no custom skin, keep default
	
	if skinMeshId and skinMeshId ~= "" then
		local mesh = shears:FindFirstChild("Mesh") or Instance.new("SpecialMesh", shears)
		mesh.MeshId = skinMeshId
		-- Reset texture if needed or apply matching texture
	end
end

local function onAttackInput(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		local char = Player.Character
		if not char then return end
		local shears = char:FindFirstChild("Shears")
		if not shears then return end 
		
		if not canAttack then return end
		canAttack = false
		
		CombatRemote:FireServer("SwingShears")
		
		task.wait(ATTACK_COOLDOWN)
		canAttack = true
	end
end

ContextActionService:BindAction("ShearsAttack", onAttackInput, true, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

CombatRemote.OnClientEvent:Connect(function(action, targetPlayer)
	if action == "VFX_Downed" and targetPlayer == Player then
		print("🩸 I have been scrapped!")
	elseif action == "ApplySkin" then
		applyShearsSkin()
	end
end)

Player.CharacterAdded:Connect(function()
	task.wait(1)
	applyShearsSkin()
end)
