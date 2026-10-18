@tool
extends Control
## Eau savonneuse en bas de l'écran : une nappe turquoise à bord ondulé, couverte de bulles de mousse.


## Couleur de l'eau (réglable par scène).
@export var couleur := Color(0.25, 0.6, 0.62, 1)
## Couleur du fond derrière les vagues (transparent = rien).
@export var fond := Color(0, 0, 0, 0)
const FOAM := Color(1, 1, 1, 0.85)
const BUBBLE_COUNT := 60

var _bubbles: Array[Vector3] = []


func _ready() -> void:
	resized.connect(_regenerate)
	_regenerate()


func _regenerate() -> void:
	# Graine fixe : les bulles restent au même endroit à chaque lancement
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_bubbles.clear()
	for i in BUBBLE_COUNT:
		var x := rng.randf_range(0.0, size.x)
		var y := rng.randf_range(4.0, size.y * 0.5)
		var r := rng.randf_range(4.0, 12.0)
		_bubbles.append(Vector3(x, y, r))
	queue_redraw()


func _draw() -> void:
	# Fond derrière les vagues (blanc sur les scores), si la scène en demande un
	if fond.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), fond)
	var points := PackedVector2Array()
	for x in range(0, int(size.x) + 1, 8):
		points.append(Vector2(x, 14.0 + sin(x * 0.03) * 5.0))
	points.append(Vector2(size.x, size.y))
	points.append(Vector2(0.0, size.y))
	draw_colored_polygon(points, couleur)
	for b in _bubbles:
		draw_circle(Vector2(b.x, b.y), b.z, FOAM)
