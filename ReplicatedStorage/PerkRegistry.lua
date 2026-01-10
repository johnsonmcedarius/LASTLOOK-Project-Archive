-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 MODULE: PerkRegistry (Updated Prices)
-- -------------------------------------------------------------------------------

local PerkRegistry = {}

PerkRegistry.Definitions = {
	
	-- // 🧵 DESIGNER PERKS
	["SilentStitch"] = {
		Name = "Silent Stitch",
		Rarity = "Common",
		Price = 3, -- Easy unlock
		Description = "Breathing and footsteps are silent while crouching.",
		Stats = {VolumeMult = 0}
	},
	
	["FastHands"] = {
		Name = "Fast Hands",
		Rarity = "Common",
		Price = 3, -- Easy unlock
		Description = "Great and Good Skill Check zones are 20% larger.",
		Stats = {ZoneSizeMult = 1.2}
	},
	
	["MedicsTouch"] = {
		Name = "Medic's Touch",
		Rarity = "Rare",
		Price = 8, -- Mid-game goal
		Description = "Healing speed is boosted by 50%.",
		Stats = {HealSpeedMult = 1.5}
	},
	
	["RunwayStrut"] = {
		Name = "Runway Strut",
		Rarity = "Rare",
		Price = 8, -- Mid-game goal
		Description = "Sprint at 150% speed for 3s after vaulting.",
		Stats = {SpeedMult = 1.5, Duration = 3, Cooldown = 40}
	},
	
	["SixthSense"] = {
		Name = "Sixth Sense",
		Rarity = "Legendary",
		Price = 12, -- High-tier
		Description = "Screen glows if Saboteur looks at you from >30 studs.",
		Stats = {Range = 30}
	},

	["AdrenalineRush"] = {
		Name = "Adrenaline Rush",
		Rarity = "Mythic",
		Price = 20, -- Elite status
		Description = "Heal 1 state + 150% speed for 5s when Exits power.",
		Stats = {HealAmount = 1, SpeedMult = 1.5, Duration = 5}
	},

	-- // ✂️ SABOTEUR PERKS
	["RippedSeam"] = {
		Name = "Ripped Seam",
		Rarity = "Common",
		Price = 3, -- Easy unlock
		Description = "Kicking a station instantly deletes 10% progress.",
		Stats = {Regression = 0.10}
	},
	
	["TrendForecast"] = {
		Name = "Trend Forecast",
		Rarity = "Common",
		Price = 3, -- Easy unlock
		Description = "Failed skill checks reveal aura for 5 seconds.",
		Stats = {Duration = 5}
	},
	
	["BloodTrail"] = {
		Name = "Blood Trail",
		Rarity = "Rare",
		Price = 8, -- Mid-game goal
		Description = "Injured Designers leave neon red footprints for 4s.",
		Stats = {Duration = 4}
	},
	
	["HeavyPresence"] = {
		Name = "Heavy Presence",
		Rarity = "Rare",
		Price = 8, -- Mid-game goal
		Description = "Terror Radius is 20% larger.",
		Stats = {RadiusMult = 1.2}
	},
	
	["HexLockdown"] = {
		Name = "Hex: Lockdown",
		Rarity = "Legendary",
		Price = 12, -- High-tier
		Description = "Block a vault for 15s after crossing it.",
		Stats = {Duration = 15}
	},
	
	["EndgameCollapse"] = {
		Name = "Endgame Collapse",
		Rarity = "Mythic",
		Price = 20, -- Elite status
		Description = "Survivors are Exposed (1-hit down) when gates power.",
		Stats = {Duration = 60}
	}
}

function PerkRegistry.GetPerk(perkId)
	return PerkRegistry.Definitions[perkId]
end

function PerkRegistry.GetStat(perkId, statName)
	local def = PerkRegistry.Definitions[perkId]
	if def and def.Stats then return def.Stats[statName] end
	return nil
end

return PerkRegistry
