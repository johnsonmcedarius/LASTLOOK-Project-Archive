-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: PerkRegistry (Module)
-- 💡 DESC: The central database for all perk stats. "The Brain."
-- -------------------------------------------------------------------------------

local PerkRegistry = {}

PerkRegistry.Definitions = {
	
	-- // DESIGNER PERKS --------------------------------------------------------
	
	["RunwayStrut"] = {
		Name = "Runway Strut",
		Rarity = "Common",
		Description = "Sprint at 135% speed for a short burst.",
		-- Stats logic looks for
		Stats = {
			SpeedMultiplier = 1.35, -- 135% speed
			Duration = 3,           -- Seconds
			Cooldown = 40,          -- Seconds
			IsLunge = true          -- Determines animation style
		}
	},
	
	["QuickStitch"] = {
		Name = "Quick Stitch",
		Rarity = "Common",
		Description = "Heal yourself at 50% speed without a medkit.",
		Stats = {
			HealSpeedMult = 0.5,
			SkillCheckDifficulty = "Hard"
		}
	},

	["ModelBehavior"] = {
		Name = "Model Behavior",
		Rarity = "Rare",
		Description = "Leave no scratch marks for 10s after unhooking someone.",
		Stats = {
			Duration = 10,
			HideScratchMarks = true
		}
	},
	
	["SecondLook"] = {
		Name = "Second Look",
		Rarity = "Mythic",
		Description = "One chance to escape a grab.",
		Stats = {
			SkillCheckWindow = 0.1, -- Tiny window, "earned not cheap"
			UsesPerMatch = 1
		}
	},

	-- // SABOTEUR PERKS --------------------------------------------------------
	
	["RippedSeam"] = {
		Name = "Ripped Seam",
		Rarity = "Common",
		Description = "Kick station to regress progress.",
		Stats = {
			RegressionPercent = 0.20, -- 20%
			KickTime = 2
		}
	}
}

-- // HELPER: Get Perk Data safely
function PerkRegistry.GetPerk(perkId)
	return PerkRegistry.Definitions[perkId]
end

-- // HELPER: Get specific stat (e.g., just the speed multiplier)
function PerkRegistry.GetStat(perkId, statName)
	local perk = PerkRegistry.Definitions[perkId]
	if perk and perk.Stats then
		return perk.Stats[statName]
	end
	return nil
end

return PerkRegistry