extends Enemy
class_name FlyingCreature

## Flying creature enemy - ranged attacker

@export var patrol_range: float = 120.0  # How far the flying creature patrols
@export var patrol_speed: float = 60.0   # Patrol movement speed
@export var attack_range: float = 150.0   # Distance to start attacking (ranged)
@export var attack_cooldown: float = 2.0  # Time between attacks
@export var preferred_distance: float = 100.0  # Preferred distance from player
@export var projectile_scene: PackedScene = preload("res://Character/Scenes/Enemies/projectile.tscn")

var start_position: Vector2
var patrol_target: Vector2
var is_attacking: bool = false
var attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	start_position = global_position
	patrol_target = start_position + Vector2(patrol_range, 0)

	# Set flying creature-specific stats
	max_speed = patrol_speed
	acceleration = 35

	# Automatically find and set player as target
	find_player()

func find_player() -> void:
	# Find the player node in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		var player_node = scene_root.get_node_or_null("Player")
		if player_node:
			target = player_node
			return
		_find_player_recursive(scene_root)

func _find_player_recursive(node: Node) -> void:
	if node is Player:
		target = node
		return
	for child in node.get_children():
		_find_player_recursive(child)

func setup_navigation() -> void:
	super.setup_navigation()
	navigation_agent.target_position = patrol_target

func _process(delta: float) -> void:
	# Call parent's _process to handle invincibility
	super._process(delta)

	if not navigation_agent:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if target:
		var distance_to_target = global_position.distance_to(target.global_position)

		# Check if player is in attack range (ranged attack)
		if distance_to_target <= attack_range and distance_to_target >= preferred_distance * 0.7 and not is_attacking and attack_timer <= 0.0:
			# Shoot projectile
			shoot_projectile()
		else:
			# Maintain preferred distance from player
			var direction_to_player = (target.global_position - global_position).normalized()

			if distance_to_target < preferred_distance * 0.7:
				# Too close, move away
				move_direction = -direction_to_player
			elif distance_to_target > preferred_distance * 1.3:
				# Too far, move closer
				set_navigation_target(target.global_position)
				var nav_direction = get_navigation_direction()
				if nav_direction == Vector2.ZERO:
					move_direction = direction_to_player
				else:
					move_direction = nav_direction
			else:
				# Good distance, strafe or maintain position
				move_direction = Vector2.ZERO
	else:
		# Patrol behavior
		patrol_behavior()
		var nav_direction = get_navigation_direction()
		move_direction = nav_direction

func patrol_behavior() -> void:
	var distance_to_target = global_position.distance_to(navigation_agent.target_position)
	if distance_to_target < 5.0:
		if patrol_target.distance_to(start_position) > patrol_range * 0.9:
			patrol_target = start_position
		else:
			patrol_target = start_position + Vector2(patrol_range, 0)
		set_navigation_target(patrol_target)

func shoot_projectile() -> void:
	if is_attacking or not projectile_scene or not target:
		return

	is_attacking = true
	attack_timer = attack_cooldown

	# Create projectile
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	# Position projectile at flying creature position
	projectile.global_position = global_position

	# Calculate direction to player
	var direction_to_player = (target.global_position - global_position).normalized()
	projectile.direction = direction_to_player

	# Rotate sprite to face direction
	if $AnimatedSprite2D:
		if direction_to_player.x < 0:
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false

	# Finish attack after a short delay
	await get_tree().create_timer(0.1).timeout
	is_attacking = false
