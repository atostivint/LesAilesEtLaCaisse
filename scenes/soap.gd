extends CharacterBody2D

var cruise_speed: float
var gravity: float
var jet_thrust: float

@export_group("Jauge de vol")
@export_range(1.0, 1000.0, 1.0) var max_flight_energy := 100.0
@export_range(0.0, 100.0, 0.5) var energy_drain_per_second := 20.0
@export_range(0.0, 100.0, 0.5) var energy_recharge_per_second := 35.0
var flight_energy: float

##  - les ailes battent en boucle (AnimationPlayer « WingsPlayer »), plus vite quand le jet est maintenu ;
##  - les yeux regardent devant, puis de temps en temps en bas d'un côté ou de l'autre (peur de tomber) ;
##  - la bouche change de forme en cycle ;
##  - la caisse affichée est celle que le joueur a équipée.

## Couleur du savon (teinte le fond ; le contour et le reflet restent intacts).
@export var body_color := Color(0, 1, 1):
	set(value):
		body_color = value
		if is_node_ready():
			$Visuals/Fond.self_modulate = value

@export_group("Ailes")
## Vitesse du battement quand le jet est maintenu (1 = vitesse normale).
@export_range(1.0, 4.0, 0.1) var flap_boost := 2.2

@export_group("Regard")
## Amplitude maximale des pupilles (unités du dessin : x de chaque côté, y vers le bas).
@export var gaze_range := Vector2(5.0, 7.0)
## Durée du coup d'oeil d'une position à l'autre (s).
@export_range(0.02, 0.5, 0.01) var gaze_move_time := 0.12
## Attente avant de regarder en bas : min et max (s).
@export var glance_wait := Vector2(1.5, 4.0)
## Durée d'un regard en bas : min et max (s).
@export var glance_hold := Vector2(0.5, 1.0)

@export_group("Bouche")
## Formes de bouche, jouées dans l'ordre en boucle.
@export var mouths: Array[Texture2D] = []
## Temps entre deux formes de bouche (s).
@export_range(0.2, 5.0, 0.1) var mouth_interval := 1.4

## Vrai quand le jet est maintenu : les ailes battent plus vite.
var thrusting := false:
	set(value):
		thrusting = value
		if is_node_ready():
			wings_player.speed_scale = flap_boost if value else 1.0

var _mouth_index := 0
var _looking_down := false
var _gaze_tween: Tween

@onready var wings_player: AnimationPlayer = $WingsPlayer
@onready var pupil_left: Sprite2D = $Visuals/PupilleGauche
@onready var pupil_right: Sprite2D = $Visuals/PupilleDroite
@onready var mouth: Sprite2D = $Visuals/Bouche
@onready var crate: Sprite2D = $Visuals/Caisse
@onready var gaze_timer: Timer = $GazeTimer
@onready var mouth_timer: Timer = $MouthTimer

var SHELF_SLOPE_TANGENT := Vector2(221.0, 71.0).normalized()
var SHELF_SLOPE_NORMAL := Vector2(-71.0, 221.0).normalized()
const MIN_SLOPE_SLIDE_SPEED := 40.0

func _ready() -> void:
	velocity = Vector2(1, 1)
	flight_energy = max_flight_energy

	$Visuals/Fond.self_modulate = body_color
	mouth_timer.wait_time = mouth_interval
	_show_mouth()
	_wait_next_glance()

func _physics_process(delta: float) -> void:
	velocity += Vector2(0, gravity) * delta
	velocity.x = cruise_speed * delta
	
	thrusting = Input.is_action_pressed("thrust") and flight_energy > 0.0
	if thrusting:
		if Input.is_action_just_pressed("thrust"):
			velocity.y = 0.0
		velocity.y -= jet_thrust * delta
		flight_energy = maxf(0.0, flight_energy - energy_drain_per_second * delta)

	move_and_slide()
	if _is_sliding_on_shelf_slope():
		flight_energy = minf(max_flight_energy, flight_energy + energy_recharge_per_second * delta)


func _is_sliding_on_shelf_slope() -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as Node
		if collider != null and collider.is_in_group("shelves"):
			return true
		# if absf(collision.get_normal().dot(SHELF_SLOPE_NORMAL)) < 0.98:
		# 	continue
		# if absf(velocity.dot(SHELF_SLOPE_TANGENT)) >= MIN_SLOPE_SLIDE_SPEED:
		# 	return true
	return false


func set_crate_texture(texture: Texture2D) -> void:
	## La caisse portée sur le dos : celle équipée à l'atelier (CrateData.texture).
	crate.texture = texture


func look(direction: Vector2) -> void:
	## Déplace les pupilles vers `direction` (x et y entre -1 et 1, y positif = en bas), en douceur.
	var target := direction.clampf(-1.0, 1.0) * gaze_range
	if _gaze_tween:
		_gaze_tween.kill()
	_gaze_tween = create_tween().set_parallel(true)
	_gaze_tween.tween_property(pupil_left, "position", target, gaze_move_time)
	_gaze_tween.tween_property(pupil_right, "position", target, gaze_move_time)


func _wait_next_glance() -> void:
	var span := glance_hold if _looking_down else glance_wait
	gaze_timer.start(randf_range(span.x, span.y))


func _on_gaze_timer_timeout() -> void:
	## Regard devant -> regard en bas à gauche, devant ou à droite -> regard devant...
	_looking_down = not _looking_down
	look(Vector2(randi_range(-1, 1), 1.0) if _looking_down else Vector2.ZERO)
	_wait_next_glance()


func _on_mouth_timer_timeout() -> void:
	_mouth_index = (_mouth_index + 1) % maxi(mouths.size(), 1)
	_show_mouth()


func _show_mouth() -> void:
	if not mouths.is_empty():
		mouth.texture = mouths[_mouth_index]
