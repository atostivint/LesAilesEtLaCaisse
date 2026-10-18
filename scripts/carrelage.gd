@tool
extends Control
## Fond en carrelage orange avec une étoile (starburst) au centre de chaque tuile,
## et quelques bulles de savon translucides.


const TILE := 150.0
const BASE := Color(0.87, 0.5, 0.17, 1)
const LIGHT := Color(0.9, 0.56, 0.23, 1)
const GROUT := Color(0.74, 0.42, 0.14, 1)
const PETAL := Color(0.42, 0.5, 0.18, 1)
const CENTER := Color(0.8, 0.35, 0.12, 1)
const BUBBLE := Color(1, 1, 1, 0.7)
const BUBBLE_FILL := Color(1, 1, 1, 0.18)

# Bulles en coordonnées de la scène : centre et rayon
const BUBBLES := [
	Vector3(593, 293, 33),
	Vector3(660, 460, 20),
	Vector3(330, 200, 14),
]


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BASE)
	var cols := ceili(size.x / TILE)
	var rows := ceili(size.y / TILE)
	for x in cols:
		for y in rows:
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			if (x + y) % 2 == 0:
				draw_rect(r, LIGHT)
			draw_rect(r, GROUT, false, 3.0)
			_starburst(r.get_center(), 30.0)
	for b in BUBBLES:
		var c := Vector2(b.x, b.y)
		draw_circle(c, b.z, BUBBLE_FILL)
		draw_arc(c, b.z, 0.0, TAU, 32, BUBBLE, 3.0)


func _starburst(center: Vector2, radius: float) -> void:
	for i in 8:
		var dir := Vector2.from_angle(i * TAU / 8.0)
		draw_line(center + dir * radius * 0.3, center + dir * radius, PETAL, 6.0)
	draw_circle(center, radius * 0.28, CENTER)
