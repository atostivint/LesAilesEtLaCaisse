extends Control
## Écran des équipes : on choisit son camp, puis la couleur du savon.
## Le visage du savon change selon l'équipe (kawaii, agressif, endormi, anxieux, blasé, fou).
## Pour l'instant, la sélection est visuelle seulement : rien n'est sauvegardé.

const ATELIER := "res://scenes/atelier.tscn"
const CRATE := preload("res://artwork/sprites/caisse_savon.svg")
const VISAGE := preload("res://scripts/visage_savon.gd")
const COULEURS := [
	Color(0.984, 0.941, 0.839, 1),
	Color(0.9, 0.6, 0.62, 1),
	Color(0.92, 0.75, 0.25, 1),
	Color(0.55, 0.68, 0.3, 1),
	Color(0.62, 0.8, 0.85, 1),
	Color(0.7, 0.6, 0.85, 1),
	Color(0.9, 0.55, 0.25, 1),
	Color(0.24, 0.16, 0.12, 1),
]
## Dans l'ordre des boutons de la grille.
## « visage » : 0 kawaii, 1 agressif, 2 endormi, 3 anxieux, 4 blasé, 5 fou (voir visage_savon.gd).
const EQUIPES := [
	{"nom": "Savon d'Alep", "phrase": "« Le savon syrieusement sale »", "visage": 0},
	{"nom": "Savon de Marseille", "phrase": "« Le savon du vieux porc »", "visage": 1},
	{"nom": "Savon de Tripoli", "phrase": "« Le savon tris pourri »", "visage": 2},
	{"nom": "Savon de Castille", "phrase": "« Le savon de la Castagne »", "visage": 3},
	{"nom": "Savon de Naplouse", "phrase": "« Le savon de la Nap-loose »", "visage": 4},
	{"nom": "Savon noir africain", "phrase": "« Le savon noir de crasse »", "visage": 5},
]
const JAUNE := Color(0.99, 0.76, 0.12, 1)
const CREME := Color(0.984, 0.941, 0.839, 1)
const BRUN := Color(0.29, 0.165, 0.078, 1)

var _equipe := 1
var _couleur := 0
var _visage

@onready var grille: GridContainer = %Equipes
@onready var swatches: HBoxContainer = %Swatches
@onready var zone: Control = %Zone
@onready var savon: Soap = %Savon
@onready var nom_label: Label = %Nom
@onready var phrase_label: Label = %Phrase


func _ready() -> void:
	Musique.jouer()
	for i in EQUIPES.size():
		var bouton: Button = grille.get_child(i)
		bouton.pressed.connect(_on_equipe.bind(i))
	for i in COULEURS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.pressed.connect(_on_couleur.bind(i))
		swatches.add_child(b)
	savon.set_crate_texture(CRATE)
	# Les yeux et la bouche d'origine du savon sont remplacés par le visage dessiné
	savon.mouth_timer.stop()
	for nom in ["YeuxBlancs", "PupilleGauche", "PupilleDroite", "Bouche"]:
		savon.get_node("Visuals/" + nom).visible = false
	_visage = Control.new()
	_visage.set_script(VISAGE)
	_visage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	savon.add_child(_visage)
	zone.resized.connect(_place_savon)
	_place_savon()
	_on_equipe(_equipe)
	_on_couleur(_couleur)


func _place_savon() -> void:
	# Le savon s'adapte à la zone d'aperçu (plafonné à 2,6 : au-delà il déborde de la carte)
	var k := minf(minf(zone.size.x / 110.0, zone.size.y / 100.0), 2.6)
	savon.scale = Vector2(k, k)
	savon.position = (zone.size / 2.0).floor()


func _on_equipe(index: int) -> void:
	_equipe = index
	var equipe: Dictionary = EQUIPES[index]
	nom_label.text = equipe["nom"]
	phrase_label.text = equipe["phrase"]
	_visage.expression = equipe["visage"]
	_visage.queue_redraw()
	for i in grille.get_child_count():
		_colorer(grille.get_child(i), CREME if i != index else JAUNE, i == index)


func _on_couleur(index: int) -> void:
	_couleur = index
	savon.body_color = COULEURS[index]
	for i in swatches.get_child_count():
		_colorer(swatches.get_child(i), COULEURS[i], i == index)


func _colorer(button: Button, bg: Color, selected := false) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = BRUN
	# Marges identiques à gauche et à droite : texte centré
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 8.0
	var epaisseur := 6 if selected else 3
	style.border_width_left = epaisseur
	style.border_width_top = epaisseur
	style.border_width_right = epaisseur
	style.border_width_bottom = epaisseur + 2 if button.get_parent() == grille else epaisseur
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)


func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file(ATELIER)
