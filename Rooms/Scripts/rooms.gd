extends Node2D

# ---------- CONSTANTS ----------
const SPAWN_ROOMS: Array = [
	preload("res://Rooms/Scenes/Spawn_Room_A.tscn"),
	preload("res://Rooms/Scenes/Spawn_Room_B.tscn")
]
const INTERMEDIATE_ROOMS: Array = [preload("res://Rooms/Scenes/Room.tscn")]
const SPECIAL_ROOMS: Array = [preload("res://Rooms/Scenes/Room.tscn")] # Add your special room scenes here
const END_ROOMS: Array = [preload("res://Rooms/Scenes/end_room.tscn")]

# If you have a boss room scene, add it here
# const SLIME_BOSS_SCENE: PackedScene = preload("res://Rooms/SlimeBossRoom.tscn")

const TILE_SIZE: int = 16
const GROUND_TILE := Vector2i(2, 1)
const RIGHT_WALL_TILE := Vector2i(3, 5)
const LEFT_WALL_TILE := Vector2i(4, 5)

# ---------- EXPORTS ----------
@export var num_levels: int = 5

# ---------- VARIABLES ----------
# Simple SavedData alternative - you can replace this with your actual SavedData
var num_floor: int = 2

# ---------- NODE REFERENCES ----------
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D

# ---------- LIFECYCLE ----------
func _ready() -> void:
	num_floor += 1

	if num_floor == 3:
		num_levels = 3

	_spawn_rooms()

# ---------- ROOM GENERATION ----------
func _spawn_rooms() -> void:
	var previous_room: Node2D = null
	var special_room_spawned: bool = false

	for i in num_levels:
		var room: Node2D

		if i == 0:
			room = _generate_spawn_room()
		else:
			if previous_room == null:
				push_error("Previous room is null when trying to connect rooms")
				continue

			if i == num_levels - 1:
				room = _generate_end_room()
			else:
				var room_result = _generate_intermediate_room(i, special_room_spawned)
				room = room_result.room
				special_room_spawned = room_result.is_special

			_connect_room_with_corridor(previous_room, room)

		add_child(room)
		_clear_entrance_walls(room, i, previous_room)
		previous_room = room

# ---------- ROOM TYPE GENERATION ----------
func _generate_spawn_room() -> Node2D:
	var room = SPAWN_ROOMS[randi() % SPAWN_ROOMS.size()].instantiate()

	# Position player at spawn
	var spawn_pos = room.get_node_or_null("PlayerSpawn/PlayerSpawnMarker")
	if spawn_pos and player:
		player.global_position = spawn_pos.global_position

	return room

func _generate_end_room() -> Node2D:
	return END_ROOMS[randi() % END_ROOMS.size()].instantiate()

func _generate_intermediate_room(room_index: int, special_room_spawned: bool) -> Dictionary:
	# Check for boss room on floor 3
	# if num_floor == 3:
	# 	return {"room": SLIME_BOSS_SCENE.instantiate(), "is_special": true}
	# Special room logic
	var is_special: bool = false
	var room: Node2D

	if (randi() % 3 == 0 and not special_room_spawned) or (room_index == num_levels - 2 and not special_room_spawned):
		room = SPECIAL_ROOMS[randi() % SPECIAL_ROOMS.size()].instantiate()
		is_special = true
	else:
		room = INTERMEDIATE_ROOMS[randi() % INTERMEDIATE_ROOMS.size()].instantiate()

	return {"room": room, "is_special": is_special}

