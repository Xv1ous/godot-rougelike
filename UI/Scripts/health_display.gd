extends Control
class_name HealthDisplay

## Heart-based health display using health_ui.png sprite

@export var max_hearts: int = 5
@export var heart_size: Vector2 = Vector2(16, 16)
@export var heart_spacing: float = 2.0

var current_hearts: int = 5
var heart_texture: Texture2D = null

@onready var hearts_container: HBoxContainer = $HeartsContainer

func _ready() -> void:
	# Load health UI texture
	heart_texture = load("res://Asset/v1.1 dungeon crawler 16X16 pixel pack/ui (new)/health_ui.png")
	setup_hearts()

func setup_hearts() -> void:
	if not hearts_container:
		return

	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()

	# Create heart sprites
	for i in range(max_hearts):
		var heart_sprite = TextureRect.new()
		heart_sprite.texture = heart_texture
		heart_sprite.custom_minimum_size = heart_size
		heart_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		hearts_container.add_child(heart_sprite)

	update_hearts()

func set_hearts(hearts: int, max_hp: int = -1) -> void:
	current_hearts = clamp(hearts, 0, max_hearts)
	if max_hp > 0:
		max_hearts = max_hp
		setup_hearts()
	update_hearts()

func update_hearts() -> void:
	if not hearts_container:
		return

	var children = hearts_container.get_children()
	for i in range(children.size()):
		var heart = children[i]
		if i < current_hearts:
			# Full heart - show normally
			heart.modulate = Color.WHITE
			heart.visible = true
		else:
			# Empty heart - make it darker/transparent
			heart.modulate = Color(0.3, 0.3, 0.3, 0.5)
			heart.visible = true
