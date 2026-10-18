extends Control
## Icône provisoire d'un matériau : une forme géométrique (cercle, carré, étoile...) en attendant les dessins.
## `shape` choisit la forme et la couleur ; on remplacera ce nœud par une image quand elles seront prêtes.


const COLORS := [
	Color(0.99, 0.76, 0.12, 1),
	Color(0.8, 0.36, 0.14, 1),
	Color(0.25, 0.55, 0.6, 1),
	Color(0.42, 0.54, 0.18, 1),
	Color(0.6, 0.36, 0.18, 1),
	Color(0.45, 0.3, 0.6, 1),
]
const OUTLINE := Color(0.29, 0.165, 0.078, 1)

@export var shape := 0


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.42
	var col: Color = COLORS[shape % COLORS.size()]
	var pts := PackedVector2Array()
	match shape % 6:
		0:
			draw_circle(c, r, col)
			draw_arc(c, r, 0.0, TAU, 32, OUTLINE, 3.0)
			return
		1:
			pts = PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, r)])
		2:
			for i in 10:
				var a := -PI / 2.0 + i * TAU / 10.0
				var rad := r if i % 2 == 0 else r * 0.45
				pts.append(c + Vector2(cos(a), sin(a)) * rad)
		3:
			pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		4:
			pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.8), c + Vector2(-r, r * 0.8)])
		5:
			for i in 6:
				var a := i * TAU / 6.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, OUTLINE, 3.0)
