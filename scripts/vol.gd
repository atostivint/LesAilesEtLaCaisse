extends Node2D
## ÉCRAN 2 : le vol. Les nœuds sont dans scenes/vol.tscn (arbre visible dans l'éditeur).
## Ce script ne calcule PAS la physique (c'est FlightSim, une classe pure : le script d'équilibrage
## la fait tourner sans fenêtre, plus vite que le temps réel) : il
##  1. transmet les touches à la simulation,
##  2. déplace les nœuds (savon, caméra) et passe les chiffres au HUD (hud.gd),
##  3. affiche le résultat.
## Les durées (secousse, délai avant de quitter l'écran de résultat, clignotement du savon,
## lissage de la caméra, apparition des tronçons du parcours) sont gérées par le moteur :
## Tween, Timer, AnimationPlayer, Camera2D.
##
## Déroulement d'un tour : READY (le savon attend en haut de la piste)
##   -> ESPACE -> RUN (piste, puis vol au jetpack : on MAINTIENT ESPACE pour monter)
##   -> chute dans l'eau ou ligne d'arrivée -> RESULT -> ENTRÉE -> atelier.
##
## Au lancement, on ajuste seulement les tailles qui dépendent des réglages (mur, eau, plafond, porte),
## et on pose les fanions de distance (World/Markers) et le parcours (World/CourseView).

enum State { READY, RUN, RESULT }

const DISTANCE_MARKER := preload("res://scenes/distance_marker.tscn")
const SCORES := {"excellent": "res://scenes/score_excellent.tscn", "bon": "res://scenes/score_bon.tscn", "moyen": "res://scenes/score_moyen.tscn", "mauvais": "res://scenes/score_mauvais.tscn", "catastrophe": "res://scenes/score_catastrophe.tscn"}

@export_group("Caméra et affichage")
## Avance de la caméra sur le savon (px) : plus grand = le savon est plus à gauche de l'écran.
@export var cam_lead := 300.0
## Avance de caméra supplémentaire par unité de vitesse (px par m/s) : le savon file vers la gauche de l'écran.
@export_range(0.0, 30.0, 0.5) var cam_speed_lead := 6.0
## Hauteur (px) du centre du savon au-dessus du point de la piste.
@export var soap_lift := 28.0

@export_group("Sensation de puissance")
## Force des secousses de caméra (px) au lâcher, au décollage, à chaque jet et à l'impact. 0 = aucune.
@export_range(0.0, 40.0, 0.5) var shake_strength := 14.0
## Durée de retombée d'une secousse (s).
@export_range(0.05, 1.5, 0.05) var shake_decay := 0.45

@export_group("Test rapide (F6 sur cette scène)")
## Si rempli (ex. "dollar"), ignore la caisse équipée à l'atelier : on teste le vol avec cette caisse.
@export var test_crate := ""

var state: State = State.READY
var sim: FlightSim
var tuning: Tuning
var course: Course
var result := {}
var shake := 0.0               # secousse en cours (1 = max, un Tween la ramène à 0)
var _shake_tween: Tween

@onready var cam: Camera2D = $Camera2D
@onready var soap: Soap = $World/Soap
@onready var course_view: Node2D = $World/CourseView
@onready var hud: CanvasLayer = $HUD
@onready var return_delay: Timer = $ReturnDelay
@onready var spawn_timer: Timer = $SpawnTimer
@onready var blink: AnimationPlayer = $World/Soap/AnimationPlayer


func _ready() -> void:
	tuning = GameState.tuning
	var crate_id: String = test_crate if test_crate != "" else GameState.equipped
	course = Course.new(tuning, tuning.course_seed)
	sim = FlightSim.new(tuning.stats_for(crate_id), tuning, course)
	soap.set_crate_texture(tuning.crate(crate_id).texture)
	Personnage.appliquer_choisi(soap)
	spawn_timer.wait_time = tuning.spawn_interval
	_spawn_segment(tuning.course_start)  # le premier tronçon est déjà là quand le savon attend en haut de la piste
	cam.make_current()
	_fit_world_to_tuning()
	_place_distance_markers()
	_update_visuals()
	cam.reset_smoothing()  # la caméra démarre sur le savon, sans glisser depuis l'origine


func _fit_world_to_tuning() -> void:
	## Mur, eau, plafond et porte s'étendent jusqu'après la ligne d'arrivée, quelle que soit la distance réglée.
	var span := tuning.door_x * tuning.ppm + 4000.0
	$World/Wall.size.x = span
	$World/Water.size.x = span
	# Le plafond = le bas du meuble (liseret marron + planche moutarde).
	$World/Ceiling.position = tuning.to_px(-1500.0 / tuning.ppm, tuning.ceiling) - Vector2(0, 160.0)
	$World/Ceiling.size = Vector2(span + 1500.0, 160.0)
	$World/Door.position = tuning.to_px(tuning.door_x, tuning.ceiling)
	$World/Door.size = Vector2(14.0 * tuning.ppm, tuning.ceiling * tuning.ppm)


func _place_distance_markers() -> void:
	for m in range(100, int(tuning.door_x), 100):
		var marker := DISTANCE_MARKER.instantiate()
		$World/Markers.add_child(marker)
		marker.setup(tuning.cm(m), tuning.to_px(m, 9.0), 9.0 * tuning.ppm)


