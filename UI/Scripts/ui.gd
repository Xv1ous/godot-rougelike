extends CanvasLayer
class_name UI

## Main UI controller for the game

@onready var hearts_container: HBoxContainer = $HUD/HBoxContainer
@onready var pause_button: TextureButton = $HUD/TopBar/PauseButton
@onready var menu_button: TextureButton = $HUD/TopBar/MenuButton
@onready var defeat_label: Label = $HUD/DefeatLabel
@onready var retry_button: TextureButton = $HUD/RetryButton
@onready var defeat_menu_button: TextureButton = $HUD/DefeatMenuButton
@onready var pause_menu: Control = $PauseMenu
@onready var pause_resume_button: TextureButton = $PauseMenu/VBoxContainer/ResumeButton
@onready var pause_menu_button: TextureButton = $PauseMenu/VBoxContainer/PauseMenuButton
@onready var fade_layer: Control = $FadeLayer
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect

var player: Player = null
var current_health: int = 100
var max_health: int = 100
var max_hearts: int = 5 # Maximum number of hearts to display
var hp_per_heart: int = 20 # HP per heart (100 HP / 5 hearts = 20)

# Heart textures
var heart_full_texture: Texture2D = null
var heart_half_texture: Texture2D = null
var heart_empty_texture: Texture2D = null

func _ready() -> void:
	# Ensure UI keeps processing and receiving input while the game is paused (Godot 4)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ui")

	# Load heart textures
	heart_full_texture = load("res://Asset/HUD_heart_red_full.png")
	heart_half_texture = load("res://Asset/HUD_heart_red_half.png")
	heart_empty_texture = load("res://Asset/HUD_heart_red_empty.png")

	# Find player in scene
	find_player()

	# Initialize hearts
	setup_hearts()
	update_hearts()

	# Hide defeat UI initially
	if defeat_label:
		defeat_label.visible = false
	if retry_button:
		retry_button.visible = false
	if defeat_menu_button:
		defeat_menu_button.visible = false
	if pause_menu:
		pause_menu.visible = false
	if fade_layer:
		fade_layer.visible = false

	# Connect button signals
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_button_pressed)
	if defeat_menu_button:
		defeat_menu_button.pressed.connect(_on_defeat_menu_button_pressed)
	if pause_resume_button:
		pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	if pause_menu_button:
		pause_menu_button.pressed.connect(_on_pause_menu_button_pressed)

	# On scene load, fade in from black (pairs with EndRoom fade-out)
	# Use call_deferred to ensure nodes are fully ready
	call_deferred("fade_in_from_black")

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

func _input(event: InputEvent) -> void:
	# Allow ESC (ui_cancel) to toggle pause
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()

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
		heart_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # Pixel-perfect filtering
		heart_sprite.modulate = Color(1, 1, 1, 1) # Fully opaque
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

	# Show defeat UI when player health reaches zero
	if current_health <= 0:
		# Hide pause menu if it was open
		if pause_menu:
			pause_menu.visible = false

		if defeat_label:
			defeat_label.visible = true
		if retry_button:
			retry_button.visible = true
		if defeat_menu_button:
			defeat_menu_button.visible = true
		get_tree().paused = true

func _on_player_max_health_changed(new_max_health: int) -> void:
	max_health = new_max_health
	max_hearts = max_health / hp_per_heart
	setup_hearts()
	update_hearts()

func _on_pause_button_pressed() -> void:
	_toggle_pause_menu()

func _on_menu_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://UI/Scenes/menu.tscn")

func _on_retry_button_pressed() -> void:
	# Reload current scene to retry
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_defeat_menu_button_pressed() -> void:
	# Go back to main menu from defeat screen
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/Scenes/menu.tscn")

func _on_pause_resume_pressed() -> void:
	# Resume game from pause menu
	get_tree().paused = false
	if pause_menu:
		pause_menu.visible = false

func _on_pause_menu_button_pressed() -> void:
	# Go back to main menu from pause menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/Scenes/menu.tscn")

func _toggle_pause_menu() -> void:
	# Don't open pause menu if player is defeated
	if current_health <= 0:
		return

	if get_tree().paused:
		# Unpause and hide pause menu
		get_tree().paused = false
		if pause_menu:
			pause_menu.visible = false
	else:
		# Pause and show pause menu
		get_tree().paused = true
		if pause_menu:
			pause_menu.visible = true

func play_floor_transition() -> void:
	# Simple fade-to-black used when going to the next floor
	if not fade_rect or not fade_layer:
		await get_tree().create_timer(0.3).timeout
		return

	fade_layer.visible = true
	var color := fade_rect.color
	color.a = 0.0
	fade_rect.color = color

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished

func fade_in_from_black() -> void:
	if not fade_rect or not fade_layer:
		return

	# Start from fully opaque black
	fade_layer.visible = true
	var color := fade_rect.color
	color.a = 1.0
	fade_rect.color = color

	# Wait a frame to ensure everything is rendered
	await get_tree().process_frame

	# Create tween to fade in from black
	var tween := create_tween()
	if not tween:
		# Fallback: just hide the fade layer if tween creation fails
		fade_layer.visible = false
		return

	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)
	await tween.finished
	fade_layer.visible = false
