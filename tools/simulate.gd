extends SceneTree
## Équilibrage sans interface (lit data/tuning.tres) :
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tools/simulate.gd
## Un "bot" simple joue à la place du joueur pour estimer les distances.
## Le bot est volontairement basique : un humain doit faire aussi bien ou mieux.

const NAMES := ["poussee", "bulles", "ailes", "glisse"]
var T: Tuning = load("res://data/tuning.tres")


func _init() -> void:
	print("=== 1. Distance du bot selon le niveau (tous les upgrades au même niveau) ===")
	for lvl in range(0, T.max_level + 1):
		var lv := {"poussee": lvl, "bulles": lvl, "ailes": lvl, "glisse": lvl}
		var r := run_bot(T.stats_for(lv), true)
		print("niveau %d : %6.1f m  (altitude max %.1f m, %.1f s)" % [lvl, r["distance"], r["alt"], r["time"]])

	print("\n=== 2. Effet de chaque amélioration seule au niveau 4 ===")
	for n in NAMES:
		var lv := {"poussee": 0, "bulles": 0, "ailes": 0, "glisse": 0}
		lv[n] = 4
		print("%-8s : %6.1f m" % [n, run_bot(T.stats_for(lv), true)["distance"]])

	print("\n=== 3. Progression : on dépense tout en équilibrant les niveaux ===")
	progression(true)
	print("\n--- Même progression, sans bon décollage (joueur moins précis) ---")
	progression(false)
	quit()


func progression(perfect: bool) -> void:
	var levels := {"poussee": 0, "bulles": 0, "ailes": 0, "glisse": 0}
	var coins := T.start_coins
	var best := 0.0
	for turn in range(1, 41):
		# Achat : toujours l'amélioration au niveau le plus bas (ordre fixe si égalité).
		var bought := true
		while bought:
			bought = false
			var pick := ""
			for n in NAMES:
				if levels[n] < T.max_level and (pick == "" or levels[n] < levels[pick]):
					pick = n
			if pick != "" and coins >= T.cost_for(levels[pick]):
				coins -= T.cost_for(levels[pick])
				levels[pick] += 1
				bought = true
		var r := run_bot(T.stats_for(levels), perfect)
		var d: float = r["distance"]
		var gain := T.reward_for(d, d > best, r["door"])
		best = maxf(best, d)
		coins += gain
		print("tour %2d | niv %s | %6.1f m | +%d pièces | reste %d" % [turn, str(levels.values()), d, gain, coins])
		if r["door"]:
			print(">>> SORTIE de la salle de bains au tour %d" % turn)
			return
	print(">>> pas de sortie en 40 tours")


func run_bot(stats: Dictionary, perfect: bool) -> Dictionary:
	var sim := FlightSim.new(stats, T)
	var frames := 0
	while sim.phase <= FlightSim.Phase.SLIDE and frames < 60 * 300:
		var pitch := 0.0
		var action := false
		if sim.phase == FlightSim.Phase.RAMP:
			action = perfect and sim.s >= T.ramp_length() - T.takeoff_window * 0.5
		elif sim.phase == FlightSim.Phase.SLIDE:
			# Le bot garde le ventre à plat (comme un joueur attentif).
			pitch = clampf(-sim.theta * 3.0, -1.0, 1.0)
		else:
			if sim.vy < -1.5:
				pitch = 1.0
			action = sim.charges > 0 and sim.boost_left <= 0.0 and sim.y < 10.0
		sim.step(Tuning.STEP, pitch, action)
		frames += 1
	return {
		"distance": sim.x,
		"alt": sim.max_altitude,
		"time": sim.time,
		"door": sim.phase == FlightSim.Phase.EXIT,
	}
