 # Player.gd (CharacterBody2D)
extends CharacterBody2D

@export var FUEL = 2000
@export var camera_scale: Vector2 = Vector2(1.0, 1.0)
@export var staticCam: bool = false
@onready var timer: Timer = $Timer
@onready var camera = $Camera

@onready var ray_dl: RayCast2D = %RayCastDownRight
@onready var ray_dr: RayCast2D = %RayCastDownLeft

# physics are designed for an 8px x 8px tileset -- 8px == 1m
const BASE_TILE_SIZE_PX = 8
@export var tile_size_px = 24
const physics_scale_factor = 3

# All forces are in units of Tiles per Second squared
# friction is a ratio and doesn't need to be scaled
const FRICTION = -3

var gravity = 120 * physics_scale_factor
var player_y_force = 300 * physics_scale_factor
var player_x_force = 165 * physics_scale_factor
var velocity_cutoff = 0.001 * physics_scale_factor

# Tilemap data
const ICE_SOURCE_ID := 5
const ICE_ATLAS_COORDS := [Vector2i(0, 0), Vector2i(1, 0)]

# Audio
@export var maxVol = -6.0
@export var minVol = -48.0
@export var noiseGate = -24.0

signal player_died

var airbrake_pressed = false

func _ready():
	add_to_group("player")
	camera.zoom = camera_scale
	player_died.connect(GameManager.on_player_died)
	$AudioStreamPlayer.volume_db = minVol

func add_fuel(amt):
	FUEL += amt
	GameManager.set_background_pitch_scale(false)

func _on_timer_timeout():
	if int(FUEL) <= 0 && not GameManager.gameStateDisabled:
		emit_signal("player_died")

# Called when the player collides with a killzone.
func die():
	emit_signal("player_died")

func _get_friction():
	var tilemap: TileMapLayer = $"../Terrain"

	for ray in [ray_dl, ray_dr]:
		if ray.is_colliding():
			var foot_position = ray.get_collision_point()
			var tile_pos = tilemap.local_to_map(foot_position)
			var source_id = tilemap.get_cell_source_id(tile_pos)
			var atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)

			# Check if tile is NOT ice
			if not (source_id == ICE_SOURCE_ID && atlas_coords in ICE_ATLAS_COORDS):
				return FRICTION

	return 0.0;
	
func _input(event):
	if event.is_action_pressed("ui_brake"):
		airbrake_pressed = true
	if event.is_action_released("ui_brake"):
		airbrake_pressed = false

func _physics_process(delta):
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var velocity_update = input_dir
	velocity_update.x *= player_x_force * delta
	velocity_update.y *= player_y_force * delta

	if FUEL > 0:
		velocity -= velocity_update
		# fuel is independent of scale
		if not GameManager.gameStateDisabled:
			FUEL -= velocity_update.length() / physics_scale_factor
	elif timer.is_stopped() and not GameManager.gameStateDisabled:
		GameManager.set_background_pitch_scale(true)
		timer.start()

	if not is_on_floor():
		velocity.y += gravity * delta
		# only airbrake if the player is not otherwise moving
		if airbrake_pressed && velocity_update == Vector2.ZERO:
			# apply the airbrake horizontally
			velocity.x += FRICTION * delta * velocity.x
			# apply the airbrake vertically
			velocity.y += FRICTION * delta * velocity.y

	elif abs(velocity.x) < velocity_cutoff:
		velocity.x = 0
	else:
		velocity.x += _get_friction() * delta * velocity.x
	move_and_slide()
	
	# This section nullifies unwanted velocity when flying into a wall/corner
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		# Normal is perpendicular to the you surface hit. 
		var normal: Vector2 = collision.get_normal()
		velocity = velocity.slide(normal)
		
	_update_animation(input_dir.normalized())
	_update_particles(input_dir.normalized())
	_update_audio(input_dir.normalized())

func _update_audio(dir: Vector2):
	const attackRate = 1.0
	const decayRate = 0.5

	var newVol
	if dir == Vector2.ZERO || int(FUEL) <= 0:
		newVol = $AudioStreamPlayer.volume_db - decayRate
		newVol = max(minVol, newVol)
		newVol = min(maxVol, newVol)
	else:
		newVol = $AudioStreamPlayer.volume_db + attackRate
		newVol = max(noiseGate, newVol)
		newVol = min(maxVol, newVol)

	$AudioStreamPlayer.volume_db = newVol

