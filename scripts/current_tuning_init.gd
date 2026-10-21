extends RefCounted
class_name CurrentTuningInit

## Initialise un Tuning avec les valeurs actuellement présentes dans data/tuning.tres,
## plus les valeurs par défaut de Tuning quand la ressource ne les surdéfinit pas.
static func make() -> Tuning:
	var tuning := Tuning.new()

	# Contenu
	tuning.materials = [
		load("res://data/materials/planche.tres"),
		load("res://data/materials/plume.tres"),
		load("res://data/materials/elastique.tres"),
		load("res://data/materials/etoile.tres"),
	]
	tuning.crates = [
		load("res://data/crates/classique.tres"),
		load("res://data/crates/cercueil.tres"),
		load("res://data/crates/baignoire.tres"),
		load("res://data/crates/baguette.tres"),
		load("res://data/crates/dollar.tres"),
	]

	# Monde
	tuning.ppm = 20.0
	tuning.display_cm_per_unit = 30.0
	tuning.door_x = 800.0
	tuning.ceiling = 28.0

	# Piste
	tuning.gravity = 9.8
	tuning.ramp_v0 = 18.0
	tuning.ramp_start_h = 10.0
	tuning.ramp_len = 26.0
	tuning.ramp_top_deg = 45.0
	tuning.ramp_lip_deg = 25.0
	tuning.mu_base = 0.14
	tuning.min_ramp_speed = 1.0
	tuning.takeoff_window = 3.5
	tuning.takeoff_bonus = 3.0

	# Vol : jetpack
	tuning.cruise_speed = 22.5
	tuning.cruise_per_weight = 1.5
	tuning.speed_ease = 4.0
	tuning.jet_gravity = 37.0
	tuning.jet_thrust = 90.0
	tuning.weight_gravity = 0.12
	tuning.rise_max = 13.0
	tuning.fall_max = 16.0
	tuning.soap_radius = 1.1

	# Caisses
	tuning.wings_base = 2
	tuning.wings_per_solidity = 1
	tuning.invuln_time = 1.2

	# Parcours
	tuning.course_seed = 0
	tuning.course_start = 50.0
	tuning.spawn_interval = 3.0
	tuning.spawn_ahead = 90.0
	tuning.segment_min = 40.0
	tuning.segment_max = 52.0
	tuning.obstacle_chance_start = 0.5
	tuning.obstacle_chance_end = 1.0
	tuning.second_obstacle_end = 0.8

	return tuning
