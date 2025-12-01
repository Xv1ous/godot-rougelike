extends CanvasLayer
class_name UI

## Main UI controller for the game

@onready var hearts_container: HBoxContainer = $HUD/HBoxContainer
@onready var pause_button: TextureButton = $HUD/TopBar/PauseButton
@onready var menu_button: TextureButton = $HUD/TopBar/MenuButton

var player: Player = null
var current_health: int = 100
var max_health: int = 100
var max_hearts: int = 5  # Maximum number of hearts to display
var hp_per_heart: int = 20  # HP per heart (100 HP / 5 hearts = 20)

# Heart textures
var heart_full_texture: Texture2D = null
var heart_half_texture: Texture2D = null
var heart_empty_texture: Texture2D = null

func _ready() -> void:
	# Load heart textures
	heart_full_texture = load("res://Asset/HUD_heart_red_full.png")
	heart_half_texture = load("res://Asset/HUD_heart_red_half.png")
	heart_empty_texture = load("res://Asset/HUD_heart_red_empty.png")

	# Find player in scene
	find_player()

	# Initialize hearts
	setup_hearts()
	update_hearts()

	# Connect button signals
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)

func find_player() -> void:
	# Find the player node
	var scene_root = get_tree().current_scene
	if scene_root:
		var player_node = scene_root.get_node_or_null("Player")
		if player_node:
			player = player_node
			# Connect to player health signals
			if player.has_signal("health_changed"):
				player.health_changed.connect(_on_player_health_changed)
			if player.has_signal("max_health_changed"):
				player.max_health_changed.connect(_on_player_max_health_changed)
			# Initialize health from player
			if player.has_method("get_health"):
				current_health = player.get_health()
			if player.has_method("get_max_health"):
				max_health = player.get_max_health()
				max_hearts = max_health / hp_per_heart
				setup_hearts()
				update_hearts()

func _process(_delta: float) -> void:
	# Update player reference if needed
	if not player:
		find_player()

	# Update health from player if available
	if player and player.has_method("get_health"):
		var new_health = player.get_health()
		if new_health != current_health:
			current_health = new_health

	if player and player.has_method("get_max_health"):
		var new_max_health = player.get_max_health()
		if new_max_health != max_health:
			max_health = new_max_health
			max_hearts = max_health / hp_per_heart
			setup_hearts()
			update_hearts()

	# Update hearts display
	update_hearts()

func set_health(health: int, max_hp: int = -1) -> void:
	current_health = health
	if max_hp > 0:
		max_health = max_hp
		max_hearts = max_health / hp_per_heart
		setup_hearts()
	update_hearts()

func setup_hearts() -> void:
	if not hearts_container:
		return

	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()

	# Create heart sprites
	for i in range(max_hearts):
		var heart_sprite = TextureRect.new()
		heart_sprite.custom_minimum_size = Vector2(16, 16)
		heart_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel-perfect filtering
		heart_sprite.modulate = Color(1, 1, 1, 1)  # Fully opaque
		hearts_container.add_child(heart_sprite)

	update_hearts()

func update_hearts() -> void:
	if not hearts_container:
		return

	# Calculate hearts to display
	var total_hearts = float(current_health) / float(hp_per_heart)
	var full_hearts = int(total_hearts)
	var has_half_heart = (total_hearts - full_hearts) >= 0.5

	var children = hearts_container.get_children()
	for i in range(children.size()):
		var heart = children[i] as TextureRect
		if i < full_hearts:
			# Full heart
			heart.texture = heart_full_texture
			heart.modulate = Color(1, 1, 1, 1)
		elif i == full_hearts and has_half_heart:
			# Half heart
			heart.texture = heart_half_texture
			heart.modulate = Color(1, 1, 1, 1)
		else:
			# Empty heart
			heart.texture = heart_empty_texture
			heart.modulate = Color(1, 1, 1, 1)

func _on_player_health_changed(new_health: int) -> void:
	current_health = new_health
	update_hearts()

func _on_player_max_health_changed(new_max_health: int) -> void:
	max_health = new_max_health
	max_hearts = max_health / hp_per_heart
	setup_hearts()
	update_hearts()

func _on_pause_button_pressed() -> void:
	# Toggle pause
	if get_tree().paused:
		get_tree().paused = false
		print("Game resumed")
	else:
		get_tree().paused = true
		print("Game paused")

func _on_menu_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://UI/menu.tscn")
