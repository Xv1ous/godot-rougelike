@tool
extends Node2D
class_name Room

# ---------- CONSTANTS ----------
const ENEMY_SCENES := {
	"slime": preload("res://Character/Scenes/Enemies/slime.tscn"),
	"goblin": preload("res://Character/Scenes/Enemies/goblin.tscn"),
	"fly": preload("res://Character/Scenes/Enemies/flying_creature.tscn")
}

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
@onready var entrance: Node2D = $Entrance
@onready var door_container: Node2D = $Door
@onready var enemies_pos_container: Node2D = $EnemiesPosition
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
	if num_enemies <= 0:
		_open_door()
		_open_entrance()


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
