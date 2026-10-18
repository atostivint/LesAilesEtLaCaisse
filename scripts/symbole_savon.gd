extends Control
## Symbole d'une équipe, affiché à droite de son bouton (feuille, goutte, château, étoile, lavande, bulles).
## Dessiné en code : `shape` choisit le symbole (0 à 5).


const OUTLINE := Color(0.29, 0.165, 0.078, 1)
const GREEN := Color(0.42, 0.54, 0.18, 1)
const BLUE := Color(0.25, 0.55, 0.6, 1)
const PURPLE := Color(0.45, 0.3, 0.6, 1)
const BROWN := Color(0.6, 0.36, 0.18, 1)
const YELLOW := Color(0.99, 0.76, 0.12, 1)

@export var shape := 0


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.42
	match shape:
		0:
			# Feuille (savon d'Alep)
			for angle in [-0.6, 0.6]:
				var leaf := _ellipse(c, r * 0.5, r * 0.95, angle)
				draw_colored_polygon(leaf, GREEN)
				draw_polyline(_closed(leaf), OUTLINE, 2.0)
		1:
			# Bulles (savon de Marseille)
			for offset in [Vector2(-r * 0.3, -r * 0.2), Vector2(r * 0.35, r * 0.1), Vector2(-r * 0.1, r * 0.5)]:
				draw_circle(c + offset, r * 0.35, BLUE)
				draw_arc(c + offset, r * 0.35, 0.0, TAU, 24, OUTLINE, 2.0)
		2:
			# Étoile (savon de Tripoli)
			var star := PackedVector2Array()
			for i in 8:
				var angle := -PI / 2.0 + i * TAU / 8.0
				var rad := r if i % 2 == 0 else r * 0.35
				star.append(c + Vector2(cos(angle), sin(angle)) * rad)
			draw_colored_polygon(star, YELLOW)
			draw_polyline(_closed(star), OUTLINE, 2.0)
		3:
			# Château (savon de Castille)
			var body := Rect2(c.x - r * 0.6, c.y - r * 0.3, r * 1.2, r * 1.2)
			draw_rect(body, BROWN)
			draw_rect(body, OUTLINE, false, 2.0)
			for i in 3:
				var merlon := Rect2(body.position.x + i * r * 0.42, body.position.y - r * 0.3, r * 0.3, r * 0.3)
				draw_rect(merlon, BROWN)
				draw_rect(merlon, OUTLINE, false, 2.0)
		4:
			# Lavande (savon de Naplouse)
			draw_line(c + Vector2(0, r), c + Vector2(0, -r * 0.2), OUTLINE, 2.0)
			for i in 5:
				draw_circle(c + Vector2(0, -r * 0.3 - i * r * 0.2), r * 0.16, PURPLE)
		5:
			# Goutte (savon noir africain)
			var drop := _ellipse(c + Vector2(0, r * 0.25), r * 0.55, r * 0.55, 0.0)
			drop.append(c + Vector2(0, -r))
			draw_colored_polygon(drop, OUTLINE)


func _ellipse(center: Vector2, rx: float, ry: float, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 20:
		var t := i * TAU / 20.0
		var p := Vector2(cos(t) * rx, sin(t) * ry).rotated(angle)
		points.append(center + p)
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed
