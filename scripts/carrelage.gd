@tool
extends Control
## Fond en carrelage orange avec une étoile (starburst) au centre de chaque tuile,
## et quelques bulles de savon translucides.


const TILE := 150.0
const BUBBLE := Color(1, 1, 1, 0.7)

## Couleur de base du carrelage (orange au départ). En vol, elle prend celle du drapeau de chaque tortue passée.
## Les autres teintes (claire, joints, étoile) en sont déduites.
@export var teinte := Color(0.87, 0.5, 0.17, 1):
	set(value):
		teinte = value
		queue_redraw()
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
	var base := teinte
	var light := teinte.lightened(0.1)
	var grout := teinte.darkened(0.15)
	var petal := teinte.darkened(0.4)
	var center := teinte.darkened(0.2)
	draw_rect(Rect2(Vector2.ZERO, size), base)
	var cols := ceili(size.x / TILE)
	var rows := ceili(size.y / TILE)
	for x in cols:
		for y in rows:
			var r := Rect2(x * TILE, y * TILE, TILE, TILE)
			if (x + y) % 2 == 0:
				draw_rect(r, light)
			draw_rect(r, grout, false, 3.0)
			_starburst(r.get_center(), 30.0, petal, center)
	for b in BUBBLES:
		var c := Vector2(b.x, b.y)
		draw_circle(c, b.z, BUBBLE_FILL)
		draw_arc(c, b.z, 0.0, TAU, 32, BUBBLE, 3.0)


func _starburst(centre: Vector2, radius: float, petal: Color, coeur: Color) -> void:
	for i in 8:
		var dir := Vector2.from_angle(i * TAU / 8.0)
		draw_line(centre + dir * radius * 0.3, centre + dir * radius, petal, 6.0)
	draw_circle(centre, radius * 0.28, coeur)
