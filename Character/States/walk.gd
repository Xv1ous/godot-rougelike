extends State
class_name WalkState

## Character is moving

func enter() -> void:
	if character.animated_sprite and character.animated_sprite.sprite_frames:
		# Try "run" first (knight animation), fallback to "walk" for other characters
		if character.animated_sprite.sprite_frames.has_animation("run"):
			character.animated_sprite.play("run")
		elif character.animated_sprite.sprite_frames.has_animation("walk"):
			character.animated_sprite.play("walk")
		# Flip sprite based on movement direction
		if character.move_direction.x < 0:
			character.animated_sprite.flip_h = true
		elif character.move_direction.x > 0:
			character.animated_sprite.flip_h = false

func update(delta: float) -> void:
	# Check if stopped moving (check in _process after move_direction is updated)
	if character.move_direction == Vector2.ZERO:
		transition_requested.emit("idle")
		return

	# Flip sprite based on movement direction
	if character.animated_sprite:
		if character.move_direction.x < 0:
			character.animated_sprite.flip_h = true
		elif character.move_direction.x > 0:
			character.animated_sprite.flip_h = false

func physics_update(delta: float) -> void:
	# Apply movement
	character.velocity = lerp(character.velocity, Vector2.ZERO, character.FRICTION)
	character.velocity += character.move_direction * character.acceleration
	character.velocity = character.velocity.limit_length(character.max_speed)
	character.move_and_slide()
