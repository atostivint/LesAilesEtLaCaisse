extends Node2D
## ÉCRAN 2 : le vol. Les nœuds sont dans scenes/vol.tscn (arbre visible dans l'éditeur).
## Ce script ne calcule PAS la physique (c'est FlightSim) : il
##  1. transmet les touches à la simulation,
##  2. déplace les nœuds (savon, caméra) et met à jour le HUD,
##  3. affiche le résultat.
##
## Déroulement d'un tour : READY (le savon attend en haut de la piste)
##   -> ESPACE -> RUN (glisse puis vol) -> splash ou porte -> RESULT -> ENTRÉE -> atelier.
##
## Nœuds créés au lancement (donc absents de l'éditeur) : les fanions de distance (World/Markers)
## et la position/taille de la porte (World/Door).

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
## Si coché, ignore les niveaux d'atelier : on teste le vol avec les niveaux ci-dessous.
@export var use_test_levels := false
@export_range(0, 20) var test_poussee := 0
@export_range(0, 20) var test_bulles := 0
@export_range(0, 20) var test_ailes := 0
@export_range(0, 20) var test_glisse := 0

var state: State = State.READY
var sim: FlightSim
var tuning: Tuning
var max_charges := 0
var action_buffer := false     # ESPACE pressé depuis la dernière image physique
var result := {}
var result_time := 0.0
var popup_time := 0.0          # affichage "BON DÉCOLLAGE"
var shake := 0.0               # secousse en cours (1 = max, retombe à 0)

@onready var cam: Camera2D = $Camera2D
@onready var soap: Node2D = $World/Soap
@onready var flame: Node2D = $World/Soap/Flame
@onready var door: ColorRect = $World/Door
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
	var lv: Dictionary = GameState.levels
	if use_test_levels:
		lv = {"poussee": test_poussee, "bulles": test_bulles, "ailes": test_ailes, "glisse": test_glisse}
	var stats := tuning.stats_for(lv)
	max_charges = stats["charges"]
	sim = FlightSim.new(stats, tuning)
	cam.make_current()
	_setup_world()
	result_root.visible = false
	popup_label.text = ""
	_update_visuals(0.0, true)


func _setup_world() -> void:
	# Porte de sortie à door_x, fanions tous les 100 m.
	var h := 26.0 * tuning.ppm
	# Mur et eau s'étendent jusqu'après la porte, quelle que soit la distance réglée.
	var span := tuning.door_x * tuning.ppm + 4000.0
	($World/Wall as ColorRect).size.x = span
	($World/Water as ColorRect).size.x = span
	door.position = tuning.to_px(tuning.door_x, 26.0)
	door.size = Vector2(14.0 * tuning.ppm, h)
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


func _pitch_input() -> float:
	## +1 = cabrer (flèche haut / W), -1 = piquer (flèche bas / S).
	var p := Input.get_axis("ui_down", "ui_up")
	if Input.is_key_pressed(KEY_W):
		p += 1.0
	if Input.is_key_pressed(KEY_S):
		p -= 1.0
	return clampf(p, -1.0, 1.0)


# --- Boucle --------------------------------------------------------------------

func _physics_process(dt: float) -> void:
	if state != State.RUN:
		return
	var was_perfect := sim.perfect_takeoff
	var was_phase := sim.phase
	var was_charges := sim.charges
	var was_bounces := sim.bounces
	sim.step(dt, _pitch_input(), action_buffer)
	if sim.charges < was_charges:
		shake = maxf(shake, 0.7)  # un jet part
	if sim.bounces > was_bounces:
		shake = 0.8  # rebond sur l'eau
	if was_phase == FlightSim.Phase.RAMP and sim.phase == FlightSim.Phase.AIR:
		shake = maxf(shake, 0.6)  # décollage
	if was_phase == FlightSim.Phase.AIR and sim.phase == FlightSim.Phase.SLIDE:
		shake = 1.0  # impact sur l'eau
	action_buffer = false
	if sim.perfect_takeoff and not was_perfect:
		popup_time = 1.6
	if sim.phase >= FlightSim.Phase.STOPPED:
		result = GameState.apply_result(sim.x, sim.phase == FlightSim.Phase.EXIT)
		state = State.RESULT
		result_time = 0.0


