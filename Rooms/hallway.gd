@tool
extends Node2D
class_name Hallway

# ---------- CONSTANTS ----------
const HALLWAY_WIDTH := 64 # Width of hallway in pixels
const HALLWAY_HEIGHT := 64 # Height of hallway in pixels

# ---------- EXPORTS ----------
@export var direction: String = "horizontal" # "horizontal" or "vertical"
@export var length: int = 1 # Length in tiles

# ---------- NODE REFERENCES ----------
@onready var wall_layer: TileMapLayer = $NavigationRegion2D/Wall
@onready var ground_layer: TileMapLayer = $NavigationRegion2D/Ground
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D

# ---------- LIFECYCLE ----------
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_generate_hallway()

# ---------- HALLWAY GENERATION ----------
func _generate_hallway() -> void:
	if not wall_layer or not ground_layer:
		return

	# Clear existing tiles
	wall_layer.clear()
	ground_layer.clear()

	var tiles_per_cell = 2 # 2 tiles per 32 pixels (16x16 tiles)
	var width_tiles = int(HALLWAY_WIDTH / 16)
	var height_tiles = int(HALLWAY_HEIGHT / 16)

	if direction == "horizontal":
		# Horizontal hallway: walls on top and bottom, floor in middle
		for x in range(length * tiles_per_cell):
			# Top wall
			wall_layer.set_cell(Vector2i(x, 0), 2, Vector2i(1, 0))
			# Bottom wall
			wall_layer.set_cell(Vector2i(x, height_tiles - 1), 2, Vector2i(1, 0))
			# Floor tiles
			for y in range(1, height_tiles - 1):
				ground_layer.set_cell(Vector2i(x, y), 2, Vector2i(0, 0))
	else:
		# Vertical hallway: walls on left and right, floor in middle
		for y in range(length * tiles_per_cell):
			# Left wall
			wall_layer.set_cell(Vector2i(0, y), 2, Vector2i(1, 0))
			# Right wall
			wall_layer.set_cell(Vector2i(width_tiles - 1, y), 2, Vector2i(1, 0))
			# Floor tiles
			for x in range(1, width_tiles - 1):
				ground_layer.set_cell(Vector2i(x, y), 2, Vector2i(0, 0))

	wall_layer.queue_redraw()
	ground_layer.queue_redraw()

	# Setup navigation
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	if not nav_region or not ground_layer:
		return

	await get_tree().physics_frame

	var nav_polygon = NavigationPolygon.new()
	var used_rect = ground_layer.get_used_rect()

	if used_rect.size.x == 0 or used_rect.size.y == 0:
		return

	var source_id = 2
	var source = ground_layer.tile_set.get_source(source_id)

	if not source or not source is TileSetAtlasSource:
		return

	var atlas_source: TileSetAtlasSource = source
	var tile_size = Vector2(atlas_source.texture_region_size)
	var world_size = Vector2(used_rect.size) * tile_size
	var world_offset = Vector2(used_rect.position) * tile_size

	var outline = PackedVector2Array([
		world_offset,
		world_offset + Vector2(world_size.x, 0),
		world_offset + world_size,
		world_offset + Vector2(0, world_size.y)
	])

	nav_polygon.add_outline(outline)
	nav_polygon.make_polygons_from_outlines()

	nav_region.navigation_polygon = nav_polygon
	nav_region.bake_navigation_polygon()
