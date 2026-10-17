extends Node2D
## Dessine le parcours (étagères, pièces, obstacles) d'après un Course. Ne calcule rien :
## les collisions sont dans FlightSim. On ne redessine que quand une pièce est ramassée.

const BROWN := Color("#3e2412")
const WOOD := Color("#c98d4f")

var tuning: Tuning
var course: Course
var taken: PackedByteArray


func setup(t: Tuning, c: Course, taken_flags: PackedByteArray) -> void:
	tuning = t
	course = c
	taken = taken_flags
	queue_redraw()


func _draw() -> void:
	if course == null:
		return
	for sh in course.shelves:
		_draw_shelf(sh)
	for o in course.obstacles:
		_draw_obstacle(o)
	for i in course.pickups.size():
		if taken[i] == 0:
			_draw_pickup(course.pickups[i])


func _rect_px(r: Rect2) -> Rect2:
	## Rect2 en mètres (x, y du BAS, largeur, hauteur) -> pixels (y de l'écran vers le bas).
	var top_left := tuning.to_px(r.position.x, r.end.y)
	return Rect2(top_left, r.size * tuning.ppm)


func _draw_shelf(sh: Rect2) -> void:
	# `sh` : y = hauteur du dessus de l'étagère, size.y = épaisseur vers le bas.
	var top := tuning.to_px(sh.position.x, sh.position.y)
	var plank := Rect2(top, Vector2(sh.size.x * tuning.ppm, sh.size.y * tuning.ppm))
	var bw := minf(plank.size.x * 0.12, 30.0)
	for bx in [plank.position.x + plank.size.x * 0.15, plank.end.x - plank.size.x * 0.15 - bw]:
		var tri := PackedVector2Array([
			Vector2(bx, plank.end.y), Vector2(bx + bw, plank.end.y), Vector2(bx, plank.end.y + bw * 1.2)])
		draw_colored_polygon(tri, BROWN)
	draw_rect(plank, WOOD)
	draw_rect(plank, BROWN, false, 4.0)


func _draw_obstacle(o: Dictionary) -> void:
	var r := _rect_px(o["rect"])
	if o["kind"] == Course.KIND_PINCE:
		# Pince à linge géante pendue au meuble : corps orange, extrémité rouge.
		draw_rect(r, Color("#c8561b"))
		draw_rect(r, BROWN, false, 4.0)
		var tip := Rect2(r.position.x, r.end.y - 36.0, r.size.x, 36.0)
		draw_rect(tip, Color("#b5361f"))
		draw_rect(tip, BROWN, false, 4.0)
		draw_line(Vector2(r.position.x + r.size.x * 0.5, r.position.y), Vector2(r.position.x + r.size.x * 0.5, r.end.y - 36.0), BROWN, 3.0)
	else:
		# Planche à clous flottante : planche de bois hérissée de pointes.
		draw_rect(r, WOOD)
		draw_rect(r, BROWN, false, 4.0)
		var n := int(r.size.x / 14.0)
		for k in n:
			var cx := r.position.x + 7.0 + k * 14.0
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 5, r.position.y), Vector2(cx + 5, r.position.y), Vector2(cx, r.position.y - 14)]), Color("#8a8a8a"))
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 5, r.end.y), Vector2(cx + 5, r.end.y), Vector2(cx, r.end.y + 14)]), Color("#8a8a8a"))
	# Pastille "!" au-dessus de l'obstacle.
	var c := Vector2(r.position.x + r.size.x * 0.5, r.position.y - 30.0 if o["kind"] == Course.KIND_CLOUS else r.end.y + 26.0)
	draw_circle(c, 13.0, Color("#E3A72F"))
	draw_arc(c, 13.0, 0.0, TAU, 16, BROWN, 3.0)
	draw_line(c + Vector2(0, -6), c + Vector2(0, 2), BROWN, 3.0)
	draw_circle(c + Vector2(0, 7), 1.8, BROWN)


func _draw_pickup(p: Dictionary) -> void:
	var c := tuning.to_px(p["pos"].x, p["pos"].y)
	var col: Color = tuning.material(p["mat"])["color"]
	match p["mat"]:
		"planche":
			var r := Rect2(c + Vector2(-17, -7), Vector2(34, 14))
			draw_rect(r, col)
			draw_rect(r, BROWN, false, 3.0)
			draw_circle(c + Vector2(-9, 0), 1.8, BROWN)
			draw_circle(c + Vector2(9, 0), 1.8, BROWN)
		"plume":
			var pts := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				pts.append(c + Vector2(cos(a) * 9.0, sin(a) * 19.0).rotated(0.6))
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, BROWN, 3.0)
			draw_line(c + Vector2(-9, 9).rotated(0.0), c + Vector2(9, -9), BROWN, 2.0)
		"elastique":
			draw_arc(c, 12.0, 0.0, TAU, 20, BROWN, 9.0)
			draw_arc(c, 12.0, 0.0, TAU, 20, col, 5.0)
		"etoile":
			var pts := PackedVector2Array()
			for i in 10:
				var rad := 18.0 if i % 2 == 0 else 8.0
				var a := -PI / 2.0 + TAU * i / 10.0
				pts.append(c + Vector2(cos(a), sin(a)) * rad)
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, BROWN, 3.0)
		_:
			draw_circle(c, 12.0, col)
