extends CharacterBody2D

enum States {IDLE, FOLLOWING}
var state: States = States.IDLE

var speed = 72;

@onready var ray_d: RayCast2D = $RayCastDown
@onready var ray_l: RayCast2D = $RayCastLeft
@onready var ray_r: RayCast2D = $RayCastRight

func _physics_process(_delta: float) -> void:
	if state == States.IDLE:
		velocity = Vector2(0, 0)
		for ray in [ray_d, ray_l, ray_r]:
			if ray.is_colliding() && ray.get_collider() == $"../Player":
				# default AnimatedSprite2D scale is (-1, -1)
				# this flips the bat so that its head is facing up
				$AnimatedSprite2D.scale = Vector2(1, 1)

				$AnimatedSprite2D.play()
				state = States.FOLLOWING

	if state == States.FOLLOWING:
		var direction = $"../Player".position - position
		direction = direction.normalized()
		velocity = direction * speed

	move_and_slide()