func _process(delta: float) -> void:
	popup_time -= delta
	shake = maxf(0.0, shake - delta / shake_decay)
	if state == State.RESULT:
		result_time += delta
	_update_visuals(delta, false)


func _update_visuals(delta: float, snap: bool) -> void:
	# Savon : position et rotation (y de l'écran va vers le bas, donc rotation inversée).
	var p := tuning.to_px(sim.x, sim.y)
	soap.position = p + Vector2(0, -soap_lift)
	soap.rotation = _soap_rot()
	flame.visible = sim.boost_left > 0.0

	# Caméra : suit le savon, monte quand il monte.
	var target := Vector2(p.x + cam_lead + sim.speed() * cam_speed_lead, minf(-240.0, p.y + 180.0))
	cam.position = target if snap else cam.position.lerp(target, 1.0 - exp(-6.0 * delta))
	cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * shake

	# HUD
	distance_label.text = "Distance : %s" % tuning.cm(sim.x)
	exit_label.text = "Sortie dans %s" % tuning.cm(maxf(0.0, tuning.door_x - sim.x))
	progress.max_value = tuning.door_x
	progress.value = sim.x
	altitude_label.text = "Altitude : %s" % tuning.cm(sim.y)
	speed_label.text = "Vitesse : %s" % tuning.cm_speed(sim.speed())
	charges_label.text = "Jets : %s   Rebonds : %d" % ["●".repeat(sim.charges) + "○".repeat(max_charges - sim.charges), sim.bounces]
	contact_label.text = _contact_text()
	popup_label.text = "BON DÉCOLLAGE ! +%s" % tuning.cm_speed(tuning.takeoff_bonus) if popup_time > 0.0 else ""
	match state:
		State.READY:
			hint_label.text = "ESPACE : lâcher le savon   (Échap : atelier)"
		State.RUN:
			if sim.phase == FlightSim.Phase.RAMP:
				hint_label.text = "ESPACE dans la zone rouge du tremplin = bon décollage"
			elif sim.phase == FlightSim.Phase.SLIDE:
				hint_label.text = "↓ : mettre à plat (glisse)   ↑ : cabrer   ESPACE : jet (pousse mais fait basculer)"
			else:
				hint_label.text = "↑ / ↓ : inclinaison     ESPACE : jet de bulles"
		State.RESULT:
			hint_label.text = ""
	result_root.visible = state == State.RESULT
	if state == State.RESULT:
		var door_hit: bool = result["door"]
		var lines: Array[String] = []
		lines.append("SORTIE !" if door_hit else "ARRÊT !")
		lines.append(tuning.cm(float(result["distance"])))
		if result["record"]:
			lines.append("NOUVEAU RECORD !")
		lines.append("+%d pièces" % int(result["gain"]))
		lines.append("Record : %s" % tuning.cm(GameState.best))
		if result_time > 0.5:
			lines.append("")
			lines.append("ENTRÉE : retour à l'atelier")
		result_label.text = "\n".join(lines)


func _contact_text() -> String:
	## Pendant la glisse : ce qui frotte dans l'eau, l'inclinaison et le freinage.
	if sim.phase != FlightSim.Phase.SLIDE:
		return ""
	return "Glisse : %s | inclinaison %d° | frein %.0f cm/s²" % [sim.contact, int(rad_to_deg(sim.theta)), sim.friction * tuning.display_cm_per_unit]


func _soap_rot() -> float:
	match sim.phase:
		FlightSim.Phase.RAMP:
			return -tuning.ramp_slope(sim.s)
		FlightSim.Phase.SLIDE, FlightSim.Phase.STOPPED:
			return -sim.theta
		_:
			return -(atan2(sim.vy, sim.vx) + sim.alpha)
