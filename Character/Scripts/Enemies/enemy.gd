extends Character
class_name Enemy

## Basic enemy that extends Character with navigation support
## Override _process to add AI behavior

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

@export var target: Node2D = null # Target to chase (e.g., player)

## Health System
@export var max_health: int = 50
var current_health: int = 50

## Invincibility System
@export var invincibility_duration: float = 0.5 # Duration of invincibility frames in seconds
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var blink_timer: float = 0.0
const BLINK_SPEED: float = 0.1 # How fast to blink (lower = faster)

func _ready() -> void:
	super._ready()
	current_health = max_health
	# Ensure sprite starts at full opacity
	if animated_sprite:
		animated_sprite.modulate.a = 1.0
	add_to_group("enemies")
	# Wait for navigation to be ready
	call_deferred("setup_navigation")

func setup_navigation() -> void:
	# Wait for the first frame to ensure navigation map is ready
	await get_tree().physics_frame
	# Wait a bit more for navigation to fully initialize
	await get_tree().process_frame
	# Ensure navigation agent is ready
	if navigation_agent:
		navigation_agent.path_desired_distance = 4.0
		navigation_agent.target_desired_distance = 4.0
	# Child classes can override this to set initial navigation target

func _process(delta: float) -> void:
	# Override this in child classes or add AI behavior here
	# For now, enemies don't move automatically
	handle_invincibility(delta)

## Helper function to get movement direction using navigation
func get_navigation_direction() -> Vector2:
	if navigation_agent.is_navigation_finished():
		return Vector2.ZERO
	else:
		var next_path_position = navigation_agent.get_next_path_position()
		return (next_path_position - global_position).normalized()

## Helper function to set navigation target
func set_navigation_target(target_position: Vector2) -> void:
	navigation_agent.target_position = target_position

## Health System Functions
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	# Don't take damage if invincible
	if is_invincible:
		return

	current_health = max(0, current_health - amount)

	# Start invincibility frames
	start_invincibility()

	# Apply knockback if source position is provided
	if source_position != Vector2.ZERO:
		var knockback_direction = (global_position - source_position).normalized()
		knockback_velocity = knockback_direction * knockback_force

	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)

func start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = invincibility_duration
	blink_timer = 0.0

func handle_invincibility(delta: float) -> void:
	if is_invincible:
		invincibility_timer -= delta
		blink_timer += delta

		# Blink effect - alternate between visible and semi-transparent
		if blink_timer >= BLINK_SPEED:
			blink_timer = 0.0
			if animated_sprite:
				# Toggle between full opacity and semi-transparent
				if animated_sprite.modulate.a == 1.0:
					animated_sprite.modulate.a = 0.5
				else:
					animated_sprite.modulate.a = 1.0

		# End invincibility
		if invincibility_timer <= 0.0:
			is_invincible = false
			invincibility_timer = 0.0
			# Restore full opacity
			if animated_sprite:
				animated_sprite.modulate.a = 1.0

func die() -> void:
	print("Enemy died!")
	queue_free()
