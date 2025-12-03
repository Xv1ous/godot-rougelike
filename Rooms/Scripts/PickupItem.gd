extends Area2D
class_name PickupItem

# ---------- EXPORTS ----------
@export var item_type: String = "health_potion"
@export var amount: int = 1

# ---------- NODE REFERENCES ----------
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ---------- CONSTANTS ----------
# Use centralized item data to avoid duplication
const ItemDataResource = preload("res://Data/item_data.gd")

# ---------- LIFECYCLE ----------
func _ready() -> void:
	print("PickupItem._ready() called - item_type: ", item_type, " position: ", global_position)

	# Set the sprite texture based on item type
	if sprite:
		if item_type in ItemDataResource.PICKUP_TEXTURES:
			sprite.texture = ItemDataResource.PICKUP_TEXTURES[item_type]
			print("Set sprite texture to: ", ItemDataResource.PICKUP_TEXTURES[item_type])
		else:
			push_warning("Unknown item type: ", item_type)

		# Make sure sprite is visible
		sprite.visible = true
		print("Sprite visible: ", sprite.visible, " texture set: ", sprite.texture != null)
	else:
		push_error("Sprite2D node not found!")

	# Connect body_entered signal to detect player
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("Connected body_entered signal")

	# Set collision layer/mask - pickups should be on World layer, detect Player layer
	collision_layer = 1 # World layer
	collision_mask = 2 # Player layer
	print("PickupItem ready! collision_layer: ", collision_layer, " collision_mask: ", collision_mask)

# ---------- PICKUP LOGIC ----------
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Apply pickup effect based on item type
	_apply_pickup_effect(body)

	# Remove the pickup
	queue_free()

func _apply_pickup_effect(player: Node2D) -> void:
	if not item_type in ItemDataResource.PICKUP_EFFECTS:
		push_warning("Unknown item type for pickup effect: ", item_type)
		return

	var effect = ItemDataResource.PICKUP_EFFECTS[item_type]

	match item_type:
		"health_potion":
			# Health potion restores health
			if "heal" in effect and player.has_method("heal"):
				player.heal(effect.heal)
				print("Player picked up health potion! +", effect.heal, " HP")

		"incivility_potion":
			# Incivility potion deals damage (poison/toxic effect)
			if "damage" in effect and player.has_method("take_damage"):
				player.take_damage(effect.damage)
				print("Player picked up incivility potion! Took ", effect.damage, " damage!")

		"speed_potion":
			# Speed potion increases movement speed temporarily
			if "speed_multiplier" in effect and player.has("max_speed"):
				var original_speed = player.max_speed
				var boosted_speed = int(original_speed * effect.speed_multiplier)
				player.max_speed = boosted_speed
				var duration = effect.get("duration", 10.0)
				print("Player picked up speed potion! Speed increased to ", boosted_speed, " for ", duration, " seconds")

				# Reset speed after duration (use a timer attached to player, not pickup)
				if player.has_method("_reset_speed_after_duration"):
					player._reset_speed_after_duration(original_speed, duration)
				else:
					# Fallback: create timer on player node
					var timer = Timer.new()
					timer.wait_time = duration
					timer.one_shot = true
					player.add_child(timer)
					timer.timeout.connect(func():
						if is_instance_valid(player):
							player.max_speed = original_speed
							print("Speed potion effect wore off. Speed back to ", original_speed)
						timer.queue_free()
					)
					timer.start()

		_:
			# Fallback: try to apply heal if defined
			if "heal" in effect and player.has_method("heal"):
				player.heal(effect.heal)
				print("Player picked up ", item_type, "! +", effect.heal, " HP")
