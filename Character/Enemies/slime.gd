extends Enemy
class_name Slime

## Slime enemy that uses navigation for pathfinding

@export var patrol_range: float = 80.0  # How far the slime patrols
@export var patrol_speed: float = 40.0   # Patrol movement speed
@export var attack_range: float = 30.0   # Distance to start attacking
@export var attack_cooldown: float = 2.0  # Time between attacks
@export var attack_damage: int = 10  # Damage dealt by slime attacks

@onready var attack_hitbox: Area2D = $AttackHitbox

var start_position: Vector2
var patrol_target: Vector2
var is_attacking: bool = false
var attack_timer: float = 0.0

func _ready() -> void:
	super._ready()
	start_position = global_position
	patrol_target = start_position + Vector2(patrol_range, 0)

	# Set slime-specific stats
	max_speed = patrol_speed
	acceleration = 25

	# Automatically find and set player as target
	find_player()

	# Connect attack hitbox signals
	if attack_hitbox:
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
		attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)

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

		# Check if player is in attack range
		if distance_to_target <= attack_range and not is_attacking and attack_timer <= 0.0:
			start_attack()
		else:
			# Chase target
			set_navigation_target(target.global_position)
			var nav_direction = get_navigation_direction()
			if nav_direction == Vector2.ZERO:
				move_direction = (target.global_position - global_position).normalized()
			else:
				move_direction = nav_direction
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

func start_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	attack_timer = attack_cooldown
	# Enable hitbox for attack
	if attack_hitbox:
		attack_hitbox.monitoring = true
		# Check for overlapping bodies immediately (in case player is already in range)
		call_deferred("_check_overlapping_bodies")
		# Disable after attack duration
		call_deferred("_finish_attack")

func _finish_attack() -> void:
	await get_tree().create_timer(0.3).timeout
	if attack_hitbox:
		attack_hitbox.monitoring = false
	is_attacking = false

func _check_overlapping_bodies() -> void:
	if not attack_hitbox or not is_attacking:
		return

	# Get all overlapping bodies
	var overlapping_bodies = attack_hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		_process_hit(body)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking:
		_process_hit(body)

func _process_hit(body: Node2D) -> void:
	if body is Player and is_attacking:
		# Deal damage to player
		body.take_damage(attack_damage)
		print("Player hit by slime for ", attack_damage, " damage!")

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player and is_attacking:
		pass
