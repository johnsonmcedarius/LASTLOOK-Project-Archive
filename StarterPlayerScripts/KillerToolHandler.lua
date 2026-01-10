-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: KillerToolHandler (Client)
-- 🛠️ AUTH: Coding Partner
-- 💡 DESC: Hides the Backpack UI for Killers so they can't unequip Shears.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local function updateInterface()
	local role = Player:GetAttribute("Role")
	
	if role == "Saboteur" then
		-- Disable the default Toolbar (Backpack)
		-- This hides the tool icons at the bottom of the screen
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		
		-- Force Equip Loop (Safety net to prevent unequipping via Backspace)
		local char = Player.Character
		if char then
			local hum = char:FindFirstChild("Humanoid")
			local backpack = Player:FindFirstChild("Backpack")
			if hum and backpack then
				local tool = backpack:FindFirstChild("Shears")
				if tool then
					hum:EquipTool(tool)
				end
			end
		end
	else
		-- Re-enable for Lobby/Survivors (if they ever get items)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end
end

-- Check often
RunService.Heartbeat:Connect(function()
	-- We put this in Heartbeat or a slower loop to ensure it stays enforced
	-- simpler approach: Listen to attribute change, but Heartbeat handles
	-- the "Force Equip" logic best.
	
	if Player.Character and Player:GetAttribute("Role") == "Saboteur" then
		local hum = Player.Character:FindFirstChild("Humanoid")
		if hum then
			-- If they are holding nothing, check backpack
			local holding = Player.Character:FindFirstChildOfClass("Tool")
			if not holding then
				local backpack = Player:FindFirstChild("Backpack")
				local shears = backpack and backpack:FindFirstChild("Shears")
				if shears then
					hum:EquipTool(shears)
				end
			end
		end
	end
end)

-- Handle UI hiding when role changes
Player:GetAttributeChangedSignal("Role"):Connect(updateInterface)
updateInterface()
