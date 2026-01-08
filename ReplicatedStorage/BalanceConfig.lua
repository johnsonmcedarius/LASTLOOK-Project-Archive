-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: BalanceConfig (Module - 2v8 SCALE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Control Panel". Scaled for 2 Killers / 8 Survivors.
-- -------------------------------------------------------------------------------

local BalanceConfig = {}

-- // STATION MECHANICS
BalanceConfig.Station = {
	BaseWorkRequired = 110,    -- [UPDATED] Bumped from 100. Need to slow down 8 people.
	BaseWorkRate = 1,         
	
	DuoMultiplier = 1.5,      
	MaxOccupants = 2,         -- Kept at 2 to force spreading out
	
	RegressionOnKick = 0.15,  
	RegressionPassive = 0.05, 
	
	PassiveJamClear = 15,     
}

-- // SKILL CHECKS
BalanceConfig.SkillCheck = {
	TriggerChance = 0.15,     
	SafeZoneSize = 0.2,       
	BonusProgress = 2,        
	MissPenalty = 5,          
}

-- // GLOBAL
BalanceConfig.Global = {
	StationsToPower = 10, -- [UPDATED] Doubled from 5. Map needs 12-14 Stations spawned.
}

return BalanceConfig
