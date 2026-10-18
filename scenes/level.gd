extends Node2D

@export var cruise_speed = 70000
@export var gravity = 2000
@export var jet_thrust = 4000

@onready var soap = $Soap
@onready var cam = $Camera2D
@onready var flight_energy_bar: ProgressBar = %FlightEnergy

@export var trap_timer_init: float = 0.5

@export_range(0, 12) var min_traps_per_spawn := 3
@export_range(0, 12) var max_traps_per_spawn := 7

var trap_spawners: Array

var TRAP = preload("res://scenes/trap.tscn")

func _ready() -> void:
	soap.cruise_speed = cruise_speed
	soap.gravity = gravity
	soap.jet_thrust = jet_thrust
	flight_energy_bar.max_value = soap.max_flight_energy
	flight_energy_bar.value = soap.flight_energy
	
	trap_spawners = %TrapsSpawnerGroup.get_children()
	%TrapTimer.wait_time = trap_timer_init
	

func _process(_delta: float) -> void:
	flight_energy_bar.value = soap.flight_energy


func _physics_process(delta: float) -> void:
	cam.position.x += soap.velocity.x * delta
	%TrapsSpawnerGroup.position.x += soap.velocity.x * delta

func hit_soap():
	print("LOSE")
	get_tree().change_scene_to_file("res://scenes/atelier.tscn")

func spawn_trap():
	var used_spawners: Array[Node2D] = []
	var spawn_count := randi_range(min_traps_per_spawn, max_traps_per_spawn)
	for _i in range(spawn_count):
		var spawner: Node2D = trap_spawners.pick_random()
		while spawner in used_spawners:
			spawner = trap_spawners.pick_random()
		used_spawners.append(spawner)

		var trap = TRAP.instantiate()
		trap.global_position = spawner.global_position
		trap.soap_entered.connect(hit_soap)
		add_child(trap)
