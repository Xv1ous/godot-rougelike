extends Resource
class_name ItemData

# ---------- PICKUP ITEM TEXTURES ----------
# Centralized location for all pickup item textures
# This prevents duplication and ensures consistency across scripts
const PICKUP_TEXTURES := {
	"health_potion": preload("res://Asset/v1.1 dungeon crawler 16X16 pixel pack/props_itens/potion_red.png"),
	"incivility_potion": preload("res://Asset/v1.1 dungeon crawler 16X16 pixel pack/props_itens/potion_green.png"),
	"speed_potion": preload("res://Asset/v1.1 dungeon crawler 16X16 pixel pack/props_itens/potion_yellow.png")
}

# ---------- PICKUP ITEM EFFECTS ----------
# Define pickup effects (heal amounts, buffs, etc.)
# Effects should match the potion name/purpose
const PICKUP_EFFECTS := {
	"health_potion": {
		"heal": 30 # Health potion restores health
	},
	"incivility_potion": {
		"damage": 20 # Incivility potion deals damage (poison/toxic effect)
	},
	"speed_potion": {
		"speed_multiplier": 1.5, # Speed potion increases movement speed
		"duration": 10.0 # Duration in seconds
	}
}
