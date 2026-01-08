-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: AccessoryRegistry (Module - HAUNTED ATELIER UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Cosmetic Items. "Haunted Couture" Collection.
-- -------------------------------------------------------------------------------

local AccessoryRegistry = {}

AccessoryRegistry.Definitions = {
	
	-- // 👜 BAGS
	["MannequinLimbPurse"] = {
		Name = "Mannequin Limb Purse",
		Rarity = "Legendary",
		Price = 6500, -- 🧵
		Description = "A sleek, designer-style handbag. The 'strap' is a pale, detached mannequin hand gripping your shoulder.",
		AssetId = 000000,
		Category = "Bags",
		Tags = {"hand", "mannequin", "creepy", "designer", "purse"}
	},
	
	-- // 😇 HEADWEAR
	["FloatingPinsHalo"] = {
		Name = "Floating Pins Halo",
		Rarity = "Mythic",
		Price = 12000, -- 🧵
		Description = "A ring of rusted sewing needles and safety pins floating and spinning slowly around the head.",
		AssetId = 000000,
		Category = "Headwear",
		Tags = {"halo", "pins", "needles", "rust", "floating"}
	},
	
	-- // 🦋 BACK
	["FragmentedMirrorWings"] = {
		Name = "Fragmented Mirror Wings",
		Rarity = "Epic",
		Price = 8500, -- 🧵
		Description = "Shards of a shattered designer mirror arranged as wings. Sharp, reflective, and broken.",
		AssetId = 000000,
		Category = "Back",
		Tags = {"wings", "mirror", "glass", "shards", "broken"}
	},

	-- // 🎭 FACE
	["ShadowStitchedVeil"] = {
		Name = "Shadow-Stitched Veil",
		Rarity = "Rare",
		Price = 4200, -- 🧵
		Description = "A sheer, black lace veil covering the face. Glowing red stitches cross over the eyes.",
		AssetId = 000000,
		Category = "Face",
		Tags = {"veil", "lace", "goth", "red", "stitches"}
	}
}

function AccessoryRegistry.GetItem(id)
	return AccessoryRegistry.Definitions[id]
end

return AccessoryRegistry
