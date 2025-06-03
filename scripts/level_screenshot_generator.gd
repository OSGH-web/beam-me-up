# Run the associated scene (level_screenshot_generator.tscn)
# to generate screenshots of all levels
extends Node2D

var level_files = []

func _ready():
	create_screenshots_directory()
	load_levels()
	await process_all_levels()
	get_tree().quit()

func create_screenshots_directory():
	var dir = DirAccess.open("res://levels")
	if !dir.dir_exists("screenshots"):
		if dir.make_dir("screenshots") != OK:
			push_error("Failed to create screenshots directory")

func process_all_levels():
	var subviewport = $SubViewportContainer/SubViewport

	for level_file in level_files:
		var level_path = "res://levels/%s" % level_file
		var scene = load(level_path)

		if not scene:
			push_error("Failed to load scene: ", level_path)
			continue

		var level_instance = scene.instantiate()
		level_instance.get_node("Player").get_node("Camera").queue_free()

		# Clear previous level
		for child in subviewport.get_children():
			child.queue_free()

		subviewport.add_child(level_instance)

		var border_size_tiles = 3
		# don't show border if we're looking at a full screen level
		if level_instance.width_in_tiles >= 80 and level_instance.height_in_tiles >= 45:
			border_size_tiles = 0
		# Update viewport size
		subviewport.size = Vector2(
			level_instance.width_in_tiles * (24 + 2 * border_size_tiles),
			level_instance.height_in_tiles * (24 + 2 * border_size_tiles)
		)
		
		# position the level with an equal border on all sides
		level_instance.position = Vector2(
			level_instance.width_in_tiles * (1 * border_size_tiles),
			level_instance.height_in_tiles * (1 * border_size_tiles)
		)

		# Wait for proper rendering
		await get_tree().process_frame
		await RenderingServer.frame_post_draw

		# Capture and save screenshot
		var img = subviewport.get_texture().get_image()
		var save_path = "res://levels/screenshots/%s.png" % level_file.get_basename()
		img.save_png(save_path)
		print("Saved screenshot: ", save_path)

func load_levels():
	var dir = DirAccess.open("res://levels/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				level_files.append(file_name)
			file_name = dir.get_next()
		level_files.sort()
		dir.list_dir_end()
	else:
		push_error("Failed to access levels directory")
