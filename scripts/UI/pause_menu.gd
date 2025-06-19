extends CanvasLayer

func _ready() -> void:
	if !get_parent().PROCESS_MODE_PAUSABLE:
		push_warning("warning: parent is not pausable")
	_init_mute_audio_button()
	_init_reset_stage_button()
	_init_time_trials_button()

	if OS.get_name() == "Web":
		%QuitButton.hide()  # or queue_free() if you want to remove it completely

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		toggle_pause()
	elif visible && event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
	if paused:
		%ResumeButton.grab_focus()

func _on_resume_button_pressed():
	toggle_pause()

func _on_quit_button_pressed():
	get_tree().quit()

func _init_mute_audio_button() -> void:
	var master_bus_idx := AudioServer.get_bus_index("Master")
	var muted := AudioServer.is_bus_mute(master_bus_idx)
	%MuteAudioButton.text = "Unmute Audio" if muted else "Mute Audio"

func toggle_master_audio_mute() -> void:
	var master_bus_idx := AudioServer.get_bus_index("Master")
	var muted := not AudioServer.is_bus_mute(master_bus_idx)
	AudioServer.set_bus_mute(master_bus_idx, muted)
	%MuteAudioButton.text = "Unmute Audio" if muted else "Mute Audio"

func _on_mute_audio_button_pressed() -> void:
	toggle_master_audio_mute()

func _on_main_menu_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _init_time_trials_button():
	if GameManager.gameMode == GameManager.GameModes.TIME_TRIAL:
		%TimeTrials.visible = true
	else:
		%TimeTrials.visible = false

func _on_time_trials_pressed() -> void:
	toggle_pause()
	get_tree().change_scene_to_file("res://scenes/UI/level_select.tscn")

func _init_reset_stage_button():
	if GameManager.gameMode == GameManager.GameModes.TIME_TRIAL:
		%ResetStageButton.visible = true
	else:
		%ResetStageButton.visible = false

func _on_reset_stage_button_pressed() -> void:
	GameManager.time_trial_reset()
