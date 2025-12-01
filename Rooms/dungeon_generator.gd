extends Node2D
class_name DungeonGenerator

# ---------- CONSTANTS ----------
const ROOM_SIZE := Vector2(320, 180) # Size of each room in pixels
const HALLWAY_LENGTH := 64 # Length of hallway in pixels

# ---------- EXPORTS ----------
@export var grid_width: int = 5
@export var grid_height: int = 5
@export var min_rooms: int = 8
@export var max_rooms: int = 15

# Room scenes - using existing rooms from the folder
@export var room_scenes: Array[PackedScene] = [
	preload("res://Rooms/Room.tscn"),
	preload("res://Rooms/Spawn_Room_B.tscn")
]
@export var spawn_room_scene: PackedScene = preload("res://Rooms/Spawn_Room_A.tscn")
@export var hallway_scene: PackedScene = preload("res://Rooms/hallway.tscn")

# ---------- VARIABLES ----------
var rooms_grid: Array[Array] = [] # 2D array to track room positions
var generated_rooms: Array[Room] = []
var generated_hallways: Array[Hallway] = []
var spawn_room: SpawnRoom
var room_connections: Dictionary = {} # Track which rooms are connected

# ---------- LIFECYCLE ----------
func _ready() -> void:
	generate_dungeon()

# ---------- DUNGEON GENERATION ----------
func generate_dungeon() -> void:
	# Initialize grid
	rooms_grid.clear()
	generated_rooms.clear()

	for y in range(grid_height):
		rooms_grid.append([])
		for x in range(grid_width):
			rooms_grid[y].append(null)

	# Generate rooms using a simple algorithm
	var room_count = randi_range(min_rooms, max_rooms)
	var start_x = grid_width / 2
	var start_y = grid_height / 2

	# Place spawn room at center
	place_spawn_room(start_x, start_y)

	# Generate other rooms
	var placed_count = 1
	var current_positions = [Vector2i(start_x, start_y)]

	while placed_count < room_count and current_positions.size() > 0:
		var pos_index = randi() % current_positions.size()
		var current_pos = current_positions[pos_index]
		current_positions.remove_at(pos_index)

		# Try to place adjacent rooms
		var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		directions.shuffle()

		for dir in directions:
			if placed_count >= room_count:
				break

			var new_pos = current_pos + dir
			if is_valid_position(new_pos) and rooms_grid[new_pos.y][new_pos.x] == null:
				if randf() < 0.6: # 60% chance to place a room
					place_room(new_pos.x, new_pos.y)
					current_positions.append(new_pos)
					placed_count += 1

	# Connect rooms with hallways
	connect_rooms_with_hallways()

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height

func place_spawn_room(grid_x: int, grid_y: int) -> void:
	var room_instance = spawn_room_scene.instantiate() as SpawnRoom
	if not room_instance:
		push_error("Failed to instantiate spawn room")
		return

	var world_pos = Vector2(grid_x * ROOM_SIZE.x, grid_y * ROOM_SIZE.y)
	room_instance.position = world_pos
	add_child(room_instance)

	rooms_grid[grid_y][grid_x] = room_instance
	generated_rooms.append(room_instance)
	spawn_room = room_instance

func place_room(grid_x: int, grid_y: int) -> void:
	# Randomly select from available room scenes
	if room_scenes.is_empty():
		push_error("No room scenes available")
		return

	var selected_scene = room_scenes[randi() % room_scenes.size()]
	var room_instance = selected_scene.instantiate() as Room
	if not room_instance:
		push_error("Failed to instantiate room")
		return

	var world_pos = Vector2(grid_x * ROOM_SIZE.x, grid_y * ROOM_SIZE.y)
	room_instance.position = world_pos
	add_child(room_instance)

	rooms_grid[grid_y][grid_x] = room_instance
	generated_rooms.append(room_instance)

func connect_rooms_with_hallways() -> void:
	# First pass: identify all connections
	for y in range(grid_height):
		for x in range(grid_width):
			var room = rooms_grid[y][x]
			if not room:
				continue

			# Check adjacent rooms and create hallways
			var directions = [
				{"dir": Vector2i(0, -1), "hallway_dir": "vertical"}, # top
				{"dir": Vector2i(1, 0), "hallway_dir": "horizontal"}, # right
				{"dir": Vector2i(0, 1), "hallway_dir": "vertical"}, # bottom
				{"dir": Vector2i(-1, 0), "hallway_dir": "horizontal"} # left
			]

			for direction in directions:
				var check_pos = Vector2i(x, y) + direction.dir
				if is_valid_position(check_pos):
					var adjacent_room = rooms_grid[check_pos.y][check_pos.x]
					if adjacent_room:
						# Create a unique connection key to avoid duplicates
						var room1_key = str(x) + "," + str(y)
						var room2_key = str(check_pos.x) + "," + str(check_pos.y)
						var connection_key = ""

						# Always use the smaller key first to avoid duplicates
						if room1_key < room2_key:
							connection_key = room1_key + "->" + room2_key
						else:
							connection_key = room2_key + "->" + room1_key

						# Only create hallway if we haven't already created one for this connection
						if not room_connections.has(connection_key):
							place_hallway_between_rooms(
								Vector2i(x, y),
								check_pos,
								direction.hallway_dir
							)
							room_connections[connection_key] = true

func place_hallway_between_rooms(pos1: Vector2i, pos2: Vector2i, direction: String) -> void:
	if not hallway_scene:
		push_error("Hallway scene not loaded")
		return

	var hallway_instance = hallway_scene.instantiate() as Hallway
	if not hallway_instance:
		push_error("Failed to instantiate hallway")
		return

	# Calculate hallway position
	# Rooms are placed directly adjacent (touching), hallway creates the connection
	var room1_pos = Vector2(pos1.x * ROOM_SIZE.x, pos1.y * ROOM_SIZE.y)
	var room2_pos = Vector2(pos2.x * ROOM_SIZE.x, pos2.y * ROOM_SIZE.y)

	var hallway_pos: Vector2
	var hallway_length: int = 1
	var tile_size = 16 # 16x16 tiles

	if direction == "horizontal":
		# Horizontal hallway: placed at the connection point between rooms
		# Position at the right edge of room1, centered vertically
		hallway_pos = Vector2(
			room1_pos.x + ROOM_SIZE.x,
			room1_pos.y + ROOM_SIZE.y / 2 - HALLWAY_LENGTH / 2
		)
		# Since rooms touch, hallway spans the connection (typically 1-2 tiles)
		# For adjacent rooms, we want a short hallway
		hallway_length = max(2, int(ROOM_SIZE.x / tile_size / 4)) # Quarter room width
		hallway_instance.direction = "horizontal"
	else:
		# Vertical hallway: placed at the connection point between rooms
		# Position at the bottom edge of room1, centered horizontally
		hallway_pos = Vector2(
			room1_pos.x + ROOM_SIZE.x / 2 - HALLWAY_LENGTH / 2,
			room1_pos.y + ROOM_SIZE.y
		)
		# Since rooms touch, hallway spans the connection
		hallway_length = max(2, int(ROOM_SIZE.y / tile_size / 4)) # Quarter room height
		hallway_instance.direction = "vertical"

	hallway_instance.length = hallway_length
	hallway_instance.position = hallway_pos
	add_child(hallway_instance)
	generated_hallways.append(hallway_instance)

# ---------- UTILITY ----------
func get_spawn_room() -> SpawnRoom:
	return spawn_room

func get_all_rooms() -> Array[Room]:
	return generated_rooms
