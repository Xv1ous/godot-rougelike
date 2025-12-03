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

func reload_navigation_for_new_floor() -> void:
	if not is_inside_tree():
		return

	# Wait a couple of frames for new rooms to be added
	await get_tree().process_frame
	await get_tree().process_frame
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

	# Check if used rect is valid
	if used_rect.size.x == 0 or used_rect.size.y == 0:
		return

	# Get tile size from TileSet - find first valid atlas source
	var tile_size = Vector2(16, 16) # Default tile size
	var tile_set = ground_layer.tile_set

	if tile_set:
		# Try to find the first valid TileSetAtlasSource by checking common source IDs
		# Source IDs in Godot 4 can be any integer, so we try a range
		for source_id in range(0, 10):
			if not tile_set.has_source(source_id):
				continue
			var source = tile_set.get_source(source_id)
			if source is TileSetAtlasSource:
				var atlas_source: TileSetAtlasSource = source
				tile_size = Vector2(atlas_source.texture_region_size)
				break

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
