class_name Soap
extends CharacterBody2D

var cruise_speed: float
var gravity: float
var jet_thrust: float

@export_group("Jauge de vol")
@export_range(1.0, 1000.0, 1.0) var max_flight_energy := 100.0
## Énergie perdue par seconde en vol (x1,5 quand on maintient la touche) : les ailes s'épuisent, seules les étagères les rechargent.
@export_range(0.0, 100.0, 0.5) var energy_drain_per_second := 7.0
## Recharge rapide pendant une glisse sur une étagère.
@export_range(0.0, 100.0, 0.5) var energy_recharge_per_second := 36.0
var flight_energy: float

@export_group("Propulsion de départ")
## Durée (s) de la glissade d'entrée : le savon est guidé en douceur, puis la main passe au joueur.
@export_range(0.0, 6.0, 0.1) var intro_time := 3.0
## Hauteur (y, en px) à laquelle le savon plane pendant l'entrée : plus grand = plus bas à l'écran.
@export_range(200.0, 700.0, 10.0) var intro_height := 520.0
## Vitesse horizontale au tout début (1 = vitesse de croisière), qui revient à la normale en douceur.
@export_range(1.0, 2.0, 0.05) var intro_speed_boost := 1.25
## Durée (s) pendant laquelle le guidage s'efface à la fin de l'entrée.
@export_range(0.2, 3.0, 0.1) var intro_fade := 1.2
var _intro_left := 0.0
## Niveau de poussée lissé (0-1) : la poussée monte et redescend progressivement.
var _thrust_level := 0.0

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
var _flight_started := false
var _thrust_needs_release := true
var _gliding := false
var _glide_tangent := Vector2.RIGHT
var _glide_normal := Vector2.UP
var _glide_boost_actuel := 1.3
var _intro_arme := false # vrai tant que le savon n'a pas encore quitté le canard
var _a_glisse := false
var _riding := false # glissade guidée sur le dos du canard
var _ride_rebond := 220.0 # impulsion vers le haut à la sortie de la glissade (px/s), propre à chaque surface
var _ride_cooldown := 0.0 # court délai avant de pouvoir repartir sur une autre surface
var _vel_avant := Vector2.ZERO # vitesse juste avant la collision (sert à garder l'élan à l'entrée d'une glissade)
var _vx_extra := 0.0 # vitesse horizontale gagnée en glissant, qui s'estompe doucement
var _ride_pts := PackedVector2Array()
var _ride_cum := PackedFloat32Array()
var _ride_s := 0.0
var _ride_v := 0.0
const RIDE_OFFSET := 18.0 # demi-hauteur du savon : il glisse posé sur la ligne
const RIDE_PENTE := 0.8 # part de la gravité qui accélère le savon dans les descentes (et le freine dans les montées)
const RIDE_V_MIN := 450.0
const RIDE_V_MAX := 1150.0 # vitesse maximale sur une glissade
var _ride_verrouille := false # glissade de départ : aucune commande possible
var _ride_vmin := RIDE_V_MIN
const RIDE_RESSORT := 1.1 # petit coup de pouce à la sortie de la surface : le savon est propulsé
var _glide_grace := 0.0 # court délai de grâce : un petit décollage sur une bosse ne coupe pas la glisse
var glide_particles: CPUParticles2D

@export_group("Vol (style Jetpack Joyride)")
## Vitesse verticale maximale vers le haut (px/s).
@export_range(100.0, 2000.0, 10.0) var max_rise_speed := 520.0
## Vitesse verticale maximale vers le bas (px/s).
@export_range(100.0, 2000.0, 10.0) var max_fall_speed := 560.0
## Gravité en plus pendant la chute (1 = symétrique) : on retombe plus vite qu'on ne monte.
@export_range(1.0, 3.0, 0.05) var fall_gravity_mult := 1.5
## Multiplicateur de vitesse pendant la glisse sur une étagère.
@export_range(1.0, 3.0, 0.05) var glide_boost := 1.3

@onready var visuals: Node2D = $Visuals

