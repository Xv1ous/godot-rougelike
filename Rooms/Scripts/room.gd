@tool
extends Node2D
class_name Room

# ---------- CONSTANTS ----------
const ENEMY_SCENES := {
	"slime": preload("res://Character/Scenes/Enemies/slime.tscn"),
	"goblin": preload("res://Character/Scenes/Enemies/goblin.tscn"),
	"fly": preload("res://Character/Scenes/Enemies/flying_creature.tscn")
}

# Use centralized item data to avoid duplication
const ItemDataResource = preload("res://Data/item_data.gd")
const PICKUP_ITEMS = ItemDataResource.PICKUP_TEXTURES

const PICKUP_SCENE := preload("res://Rooms/Scenes/PickupItem.tscn")
# ---------- EXPORTS ----------
@export var num_enemies: int

var _close_entrance_backing := false
var _room_activated := false
@export var close_entrance := false:
	set(value):
		if value != _close_entrance_backing:
			_close_entrance_backing = value
			_update_entrance()
	get:
		return _close_entrance_backing

# ---------- NODE REFERENCES ----------
@onready var wall_layer: TileMapLayer = $NavigationRegion2D/Wall
@onready var ground_layer: TileMapLayer = $NavigationRegion2D/Ground
@onready var entrance: Node2D = $Entrance
@onready var door_container: Node2D = $Door
@onready var enemies_pos_container: Node2D = $EnemiesPosition
@onready var pickup_pos_container: Node2D = $PickupPosition
@onready var player_detector: Area2D = $PlayerDetector

# ---------- LIFECYCLE ----------
func _ready() -> void:
	num_enemies = enemies_pos_container.get_child_count()
	# Ensure PlayerDetector is monitoring and connected
	if player_detector:
		player_detector.monitoring = true
		player_detector.collision_mask = 2 # Player layer
		# Connect signal if not already connected
		if not player_detector.body_entered.is_connected(_on_player_detector_body_entered):
			player_detector.body_entered.connect(_on_player_detector_body_entered)

# ---------- ENTRANCE MANAGEMENT ----------
func _update_entrance() -> void:
	if not is_inside_tree() or not wall_layer:
		return

	for entry_pos in entrance.get_children():
		if not entry_pos:
			continue

		var global_pos: Vector2 = entry_pos.global_position
		var local_pos := wall_layer.to_local(global_pos)
		var cell := wall_layer.local_to_map(local_pos)

		if _close_entrance_backing:
			wall_layer.set_cell(cell, 2, Vector2i(2, 7))
		else:
			wall_layer.set_cell(cell, -1)

	wall_layer.queue_redraw()

# ---------- GAMEPLAY ----------
func _spawn_enemies() -> void:
	var enemy_keys = ENEMY_SCENES.keys()
	for pos_marker in enemies_pos_container.get_children():
		if not pos_marker:
			continue

		# Randomly select an enemy type from the dictionary
		var random_enemy_key = enemy_keys[randi() % enemy_keys.size()]
		var enemy: CharacterBody2D = ENEMY_SCENES[random_enemy_key].instantiate()
		enemy.tree_exited.connect(_on_enemy_killed)

		# Store the marker reference and position
		# We'll get the global position after adding to tree
		var marker_node = pos_marker

		# Add enemy as child of the room using call_deferred to avoid physics query issues
		call_deferred("_add_enemy_to_room", enemy, marker_node)

func _add_enemy_to_room(enemy: CharacterBody2D, marker_node: Node2D) -> void:
	# Add enemy first so it's in the tree
	add_child(enemy)

	# Now get the marker's global position - this should be correct now that room is positioned
	if is_inside_tree() and marker_node and is_instance_valid(marker_node):
		# Use the marker's global position directly
		enemy.global_position = marker_node.global_position
	else:
		# Fallback: calculate position manually
		if enemies_pos_container and marker_node:
			var container_offset = enemies_pos_container.position
			var marker_offset = marker_node.position
			enemy.position = container_offset + marker_offset


func _on_enemy_killed() -> void:
	num_enemies -= 1
	print("Enemy killed! Remaining enemies: ", num_enemies)
	if num_enemies <= 0:
		print("All enemies defeated! Opening door and spawning pickups...")
		_open_door()
		_open_entrance()
		_spawn_pickups()


func _open_door() -> void:
	if Engine.is_editor_hint():
		return

	if not door_container:
		return

	for door in door_container.get_children():
		if door.has_method("open"):
			door.open()

func _open_entrance() -> void:
	close_entrance = false


func _on_player_detector_body_entered(body: Node2D) -> void:
	if _room_activated:
		return

	if not body.is_in_group("player"):
		return

	_room_activated = true
	close_entrance = true
	_spawn_enemies()

# ---------- PICKUP SPAWNING ----------
func _spawn_pickups() -> void:
	print("=== _spawn_pickups() called ===")

	if Engine.is_editor_hint():
		print("In editor, skipping pickup spawn")
		return

	print("pickup_pos_container: ", pickup_pos_container)
	if not pickup_pos_container:
		print("ERROR: PickupPosition container not found, cannot spawn pickups")
		return

	var pickup_markers = pickup_pos_container.get_children()
	print("Found ", pickup_markers.size(), " pickup markers")

	if pickup_markers.is_empty():
		print("ERROR: No pickup markers found in PickupPosition container")
		return

	# Spawn 1-3 random pickups (or up to available markers)
	var num_pickups = min(randi_range(1, 3), pickup_markers.size())
	var pickup_keys = PICKUP_ITEMS.keys()
	print("Will spawn ", num_pickups, " pickups from ", pickup_keys.size(), " item types")

	# Shuffle markers to randomize which ones are used
	var shuffled_markers = pickup_markers.duplicate()
	shuffled_markers.shuffle()

	for i in num_pickups:
		if i >= shuffled_markers.size():
			print("Breaking: i (", i, ") >= shuffled_markers.size() (", shuffled_markers.size(), ")")
			break

		var marker = shuffled_markers[i]
		print("Processing marker ", i, ": ", marker)

		if not marker or not is_instance_valid(marker):
			print("Marker ", i, " is invalid, skipping")
			continue

		var random_item_key = pickup_keys[randi() % pickup_keys.size()]
		var spawn_position = marker.global_position
		print("Spawning ", random_item_key, " at position: ", spawn_position)

		spawn_pickup(random_item_key, spawn_position)

	print("=== Finished spawning pickups ===")

func spawn_pickup(item_name: String, spawn_pos: Vector2) -> void:
	print("spawn_pickup() called with item: ", item_name, " at pos: ", spawn_pos)

	if not item_name in PICKUP_ITEMS:
		push_error("Unknown pickup item: ", item_name)
		return

	if not PICKUP_SCENE:
		push_error("PICKUP_SCENE is null!")
		return

	var pickup = PICKUP_SCENE.instantiate()
	if not pickup:
		push_error("Failed to instantiate pickup scene!")
		return

	pickup.item_type = item_name

	# Add to tree first, then set position (similar to enemy spawning)
	add_child(pickup)

	# Use call_deferred to set position after node is fully in tree
	call_deferred("_set_pickup_position", pickup, spawn_pos)
	print("Added pickup to scene tree, will set position to: ", spawn_pos)

func _set_pickup_position(pickup: PickupItem, spawn_pos: Vector2) -> void:
	if pickup and is_instance_valid(pickup):
		pickup.global_position = spawn_pos
		print("Set pickup global_position to: ", pickup.global_position)
