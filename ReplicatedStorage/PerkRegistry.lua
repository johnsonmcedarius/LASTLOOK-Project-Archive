-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: PerkRegistry (Module - LAUNCH COLLECTION)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The 12 Launch Perks. Influence (📍) Prices included.
-- -------------------------------------------------------------------------------

local PerkRegistry = {}

PerkRegistry.Definitions = {
	
	-- // 🧵 DESIGNER PERKS (SURVIVORS) ---------------------------------------
	
	["RunwayStrut"] = {
		Name = "Runway Strut",
		Rarity = "Rare",
		Price = 10, -- 📍
		Description = "Sprint at 150% speed for 3s after vaulting.",
		Stats = {SpeedMult = 1.5, Duration = 3, Cooldown = 40}
	},
	
	["SilentStitch"] = {
		Name = "Silent Stitch",
		Rarity = "Common",
		Price = 5, -- 📍
		Description = "Breathing and footsteps are silent while crouching.",
		Stats = {VolumeMult = 0}
	},

	["AdrenalineRush"] = {
		Name = "Adrenaline Rush",
		Rarity = "Mythic",
		Price = 25, -- 📍
		Description = "Heal 1 state + 150% speed for 5s when Exits power.",
		Stats = {HealAmount = 1, SpeedMult = 1.5, Duration = 5}
	},
	
	["FastHands"] = {
		Name = "Fast Hands",
		Rarity = "Common",
		Price = 5, -- 📍
		Description = "Great and Good Skill Check zones are 20% larger.",
		Stats = {ZoneSizeMult = 1.2}
	},
	
	["MedicsTouch"] = {
		Name = "Medic's Touch",
		Rarity = "Rare",
		Price = 8, -- 📍
		Description = "Healing speed is boosted by 50%.",
		Stats = {HealSpeedMult = 1.5}
	},
	
	["SixthSense"] = {
		Name = "Sixth Sense",
		Rarity = "Legendary",
		Price = 15, -- 📍
		Description = "Screen glows if Saboteur looks at you from >30 studs.",
		Stats = {Range = 30}
	},

	-- // ✂️ SABOTEUR PERKS (KILLERS) -----------------------------------------
	
	["RippedSeam"] = {
		Name = "Ripped Seam",
		Rarity = "Common",
		Price = 5, -- 📍
		Description = "Kicking a station instantly deletes 10% progress.",
		Stats = {Regression = 0.10}
	},
	
	["BloodTrail"] = {
		Name = "Blood Trail",
		Rarity = "Rare",
		Price = 8, -- 📍
		Description = "Injured Designers leave neon red footprints for 4s.",
		Stats = {Duration = 4}
	},
	
	["HexLockdown"] = {
		Name = "Hex: Lockdown",
		Rarity = "Legendary",
		Price = 15, -- 📍
		Description = "Block a vault for 15s after crossing it.",
		Stats = {Duration = 15}
	},
	
	["TrendForecast"] = {
		Name = "Trend Forecast",
		Rarity = "Common",
		Price = 5, -- 📍
		Description = "Failed skill checks reveal aura for 5 seconds.",
		Stats = {Duration = 5}
	},
	
	["HeavyPresence"] = {
		Name = "Heavy Presence",
		Rarity = "Rare",
		Price = 10, -- 📍
		Description = "Terror Radius is 20% larger.",
		Stats = {RadiusMult = 1.2}
	},
	
	["EndgameCollapse"] = {
		Name = "Endgame Collapse",
		Rarity = "Mythic",
		Price = 25, -- 📍
		Description = "Survivors are Exposed (1-hit down) when gates power.",
		Stats = {Duration = 60}
	}
}

-- // HELPER: Get Perk Data
function PerkRegistry.GetPerk(perkId)
	return PerkRegistry.Definitions[perkId]
end

return PerkRegistry
