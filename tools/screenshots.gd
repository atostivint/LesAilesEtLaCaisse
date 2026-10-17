extends SceneTree
## Auto-jeu pour vérifier visuellement les écrans (fenêtre réelle, pas --headless) :
##   Godot --path . -s tools/screenshots.gd -- <dossier_de_sortie>
## Joue un tour avec un petit pilote automatique et sauvegarde des PNG.

var out := "/tmp/"
var f := 0
var done := {}
var result_t := 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0].path_join("")
	Engine.time_scale = 2.0
	change_scene_to_file("res://scenes/atelier.tscn")


func _press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)


func _shot(name: String) -> void:
	if done.has(name):
		return
	done[name] = true
	root.get_viewport().get_texture().get_image().save_png(out + name + ".png")
	print("capture : ", name)


func _process(_delta: float) -> bool:
	f += 1
	var gs = root.get_node("GameState")
	if f == 10:
		_shot("1_atelier")
		gs.materials = {"planche": 20, "plume": 5, "elastique": 1}
		gs.last_run = {"distance": 412.0, "collected": {"planche": 8, "plume": 2}, "record": true, "door": false, "turn": 1}
		gs.unlock("crayon")
		current_scene.call("_refresh")
	elif f == 20:
		_shot("2_atelier_debloque")
		change_scene_to_file("res://scenes/vol.tscn")
	elif f == 40:
		_shot("3_vol_pret")
		_press("ui_accept")
		Input.action_release("ui_accept")
	elif f > 40 and current_scene.name == "Vol":
		var v = current_scene
		var sim: FlightSim = v.sim
		if v.state == 1:
			if sim.phase == FlightSim.Phase.RAMP:
				if sim.s > 8.0:
					_shot("4_piste")
				if sim.s >= gs.tuning.ramp_length() - 1.5:
					_press("ui_accept")
					Input.action_release("ui_accept")
			else:
				if sim.time > 4.0:
					_shot("5_en_vol")
				if sim.time > 9.0:
					_shot("5b_en_vol_plus_loin")
				# Pilote : maintient le jetpack quand le savon est sous ~12 m.
				if sim.y + sim.vy * 0.25 < 12.0:
					Input.action_press("ui_accept")
				else:
					Input.action_release("ui_accept")
		elif v.state == 2:
			Input.action_release("ui_accept")
			result_t += _delta
			if result_t > 0.8:
				_shot("6_resultat")
				print("distance=", v.result["distance"], " récolte=", v.result["collected"])
				return true
	if f > 9000:
		print("TIMEOUT")
		return true
	return false
