@tool
extends Room
class_name SpawnRoom

# ---------- EXPORTS ----------
@export var player_scene: PackedScene
@export var attach_player_instance: bool = false

# ---------- NODE REFERENCES ----------
@onready var player_spawn_marker: Marker2D = $PlayerSpawn/PlayerSpawnMarker

# ---------- LIFECYCLE ----------
func _ready() -> void:
	super._ready()
	num_enemies = 0
	call_deferred("_position_player_at_spawn")
	call_deferred("_open_spawn_room_exits")

	if attach_player_instance:
		if not get_tree().get_first_node_in_group("player"):
			spawn_player_instance()

# ---------- GAMEPLAY ----------
func _spawn_enemies() -> void:
	pass

func _on_player_detector_body_entered(body: Node2D) -> void:
	super._on_player_detector_body_entered(body)
	call_deferred("_open_spawn_room_exits")

# ---------- DOOR MANAGEMENT ----------
func _open_spawn_room_exits() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Open doors immediately for spawn room (set to fully open frame)
	if door_container:
		for door in door_container.get_children():
			if door.has_node("AnimatedSprite2D"):
				var sprite = door.get_node("AnimatedSprite2D")
				sprite.frame = 14  # Set to fully open frame immediately
				# Also disable collision
				if door.has_node("CollisionShape2D"):
					door.get_node("CollisionShape2D").disabled = true

	_open_door()
	await get_tree().create_timer(0.1).timeout
	_open_entrance()

# ---------- PLAYER SPAWNING ----------
func get_player_spawn_position() -> Vector2:
	if player_spawn_marker:
		return player_spawn_marker.global_position
	return global_position

func _position_player_at_spawn() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	if not player_spawn_marker:
		var marker = get_node_or_null("PlayerSpawn/PlayerSpawnMarker")
		if marker:
			player.global_position = marker.global_position
		return

	player.global_position = player_spawn_marker.global_position

func spawn_player_instance() -> Node:
	if not player_scene:
		return null

	var instance := player_scene.instantiate()
	if player_spawn_marker:
		instance.global_position = player_spawn_marker.global_position
	add_child(instance)
	return instance
