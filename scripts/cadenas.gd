extends Control
## Cadenas dessiné en code : fermé (caisse non construite) ou ouvert (caisse construite).


const BROWN := Color(0.29, 0.165, 0.078, 1)
const CREAM := Color(0.984, 0.941, 0.839, 1)

@export var open := false


func _draw() -> void:
	var w := size.x * 0.6
	var h := size.y * 0.5
	var body := Rect2(size.x / 2.0 - w / 2.0, size.y * 0.45, w, h)
	var r := w * 0.32
	var sommet := body.position.y
	if open:
		# Anse soulevée sur le côté
		draw_arc(Vector2(body.position.x + w * 0.5 - r * 0.6, sommet - r * 0.5), r, PI, TAU, 16, BROWN, 3.0)
	else:
		# Anse fermée, posée sur le corps
		draw_arc(Vector2(body.position.x + w * 0.5, sommet), r, PI, TAU, 16, BROWN, 3.0)
	draw_rect(body, BROWN)
	draw_rect(Rect2(body.position + Vector2(w * 0.4, h * 0.3), Vector2(w * 0.2, h * 0.3)), CREAM)
