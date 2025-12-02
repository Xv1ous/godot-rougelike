extends Enemy
class_name Goblin

## Goblin enemy that uses navigation for pathfinding

@export var patrol_range: float = 100.0  # How far the goblin patrols
@export var patrol_speed: float = 50.0   # Patrol movement speed
@export var attack_range: float = 50.0   # Distance to start attacking
@export var attack_cooldown: float = 1.5  # Time between attacks
@export var attack_damage: int = 15  # Damage dealt by goblin attacks

@onready var dagger: Node2D = $Dagger
@onready var dagger_animation: AnimationPlayer = $Dagger/DaggerAnimationPlayer
@onready var dagger_hitbox: Area2D = $Dagger/Hitbox

var start_position: Vector2
var patrol_target: Vector2
var is_attacking: bool = false
var attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	start_position = global_position
	patrol_target = start_position + Vector2(patrol_range, 0)

	# Set goblin-specific stats
	max_speed = patrol_speed
	acceleration = 30

	# Automatically find and set player as target
	find_player()

	# Connect dagger hitbox signals
	if dagger_hitbox:
		dagger_hitbox.body_entered.connect(_on_dagger_hitbox_body_entered)
		dagger_hitbox.area_entered.connect(_on_dagger_hitbox_area_entered)

	# Connect animation finished signal
	if dagger_animation:
		dagger_animation.animation_finished.connect(_on_dagger_animation_finished)

func find_player() -> void:
	# Find the player node in the scene tree
	# Search from the root of the scene
	var scene_root = get_tree().current_scene
	if scene_root:
		# Try finding by node name first (most reliable)
		var player_node = scene_root.get_node_or_null("Player")
		if player_node:
			target = player_node
			return

		# If not found by name, search for Player class
		_find_player_recursive(scene_root)

func _find_player_recursive(node: Node) -> void:
	if node is Player:
		target = node
		return

	for child in node.get_children():
		_find_player_recursive(child)

func setup_navigation() -> void:
	super.setup_navigation()
	# Set initial patrol target for navigation
	navigation_agent.target_position = patrol_target

func _process(delta: float) -> void:
	# Call parent's _process to handle invincibility
	super._process(delta)

	# Make sure navigation agent is ready
	if not navigation_agent:
		return

	# Update attack timer
	if attack_timer > 0.0:
		attack_timer -= delta

	# Update navigation target and handle attacks
	if target:
		var distance_to_target = global_position.distance_to(target.global_position)

		# Check if player is in attack range
		if distance_to_target <= attack_range and not is_attacking and attack_timer <= 0.0:
			# Face the player and attack
			face_target()
			start_dagger_attack()
		else:
			# Chase target if assigned
			set_navigation_target(target.global_position)

			# Use navigation to get movement direction
			var nav_direction = get_navigation_direction()

			# Fallback to direct movement if navigation isn't working
			if nav_direction == Vector2.ZERO:
				# Direct movement toward target as fallback
				move_direction = (target.global_position - global_position).normalized()
			else:
				move_direction = nav_direction
	else:
		# Patrol behavior
		patrol_behavior()

		# Use navigation to get movement direction
		var nav_direction = get_navigation_direction()
		move_direction = nav_direction

func patrol_behavior() -> void:
	# Check if reached patrol target
	var distance_to_target = global_position.distance_to(navigation_agent.target_position)

	if distance_to_target < 5.0:
		# Reached target, set new patrol target
		if patrol_target.distance_to(start_position) > patrol_range * 0.9:
			# At far end, go back to start
			patrol_target = start_position
		else:
			# At start, go to far end
			patrol_target = start_position + Vector2(patrol_range, 0)

		set_navigation_target(patrol_target)

func face_target() -> void:
	# Rotate dagger toward target
	if target and dagger:
		var direction_to_target = (target.global_position - global_position).normalized()
		dagger.rotation = direction_to_target.angle()

func start_dagger_attack() -> void:
	if is_attacking or not dagger_animation:
		return

	is_attacking = true
	attack_timer = attack_cooldown
	# Check for overlapping bodies immediately (in case player is already in range)
	if dagger_hitbox:
		call_deferred("_check_overlapping_bodies")
	dagger_animation.play("dagger_attack")

func _on_dagger_animation_finished(anim_name: StringName) -> void:
	if anim_name == "dagger_attack" or anim_name == "charge_attack":
		is_attacking = false

func _check_overlapping_bodies() -> void:
	if not dagger_hitbox or not is_attacking:
		return

	# Get all overlapping bodies
	var overlapping_bodies = dagger_hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		_process_hit(body)

func _on_dagger_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking:
		_process_hit(body)

func _process_hit(body: Node2D) -> void:
	# Check if player entered the hitbox
	if body is Player and is_attacking:
		# Deal damage to player and apply knockback
		body.take_damage(attack_damage, global_position)
		print("Player hit by goblin dagger for ", attack_damage, " damage!")

func _on_dagger_hitbox_area_entered(area: Area2D) -> void:
	# Check if player's sword area entered (for clashing)
	if area.get_parent() is Player and is_attacking:
		# Sword clash! You can add parry logic here
		pass