func _ready() -> void:
	velocity = Vector2(1, 1)
	flight_energy = max_flight_energy

	$Visuals/Fond.self_modulate = body_color
	_creer_particules_glisse()
	mouth_timer.wait_time = mouth_interval
	_show_mouth()


func start_flight(ligne_depart := PackedVector2Array()) -> void:
	## ligne_depart : le dos du canard (de gauche à droite). Le savon tombe dessus depuis le vide, le suit jusqu'au bout
	## et en est lancé : le joueur ne peut rien faire avant (pas de commande, pas de rampe ratée).
	_flight_started = true

	# Départ dans le vide : le savon tombe sur le canard et glisse sur son dos ; le guidage d'entrée
	# ne commence qu'à la sortie du canard (voir _update_glide)
	velocity = Vector2.ZERO
	_intro_left = 0.0
	_intro_arme = true

	_thrust_needs_release = true
	wings_player.play("flap")
	mouth_timer.start()
	_wait_next_glance()
	if ligne_depart.size() >= 3:
		_demarrer_glissade_depart(ligne_depart)


func _demarrer_glissade_depart(dos: PackedVector2Array) -> void:
	## Trajectoire : une chute courbe depuis la position du savon jusqu'au sommet de la tête du canard, puis tout le dos.
	## Comme la glissade est guidée (pas de collision), elle ne peut pas être ratée.
	var depart := global_position
	var arrivee: Vector2 = dos[2] + Vector2.UP * RIDE_OFFSET
	var controle := Vector2(depart.x + (arrivee.x - depart.x) * 0.25, depart.y + (arrivee.y - depart.y) * 0.55)
	var ligne := PackedVector2Array()
	for i in 10:
		var t := float(i) / 10.0
		ligne.append(depart.lerp(controle, t).lerp(controle.lerp(arrivee, t), t) - Vector2.UP * RIDE_OFFSET)
	for i in range(2, dos.size()):
		ligne.append(dos[i])
	start_ride(ligne, true)


func _physics_process(delta: float) -> void:
	if not _flight_started:
		return
	_ride_cooldown = maxf(0.0, _ride_cooldown - delta)
	if _riding:
		_ride_step(delta)
		return

	var speed := cruise_speed
	# Guidage d'entrée : 1 pendant l'essentiel de la glissade, puis s'efface en douceur (0 = contrôle total)
	var guide := 0.0
	if _intro_left > 0.0:
		_intro_left = maxf(0.0, _intro_left - delta)
		guide = smoothstep(0.0, 1.0, clampf(_intro_left / intro_fade, 0.0, 1.0))
		speed *= lerpf(1.0, intro_speed_boost, guide)

	if _thrust_needs_release and not Input.is_action_pressed("thrust"):
		_thrust_needs_release = false
	thrusting = not _thrust_needs_release and Input.is_action_pressed("thrust") and flight_energy > 0.0
	# Dès que le joueur appuie pendant la glissade d'entrée, il reprend la main (le guidage s'efface)
	if thrusting and _intro_left > 0.25:
		_intro_left = 0.25
	# La poussée monte et retombe vite mais sans coup sec quand on appuie ou relâche
	# Elle monte vite (réponse immédiate à l'appui) et retombe encore plus vite au relâchement
	_thrust_level = move_toward(_thrust_level, 1.0 if thrusting else 0.0, (16.0 if thrusting else 20.0) * delta)

	if _gliding:
		# Glisse : le savon file le long de l'étagère, plus vite qu'en vol, sans friction.
		# La vitesse rejoint la glisse en douceur (pas de changement de direction brutal à l'entrée).
		# Le savon est plaqué contre la surface (proportionnellement à sa vitesse) pour suivre les bosses du dos
		var vitesse_glisse := speed * delta * _glide_boost_actuel
		var cible := _glide_tangent * vitesse_glisse - _glide_normal * (60.0 + vitesse_glisse * 0.4)
		if thrusting:
			cible.y -= jet_thrust * 0.5
		velocity = velocity.lerp(cible, 1.0 - exp(-14.0 * delta))
	else:
		# Comme Jetpack Joyride : on maintient = on accélère vers le haut en douceur, on relâche = on retombe,
		# avec une vitesse verticale plafonnée dans les deux sens.
		# Chute plus rapide que la montée (sinon le savon flotte au relâchement)
		var g := gravity
		if velocity.y > 0.0:
			g *= 1.0 + (fall_gravity_mult - 1.0) * (1.0 - _thrust_level)
		var acc := g - jet_thrust * _thrust_level
		if guide > 0.0:
			# Pendant l'entrée, le savon est attiré vers sa hauteur de vol : il glisse sans monter ni plonger
			var vy_cible := clampf((intro_height - global_position.y) * 3.0, -220.0, 220.0)
			acc = lerpf(acc, (vy_cible - velocity.y) * 6.0, guide)
		velocity.y = clampf(velocity.y + acc * delta, -max_rise_speed, max_fall_speed)
		velocity.x = speed * delta + _vx_extra
		_vx_extra = move_toward(_vx_extra, 0.0, 700.0 * delta)
	# Les ailes s'épuisent avec le temps (plus vite en poussant) ; seules les étagères les rechargent
	flight_energy = maxf(0.0, flight_energy - energy_drain_per_second * (1.5 if thrusting else 1.0) * delta)

	_vel_avant = velocity
	move_and_slide()
	_update_glide(delta)


