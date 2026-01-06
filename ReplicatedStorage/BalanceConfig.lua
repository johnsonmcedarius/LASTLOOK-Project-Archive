-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: BalanceConfig (Module)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Control Panel" for Game Balance. Tweaked for Alpha 2.0.
-- -------------------------------------------------------------------------------

local BalanceConfig = {}

-- // STATION MECHANICS
BalanceConfig.Station = {
	BaseWorkRequired = 100,    -- [UPDATED] Buffed from 80 to 100. Slow the game down.
	BaseWorkRate = 1,         -- Units per second (Solo)
	
	DuoMultiplier = 1.5,      -- [UPDATED] Nerfed from 1.8. Duos were too OP with Fast Hands.
	MaxOccupants = 2,         -- Hard cap on players per station
	
	RegressionOnKick = 0.15,  -- Lose 15% progress if Saboteur kicks it
	RegressionPassive = 0.05, -- Lose 5% per second if left at 99%
	
	PassiveJamClear = 15,     -- [NEW] Seconds before a Jam clears itself (Anti-Troll)
}

-- // SKILL CHECKS
BalanceConfig.SkillCheck = {
	TriggerChance = 0.15,     -- 15% chance per second
	SafeZoneSize = 0.2,       -- 20% of circle
	BonusProgress = 2,        
	MissPenalty = 5,          
}

-- // GLOBAL
BalanceConfig.Global = {
	StationsToPower = 5,
}

return BalanceConfig
