@tool
extends Control
## Eau savonneuse en bas de l'écran : une nappe turquoise à bord ondulé qui ondule en continu,
## couverte de bulles de mousse qui montent doucement, vacillent et éclatent à la surface.


## Couleur de l'eau (réglable par scène).
@export var couleur := Color(0.25, 0.6, 0.62, 1)
## Couleur du fond derrière les vagues (transparent = rien).
@export var fond := Color(0, 0, 0, 0)
const FOAM := Color(1, 1, 1, 0.85)
const BUBBLE_COUNT := 60
const PAS := 8 # distance entre deux points de la surface (px)
const SURFACE_Y := 14.0 # hauteur moyenne de la surface

# Une bulle : x, rayon, vitesse de montée (px/s), phase (0..1 pour la position, TAU pour le vacillement)
var _bubbles: Array[Vector4] = []
var _temps := 0.0


func _ready() -> void:
	resized.connect(_regenerate)
	_regenerate()
	# Animée en jeu seulement : dans l'éditeur l'eau reste figée
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_temps += delta
	queue_redraw()


func _regenerate() -> void:
	# Graine fixe : les bulles repartent du même endroit à chaque lancement
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_bubbles.clear()
	for i in BUBBLE_COUNT:
		_bubbles.append(Vector4(
			rng.randf_range(0.0, size.x),
			rng.randf_range(3.0, 11.0),
			rng.randf_range(8.0, 24.0),
			rng.randf()))
	queue_redraw()


func _surface(x: float, decalage := 0.0, amplitude := 1.0) -> float:
	## Hauteur de la surface en x : deux houles qui se croisent, dans des sens opposés.
	return SURFACE_Y + decalage \
		+ (sin(x * 0.03 + _temps * 1.6) * 4.0 + sin(x * 0.011 - _temps * 0.9) * 3.0) * amplitude


func _draw() -> void:
	# Fond derrière les vagues (blanc sur les scores), si la scène en demande un
	if fond.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), fond)
	# Houle du fond : une nappe plus claire, décalée, qui bouge à contre-sens
	var arriere := PackedVector2Array()
	for x in range(0, int(size.x) + 1, PAS):
		arriere.append(Vector2(x, _surface(x + 70.0, -5.0, 0.8)))
	arriere.append(Vector2(size.x, size.y))
	arriere.append(Vector2(0.0, size.y))
	draw_colored_polygon(arriere, couleur.lightened(0.28))
	# Nappe principale
	var points := PackedVector2Array()
	var crete := PackedVector2Array()
	for x in range(0, int(size.x) + 1, PAS):
		var p := Vector2(x, _surface(x))
		points.append(p)
		crete.append(p)
	points.append(Vector2(size.x, size.y))
	points.append(Vector2(0.0, size.y))
	draw_colored_polygon(points, couleur)
	# Liseré d'écume sur la crête
	draw_polyline(crete, Color(1, 1, 1, 0.55), 2.5, true)
	# Bulles : elles montent du fond, vacillent, rétrécissent et s'effacent en arrivant à la surface
	var hauteur := maxf(size.y - SURFACE_Y - 4.0, 8.0)
	for b in _bubbles:
		var p := fposmod(b.w + _temps * b.z / hauteur, 1.0)
		var y := lerpf(size.y - b.y, SURFACE_Y + 2.0, p)
		var x := b.x + sin(_temps * 1.3 + b.w * TAU) * 5.0
		var r := b.y * (1.0 - 0.45 * p * p)
		var alpha := 1.0 - pow(p, 5.0)
		var c := Color(FOAM.r, FOAM.g, FOAM.b, FOAM.a * alpha)
		draw_circle(Vector2(x, y), r, c)
		# Petit reflet
		draw_circle(Vector2(x - r * 0.3, y - r * 0.3), r * 0.28, Color(1, 1, 1, alpha))
