extends Node2D

@export var cruise_speed = 30000
@export var gravity = 2000
@export var jet_thrust = 4000

@onready var soap = $Soap
@onready var cam = $Camera2D

func _ready() -> void:
	soap.cruise_speed = cruise_speed
	soap.gravity = gravity
	soap.jet_thrust = jet_thrust
	

func _physics_process(delta: float) -> void:
	cam.position.x += soap.velocity.x * delta
