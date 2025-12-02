extends Node
class_name State

## Base class for all character states
## Each state handles its own logic and transitions

signal transition_requested(new_state: String)

var character: Character

func _ready() -> void:
	# Get the Character node (parent of StateMachine)
	var state_machine = get_parent()
	if state_machine:
		var char_node = state_machine.get_parent()
		if char_node is Character:
			character = char_node

## Called when entering this state
func enter() -> void:
	pass

## Called every frame while in this state
func update(delta: float) -> void:
	pass

## Called in _physics_process while in this state
func physics_update(delta: float) -> void:
	pass

## Called when exiting this state
func exit() -> void:
	pass
