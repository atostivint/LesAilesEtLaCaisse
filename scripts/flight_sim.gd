class_name FlightSim
extends RefCounted
## Simulation PURE du vol (aucun nœud Godot) : on lui donne les stats du savon,
## puis on appelle step() à chaque image. Elle sert au jeu ET au script d'équilibrage.
##
## Repère : x vers la droite, y vers le HAUT (altitude au-dessus de l'eau), en mètres.
## Phases : RAMP (piste) -> AIR (vol) -> SLIDE (glisse sur l'eau après l'impact)
## -> STOPPED (le savon s'est arrêté) ; ou EXIT (a franchi la porte à 700 m).

enum Phase { RAMP, AIR, SLIDE, STOPPED, EXIT }

var phase: Phase = Phase.RAMP
var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var alpha := 0.0            # incidence : angle entre la trajectoire et le nez du savon
var s := 0.0                # position le long de la piste (m)
var ramp_speed := 0.0
var charges := 0            # jets de bulles restants
var boost_left := 0.0       # temps restant du jet en cours
var perfect_takeoff := false
var max_altitude := 0.0
var time := 0.0
var theta := 0.0            # SLIDE : inclinaison du savon (rad, + = nez en haut, la caisse plonge)
var omega := 0.0            # SLIDE : vitesse de rotation (rad/s)
var contact := ""           # SLIDE : "ventre", "caisse" ou "nez" (ce qui frotte dans l'eau)
var friction := 0.0         # SLIDE : décélération actuelle (m/s²)
var bounces := 0            # nombre de rebonds déjà faits

var t: Tuning               # réglages (lus à chaque pas : modifiables en direct)
var _lift := 1.0
var _drag := 1.0
var _mu := 0.1


func _init(stats: Dictionary, tuning: Tuning) -> void:
	t = tuning
	ramp_speed = stats["v0"]
	charges = stats["charges"]
	_lift = stats["lift"]
	_drag = stats["drag"]
	_mu = stats["mu"]
	alpha = deg_to_rad(t.alpha0_deg)
	var p := t.ramp_point(0.0)
	x = p.x
	y = p.y


# --- Simulation --------------------------------------------------------------

func step(dt: float, pitch_input: float, action: bool) -> void:
	## pitch_input : -1 (piquer) .. +1 (cabrer). action : ESPACE vient d'être pressé.
	if phase == Phase.RAMP:
		_step_ramp(dt, action)
	elif phase == Phase.AIR:
		_step_air(dt, pitch_input, action)
	elif phase == Phase.SLIDE:
		_step_slide(dt, pitch_input, action)
	time += dt


func _step_ramp(dt: float, action: bool) -> void:
	# La pente tire le savon, le frottement le retient.
	var slope := t.ramp_slope(s)
	var accel := -t.gravity * sin(slope) - _mu * t.gravity * cos(slope)
	ramp_speed = maxf(ramp_speed + accel * dt, t.min_ramp_speed)
	# Bon décollage : ESPACE dans les derniers mètres du tremplin = coup de reins.
	if action and not perfect_takeoff and s >= t.ramp_length() - t.takeoff_window:
		perfect_takeoff = true
		ramp_speed += t.takeoff_bonus
	s += ramp_speed * dt
	if s >= t.ramp_length():
		_take_off()
		return
	var p := t.ramp_point(s)
	x = p.x
	y = p.y


func _take_off() -> void:
	var p := t.ramp_point(t.ramp_length())
	var b := t.ramp_slope(t.ramp_length())
	x = p.x
	y = p.y
	vx = ramp_speed * cos(b)
	vy = ramp_speed * sin(b)
	max_altitude = y
	phase = Phase.AIR


