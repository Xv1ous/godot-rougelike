extends Node2D

# ---------- NODE REFERENCES ----------
@onready var dungeon_container: Node2D = $DungeonContainer
@onready var grid_width_label: Label = $UI/Control/VBoxContainer/GridWidthLabel
@onready var grid_width_slider: HSlider = $UI/Control/VBoxContainer/GridWidthSlider
@onready var grid_height_label: Label = $UI/Control/VBoxContainer/GridHeightLabel
@onready var grid_height_slider: HSlider = $UI/Control/VBoxContainer/GridHeightSlider
@onready var min_rooms_label: Label = $UI/Control/VBoxContainer/MinRoomsLabel
@onready var min_rooms_slider: HSlider = $UI/Control/VBoxContainer/MinRoomsSlider
@onready var max_rooms_label: Label = $UI/Control/VBoxContainer/MaxRoomsLabel
@onready var max_rooms_slider: HSlider = $UI/Control/VBoxContainer/MaxRoomsSlider
@onready var generate_button: Button = $UI/Control/VBoxContainer/GenerateButton
@onready var clear_button: Button = $UI/Control/VBoxContainer/ClearButton
@onready var info_label: Label = $UI/Control/VBoxContainer/InfoLabel
@onready var stats_label: Label = $UI/Control/VBoxContainer/StatsLabel

# ---------- VARIABLES ----------
var dungeon_generator_script: GDScript = preload("res://Rooms/dungeon_generator.gd")
var current_generator: DungeonGenerator = null

# ---------- LIFECYCLE ----------
func _ready() -> void:
	# Connect signals
	if grid_width_slider:
		grid_width_slider.value_changed.connect(_on_grid_width_changed)
	if grid_height_slider:
		grid_height_slider.value_changed.connect(_on_grid_height_changed)
	if min_rooms_slider:
		min_rooms_slider.value_changed.connect(_on_min_rooms_changed)
	if max_rooms_slider:
		max_rooms_slider.value_changed.connect(_on_max_rooms_changed)
	if generate_button:
		generate_button.pressed.connect(_on_generate_button_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_button_pressed)

	# Initialize UI
	_update_ui()

# ---------- UI UPDATES ----------
func _update_ui() -> void:
	if grid_width_label:
		grid_width_label.text = "Grid Width: " + str(int(grid_width_slider.value))
	if grid_height_label:
		grid_height_label.text = "Grid Height: " + str(int(grid_height_slider.value))
	if min_rooms_label:
		min_rooms_label.text = "Min Rooms: " + str(int(min_rooms_slider.value))
	if max_rooms_label:
		max_rooms_label.text = "Max Rooms: " + str(int(max_rooms_slider.value))

	# Update max_rooms minimum to be >= min_rooms
	if max_rooms_slider.value < min_rooms_slider.value:
		max_rooms_slider.value = min_rooms_slider.value

# ---------- SIGNAL HANDLERS ----------
func _on_grid_width_changed(value: float) -> void:
	_update_ui()

func _on_grid_height_changed(value: float) -> void:
	_update_ui()

func _on_min_rooms_changed(value: float) -> void:
	_update_ui()

func _on_max_rooms_changed(value: float) -> void:
	_update_ui()

func _on_generate_button_pressed() -> void:
	generate_dungeon()

func _on_clear_button_pressed() -> void:
	clear_dungeon()

# ---------- DUNGEON GENERATION ----------
func generate_dungeon() -> void:
	# Clear existing dungeon first
	clear_dungeon()

	# Create new dungeon generator instance
	var generator = Node2D.new()
	generator.set_script(dungeon_generator_script)

	# Set parameters before adding to tree (so _ready doesn't run yet)
	generator.grid_width = int(grid_width_slider.value)
	generator.grid_height = int(grid_height_slider.value)
	generator.min_rooms = int(min_rooms_slider.value)
	generator.max_rooms = int(max_rooms_slider.value)

	# Add to container - this will trigger _ready() and generate_dungeon()
	dungeon_container.add_child(generator)
	current_generator = generator as DungeonGenerator

	# Wait for generation to complete
	await get_tree().process_frame
	await get_tree().process_frame

	# Update stats
	_update_stats()

	if info_label:
		info_label.text = "Dungeon generated successfully!"
	print("Dungeon generated with ", current_generator.generated_rooms.size(), " rooms and ", current_generator.generated_hallways.size(), " hallways")

func clear_dungeon() -> void:
	for child in dungeon_container.get_children():
		child.queue_free()
	current_generator = null

	if info_label:
		info_label.text = "Dungeon cleared"
	if stats_label:
		stats_label.text = "No dungeon generated"

func _update_stats() -> void:
	if not current_generator:
		return

	var room_count = current_generator.generated_rooms.size()
	var hallway_count = current_generator.generated_hallways.size()
	var spawn_room = current_generator.get_spawn_room()

	var stats_text = "Dungeon Stats:\n"
	stats_text += "Rooms: " + str(room_count) + "\n"
	stats_text += "Hallways: " + str(hallway_count) + "\n"
	stats_text += "Grid Size: " + str(current_generator.grid_width) + "x" + str(current_generator.grid_height) + "\n"

	if spawn_room:
		stats_text += "Spawn Room: Found"
	else:
		stats_text += "Spawn Room: Not found"

	if stats_label:
		stats_label.text = stats_text
