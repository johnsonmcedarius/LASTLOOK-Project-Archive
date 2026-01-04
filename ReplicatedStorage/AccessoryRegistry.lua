-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AccessoryRegistry (Module)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Cosmetic Items. Prices in Spools (🧵).
-- -------------------------------------------------------------------------------

local AccessoryRegistry = {}

AccessoryRegistry.Definitions = {
	
	-- // 👜 BAGS (The Roots Collection)
	["RootsSmall"] = {
		Name = "Roots Briefcase (Small)",
		Rarity = "Legendary",
		Price = 8500, -- 🧵
		Description = "Coated canvas with leather trim. From the Blues City Bloom collection.",
		AssetId = 000000 -- Nerd puts the mesh ID here
	},
	
	["RootsMedium"] = {
		Name = "Roots Briefcase (Med)",
		Rarity = "Mythic",
		Price = 15000, -- 🧵
		Description = "The statement piece. Magnetic patch system included.",
		AssetId = 000000
	},

	-- // 🧢 APPAREL
	["DenimTrucker"] = {
		Name = "901 Trucker Jacket",
		Rarity = "Rare",
		Price = 4500, -- 🧵
		Description = "Heavy denim with graffiti detailing. Memphis made.",
		AssetId = 000000
	},
	
	["NeonVisor"] = {
		Name = "Atelier Visor",
		Rarity = "Common",
		Price = 1500, -- 🧵
		Description = "Standard issue for floor designers.",
		AssetId = 000000
	}
}

function AccessoryRegistry.GetItem(id)
	return AccessoryRegistry.Definitions[id]
end

return AccessoryRegistry