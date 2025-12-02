extends CharacterBody2D
class_name Character

## Shared character movement and animations

const FRICTION := 0.15

@export var acceleration: int = 40
@export var max_speed: int = 100
@export var knockback_force: float = 200.0 # Base knockback force
@export var knockback_decay: float = 0.85 # How fast knockback decays (0-1, lower = faster decay)

var move_direction: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO # Current knockback velocity

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Nothing needed here yet, state machine will auto-start
	pass


## Child classes (Player/Enemy) will override this
func _process(delta: float) -> void:
	# Base class does nothing
	pass