# ---------- CORRIDOR CONNECTION ----------
func _connect_room_with_corridor(previous_room: Node2D, room: Node2D) -> void:
	var previous_room_nav: NavigationRegion2D = previous_room.get_node_or_null("NavigationRegion2D")
	var previous_room_door: Node2D = previous_room.get_node_or_null("Door/Door")

	if not previous_room_nav or not previous_room_door:
		return

	var previous_room_ground: TileMapLayer = previous_room_nav.get_node_or_null("Ground")
	if not previous_room_ground:
		return

	# Convert door position to tile coordinates
	var door_local_pos = previous_room_ground.to_local(previous_room_door.global_position)
	var exit_tile_pos: Vector2i = previous_room_ground.local_to_map(door_local_pos) + Vector2i.UP * 2

	# Create corridor
	var corridor_height: int = randi() % 5 + 2
	_create_corridor_tiles(previous_room_ground, exit_tile_pos, corridor_height)

	# Position new room
	_position_new_room(room, previous_room_door, corridor_height)

func _create_corridor_tiles(ground_layer: TileMapLayer, exit_tile_pos: Vector2i, corridor_height: int) -> void:
	for y in corridor_height:
		# Set corridor tiles in previous room - using source_id 2, atlas_coords for tiles
		ground_layer.set_cell(exit_tile_pos + Vector2i(-2, -y), 2, LEFT_WALL_TILE)
		ground_layer.set_cell(exit_tile_pos + Vector2i(-1, -y), 2, GROUND_TILE)
		ground_layer.set_cell(exit_tile_pos + Vector2i(0, -y), 2, GROUND_TILE)
		ground_layer.set_cell(exit_tile_pos + Vector2i(1, -y), 2, RIGHT_WALL_TILE)

func _position_new_room(room: Node2D, previous_room_door: Node2D, corridor_height: int) -> void:
	var new_room_nav: NavigationRegion2D = room.get_node_or_null("NavigationRegion2D")
	if not new_room_nav:
		return

	var new_room_ground: TileMapLayer = new_room_nav.get_node_or_null("Ground")
	if not new_room_ground:
		return

	var used_rect = new_room_ground.get_used_rect()
	var entrance_pos = room.get_node_or_null("Entrance/Marker2D")

	if entrance_pos:
		# Get entrance position in local coordinates before positioning room
		var entrance_local_pos = entrance_pos.position

		# Calculate room position - align entrance with corridor
		# Position room so entrance aligns with the corridor exit
		var corridor_exit_world = previous_room_door.global_position + Vector2.UP * (corridor_height + 1) * TILE_SIZE
		room.position = corridor_exit_world - entrance_local_pos + Vector2.LEFT * TILE_SIZE * 0.5
	else:
		# Fallback positioning
		room.position = previous_room_door.global_position + Vector2.UP * used_rect.size.y * TILE_SIZE + Vector2.UP * (1 + corridor_height) * TILE_SIZE + Vector2.LEFT * TILE_SIZE * 0.5

# ---------- ENTRANCE MANAGEMENT ----------
func _clear_entrance_walls(room: Node2D, room_index: int, previous_room: Node2D) -> void:
	if room_index == 0 or previous_room == null:
		return

	var room_nav: NavigationRegion2D = room.get_node_or_null("NavigationRegion2D")
	if not room_nav:
		return

	var room_wall: TileMapLayer = room_nav.get_node_or_null("Wall")
	var room_ground: TileMapLayer = room_nav.get_node_or_null("Ground")

	if not room_wall or not room_ground:
		return

	# Wait a frame for room to be fully in tree
	await get_tree().process_frame

	var entrance_markers = room.get_node_or_null("Entrance")
	if not entrance_markers:
		return

	for marker in entrance_markers.get_children():
		if not marker:
			continue

		# Use local position since room is now in tree
		var entrance_local = marker.position
		var entrance_cell = room_wall.local_to_map(entrance_local)

		# Clear wall at entrance to connect hallway
		room_wall.set_cell(entrance_cell, -1)

		# Ensure floor is present at entrance
		var ground_cell = room_ground.local_to_map(entrance_local)
		if room_ground.get_cell_source_id(ground_cell) == -1:
			room_ground.set_cell(ground_cell, 2, GROUND_TILE)
