extends State
class_name IdleState

## Character is standing still

func enter() -> void:
	character.velocity = Vector2.ZERO
	if character.animated_sprite and character.animated_sprite.sprite_frames:
		if character.animated_sprite.sprite_frames.has_animation("idle"):
			character.animated_sprite.play("idle")

func update(delta: float) -> void:
	# Check for movement input (check in _process after move_direction is updated)
	if character.move_direction != Vector2.ZERO:
		transition_requested.emit("walk")

func physics_update(delta: float) -> void:
	# Apply friction
	character.velocity = lerp(character.velocity, Vector2.ZERO, character.FRICTION)
	character.move_and_slide()