func _update_animation(dir: Vector2):
	if dir == Vector2.ZERO:
		if airbrake_pressed:
			# Moving down
			if velocity.y >= 0:
				# Down + Left
				if velocity.x < 0:
					$AnimatedSprite2D.frame = 16
				# Down + Right
				elif velocity.x > 0:
					$AnimatedSprite2D.frame = 15
				# Down only
				else:
					$AnimatedSprite2D.frame = 14

			# Moving up
			else:
				# Up + Left
				if velocity.x < 0:
					$AnimatedSprite2D.frame = 12
				# Up + Right
				elif velocity.x > 0:
					$AnimatedSprite2D.frame = 13
				# Up only
				else:
					$AnimatedSprite2D.frame = 11
			return
		else:
			$AnimatedSprite2D.frame = 0
			return

	if int(FUEL) <= 0:
		$AnimatedSprite2D.frame = 0
		return

	var x = dir.x
	var y = dir.y
	var is_diagonal = abs(x) > 0.2 && abs(y) > 0.2

	const deadzone = 0.2;
	if is_diagonal:
		if x > deadzone:
			$AnimatedSprite2D.frame = 7 if y > deadzone else 6  # down-right/up-right
		else:
			$AnimatedSprite2D.frame = 8 if y > deadzone else 5  # down-left/up-left
	else:
		if y < -deadzone:
			$AnimatedSprite2D.frame = 1  # up
		elif y > deadzone:
			$AnimatedSprite2D.frame = 3 # down
		elif x > deadzone:
			$AnimatedSprite2D.frame = 2 # right
		elif x < -deadzone:
			$AnimatedSprite2D.frame = 4  # left

func _update_particles(dir: Vector2):
	if dir == Vector2.ZERO || int(FUEL) <= 0:
		$Node2D/CPUParticles2D.emitting = false
	else:
		$Node2D/CPUParticles2D.emitting = true

	var angle = 0.0
	if $AnimatedSprite2D.frame == 3: # Down
		angle = 0 * PI / 180
	if $AnimatedSprite2D.frame == 8: # Down-Left
		angle = 45 * PI / 180
	if $AnimatedSprite2D.frame == 4: # Left
		angle = 90 * PI / 180
	if $AnimatedSprite2D.frame == 5: # Up-Left
		angle = 135 * PI / 180
	if $AnimatedSprite2D.frame == 1: # Up
		angle = 180 * PI / 180
	if $AnimatedSprite2D.frame == 6: # Up-Right
		angle = 225 * PI / 180
	if $AnimatedSprite2D.frame == 2: # Right
		angle = 270 * PI / 180
	if $AnimatedSprite2D.frame == 7: # Down-Right
		angle = 315 * PI / 180

	$Node2D.rotation = angle

func _setup_camera_limits(map_width_px, map_height_px):
	# by default, restrict the camera to the bounding box of the level
	$Camera.limit_left = 0
	$Camera.limit_right = map_width_px
	$Camera.limit_top = 0;
	$Camera.limit_bottom = map_height_px

	# if the level is less wide than the screen, center the level horizontally in the camera's view
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	if map_width_px * camera_scale[0] < viewport_width:
		$Camera.limit_left = (map_width_px / 2)  - (viewport_width / 2) / camera_scale[0]  
		$Camera.limit_right = (map_width_px / 2)  + (viewport_width / 2) / camera_scale[0] 
		$Camera.drag_horizontal_enabled = false

	# if the level is shorter than the screen, center the level vertically in the camera's view
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	if map_height_px * camera_scale[0] < viewport_height:
		$Camera.limit_top =  (map_height_px / 2) - (viewport_height / 2) / camera_scale[0]
		$Camera.limit_bottom = (map_height_px / 2)  + (viewport_height / 2) / camera_scale[0]
		$Camera.drag_vertical_enabled = false
		
	if staticCam:
		var level = get_parent() as Node2D
		camera.get_parent().remove_child(camera)
		call_deferred("add_camera_to_level", level, camera)
		camera.global_position = Vector2(map_width_px, map_height_px)
		
func add_camera_to_level(level: Node2D, cam: Camera2D):
	level.add_child(cam)
	
