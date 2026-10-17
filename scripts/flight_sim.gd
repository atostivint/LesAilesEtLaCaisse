class_name FlightSim
extends RefCounted
## Simulation PURE du vol (aucun nœud Godot) : on lui donne les stats de la caisse et le parcours,
## puis on appelle step() à chaque image. Elle sert au jeu ET au script d'équilibrage.
##
## Repère : x vers la droite, y vers le HAUT (altitude au-dessus de l'eau), en mètres.
## Phases : RAMP (piste) -> AIR (vol au jetpack) -> STOPPED (tombé dans l'eau) ; ou EXIT (ligne d'arrivée).

enum Phase { RAMP, AIR, STOPPED, EXIT }

var phase: Phase = Phase.RAMP
var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var s := 0.0                # position le long de la piste (m)
var ramp_speed := 0.0
var perfect_takeoff := false
var thrusting := false      # le jetpack souffle (pour la flamme)
var wings := 0              # ailes (plumes) restantes
var max_wings := 0
var broken := false         # plus d'ailes : le jetpack ne marche plus, le savon tombe
var invuln := 0.0           # temps d'invulnérabilité restant après un piège
var hits := 0               # pièges touchés
var hit_flag := false       # vrai pendant l'image où un piège vient d'être touché
var time := 0.0
var collected := {}         # matériau -> quantité ramassée pendant ce vol
var taken: PackedByteArray  # une case par pièce du parcours (1 = ramassée)
var new_pickups: Array[int] = []   # indices des pièces ramassées pendant la dernière image

var t: Tuning
var course: Course
var _cruise := 13.0
var _gravity := 24.0
var _mu := 0.1


func _init(stats: Dictionary, tuning: Tuning, course_data: Course) -> void:
	t = tuning
	course = course_data
	ramp_speed = stats["v0"]
	_cruise = stats["cruise"]
	_gravity = stats["gravity"]
	_mu = stats["mu"]
	wings = stats["wings"]
	max_wings = wings
	taken = PackedByteArray()
	taken.resize(course.pickups.size())
	var p := t.ramp_point(0.0)
	x = p.x
	y = p.y


# --- Simulation --------------------------------------------------------------

func step(dt: float, thrust_held: bool, tap: bool) -> void:
	## thrust_held : le joueur maintient la touche de jetpack. tap : la touche vient d'être pressée.
	hit_flag = false
	new_pickups.clear()
	if phase == Phase.RAMP:
		_step_ramp(dt, tap)
	elif phase == Phase.AIR:
		_step_air(dt, thrust_held)
	time += dt


func _step_ramp(dt: float, tap: bool) -> void:
	# La pente tire le savon, le frottement le retient.
	var slope := t.ramp_slope(s)
	var accel := -t.gravity * sin(slope) - _mu * t.gravity * cos(slope)
	ramp_speed = maxf(ramp_speed + accel * dt, t.min_ramp_speed)
	# Bon décollage : un appui dans les derniers mètres du tremplin = coup de reins.
	if tap and not perfect_takeoff and s >= t.ramp_len - t.takeoff_window:
		perfect_takeoff = true
		ramp_speed += t.takeoff_bonus
	s += ramp_speed * dt
	if s >= t.ramp_len:
		_take_off()
		return
	var p := t.ramp_point(s)
	x = p.x
	y = p.y


func _take_off() -> void:
	var p := t.ramp_point(t.ramp_len)
	var b := t.ramp_slope(t.ramp_len)
	x = p.x
	y = p.y
	vx = ramp_speed * cos(b)
	vy = ramp_speed * sin(b)
	phase = Phase.AIR


func _step_air(dt: float, thrust_held: bool) -> void:
	# Jetpack : on maintient pour monter, on relâche pour retomber.
	thrusting = thrust_held and not broken
	var ay := -_gravity + (t.jet_thrust if thrusting else 0.0)
	vy = clampf(vy + ay * dt, -t.fall_max, t.rise_max)
	# Le défilement rejoint doucement sa vitesse de croisière (élan de la piste, puis poids de la caisse).
	vx = move_toward(vx, _cruise, t.speed_ease * dt)
	x += vx * dt
	y += vy * dt
	# Le plafond (le meuble) arrête la montée sans faire de mal.
	if y > t.ceiling:
		y = t.ceiling
		vy = minf(vy, 0.0)
	invuln = maxf(0.0, invuln - dt)

	_collect()
	_check_obstacles()

	if x >= t.door_x:
		x = t.door_x
		phase = Phase.EXIT
	elif y <= 0.0:
		y = 0.0
		phase = Phase.STOPPED


func _collect() -> void:
	var r := t.soap_radius + 0.8
	for i in course.pickups.size():
		if taken[i] == 1:
			continue
		var pos: Vector2 = course.pickups[i]["pos"]
		if pos.x < x - 4.0:
			continue
		if pos.x > x + 4.0:
			break  # les pièces sont rangées de gauche à droite
		if Vector2(x, y).distance_to(pos) <= r:
			taken[i] = 1
			var mat: String = course.pickups[i]["mat"]
			collected[mat] = int(collected.get(mat, 0)) + 1
			new_pickups.append(i)


func _check_obstacles() -> void:
	if invuln > 0.0:
		return
	var c := Vector2(x, y)
	for o in course.obstacles:
		var rect: Rect2 = o["rect"]
		if rect.position.x > x + 6.0:
			continue
		if rect.end.x < x - 6.0:
			continue
		if Course.circle_hits_rect(c, t.soap_radius, rect):
			wings = maxi(0, wings - 1)
			hits += 1
			hit_flag = true
			invuln = t.invuln_time
			if wings == 0:
				broken = true
			return


func speed() -> float:
	if phase == Phase.RAMP:
		return ramp_speed
	return sqrt(vx * vx + vy * vy)
