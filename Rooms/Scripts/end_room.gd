@tool
extends Room
class_name EndRoom


var _floor_transition_started: bool = false


func _ready() -> void:
	# Keep base Room setup (entrance, player detector, etc.)
	super._ready()
	# End room doesn't spawn enemies
	num_enemies = 0


func _on_player_detector_body_entered(body: Node2D) -> void:
	# Only react in game, not in editor
	if Engine.is_editor_hint():
		return

	# Ignore if already triggered
	if _floor_transition_started:
		return

	# Only trigger when the player enters
	if not body.is_in_group("player"):
		return

	_floor_transition_started = true

	var tree := get_tree()
	if not tree:
		return

	# Ask UI to play a fade-out transition if available
	var ui_node := tree.get_first_node_in_group("ui")
	if ui_node and ui_node.has_method("play_floor_transition"):
		await ui_node.play_floor_transition()
	else:
		await tree.create_timer(0.3).timeout

	# After fade-out, reload the main game scene to start a new floor
	tree.change_scene_to_file("res://Scenes/game.tscn")
