class_name Course
extends RefCounted
## Le parcours d'un vol : étagères (décor), pièces à rattraper (posées sur les étagères) et obstacles.
## Classe PURE (aucun nœud), générée depuis une graine : la simulation, l'écran de vol
## et le script d'équilibrage voient exactement le même parcours.
##
## Repère : x vers la droite, y vers le HAUT (altitude au-dessus de l'eau), en mètres.
## Les étagères n'ont PAS de collision : elles servent seulement d'appui visuel aux pièces.

const KIND_PINCE := "pince"      # pince à linge pendue au meuble
const KIND_CLOUS := "clous"      # planche à clous flottante

var shelves: Array[Rect2] = []   # (x, y du dessus, largeur, épaisseur) ; l'épaisseur va vers le bas
var pickups: Array[Dictionary] = []   # {"mat": id, "pos": Vector2}
var obstacles: Array[Dictionary] = [] # {"kind": KIND_*, "rect": Rect2 (x, ybas, largeur, hauteur)}
var seed_used := 0

var _t: Tuning
var _rng := RandomNumberGenerator.new()


func _init(tuning: Tuning, seed_value: int = 0) -> void:
	_t = tuning
	seed_used = seed_value if seed_value != 0 else int(Time.get_ticks_usec()) + 1
	_rng.seed = seed_used
	_generate()


func _generate() -> void:
	var x := _t.course_start
	while x < _t.door_x - 40.0:
		var seg := _rng.randf_range(_t.segment_min, _t.segment_max)
		var d := clampf(x / _t.door_x, 0.0, 1.0)  # difficulté 0..1
		_make_shelf(x + seg * 0.05, seg * 0.45)
		if _rng.randf() < lerpf(_t.obstacle_chance_start, _t.obstacle_chance_end, d):
			_make_obstacle(x + seg * 0.62, d)
			if _rng.randf() < _t.second_obstacle_end * d:
				_make_obstacle(x + seg * 0.62 + 17.0, d)
		x += seg


func _make_shelf(x: float, width: float) -> void:
	var h := _rng.randf_range(5.0, _t.ceiling - 6.0)
	shelves.append(Rect2(x, h, width, 0.7))
	# Les pièces sont posées sur l'étagère (ou accrochées en dessous, une fois sur quatre).
	var below := _rng.randf() < 0.25
	var n := _rng.randi_range(2, 4)
	var step := width / float(n + 1)
	for i in n:
		var px := x + step * (i + 1)
		var py := h - 1.6 if below else h + 1.7
		pickups.append({"mat": _pick_material(px), "pos": Vector2(px, py)})


func _pick_material(px: float) -> String:
	## Tirage pondéré parmi les matériaux déjà disponibles à cette distance.
	var total := 0.0
	for m in Tuning.MATERIALS:
		if px >= float(m["from"]):
			total += float(m["weight"])
	var r := _rng.randf() * total
	for m in Tuning.MATERIALS:
		if px >= float(m["from"]):
			r -= float(m["weight"])
			if r <= 0.0:
				return m["id"]
	return Tuning.MATERIALS[0]["id"]


func _make_obstacle(x: float, d: float) -> void:
	if x > _t.door_x - 25.0:
		return
	if _rng.randf() < 0.5:
		# Pince à linge : pendue au plafond, de plus en plus longue.
		var length := _rng.randf_range(6.0, 10.0 + 8.0 * d)
		obstacles.append({"kind": KIND_PINCE, "rect": Rect2(x, _t.ceiling - length, 2.0, length)})
	else:
		# Planche à clous flottante, à une hauteur quelconque.
		var y := _rng.randf_range(3.5, _t.ceiling - 6.0)
		obstacles.append({"kind": KIND_CLOUS, "rect": Rect2(x, y, 5.0, 1.3)})


static func circle_hits_rect(c: Vector2, r: float, rect: Rect2) -> bool:
	var nx := clampf(c.x, rect.position.x, rect.end.x)
	var ny := clampf(c.y, rect.position.y, rect.end.y)
	return c.distance_squared_to(Vector2(nx, ny)) <= r * r
