extends Node
class_name StateMachine

## Manages state transitions and updates

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Get all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transition_requested.connect(_on_transition_requested)

	# Set initial state after everything is ready
	# Use call_deferred to ensure SpriteFrames are loaded
	if states.has("idle"):
		call_deferred("change_state", "idle")

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func change_state(state_name: String) -> void:
	var new_state = states.get(state_name.to_lower())
	if not new_state:
		push_error("State '%s' not found!" % state_name)
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()

func _on_transition_requested(new_state: String) -> void:
	change_state(new_state)
