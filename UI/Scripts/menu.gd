extends Control
class_name Menu

## Main menu controller

@onready var start_button: TextureButton = $VBoxContainer/StartButton
@onready var options_button: TextureButton = $VBoxContainer/OptionsButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton

func _ready() -> void:
	# Connect button signals
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed() -> void:
	# Load the game scene
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_options_button_pressed() -> void:
	# Show options menu (you can implement this later)
	print("Options button pressed")

func _on_quit_button_pressed() -> void:
	# Quit the game
	get_tree().quit()
