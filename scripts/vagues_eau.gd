@tool
extends Control
## Vagues animées en haut de l'eau (le bas de la piste) : trois crêtes d'écume qui défilent
## à des vitesses et des sens différents, sur une nappe plus claire.


const WATER_LIGHT := Color(0.36, 0.72, 0.72, 0.6)
const FOAM := Color(1, 1, 1, 1)
const PAS := 12.0 # distance entre deux points d'une crête (px)
const PROFONDEUR := 14.0 # épaisseur de la nappe claire sous la première crête (px)
const COUCHES := [
	# y de base, amplitude, longueur d'onde (px), vitesse (px/s), épaisseur du trait, opacité
	{"y": 10.0, "amp": 5.0, "onde": 220.0, "vitesse": 40.0, "trait": 3.0, "alpha": 0.8},
	{"y": 26.0, "amp": 7.0, "onde": 300.0, "vitesse": -28.0, "trait": 2.5, "alpha": 0.55},
	{"y": 44.0, "amp": 4.0, "onde": 160.0, "vitesse": 56.0, "trait": 2.0, "alpha": 0.4},
]

var _temps := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(not Engine.is_editor_hint())


func _process(delta: float) -> void:
	_temps += delta
	queue_redraw()


func _draw() -> void:
	# Nappe claire sous la première crête
	var haut := _courbe(COUCHES[0])
	var nappe := haut.duplicate()
	for i in range(haut.size() - 1, -1, -1):
		nappe.append(haut[i] + Vector2(0, PROFONDEUR))
	draw_colored_polygon(nappe, WATER_LIGHT)
	# Crêtes d'écume
	for couche in COUCHES:
		var couleur := Color(FOAM.r, FOAM.g, FOAM.b, couche["alpha"])
		draw_polyline(_courbe(couche), couleur, couche["trait"], true)


func _courbe(couche: Dictionary) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var k: float = TAU / float(couche["onde"])
	var decalage: float = _temps * float(couche["vitesse"])
	var y_base: float = couche["y"]
	var amp: float = couche["amp"]
	for x in range(0, int(size.x) + int(PAS), int(PAS)):
		var y: float = y_base + sin((x + decalage) * k) * amp
		pts.append(Vector2(x, y))
	return pts
