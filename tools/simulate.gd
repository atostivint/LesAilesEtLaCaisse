extends SceneTree
## Équilibrage sans interface (lit data/tuning.tres) :
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tools/simulate.gd
## Un "bot" simple joue à la place du joueur : il vise la pièce la plus proche et évite les obstacles.
## Le bot est volontairement basique : un humain doit faire aussi bien ou mieux.

const RUNS := 40
var T: Tuning = load("res://data/tuning.tres")


func _init() -> void:
	print("=== 1. Distance et récolte du bot, par caisse (%d vols chacune) ===" % RUNS)
	for c in T.crates:
		var dist := 0.0
		var finished := 0
		var got := {}
		for i in RUNS:
			var r := run_bot(c.id, 1000 + i, true)
			dist += r["distance"]
			finished += 1 if r["door"] else 0
			for m in r["collected"]:
				got[m] = int(got.get(m, 0)) + int(r["collected"][m])
		var per_run := {}
		for m in got:
			per_run[m] = snappedf(float(got[m]) / RUNS, 0.1)
		print("%-10s : moy %5.0f / %d | arrivée %2d/%d | par vol %s" % [c.id, dist / RUNS, int(T.door_x), finished, RUNS, str(per_run)])

	print("\n=== 2. Même chose avec un joueur moins précis (réagit tard) ===")
	for c in T.crates:
		var dist := 0.0
		var finished := 0
		for i in RUNS:
			var r := run_bot(c.id, 1000 + i, false)
			dist += r["distance"]
			finished += 1 if r["door"] else 0
		print("%-10s : moy %5.0f | arrivée %2d/%d" % [c.id, dist / RUNS, finished, RUNS])

	print("\n=== 3. Progression : on joue, on débloque dès qu'on peut (caisse la moins chère d'abord) ===")
	progression(true)
	print("\n--- Même progression, joueur moins précis ---")
	progression(false)
	quit()


func progression(perfect: bool) -> void:
	var stock := {}
	var unlocked := ["classique"]
	var equipped := "classique"
	for turn in range(1, 61):
		# Débloque tout ce qui est possible, la caisse la plus lourde en matériaux en dernier.
		var progress := true
		while progress:
			progress = false
			for c in T.crates:
				if unlocked.has(c.id):
					continue
				var ok := true
				for m in c.cost:
					if int(stock.get(m, 0)) < int(c.cost[m]):
						ok = false
				if ok:
					for m in c.cost:
						stock[m] = int(stock.get(m, 0)) - int(c.cost[m])
					unlocked.append(c.id)
					equipped = c.id
					print(">>> tour %2d : caisse débloquée : %s" % [turn, c.id])
					progress = true
					break
		var r := run_bot(equipped, 5000 + turn, perfect)
		for m in r["collected"]:
			stock[m] = int(stock.get(m, 0)) + int(r["collected"][m])
		if unlocked.size() == T.crates.size():
			print("=== toutes les caisses débloquées au tour %d ===" % turn)
			return
	print("=== pas toutes les caisses après 60 tours (stock %s) ===" % str(stock))


func run_bot(crate_id: String, seed_value: int, perfect: bool) -> Dictionary:
	var course := Course.new(T, seed_value)
	var sim := FlightSim.new(T.stats_for(crate_id), T, course)
	var frames := 0
	# Joueur "humain" : il réagit avec un retard (la décision est appliquée `lag` images plus tard),
	# regarde moins loin et ne vise que les pièces proches de son altitude.
	var reaction := 0.0 if perfect else 0.5
	var lag := 0 if perfect else 14
	var queue: Array[bool] = []
	while sim.phase <= FlightSim.Phase.AIR and frames < 60 * 300:
		var tap := false
		var hold := false
		if sim.phase == FlightSim.Phase.RAMP:
			tap = perfect and sim.s >= T.ramp_len - T.takeoff_window * 0.5
			hold = true
		else:
			queue.append(_decide(sim, reaction, perfect))
			hold = queue[0] if queue.size() > lag else true
			if queue.size() > lag:
				queue.pop_front()
		sim.step(Tuning.STEP, hold, tap)
		frames += 1
	return {"distance": sim.x, "door": sim.phase == FlightSim.Phase.EXIT, "collected": sim.collected, "hits": sim.hits, "time": sim.time}


func _decide(sim: FlightSim, reaction: float, perfect: bool) -> bool:
	## Cible une altitude (pièce proche ou passage sûr), puis maintient le jetpack pour y rester.
	var look := sim.vx * (1.1 - reaction)
	var target := 10.0
	# Obstacles devant : choisit un passage libre.
	var blocked: Array[Vector2] = []   # intervalles d'altitude interdits
	for o in sim.course.obstacles:
		var r: Rect2 = o["rect"]
		if r.end.x < sim.x - 2.0 or r.position.x > sim.x + look:
			continue
		blocked.append(Vector2(r.position.y - T.soap_radius - 0.6, r.end.y + T.soap_radius + 0.6))
	# Pièce la plus proche devant.
	var best := -1
	var best_d := 1e9
	for i in sim.course.pickups.size():
		if sim.taken[i] == 1:
			continue
		var p: Vector2 = sim.course.pickups[i]["pos"]
		if p.x < sim.x or p.x > sim.x + 24.0:
			continue
		var ok := perfect or absf(p.y - sim.y) < 6.0
		for b in blocked:
			if p.y > b.x and p.y < b.y:
				ok = false
		if ok and p.x - sim.x < best_d:
			best_d = p.x - sim.x
			best = i
	if best >= 0:
		target = (sim.course.pickups[best]["pos"] as Vector2).y
	# Si la cible est dans une zone interdite, on va au bord libre le plus proche.
	for b in blocked:
		if target > b.x and target < b.y:
			var up := b.y
			var down := b.x
			target = up if (up < T.ceiling - 1.0 and absf(up - sim.y) < absf(down - sim.y)) or down < 2.0 else down
	target = clampf(target, 3.0, T.ceiling - 1.5)
	# Régulateur simple : monte si trop bas (en tenant compte de la vitesse verticale).
	return sim.y + sim.vy * 0.25 < target
