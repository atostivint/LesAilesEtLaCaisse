@tool
extends Control
## Moulures décoratives sur la planche du haut de la piste (le plafond) : frises de dents,
## oves et dards, perles et rosaces qui se répètent de gauche à droite.


const LIGHT := Color(0.97, 0.8, 0.42, 1)
const SHADE := Color(0.7, 0.46, 0.1, 1)
const SHADOW := Color(0.243, 0.141, 0.071, 1)
const ROSE := Color(0.95, 0.74, 0.32, 1)
const DENT := 18
const OVE := 40
const ROSACE := 80


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := int(size.x)
	# Liseret clair en haut
	draw_rect(Rect2(0, 0, w, 4), LIGHT)
	# Frise de dents
	for x in range(0, w, DENT):
		draw_rect(Rect2(x + 4, 14, 9, 12), SHADE)
		draw_rect(Rect2(x + 4, 14, 9, 12), SHADOW, false, 1.5)
	draw_rect(Rect2(0, 28, w, 3), SHADE)
	# Oves et dards
	for x in range(0, w, OVE):
		var c := Vector2(x + OVE * 0.5, 50)
		draw_colored_polygon(_ellipse(c, 9.0, 7.0), LIGHT)
		draw_polyline(_ferme(_ellipse(c, 9.0, 7.0)), SHADOW, 1.5)
		var d := x + OVE
		draw_colored_polygon(PackedVector2Array([Vector2(d - 5, 38), Vector2(d + 5, 38), Vector2(d, 46)]), SHADE)
	draw_rect(Rect2(0, 72, w, 3), SHADOW)
	# Perles
	for x in range(0, w, 12):
		draw_circle(Vector2(x + 6, 86), 3.5, SHADE)
	# Rosaces
	for x in range(0, w, ROSACE):
		_rosace(Vector2(x + ROSACE * 0.5, 118))
	# Rainure au-dessus du liseret brun du bas
	draw_rect(Rect2(0, 142, w, 2), SHADE)


func _rosace(c: Vector2) -> void:
	for i in 8:
		var dir := Vector2.from_angle(i * TAU / 8.0)
		draw_circle(c + dir * 9.0, 4.5, ROSE)
	draw_circle(c, 7.0, LIGHT)
	draw_arc(c, 7.0, 0.0, TAU, 24, SHADOW, 1.5)
	draw_circle(c, 2.5, SHADOW)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _ferme(pts: PackedVector2Array) -> PackedVector2Array:
	var fermee := pts.duplicate()
	fermee.append(pts[0])
	return fermee
