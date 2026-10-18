extends Control
## Visage du savon, dessiné d'après « six rectangles animés » (noir et blanc) :
## 0 kawaii, 1 agressif, 2 endormi, 3 anxieux, 4 blasé, 5 fou.
## Les coordonnées du dessin (180 × 170) sont ramenées au centre du corps du savon, en unités du savon.


const INK := Color(0.07, 0.07, 0.07, 1)
const WHITE := Color(1, 1, 1, 1)
const DRAW_SCALE := 0.2
const LINE_W := 0.8

@export var expression := 0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# Animation : le visage respire doucement et cligne (écrasement bref) toutes les 3 secondes
	var clignement := fmod(_t, 3.0) < 0.12
	var respiration := sin(_t * 3.0)
	var echelle_y := (0.85 if clignement else 1.0) + 0.03 * respiration
	draw_set_transform(Vector2(0.0, 0.6 * respiration), 0.0, Vector2(1.0, echelle_y))
	match expression:
		0:
			_kawaii()
		1:
			_agressif()
		2:
			_endormi()
		3:
			_anxieux()
		4:
			_blase()
		_:
			_fou()


func _kawaii() -> void:
	for x in [58.0, 122.0]:
		_disc(Vector2(x, 78), 15, INK)
		_disc(Vector2(x - 6, 71), 5.5, WHITE)
		_disc(Vector2(x + 5, 85), 2.5, WHITE)
	_line(_quad(Vector2(78, 108), Vector2(84, 118), Vector2(90, 108)), INK)
	_line(_quad(Vector2(90, 108), Vector2(96, 118), Vector2(102, 108)), INK)


func _agressif() -> void:
	_poly([Vector2(36, 60), Vector2(84, 82), Vector2(84, 100), Vector2(36, 100)], WHITE, true)
	_poly([Vector2(144, 60), Vector2(96, 82), Vector2(96, 100), Vector2(144, 100)], WHITE, true)
	_disc(Vector2(72, 93), 6, INK)
	_disc(Vector2(108, 93), 6, INK)
	_poly([Vector2(40, 118), Vector2(140, 118), Vector2(130, 152), Vector2(50, 152)], INK, false)
	for dents in [[43, 58], [58, 73], [73, 88], [88, 103], [103, 118], [118, 137]]:
		_poly([Vector2(dents[0], 118), Vector2(dents[1], 118), Vector2((dents[0] + dents[1]) / 2.0, 134)], WHITE, false)
	for dents in [[55, 70], [70, 85], [85, 100], [100, 115]]:
		_poly([Vector2(dents[0], 152), Vector2(dents[1], 152), Vector2((dents[0] + dents[1]) / 2.0, 138)], WHITE, false)


func _endormi() -> void:
	_half_disk(Vector2(60, 76), 16, INK)
	_half_disk(Vector2(120, 76), 16, INK)
	_line(PackedVector2Array([P(40, 76), P(80, 76)]), INK)
	_line(PackedVector2Array([P(100, 76), P(140, 76)]), INK)
	_poly_ellipse(Vector2(90, 125), 12, 17, INK)


func _anxieux() -> void:
	for x in [58.0, 122.0]:
		_disc(Vector2(x, 70), 20, WHITE)
		_ring(Vector2(x, 70), 20)
		_disc(Vector2(x, 70), 4, INK)
	var wave := PackedVector2Array()
	for i in 25:
		var x := 52.0 + i * 3.0
		wave.append(P(x, 126.0 - 10.0 * absf(sin((x - 52.0) * PI / 18.0))))
	_line(wave, INK)


func _blase() -> void:
	_half_disk(Vector2(60, 72), 16, WHITE)
	_half_disk(Vector2(120, 72), 16, WHITE)
	_disc(Vector2(60, 79), 6, INK)
	_disc(Vector2(120, 79), 6, INK)
	_line(PackedVector2Array([P(42, 72), P(78, 72)]), INK)
	_line(PackedVector2Array([P(102, 72), P(138, 72)]), INK)
	_line(_quad(Vector2(60, 122), Vector2(100, 132), Vector2(132, 108)), INK)


func _fou() -> void:
	_disc(Vector2(55, 68), 21, WHITE)
	_ring(Vector2(55, 68), 21)
	_disc(Vector2(61, 61), 4, INK)
	_disc(Vector2(125, 78), 10, WHITE)
	_ring(Vector2(125, 78), 10)
	_disc(Vector2(123, 79), 3, INK)
	draw_colored_polygon(_quad(Vector2(40, 115), Vector2(90, 160), Vector2(140, 115)), INK)
	draw_colored_polygon(_quad(Vector2(92, 127), Vector2(105, 144), Vector2(118, 127)), WHITE)


# Conversion d'un point du dessin (180 × 170) vers les unités du savon
func P(x: float, y: float) -> Vector2:
	return Vector2((x - 90.0) * DRAW_SCALE, (y - 85.0) * DRAW_SCALE)


func _disc(c: Vector2, r: float, color: Color) -> void:
	draw_circle(P(c.x, c.y), r * DRAW_SCALE, color)


func _ring(c: Vector2, r: float) -> void:
	draw_arc(P(c.x, c.y), r * DRAW_SCALE, 0.0, TAU, 32, INK, LINE_W)


func _half_disk(c: Vector2, r: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var t := PI * (1.0 - i / 16.0)
		pts.append(P(c.x + r * cos(t), c.y + r * sin(t)))
	draw_colored_polygon(pts, color)
	draw_polyline(_closed(pts), INK, LINE_W)


func _poly_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := i * TAU / 24.0
		pts.append(P(c.x + rx * cos(t), c.y + ry * sin(t)))
	draw_colored_polygon(pts, color)


func _poly(points: Array, color: Color, outlined: bool) -> void:
	var pts := PackedVector2Array()
	for p in points:
		pts.append(P(p.x, p.y))
	draw_colored_polygon(pts, color)
	if outlined:
		draw_polyline(_closed(pts), INK, LINE_W)


func _quad(a: Vector2, c: Vector2, b: Vector2) -> PackedVector2Array:
	# Courbe de Bézier quadratique, échantillonnée
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var p := (1.0 - t) * (1.0 - t) * a + 2.0 * (1.0 - t) * t * c + t * t * b
		pts.append(P(p.x, p.y))
	return pts


func _line(pts: PackedVector2Array, color: Color) -> void:
	draw_polyline(pts, color, LINE_W)


func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var closed := pts.duplicate()
	closed.append(pts[0])
	return closed
