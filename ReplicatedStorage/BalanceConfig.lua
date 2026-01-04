-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: BalanceConfig (Module)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Control Panel" for Game Balance. Tweak numbers here.
-- -------------------------------------------------------------------------------

local BalanceConfig = {}

-- // STATION MECHANICS
BalanceConfig.Station = {
	BaseWorkRequired = 80,    -- "Units" of work (Seconds if rate is 1)
	BaseWorkRate = 1,         -- Units per second (Solo)
	
	DuoMultiplier = 1.8,      -- 1.8x speed for 2 people (NOT 2.0x)
	MaxOccupants = 2,         -- Hard cap on players per station
	
	RegressionOnKick = 0.15,  -- Lose 15% progress if Saboteur kicks it
	RegressionPassive = 0.05, -- Lose 5% per second if left at 99% (optional, adds pressure)
}

-- // SKILL CHECKS
BalanceConfig.SkillCheck = {
	TriggerChance = 0.15,     -- 15% chance per second while working
	SafeZoneSize = 0.2,       -- 20% of the circle is the "Good" zone
	BonusProgress = 2,        -- Units gained for a "Great" hit
	MissPenalty = 5,          -- Units lost for a "Miss"
}

-- // GLOBAL
BalanceConfig.Global = {
	StationsToPower = 5,
}

return BalanceConfig