# --- Entrées -------------------------------------------------------------------

## Action "thrust" (Projet > Réglages > Contrôles) : ESPACE, ENTRÉE, flèche haut, W ou clic gauche.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/atelier.tscn")
	elif event.is_action_pressed("thrust"):
		match state:
			State.READY:
				state = State.RUN
				spawn_timer.start()
				_shake(1.0)  # lâcher : coup de départ
			State.RESULT:
				if return_delay.is_stopped():
						_aller_au_score()


# --- Boucle --------------------------------------------------------------------

func _physics_process(dt: float) -> void:
	if state != State.RUN:
		return
	var was_perfect := sim.perfect_takeoff
	var was_phase := sim.phase
	sim.step(dt, Input.is_action_pressed("thrust"), Input.is_action_just_pressed("thrust"))
	if sim.hit_flag:
		_shake(1.0)  # piège touché
		blink.play("blink")
	if sim.invuln <= 0.0 and blink.is_playing():
		blink.stop()
		soap.modulate = Color.WHITE
	if not sim.new_pickups.is_empty():
		_shake(0.15)  # petite tape quand on ramasse une pièce
		course_view.collect(sim.new_pickups)
	if was_phase == FlightSim.Phase.RAMP and sim.phase == FlightSim.Phase.AIR:
		_shake(0.6)  # décollage
	if sim.perfect_takeoff and not was_perfect:
		hud.show_popup("BON DÉCOLLAGE ! +%s" % tuning.cm_speed(tuning.takeoff_bonus), 1.6)
	if sim.phase >= FlightSim.Phase.STOPPED:
		_finish()


func _finish() -> void:
	result = GameState.apply_result(sim.x, sim.phase == FlightSim.Phase.EXIT, sim.collected)
	state = State.RESULT
	spawn_timer.stop()
	blink.stop()
	soap.modulate = Color.WHITE
	if sim.phase == FlightSim.Phase.STOPPED:
		_shake(1.0)  # plouf
	return_delay.start()  # le message « ENTRÉE » n'apparaît (et l'écran ne se quitte) qu'après ce délai


func _aller_au_score() -> void:
	## Fin de vol : l'écran de score dépend de la distance (ligne d'arrivée franchie = excellent).
	var ratio: float = float(result["distance"]) / tuning.door_x
	var palier := "catastrophe"
	if result["door"]:
		palier = "excellent"
	elif ratio >= 0.6:
		palier = "bon"
	elif ratio >= 0.35:
		palier = "moyen"
	elif ratio >= 0.15:
		palier = "mauvais"
	get_tree().change_scene_to_file(SCORES[palier])


func _on_return_delay_timeout() -> void:
	_aller_au_score()


func _on_spawn_timer_timeout() -> void:
	## Un nouveau tronçon (étagère, pièces, obstacle) apparaît devant le savon.
	_spawn_segment(sim.x + tuning.spawn_ahead)


func _spawn_segment(from_x: float) -> void:
	if course.spawn_segment(from_x):
		course_view.sync(tuning, course)
	else:
		spawn_timer.stop()  # ligne d'arrivée proche : plus rien à faire apparaître


func _shake(strength: float) -> void:
	## Secousse de caméra : démarre à `strength` (jamais moins que la secousse en cours) et retombe à 0.
	shake = maxf(shake, strength)
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "shake", 0.0, shake_decay * shake)


func _process(_delta: float) -> void:
	_update_visuals()


func _update_visuals() -> void:
	# Savon : position et rotation (y de l'écran va vers le bas, donc rotation inversée).
	var p := tuning.to_px(sim.x, sim.y)
	var on_ramp := sim.phase == FlightSim.Phase.RAMP
	# En vol, le centre du savon = le point de collision ; sur la piste, il est un peu au-dessus.
	soap.position = p - Vector2(0, soap_lift if on_ramp else 0.0)
	# Sur la piste le savon suit la pente ; en vol son nez suit la montée / la descente, adouci.
	soap.rotation = -tuning.ramp_slope(sim.s) if on_ramp else -atan2(sim.vy, maxf(sim.vx, 1.0)) * 0.6
	soap.thrusting = sim.thrusting and state == State.RUN  # jet maintenu : les ailes battent plus vite

	# Caméra : suit le savon en x ; en y le couloir (eau -> plafond) reste entier à l'écran.
	# Le lissage est celui de la Camera2D (réglé dans vol.tscn).
	cam.position = Vector2(p.x + cam_lead + sim.speed() * cam_speed_lead, -tuning.ceiling * tuning.ppm * 0.5 + 20.0)
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * shake

	hud.update_run(sim, tuning)
	hud.set_hint(_hint())


func _hint() -> String:
	match state:
		State.READY:
			return "ESPACE : lâcher le savon   (Échap : atelier)"
		State.RUN:
			if sim.phase == FlightSim.Phase.RAMP:
				return "ESPACE dans la zone rouge du tremplin = bon décollage, puis MAINTIENS ESPACE pour voler"
			return "MAINTIENS ESPACE : jetpack     relâche : tu retombes     évite les pièges, ramasse les pièces"
	return ""