func start_ride(points: PackedVector2Array, verrouille := false) -> void:
	## Glissade guidée : le savon suit la ligne `points` (le dos du canard, de gauche à droite).
	## Il accélère en descente, ralentit en remontée, puis s'envole au bout (voir _ride_step).
	if points.size() < 2:
		return
	_riding = true
	_ride_pts = points
	_ride_cum = PackedFloat32Array([0.0])
	for i in range(1, points.size()):
		_ride_cum.append(_ride_cum[i - 1] + points[i].distance_to(points[i - 1]))
	# Le savon entre dans la glissade au point de la ligne le plus proche de lui
	var meilleur := 0
	var d_min := INF
	for i in points.size():
		var d := points[i].distance_squared_to(global_position)
		if d < d_min:
			d_min = d
			meilleur = i
	_ride_s = 0.0 if verrouille else _ride_cum[meilleur]
	_ride_verrouille = verrouille
	_ride_vmin = 200.0 if verrouille else RIDE_V_MIN
	# L'élan de l'arrivée est conservé : la vitesse d'entrée est la part de la vitesse qui suit la pente
	var tangente_entree: Vector2 = _ride_point(_ride_s)[1]
	_ride_v = 200.0 if verrouille else maxf(RIDE_V_MIN, _vel_avant.dot(tangente_entree) * 0.9)
	velocity = Vector2.ZERO
	if glide_particles:
		glide_particles.emitting = true


func _ride_point(s: float) -> Array:
	## Position (sur la ligne) et tangente à la distance `s` du début de la ligne.
	var n := _ride_pts.size()
	var i := 1
	while i < n - 1 and _ride_cum[i] < s:
		i += 1
	var a := _ride_pts[i - 1]
	var b := _ride_pts[i]
	var seg := _ride_cum[i] - _ride_cum[i - 1]
	var u := clampf((s - _ride_cum[i - 1]) / maxf(seg, 0.001), 0.0, 1.0)
	return [a.lerp(b, u), (b - a).normalized()]


