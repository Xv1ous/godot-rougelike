extends Node2D

# ---------- NODE REFERENCES ----------
@onready var rooms_node: Node2D = $Rooms

# ---------- LIFECYCLE ----------
func _ready() -> void:
	# Randomize seed for better randomization
	randomize()

	# Wait for rooms to generate, then setup navigation for all rooms
	await get_tree().process_frame
	await get_tree().process_frame # Extra frame for room generation
	setup_navigation_for_all_rooms()

# ---------- NAVIGATION SETUP ----------
func setup_navigation_for_all_rooms() -> void:
	if not rooms_node:
		return

	# Get all Room nodes that are children of the Rooms node
	for room in rooms_node.get_children():
		if room is Room and room.has_node("NavigationRegion2D"):
			var nav_region = room.get_node("NavigationRegion2D")
			var ground_layer = nav_region.get_node_or_null("Ground")

			if ground_layer:
				setup_room_navigation(nav_region, ground_layer)

func setup_room_navigation(nav_region: NavigationRegion2D, ground_layer: TileMapLayer) -> void:
	await get_tree().physics_frame

	if not nav_region or not ground_layer:
		return

	var nav_polygon = NavigationPolygon.new()
	var used_rect = ground_layer.get_used_rect()
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
