extends Node2D
## ÉCRAN 2 : le vol. Les nœuds sont dans scenes/vol.tscn (arbre visible dans l'éditeur).
## Ce script ne calcule PAS la physique (c'est FlightSim) : il
##  1. transmet les touches à la simulation,
##  2. déplace les nœuds (savon, caméra) et met à jour le HUD,
##  3. affiche le résultat.
##
## Déroulement d'un tour : READY (le savon attend en haut de la piste)
##   -> ESPACE -> RUN (piste, puis vol au jetpack : on MAINTIENT ESPACE pour monter)
##   -> chute dans l'eau ou ligne d'arrivée -> RESULT -> ENTRÉE -> atelier.
##
## Nœuds créés au lancement (donc absents de l'éditeur) : les fanions de distance (World/Markers),
## le plafond (World/Ceiling), la ligne d'arrivée (World/Door) et le parcours (World/CourseView).

enum State { READY, RUN, RESULT }

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
var course: Course
var action_buffer := false     # ESPACE pressé depuis la dernière image physique
var result := {}
var result_time := 0.0
var popup_time := 0.0          # affichage "BON DÉCOLLAGE"
var shake := 0.0               # secousse en cours (1 = max, retombe à 0)

@onready var cam: Camera2D = $Camera2D
@onready var soap: Node2D = $World/Soap
@onready var flame: Node2D = $World/Soap/Flame
@onready var door: ColorRect = $World/Door
@onready var ceiling_rect: ColorRect = $World/Ceiling
@onready var course_view: Node2D = $World/CourseView
@onready var world: Node2D = $World
@onready var distance_label: Label = %DistanceLabel
@onready var exit_label: Label = %ExitLabel
@onready var progress: ProgressBar = %ProgressBar
@onready var altitude_label: Label = %AltitudeLabel
@onready var speed_label: Label = %SpeedLabel
@onready var charges_label: Label = %ChargesLabel
@onready var contact_label: Label = %ContactLabel
@onready var hint_label: Label = %HintLabel
@onready var popup_label: Label = %PopupLabel
@onready var result_root: Control = %ResultRoot
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	tuning = GameState.tuning
	var crate_id: String = test_crate if test_crate != "" else GameState.equipped
	var stats := tuning.stats_for(crate_id)
	course = Course.new(tuning, tuning.course_seed)
	sim = FlightSim.new(stats, tuning, course)
	($World/Soap/Crate as Polygon2D).color = tuning.crate(crate_id)["color"]
	course_view.setup(tuning, course, sim.taken)
	cam.make_current()
	_setup_world()
	result_root.visible = false
	popup_label.text = ""
	_update_visuals(0.0, true)


func _setup_world() -> void:
	# Porte de sortie à door_x, fanions tous les 100 m.
	var h := tuning.ceiling * tuning.ppm
	# Mur et eau s'étendent jusqu'après la porte, quelle que soit la distance réglée.
	var span := tuning.door_x * tuning.ppm + 4000.0
	($World/Wall as ColorRect).size.x = span
	($World/Water as ColorRect).size.x = span
	door.position = tuning.to_px(tuning.door_x, tuning.ceiling)
	door.size = Vector2(14.0 * tuning.ppm, h)
	# Le plafond = le bas du meuble (liseret marron + planche moutarde).
	ceiling_rect.position = tuning.to_px(-1500.0 / tuning.ppm, tuning.ceiling) - Vector2(0, 160.0)
	ceiling_rect.size = Vector2(span + 1500.0, 160.0)
	var edge := ColorRect.new()
	edge.color = Color("#3e2412")
	edge.position = Vector2(0, 160.0 - 8.0)
	edge.size = Vector2(ceiling_rect.size.x, 8.0)
	ceiling_rect.add_child(edge)
	var markers := Node2D.new()
	markers.name = "Markers"
	world.add_child(markers)
	world.move_child(markers, $World/Water.get_index())
	for m in range(100, int(tuning.door_x), 100):
		var pole := ColorRect.new()
		pole.color = Color(0.25, 0.25, 0.25)
		pole.position = tuning.to_px(m, 9.0)
		pole.size = Vector2(4, 9.0 * tuning.ppm)
		markers.add_child(pole)
		var tag := Label.new()
		tag.text = tuning.cm(m)
		tag.add_theme_font_size_override("font_size", 26)
		tag.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
		tag.position = tuning.to_px(m, 9.0) + Vector2(8, -34)
		markers.add_child(tag)


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
	if sim.hit_flag:
		shake = 1.0  # piège touché
	if not sim.new_pickups.is_empty():
		shake = maxf(shake, 0.15)  # petite tape quand on ramasse une pièce
		course_view.queue_redraw()
	if was_phase == FlightSim.Phase.RAMP and sim.phase == FlightSim.Phase.AIR:
		shake = maxf(shake, 0.6)  # décollage
	action_buffer = false
	if sim.perfect_takeoff and not was_perfect:
		popup_time = 1.6
	if sim.phase >= FlightSim.Phase.STOPPED:
		result = GameState.apply_result(sim.x, sim.phase == FlightSim.Phase.EXIT, sim.collected)
		state = State.RESULT
		result_time = 0.0
		if sim.phase == FlightSim.Phase.STOPPED:
			shake = 1.0  # plouf