func _ride_step(delta: float) -> void:
	var total := _ride_cum[_ride_cum.size() - 1]
	var info := _ride_point(_ride_s)
	var tangente: Vector2 = info[1]
	# Descente = accélération, remontée = ralentissement (la tangente va vers la droite : y > 0 = ça descend)
	_ride_v = clampf(_ride_v + gravity * RIDE_PENTE * tangente.y * delta, _ride_vmin, RIDE_V_MAX)
	_ride_s += _ride_v * delta
	info = _ride_point(minf(_ride_s, total))
	tangente = info[1]
	var normale := Vector2(tangente.y, -tangente.x) # vers le haut, hors du dos
	global_position = Vector2(info[0]) + normale * RIDE_OFFSET
	visuals.rotation = lerp_angle(visuals.rotation, tangente.angle(), minf(1.0, 14.0 * delta))
	flight_energy = minf(max_flight_energy, flight_energy + energy_recharge_per_second * delta)
	velocity = tangente * _ride_v
	# Fin de la ligne (bout de la queue) ou le joueur reprend la main : envol
	if _ride_s >= total or (not _ride_verrouille and Input.is_action_just_pressed("thrust")):
		_riding = false
		_ride_verrouille = false
		_ride_cooldown = 0.5
		# Propulsion à la sortie : le savon part dans l'axe de la pente avec l'élan acquis
		velocity = tangente * _ride_v * RIDE_RESSORT
		velocity.y -= _ride_rebond # petit rebond à la sortie : on ne retombe pas tout de suite
		_vx_extra = maxf(0.0, velocity.x - cruise_speed * delta)
		if _intro_arme:
			_intro_arme = false
			_intro_left = intro_time
		if glide_particles:
			glide_particles.emitting = false


func _update_glide(delta: float) -> void:
	var normal := Vector2.ZERO
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as Node
		if collider != null and collider.has_meta("ride") and _ride_cooldown <= 0.0:
			if collider.has_meta("recharge_part"):
				flight_energy = minf(max_flight_energy, flight_energy + max_flight_energy * float(collider.get_meta("recharge_part")))
			_ride_rebond = float(collider.get_meta("rebond", 220.0))
			start_ride(collider.get_meta("ride"))
			return
		if collider != null and collider.has_meta("ride"):
			continue # surface à glissade guidée : juste après une glissade on la traverse sans ralentir
		# Seule la face du dessus de l'étagère fait glisser (pas le dessous, ni la tranche)
		if collider != null and collider.is_in_group("shelves") and collision.get_normal().y < -0.35:
			normal = collision.get_normal()
			# Chaque surface peut avoir sa propre vitesse de glisse (métadonnée « glide_boost »)
			_glide_boost_actuel = float(collider.get_meta("glide_boost", glide_boost))
	var on_shelf := normal != Vector2.ZERO
	if on_shelf:
		_glide_normal = normal
		# Tangente orientée vers la droite
		_glide_tangent = Vector2(normal.y, -normal.x)
		if _glide_tangent.x < 0.0:
			_glide_tangent = -_glide_tangent
		flight_energy = minf(max_flight_energy, flight_energy + energy_recharge_per_second * delta)
	# On quitte la glisse dès qu'on pousse franchement vers le haut ou qu'on n'est plus au contact
	if on_shelf:
		_glide_grace = 0.12
	else:
		_glide_grace = maxf(0.0, _glide_grace - delta)
	_gliding = (on_shelf or _glide_grace > 0.0) and not thrusting
	if on_shelf:
		_a_glisse = true
	elif _a_glisse and _intro_arme and _glide_grace <= 0.0:
		# Le savon quitte le canard : la glissade d'entrée guide l'envol vers la hauteur de vol
		_intro_arme = false
		_intro_left = intro_time
	if glide_particles:
		glide_particles.emitting = on_shelf
	# Le savon s'incline avec la pente pendant la glisse
	var cible := _glide_tangent.angle() if on_shelf else 0.0
	visuals.rotation = lerp_angle(visuals.rotation, cible, minf(1.0, 12.0 * delta))


func _creer_particules_glisse() -> void:
	## Bulles de savon derrière le savon pendant la glisse : sensation de vitesse.
	glide_particles = CPUParticles2D.new()
	glide_particles.emitting = false
	glide_particles.amount = 28
	glide_particles.lifetime = 0.6
	glide_particles.local_coords = false
	glide_particles.position = Vector2(-18, 14)
	glide_particles.direction = Vector2(-1, 0.2)
	glide_particles.spread = 35.0
	glide_particles.initial_velocity_min = 80.0
	glide_particles.initial_velocity_max = 220.0
	glide_particles.gravity = Vector2.ZERO
	glide_particles.scale_amount_min = 3.0
	glide_particles.scale_amount_max = 7.0
	glide_particles.color = Color(0.85, 0.96, 1.0, 0.8)
	add_child(glide_particles)


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
