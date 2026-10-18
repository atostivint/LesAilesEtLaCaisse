extends Node2D

@export var cruise_speed = 50000
@export var gravity = 2000
@export var jet_thrust = 4000

@onready var soap = $Soap
@onready var cam = $Camera2D
@onready var carrelage: Control = $Carrelage
@onready var flight_energy_bar: ProgressBar = %FlightEnergy
@onready var start_prompt: Label = %StartPrompt
@onready var flight_instructions: Label = %FlightInstructions

var game_started := false
var tuning: Tuning

## Vitesse de défilement du carrelage, en part de la vitesse du savon : 0 = fixe à l'écran, 1 = fixe dans le monde.
## Plus c'est bas, moins ça scintille (confort visuel).
@export_range(0.0, 1.0, 0.05) var bg_parallax := 0.3

@export var trap_timer_init: float = 0.5
@export_range(0.5, 30.0, 0.5) var shelf_spawn_interval := 3.0

@export_range(0, 12) var min_traps_per_spawn := 0
@export_range(0, 12) var max_traps_per_spawn := 4

@export_range(0, 1, 0.1) var bonus_spawn_proba = 0.5

var trap_spawners: Array
var shelf_spawners: Array

var TRAP = preload("res://scenes/trap.tscn")
var BONUS = preload("res://scenes/bonus.tscn")
var SHELF = preload("res://scenes/shelf.tscn")

const SCORES := {"excellent": "res://scenes/score_excellent.tscn", "bon": "res://scenes/score_bon.tscn", "moyen": "res://scenes/score_moyen.tscn", "mauvais": "res://scenes/score_mauvais.tscn", "catastrophe": "res://scenes/score_catastrophe.tscn"}

var _start_x := 0.0 # position x du savon au départ : la distance du vol en découle
var _collected := {} # matériaux ramassés pendant le vol (confiés à GameState à la fin)
var _termine := false # vrai dès la fin du vol : évite de changer de scène deux fois (deux pièges touchés le même frame)

func _ready() -> void:
	Musique.jouer_piste(Musique.PISTE_COURSE)
	tuning = GameState.tuning
	soap.set_crate_texture(tuning.crate(GameState.equipped).texture)
	Personnage.appliquer_choisi(soap)
	soap.cruise_speed = cruise_speed
	soap.gravity = gravity
	soap.jet_thrust = jet_thrust
	_start_x = soap.global_position.x
	flight_energy_bar.max_value = soap.max_flight_energy
	flight_energy_bar.value = soap.flight_energy
	
	trap_spawners = %TrapsSpawnerGroup.get_children()
	%TrapTimer.wait_time = trap_timer_init
	%TrapTimer.stop()
	shelf_spawners = %ShelfSpawnersGroup.get_children()
	%ShelfTimer.wait_time = shelf_spawn_interval
	%ShelfTimer.stop()
	

func _input(event: InputEvent) -> void:
	if not game_started and event.is_action_pressed("thrust"):
		_start_game()


func _start_game() -> void:
	game_started = true
	soap.start_flight()
	%TrapTimer.start()
	%ShelfTimer.start()
	start_prompt.hide()
	flight_instructions.show()


func _process(_delta: float) -> void:
	flight_energy_bar.value = soap.flight_energy


func _physics_process(delta: float) -> void:
	if not game_started:
		return
	cam.position.x += soap.velocity.x * delta
	carrelage.position.x += soap.velocity.x * delta * (1.0 - bg_parallax)
	%TrapsSpawnerGroup.position.x += soap.velocity.x * delta
	%ShelfSpawnersGroup.position.x += soap.velocity.x * delta
	%Ceiling.position.x += soap.velocity.x * delta
	%Ground.position.x += soap.velocity.x * delta

func die():
	_terminer_vol()

func hit_soap():
	_terminer_vol()

func _terminer_vol() -> void:
	## Fin de vol (chute ou piège) : on enregistre le résultat, puis on passe à l'écran de score du palier.
	if _termine:
		return
	_termine = true
	var distance: float = (soap.global_position.x - _start_x) / tuning.ppm
	GameState.apply_result(distance, distance >= tuning.door_x, _collected)
	# Différé : on peut être dans un callback physique (piège ou sol touché), où changer de scène est interdit
	get_tree().change_scene_to_file.call_deferred(SCORES[_palier(distance)])

func _palier(distance: float) -> String:
	## Même barème que vol.gd : le palier se lit sur la part de la ligne d'arrivée (tuning.door_x) parcourue.
	var ratio := distance / tuning.door_x
	if ratio >= 1.0:
		return "excellent"
	if ratio >= 0.6:
		return "bon"
	if ratio >= 0.35:
		return "moyen"
	if ratio >= 0.15:
		return "mauvais"
	return "catastrophe"

func apply_bonus(material: MaterialData) -> void:
	if material == null or material.id.is_empty():
		return
	_collected[material.id] = int(_collected.get(material.id, 0)) + 1


func _pick_bonus_material() -> MaterialData:
	if tuning.materials.is_empty():
		push_error("Cannot spawn a material bonus: Tuning has no materials.")
		return null

	var total_weight := 0.0
	for material in tuning.materials:
		if material == null or material.weight < 0.0:
			push_error("Cannot spawn a material bonus: a configured material is null or has negative weight.")
			return null
		total_weight += material.weight
	if total_weight <= 0.0:
		push_error("Cannot spawn a material bonus: all configured material weights are zero.")
		return null

	var roll := randf() * total_weight
	var last_weighted_material: MaterialData
	for material in tuning.materials:
		if material.weight <= 0.0:
			continue
		last_weighted_material = material
		roll -= material.weight
		if roll < 0.0:
			return material
	return last_weighted_material

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

	# Spawn material
	if randf() <= bonus_spawn_proba:
		var spawner: Node2D = trap_spawners.pick_random()
		while spawner in used_spawners:
			spawner = trap_spawners.pick_random()
		var material := _pick_bonus_material()
		if material != null:
			var bonus = BONUS.instantiate()
			bonus.global_position = spawner.global_position
			bonus.setup(material)
			bonus.soap_entered.connect(apply_bonus)
			add_child(bonus)


func spawn_shelf() -> void:
	if shelf_spawners.is_empty():
		push_error("Cannot spawn a shelf: ShelfSpawnersGroup has no spawn points.")
		return

	var spawner: Node2D = shelf_spawners.pick_random()
	var shelf := SHELF.instantiate() as StaticBody2D
	add_child(shelf)
	shelf.global_position = spawner.global_position


func _on_ground_body_entered(body: Node2D) -> void:
	if body.name == "Soap":
		die()
