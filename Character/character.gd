extends CharacterBody2D
class_name Character

## Shared character movement and animations

const FRICTION := 0.15

@export var acceleration: int = 40
@export var max_speed: int = 100

var move_direction: Vector2 = Vector2.ZERO

@onready var state_machine: StateMachine = $StateMachine
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Nothing needed here yet, state machine will auto-start
	pass


## Child classes (Player/Enemy) will override this
func _process(delta: float) -> void:
	# Base class does nothing
	pass