func _process(delta: float) -> void:
	popup_time -= delta
	shake = maxf(0.0, shake - delta / shake_decay)
	if state == State.RESULT:
		result_time += delta
	_update_visuals(delta, false)


func _update_visuals(delta: float, snap: bool) -> void:
	# Savon : position et rotation (y de l'écran va vers le bas, donc rotation inversée).
	var p := tuning.to_px(sim.x, sim.y)
	var lift := soap_lift if sim.phase == FlightSim.Phase.RAMP else 0.0  # en vol, le centre du savon = le point de collision
	soap.position = p + Vector2(0, -lift)
	soap.rotation = _soap_rot()
	flame.visible = sim.thrusting and state == State.RUN
	# Clignote pendant l'invulnérabilité après un piège.
	soap.modulate.a = 0.35 if sim.invuln > 0.0 and int(sim.time * 12.0) % 2 == 0 else 1.0

	# Caméra : suit le savon en x ; en y le couloir (eau -> plafond) reste entier à l'écran.
	var target := Vector2(p.x + cam_lead + sim.speed() * cam_speed_lead, -tuning.ceiling * tuning.ppm * 0.5 + 20.0)
	cam.position = target if snap else cam.position.lerp(target, 1.0 - exp(-6.0 * delta))
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * shake

	# HUD
	distance_label.text = "Distance : %s" % tuning.cm(sim.x)
	exit_label.text = "Sortie dans %s" % tuning.cm(maxf(0.0, tuning.door_x - sim.x))
	progress.max_value = tuning.door_x
	progress.value = sim.x
	altitude_label.text = "Récolte : %s" % tuning.collected_text(sim.collected)
	speed_label.text = "Vitesse : %s" % tuning.cm_speed(sim.speed())
	charges_label.text = "Ailes : %s" % ("♥".repeat(sim.wings) + "♡".repeat(sim.max_wings - sim.wings))
	contact_label.text = ""
	popup_label.text = "BON DÉCOLLAGE ! +%s" % tuning.cm_speed(tuning.takeoff_bonus) if popup_time > 0.0 else ""
	match state:
		State.READY:
			hint_label.text = "ESPACE : lâcher le savon   (Échap : atelier)"
		State.RUN:
			if sim.phase == FlightSim.Phase.RAMP:
				hint_label.text = "ESPACE dans la zone rouge du tremplin = bon décollage, puis MAINTIENS ESPACE pour voler"
			else:
				hint_label.text = "MAINTIENS ESPACE : jetpack     relâche : tu retombes     évite les pièges, ramasse les pièces"
		State.RESULT:
			hint_label.text = ""
	result_root.visible = state == State.RESULT
	if state == State.RESULT:
		var door_hit: bool = result["door"]
		var lines: Array[String] = []
		lines.append("LIGNE D'ARRIVÉE !" if door_hit else ("PLOUF !" if not sim.broken else "PLUS D'AILES !"))
		lines.append(tuning.cm(float(result["distance"])))
		if result["record"]:
			lines.append("NOUVEAU RECORD !")
		lines.append("Récolte : %s" % tuning.collected_text(result["collected"]))
		lines.append("Record : %s" % tuning.cm(GameState.best))
		if result_time > 0.5:
			lines.append("")
			lines.append("ENTRÉE : retour à l'atelier")
		result_label.text = "\n".join(lines)


func _soap_rot() -> float:
	match sim.phase:
		FlightSim.Phase.RAMP:
			return -tuning.ramp_slope(sim.s)
		_:
			# Le nez suit la montée / la descente, adouci.
			return -atan2(sim.vy, maxf(sim.vx, 1.0)) * 0.6
