-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 MODULE: HealingManager (Server)
-- -------------------------------------------------------------------------------

local HealingManager = {}

function HealingManager.ProcessHeal(healer, targetChar)
	local targetPlayer = game.Players:GetPlayerFromCharacter(targetChar)
	if not targetPlayer then return end
	
	-- Calculate Heal Speed based on Perks
	local speed = 1
	if healer:GetAttribute("HasMedicPerk") then speed = 1.5 end
	
	-- Apply Heal Logic (simplified)
	local current = targetPlayer:GetAttribute("HealProgress") or 0
	targetPlayer:SetAttribute("HealProgress", current + speed)
	
	if current >= 100 then
		targetPlayer:SetAttribute("HealthState", "Healthy")
		targetPlayer:SetAttribute("HealProgress", 0)
	end
end

return HealingManager
