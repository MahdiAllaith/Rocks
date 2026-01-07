export type InventoryItemType =
	"UseItem"
| "RockModifire"
| "Kit"
| "Junk"
| "Other"

export type InventoryItemData = {
	Name: string,
	Amount: number,
	ItemType: InventoryItemType,
}

local PROFILE_TEMPLATE = {

	-- =========================
	-- WALLET DATA
	-- =========================
	Wallet = {
		RocksAmount = 0,
		LuminiteAmount = 0,
	},

	-- =========================
	-- LEVEL / XP DATA
	-- =========================
	Level = {
		LevelNumber = 0,
		CurrentXpAmount = 0,

		DoubleXp = false,
	},

	-- =========================
	-- ROCK / COMBAT DATA
	-- =========================
	RockStats = {
		Model = "",     -- string | ""
		Handler = "",   -- string | ""
		Buffer = "",    -- string | ""
	},

	-- =========================
	-- CHARACTER KITS DATA
	-- =========================
	CharacterKits = {
		Health = "",     -- Kit name or ""
		Stamina = "",    -- Kit name or ""
		Abilities = "",  -- Kit name or ""
	},

	-- =========================
	-- INVENTORY DATA
	-- =========================
	Inventory = {
		-- Array of stacks
		-- Each entry represents ONE stack
		-- Example:
		-- {
		--   Name = "FireRune",
		--   Amount = 2,
		--   ItemType = "RockModifire"
		-- }

		Items = {} :: InventoryItemData,
	},

}

return PROFILE_TEMPLATE
