extends CharacterBody2D
class_name Projectile

## Simple projectile for ranged attacks

const Player = preload("res://Character/Scripts/player.gd")

@export var speed: float = 200.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Destroy projectile after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		velocity = direction * speed
		move_and_slide()

		# Check for collisions
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			# Check if it's a player
			if collider is Player:
				# Hit player
				hit_player(collider)
				queue_free()
			elif collider is TileMap:
				# Hit wall
				queue_free()

func hit_player(player: Player) -> void:
	# Deal damage to player and apply knockback
	player.take_damage(damage, global_position)
	print("Player hit by projectile for ", damage, " damage!")