func _step_air(dt: float, pitch_input: float, action: bool) -> void:
	var v := maxf(sqrt(vx * vx + vy * vy), 0.1)
	var dirx := vx / v
	var diry := vy / v

	# 1. Inclinaison : le joueur choisit l'incidence (cabrer = plus de portance ET de traînée).
	var a0 := deg_to_rad(t.alpha0_deg)
	var target := a0
	if pitch_input >= 0.0:
		target = lerpf(a0, deg_to_rad(t.alpha_up_deg), pitch_input)
	else:
		target = lerpf(a0, deg_to_rad(t.alpha_down_deg), -pitch_input)
	alpha = lerpf(alpha, target, minf(1.0, dt * t.pitch_response))

	# 2. Forces aérodynamiques (toutes proportionnelles à la vitesse²).
	var cl := clampf(t.cl_slope * alpha, -t.cl_max, t.cl_max)
	var lift := t.lift_k * _lift * v * v * cl
	var drag := t.drag_k * _drag * v * v * (t.cd0 + t.cd_k * cl * cl)
	# La portance est perpendiculaire à la trajectoire, la traînée s'y oppose.
	var ax := -dirx * drag - diry * lift
	var ay := -t.gravity - diry * drag + dirx * lift

	# 3. Jet de bulles : poussée dans l'axe du nez, pendant BOOST_DURATION.
	if action and boost_left <= 0.0 and charges > 0:
		charges -= 1
		boost_left = t.boost_duration
	if boost_left > 0.0:
		var nose := atan2(vy, vx) + alpha
		ax += cos(nose) * t.thrust
		ay += sin(nose) * t.thrust
		boost_left -= dt

	# 4. Intégration.
	vx = maxf(vx + ax * dt, 0.5)
	vy += ay * dt
	x += vx * dt
	y += vy * dt
	max_altitude = maxf(max_altitude, y)

	if x >= t.door_x:
		x = t.door_x
		phase = Phase.EXIT
	elif y <= 0.0:
		_touch_down()


func _touch_down() -> void:
	## Impact sur l'eau. Selon la vitesse de chute, le savon REBONDIT (ricochet) ou se pose et glisse.
	## Rebond : la vitesse verticale est rendue en partie (restitution), et le frottement du contact
	## retire de la vitesse horizontale, proportionnellement à la force du choc.
	## La matière qui touche compte : le ventre rebondit bien, la caisse (nez en haut) ou le nez
	## qui pique amortissent presque tout.
	theta = atan2(vy, vx) + alpha
	var deg := rad_to_deg(theta)
	var crate := smoothstep(t.crate_start_deg, t.crate_full_deg, deg)
	var dig := smoothstep(t.dig_start_deg, t.dig_full_deg, -deg)
	var impact := maxf(0.0, -vy)
	y = 0.0
	if impact >= t.bounce_min_speed and bounces < t.max_bounces:
		var material := (1.0 - 0.85 * crate) * (1.0 - 0.85 * dig)
		var skip := t.bounce_skip * vx * pow(0.6, bounces)
		var vy_out := (impact * t.bounce_restitution + skip) * material
		vx = maxf(vx - t.bounce_friction * (impact + vy_out), vx * 0.2)
		vy = vy_out
		y = 0.001  # un poil au-dessus de l'eau pour ne pas re-déclencher l'impact
		bounces += 1
		omega = -impact * t.touchdown_spin
		return
	# Pas (ou plus) de rebond : on se pose et on glisse.
	omega = vy * t.touchdown_spin
	var descent := impact / maxf(vx, 0.1)
	vx *= maxf(t.impact_keep_min, 1.0 - t.impact_loss * descent)
	vy = 0.0
	contact = "ventre"
	phase = Phase.SLIDE


func _step_slide(dt: float, pitch_input: float, action: bool) -> void:
	## Le savon glisse sur l'eau. Ce qui touche l'eau décide du frottement :
	##  - ventre à plat : il glisse loin ; - nez en haut : la CAISSE traîne et freine net ;
	##  - nez en bas : il pique et freine aussi.
	## Un jet de bulles pousse vers l'avant mais fait basculer le nez vers le bas (bousculade).
	var deg := rad_to_deg(theta)
	var crate := smoothstep(t.crate_start_deg, t.crate_full_deg, deg)
	var dig := smoothstep(t.dig_start_deg, t.dig_full_deg, -deg)
	friction = t.belly_friction + t.crate_friction * crate + t.dig_friction * dig
	contact = "caisse" if crate > 0.3 else ("nez" if dig > 0.3 else "ventre")

	if action and boost_left <= 0.0 and charges > 0:
		charges -= 1
		boost_left = t.boost_duration
	var push := 0.0
	var torque := -t.level_stiffness * theta - t.level_damping * omega + pitch_input * t.slide_pitch_torque
	if boost_left > 0.0:
		push = t.thrust * cos(theta)
		torque -= t.jet_torque
		boost_left -= dt

	vx = maxf(0.0, vx + (push - friction) * dt)
	omega += torque * dt
	theta = clampf(theta + omega * dt, -deg_to_rad(80.0), deg_to_rad(80.0))
	x += vx * dt
	if x >= t.door_x:
		x = t.door_x
		phase = Phase.EXIT
	elif vx <= t.stop_speed and boost_left <= 0.0:
		phase = Phase.STOPPED


func speed() -> float:
	if phase == Phase.RAMP:
		return ramp_speed
	return sqrt(vx * vx + vy * vy)
