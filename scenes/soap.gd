extends CharacterBody2D

var cruise_speed: float
var gravity: float
var jet_thrust: float

func _ready() -> void:
	velocity = Vector2(1, 1)

func _physics_process(delta: float) -> void:
	velocity += Vector2(0, gravity) * delta
	velocity.x = cruise_speed * delta
	
	if Input.is_action_just_pressed("thrust"):
		velocity.y = 0
	if Input.is_action_pressed("thrust"):
		velocity.y -= jet_thrust * delta

	move_and_slide()
