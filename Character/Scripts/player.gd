extends Character
class_name Player

# ---------- CONSTANTS ----------
const CHARGE_TIME: float = 0.5
const BLINK_SPEED: float = 0.1

# ---------- SIGNALS ----------
signal health_changed(new_health: int)
signal max_health_changed(new_max_health: int)

# ---------- EXPORTS ----------
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var charge_attack_damage: int = 40
@export var invincibility_duration: float = 1.0

# ---------- NODE REFERENCES ----------
@onready var sword: Node2D = $Sword
@onready var sword_animation: AnimationPlayer = $Sword/SwordAnimatonPlayer
@onready var sword_hitbox: Area2D = $Sword/Hitbox
@onready var camera: Camera2D = $Camera2D

# ---------- STATE VARIABLES ----------
var current_health: int = 100
var is_attacking: bool = false
var is_holding_attack: bool = false
var attack_hold_time: float = 0.0
var hit_enemies: Array[Node] = []
var is_invincible: bool = false
var invincibility_timer: float = 0.0
var blink_timer: float = 0.0

# ---------- LIFECYCLE ----------
func _ready() -> void:
	super._ready()
	add_to_group("player")
	current_health = max_health

	if animated_sprite:
		animated_sprite.modulate.a = 1.0

	if camera:
		camera.make_current()

	sword_animation.animation_finished.connect(_on_sword_animation_finished)

	if sword_hitbox:
		sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)
		sword_hitbox.monitoring = false

	call_deferred("_emit_initial_health")

func _process(delta: float) -> void:
	handle_movement_input()
	handle_sprite_flipping()
	handle_sword_rotation()
	handle_attack_input(delta)
	handle_invincibility(delta)

# ---------- HEALTH SYSTEM ----------
func _emit_initial_health() -> void:
	health_changed.emit(current_health)
	max_health_changed.emit(max_health)

func get_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	start_invincibility()

	# Apply knockback if source position is provided
	if source_position != Vector2.ZERO:
		var knockback_direction = (global_position - source_position).normalized()
		knockback_velocity = knockback_direction * knockback_force

	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func die() -> void:
	print("Player died!")

# ---------- INPUT HANDLING ----------
func handle_movement_input() -> void:
	move_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()

func handle_sprite_flipping() -> void:
	var mouse_direction = (get_global_mouse_position() - global_position).normalized()

	if mouse_direction.x < 0:
		sword.scale.y = -1
		animated_sprite.flip_h = true
	else:
		sword.scale.y = 1
		animated_sprite.flip_h = false

func handle_sword_rotation() -> void:
	if is_attacking:
		return

	var mouse_direction = (get_global_mouse_position() - global_position).normalized()
	sword.rotation = mouse_direction.angle()

# ---------- ATTACK SYSTEM ----------
func handle_attack_input(delta: float) -> void:
	if Input.is_action_just_pressed("ui_attack"):
		is_holding_attack = true
		attack_hold_time = 0.0
		return

	if Input.is_action_pressed("ui_attack") and is_holding_attack and not is_attacking:
		attack_hold_time += delta
		if attack_hold_time >= CHARGE_TIME:
			start_charge_attack()
			is_holding_attack = false
		return

	if Input.is_action_just_released("ui_attack") and is_holding_attack:
		if attack_hold_time < CHARGE_TIME:
			start_attack()
		is_holding_attack = false
		attack_hold_time = 0.0

func start_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	hit_enemies.clear()

	if sword_hitbox:
		sword_hitbox.monitoring = true
		call_deferred("_check_overlapping_bodies")

	sword_animation.play("sword_attack")

func start_charge_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	hit_enemies.clear()

	if sword_hitbox:
		sword_hitbox.monitoring = true
		call_deferred("_check_overlapping_bodies")

	sword_animation.play("charge_attack")

func _on_sword_animation_finished(anim_name: StringName) -> void:
	if anim_name == "sword_attack" or anim_name == "charge_attack":
		is_attacking = false
		if sword_hitbox:
			sword_hitbox.monitoring = false
		hit_enemies.clear()

func _check_overlapping_bodies() -> void:
	if not sword_hitbox or not is_attacking:
		return

	var overlapping_bodies = sword_hitbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		_process_hit(body)

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking:
		_process_hit(body)

func _process_hit(body: Node2D) -> void:
	if body is Enemy and is_attacking:
		if body in hit_enemies:
			return

		hit_enemies.append(body)

		var damage = attack_damage
		if sword_animation.current_animation == "charge_attack":
			damage = charge_attack_damage

		# Pass player position for knockback
		body.take_damage(damage, global_position)
		print("Player hit enemy for ", damage, " damage! Enemy health: ", body.current_health, "/", body.max_health)

# ---------- INVINCIBILITY SYSTEM ----------
func start_invincibility() -> void:
	is_invincible = true
	invincibility_timer = invincibility_duration
	blink_timer = 0.0

func handle_invincibility(delta: float) -> void:
	if is_invincible:
		invincibility_timer -= delta
		blink_timer += delta

		if blink_timer >= BLINK_SPEED:
			blink_timer = 0.0
			if animated_sprite:
				if animated_sprite.modulate.a == 1.0:
					animated_sprite.modulate.a = 0.5
				else:
					animated_sprite.modulate.a = 1.0

		if invincibility_timer <= 0.0:
			is_invincible = false
			invincibility_timer = 0.0
			if animated_sprite:
				animated_sprite.modulate.a = 1.0
