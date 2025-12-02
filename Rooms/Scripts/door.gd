extends StaticBody2D

# ---------- NODE REFERENCES ----------
@onready var animation_player : AnimationPlayer = $AnimationPlayer

# ---------- GAMEPLAY ----------
func open():
	if not is_inside_tree() or not animation_player:
		return

	if animation_player.has_animation("open"):
		animation_player.play("open")
