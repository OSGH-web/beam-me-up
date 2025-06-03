extends Control
class_name LevelSelect

@onready var button_container: GridContainer = %ButtonGrid
var level_files = []
var current_index := 0

func _ready():
	level_files = GameManager.load_levels(true)
	_create_level_grid()
	button_container.get_children()[0].grab_focus()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _create_level_grid():
	for child in button_container.get_children():
		child.queue_free()

	var n_levels = level_files.size()
	var button_scene = preload("res://scenes/UI/level_button.tscn")
	var tinted_style = preload("res://assets/styles/sbf_dark.tres")

	for i in n_levels:
		var button = button_scene.instantiate() as Button
		button.text = str(i + 1)
		button_container.add_child(button)
		button.pressed.connect(_on_level_selected.bind(i))
		button.focus_entered.connect(_focus.bind(i))
		button.mouse_entered.connect(_update_level_info_display.bind(i))
		button.mouse_exited.connect(_mouse_exit)
		if _dev_time_beat(i):
			button.add_theme_stylebox_override("normal", preload("res://assets/styles/sbf_light_border.tres"))
			button.add_theme_stylebox_override("hover", preload("res://assets/styles/sbf_light_border.tres"))
		elif _goal_time_beat(i):
			button.add_theme_stylebox_override("normal", preload("res://assets/styles/sbf_silver_border.tres"))
			button.add_theme_stylebox_override("hover", preload("res://assets/styles/sbf_silver_border.tres"))
			
	# update focus neighbors to allow for horizontal wrapping
	for i in n_levels:
		var neighbor_left_idx = (i - 1) % n_levels
		var neighbor_right_idx = (i + 1) % n_levels
		var button = button_container.get_child(i)
		var neighbor_left = button_container.get_child(neighbor_left_idx)
		var neighbor_right = button_container.get_child(neighbor_right_idx)
		button.focus_neighbor_left = neighbor_left.get_path()
		button.focus_neighbor_right = neighbor_right.get_path()

# steal back cursor focus after hover
#   - cursor_index is updated on arrow key movement.
#   - cursor_index is not updated on mouse_entered.
#   - on mouse_exit, the banner displays the level at the cursor_index
var cursor_index = -1
func _focus(level_index):
	cursor_index = level_index
	_update_level_info_display(level_index)

func _mouse_exit():
	_update_level_info_display(cursor_index)

func _on_level_selected(level_index: int):
	var file_path = "res://levels/%s" % level_files[level_index]
	GameManager.time = 0.0
	GameManager.game_started = false
	GameManager.set_background_music(level_index)
	get_tree().change_scene_to_file(file_path)

func _update_level_info_display(level_index):
	var level_file = level_files[level_index]
	var level_path = "res://levels/%s" % level_file
	var level_scene = load(level_path)
	if not level_scene:
		return

	var level_instance = level_scene.instantiate()
	%LevelName.text = level_instance.level_name
	level_instance.free()
	var time = GameManager.level_data.level_times.get(level_path, null)
	if time == null or str(time) == "":
		%LevelStats.text = "Level Not Complete"
	else:
		%LevelStats.text = GameManager.format_milliseconds(time)
	var goal_time = GameManager.level_data.goal_times[level_index]
	var dev_time = GameManager.level_data.dev_times[level_index]
	%GoalTime.text = GameManager.format_milliseconds(goal_time)
	%TimeToBeat.text = GameManager.format_milliseconds(dev_time)

	# set the player time panel gold if the dev time is beat or silver if the goal time is beat
	var sbf_style
	if _dev_time_beat(level_index):
		sbf_style = preload("res://assets/styles/sbf_gold.tres")
	elif _goal_time_beat(level_index):
		sbf_style = preload("res://assets/styles/sbf_silver.tres")
	else:
		sbf_style = preload("res://assets/styles/sbf_light.tres")
	for l: Label in %PlayerTime.get_children():
		l.add_theme_stylebox_override("normal", sbf_style)

func _dev_time_beat(level_index):
	var level_file = level_files[level_index]
	var level_path = "res://levels/%s" % level_file
	var recorded_time = GameManager.level_data.level_times.get(level_path, -1)
	if recorded_time == -1:
		return false
	var dev_time = GameManager.level_data.dev_times[level_index]
	return recorded_time <= dev_time
	
func _goal_time_beat(level_index):
	var level_file = level_files[level_index]
	var level_path = "res://levels/%s" % level_file
	var recorded_time = GameManager.level_data.level_times.get(level_path, -1)
	if recorded_time == -1:
		return false
	var goal_time = GameManager.level_data.goal_times[level_index]
	return recorded_time <= goal_time
