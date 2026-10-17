extends Node2D
## Pose le parcours (étagères, pièces, obstacles) dans le monde d'après un Course.
## Le dessin de chaque élément est dans sa scène (shelf, pince, clous, pickup) ; ce script les instancie
## et les place. Les collisions sont dans FlightSim.

const SHELF := preload("res://scenes/shelf.tscn")
const PINCE := preload("res://scenes/pince.tscn")
const CLOUS := preload("res://scenes/clous.tscn")
const PICKUP := preload("res://scenes/pickup.tscn")

var _pickups: Array[Node2D] = []   # même ordre que course.pickups


func setup(tuning: Tuning, course: Course) -> void:
	for sh in course.shelves:
		var shelf := SHELF.instantiate()
		add_child(shelf)
		shelf.setup(tuning.to_px(sh.position.x, sh.position.y), sh.size * tuning.ppm)
	for o in course.obstacles:
		var obstacle: Control = (PINCE if o["kind"] == Course.KIND_PINCE else CLOUS).instantiate()
		add_child(obstacle)
		obstacle.setup(_rect_px(tuning, o["rect"]))
	for p in course.pickups:
		var pickup := PICKUP.instantiate()
		add_child(pickup)
		pickup.setup(p["mat"], tuning.to_px(p["pos"].x, p["pos"].y))
		_pickups.append(pickup)


func collect(indices: Array[int]) -> void:
	## Fait disparaître les pièces qui viennent d'être ramassées.
	for i in indices:
		_pickups[i].hide()


func _rect_px(tuning: Tuning, r: Rect2) -> Rect2:
	## Rect2 en mètres (x, y du BAS, largeur, hauteur) -> pixels (y de l'écran vers le bas).
	return Rect2(tuning.to_px(r.position.x, r.end.y), r.size * tuning.ppm)
