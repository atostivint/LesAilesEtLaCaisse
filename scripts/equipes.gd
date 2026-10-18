extends Control
## Écran des équipes : on choisit son camp, puis la couleur du savon.
## Le choix est enregistré (GameState) et appliqué partout : menu, jeu, scores.
## « Valider mon savon » lance une courte animation puis revient à l'atelier.

const ATELIER := "res://scenes/atelier.tscn"
const CRATE := preload("res://artwork/sprites/caisse_savon.svg")
const PERSONNAGE := preload("res://scripts/personnage.gd")
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
## « visage » : index d'yeux et de bouche (voir personnage.gd).
const EQUIPES := [
	{"nom": "Alep", "phrase": "« Le savon syrieusement sale »", "visage": 0},
	{"nom": "Marseille", "phrase": "« Le savon du vieux porc »", "visage": 1},
	{"nom": "Tripoli", "phrase": "« Le savon tris pourri »", "visage": 2},
	{"nom": "Castille", "phrase": "« Le savon de la Castagne »", "visage": 3},
]
const JAUNE := Color(0.99, 0.76, 0.12, 1)
const CREME := Color(0.984, 0.941, 0.839, 1)
const BRUN := Color(0.29, 0.165, 0.078, 1)

var _equipe := 1
var _couleur := 0
var _valide := false

@onready var grille: GridContainer = %Equipes
@onready var swatches: HBoxContainer = %Swatches
@onready var zone: Control = %Zone
@onready var savon: Soap = %Savon
@onready var nom_label: Label = %Nom
@onready var phrase_label: Label = %Phrase
@onready var valider: Button = $Marge/Main/Valider


func _ready() -> void:
	Musique.jouer()
	if GameState.equipe >= 0:
		_equipe = GameState.equipe
		_couleur = GameState.couleur
	for i in EQUIPES.size():
		var bouton: Button = grille.get_child(i)
		bouton.pressed.connect(_on_equipe.bind(i))
	for i in COULEURS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.pressed.connect(_on_couleur.bind(i))
		swatches.add_child(b)
	valider.pressed.connect(_on_valider)
	savon.set_crate_texture(CRATE)
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
	if _valide:
		return
	_equipe = index
	var equipe: Dictionary = EQUIPES[index]
	nom_label.text = equipe["nom"]
	phrase_label.text = equipe["phrase"]
	PERSONNAGE.appliquer(savon, equipe["visage"], COULEURS[_couleur])
	for i in grille.get_child_count():
		_colorer(grille.get_child(i), CREME if i != index else JAUNE, i == index)


func _on_couleur(index: int) -> void:
	if _valide:
		return
	_couleur = index
	PERSONNAGE.appliquer(savon, EQUIPES[_equipe]["visage"], COULEURS[index])
	for i in swatches.get_child_count():
		_colorer(swatches.get_child(i), COULEURS[i], i == index)


func _on_valider() -> void:
	## Enregistre l'équipe, fait « rebondir » le savon avec un message, puis revient à l'atelier.
	if _valide:
		return
	_valide = true
	valider.disabled = true
	GameState.set_equipe(_equipe, _couleur)
	var message := Label.new()
	message.text = "Savon validé !"
	message.add_theme_color_override("font_color", Color(0.18, 0.4, 0.08, 1))
	message.add_theme_font_size_override("font_size", 40)
	message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	message.offset_top = 16.0
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(message)
	var k: float = savon.scale.x
	var tween := create_tween()
	tween.tween_property(savon, "scale", Vector2(k * 1.2, k * 1.2), 0.2)
	tween.tween_property(savon, "scale", Vector2(k * 0.95, k * 0.95), 0.1)
	tween.tween_property(savon, "scale", Vector2(k, k), 0.1)
	await get_tree().create_timer(0.9).timeout
	get_tree().change_scene_to_file(ATELIER)


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
