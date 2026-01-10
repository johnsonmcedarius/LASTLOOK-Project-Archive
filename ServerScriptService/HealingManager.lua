-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 MODULE: HealingManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles healing logic + Medic Perk bonuses.
-- -------------------------------------------------------------------------------

local HealingManager = {}
local ServerStorage = game:GetService("ServerStorage")

local AddScoreBindable = ServerStorage:FindFirstChild("AddScore")

function HealingManager.ProcessHeal(healer, targetChar)
	local targetPlayer = game.Players:GetPlayerFromCharacter(targetChar)
	if not targetPlayer then return end
	
	-- 1. Calculate Speed (Medic Perk)
	-- We check the attribute "EquippedPerks" on the Healer
	local speed = 1
	local perks = healer:GetAttribute("EquippedPerks") or ""
	
	if string.find(perks, "MedicsTouch") then 
		speed = 1.5 -- 50% Faster
	end
	
	-- 2. Apply Heal Progress
	local current = targetPlayer:GetAttribute("HealProgress") or 0
	local newProgress = current + speed
	
	targetPlayer:SetAttribute("HealProgress", newProgress)
	
	-- 3. Check Completion (Assume 100 ticks needed)
	if newProgress >= 100 then
		targetPlayer:SetAttribute("HealthState", "Healthy")
		targetPlayer:SetAttribute("HealProgress", 0)
		
		-- 4. Reward the Healer
		if AddScoreBindable then
			AddScoreBindable:Fire(healer, "HEAL_TEAMMATE", 100)
		end
	end
end

return HealingManager
