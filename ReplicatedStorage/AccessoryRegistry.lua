-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AccessoryRegistry (Module - SEARCHABLE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Cosmetic Items. Now with Categories/Tags for the Search Bar.
-- -------------------------------------------------------------------------------

local AccessoryRegistry = {}

AccessoryRegistry.Definitions = {
	
	-- // 👜 BAGS
	["RootsSmall"] = {
		Name = "Roots Briefcase (Small)",
		Rarity = "Legendary",
		Price = 8500, -- 🧵
		Description = "Coated canvas with leather trim. Blues City Bloom.",
		AssetId = 000000,
		Category = "Bags",
		Tags = {"leather", "purse", "designer", "blue"}
	},
	
	["RootsMedium"] = {
		Name = "Roots Briefcase (Med)",
		Rarity = "Mythic",
		Price = 15000, -- 🧵
		Description = "The statement piece. Magnetic patch system.",
		AssetId = 000000,
		Category = "Bags",
		Tags = {"leather", "purse", "designer", "big"}
	},

	-- // 🧢 APPAREL
	["DenimTrucker"] = {
		Name = "901 Trucker Jacket",
		Rarity = "Rare",
		Price = 4500, -- 🧵
		Description = "Heavy denim with graffiti detailing.",
		AssetId = 000000,
		Category = "Apparel",
		Tags = {"jacket", "denim", "blue", "streetwear"}
	},
	
	["NeonVisor"] = {
		Name = "Atelier Visor",
		Rarity = "Common",
		Price = 1500, -- 🧵
		Description = "Standard issue for floor designers.",
		AssetId = 000000,
		Category = "Headwear",
		Tags = {"hat", "visor", "neon", "cheap"}
	}
}

function AccessoryRegistry.GetItem(id)
	return AccessoryRegistry.Definitions[id]
end

return AccessoryRegistry
