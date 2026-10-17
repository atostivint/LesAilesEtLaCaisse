extends Node2D
## ÉCRAN 2 : le vol. Les nœuds sont dans scenes/vol.tscn (arbre visible dans l'éditeur).
## Ce script ne calcule PAS la physique (c'est FlightSim) : il
##  1. transmet les touches à la simulation,
##  2. déplace les nœuds (savon, caméra) et passe les chiffres au HUD (hud.gd),
##  3. affiche le résultat.
##
## Déroulement d'un tour : READY (le savon attend en haut de la piste)
##   -> ESPACE -> RUN (piste, puis vol au jetpack : on MAINTIENT ESPACE pour monter)
##   -> chute dans l'eau ou ligne d'arrivée -> RESULT -> ENTRÉE -> atelier.
##
## Au lancement, on ajuste seulement les tailles qui dépendent des réglages (mur, eau, plafond, porte),
## et on pose les fanions de distance (World/Markers) et le parcours (World/CourseView).

enum State { READY, RUN, RESULT }

const DISTANCE_MARKER := preload("res://scenes/distance_marker.tscn")

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
## Si rempli (ex. "poisson"), ignore la caisse équipée à l'atelier : on teste le vol avec cette caisse.
@export var test_crate := ""

var state: State = State.READY
var sim: FlightSim
var tuning: Tuning
var action_buffer := false     # ESPACE pressé depuis la dernière image physique
var result := {}
var result_time := 0.0
var popup_time := 0.0          # affichage "BON DÉCOLLAGE"
var shake := 0.0               # secousse en cours (1 = max, retombe à 0)

@onready var cam: Camera2D = $Camera2D
@onready var soap: Node2D = $World/Soap
@onready var flame: Node2D = $World/Soap/Flame
@onready var course_view: Node2D = $World/CourseView
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	tuning = GameState.tuning
	var crate_id: String = test_crate if test_crate != "" else GameState.equipped
	var course := Course.new(tuning, tuning.course_seed)
	sim = FlightSim.new(tuning.stats_for(crate_id), tuning, course)
	($World/Soap/Crate as Polygon2D).color = tuning.crate(crate_id).color
	course_view.setup(tuning, course)
	cam.make_current()
	_fit_world_to_tuning()
	_place_distance_markers()
	_update_visuals(0.0, true)


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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/atelier.tscn")
		return
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		match state:
			State.READY:
				state = State.RUN
				shake = 1.0  # lâcher : coup de départ
			State.RUN:
				action_buffer = true  # consommé par la prochaine image physique
			State.RESULT:
				if result_time > 0.5:
					get_tree().change_scene_to_file("res://scenes/atelier.tscn")


func _thrust_held() -> bool:
	## Jetpack : ESPACE / ENTRÉE, flèche haut, W ou clic gauche maintenus.
	return Input.is_action_pressed("ui_accept") or Input.is_action_pressed("ui_up") \
		or Input.is_key_pressed(KEY_W) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


# --- Boucle --------------------------------------------------------------------

func _physics_process(dt: float) -> void:
	if state != State.RUN:
		return
	var was_perfect := sim.perfect_takeoff
	var was_phase := sim.phase
	sim.step(dt, _thrust_held(), action_buffer)
	action_buffer = false
	if sim.hit_flag:
		shake = 1.0  # piège touché
	if not sim.new_pickups.is_empty():
		shake = maxf(shake, 0.15)  # petite tape quand on ramasse une pièce
		course_view.collect(sim.new_pickups)
	if was_phase == FlightSim.Phase.RAMP and sim.phase == FlightSim.Phase.AIR:
		shake = maxf(shake, 0.6)  # décollage
	if sim.perfect_takeoff and not was_perfect:
		popup_time = 1.6
	if sim.phase >= FlightSim.Phase.STOPPED:
		_finish()


func _finish() -> void:
	result = GameState.apply_result(sim.x, sim.phase == FlightSim.Phase.EXIT, sim.collected)
	state = State.RESULT
	result_time = 0.0
	if sim.phase == FlightSim.Phase.STOPPED:
		shake = 1.0  # plouf
	hud.show_result(_result_text())


func _process(delta: float) -> void:
	popup_time -= delta
	shake = maxf(0.0, shake - delta / shake_decay)
	if state == State.RESULT:
		result_time += delta
		hud.set_return_prompt(result_time > 0.5)
	_update_visuals(delta, false)


func _update_visuals(delta: float, snap: bool) -> void:
	# Savon : position et rotation (y de l'écran va vers le bas, donc rotation inversée).
	var p := tuning.to_px(sim.x, sim.y)
	var on_ramp := sim.phase == FlightSim.Phase.RAMP
	# En vol, le centre du savon = le point de collision ; sur la piste, il est un peu au-dessus.
	soap.position = p - Vector2(0, soap_lift if on_ramp else 0.0)
	# Sur la piste le savon suit la pente ; en vol son nez suit la montée / la descente, adouci.
	soap.rotation = -tuning.ramp_slope(sim.s) if on_ramp else -atan2(sim.vy, maxf(sim.vx, 1.0)) * 0.6
	flame.visible = sim.thrusting and state == State.RUN
	# Clignote pendant l'invulnérabilité après un piège.
	soap.modulate.a = 0.35 if sim.invuln > 0.0 and int(sim.time * 12.0) % 2 == 0 else 1.0

	# Caméra : suit le savon en x ; en y le couloir (eau -> plafond) reste entier à l'écran.
	var target := Vector2(p.x + cam_lead + sim.speed() * cam_speed_lead, -tuning.ceiling * tuning.ppm * 0.5 + 20.0)
	cam.position = target if snap else cam.position.lerp(target, 1.0 - exp(-6.0 * delta))
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * shake

	hud.update_run(sim, tuning)
	hud.set_popup("BON DÉCOLLAGE ! +%s" % tuning.cm_speed(tuning.takeoff_bonus) if popup_time > 0.0 else "")
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


func _result_text() -> String:
	var lines: Array[String] = []
	lines.append("LIGNE D'ARRIVÉE !" if result["door"] else ("PLOUF !" if not sim.broken else "PLUS D'AILES !"))
	lines.append(tuning.cm(float(result["distance"])))
	if result["record"]:
		lines.append("NOUVEAU RECORD !")
	lines.append("Récolte : %s" % tuning.collected_text(result["collected"]))
	lines.append("Record : %s" % tuning.cm(GameState.best))
	return "\n".join(lines)
