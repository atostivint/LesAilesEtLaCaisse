extends Control
## Écran des équipes : on choisit son camp, puis la couleur du savon.
## Le choix est enregistré (GameState) et appliqué partout : menu, jeu, scores.
## « Valider mon savon » lance une courte animation puis revient à l'atelier.

const ATELIER := "res://scenes/atelier.tscn"
const CRATE := preload("res://artwork/sprites/caisse_savon.svg")
const PERSONNAGE := preload("res://scripts/personnage.gd")
const CADENAS := preload("res://scripts/cadenas.gd")
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
## « seuil » : distance de record (en mètres) à atteindre pour débloquer l'équipe. 0 = dès le début.
const EQUIPES := [
	{"nom": "Marseille", "phrase": "« Le savon du vieux porc »", "visage": 1, "seuil": 0},
	{"nom": "Alep", "phrase": "« Le savon syrieusement sale »", "visage": 0, "seuil": 500},
	{"nom": "Tripoli", "phrase": "« Le savon tris pourri »", "visage": 2, "seuil": 1500},
	{"nom": "Castille", "phrase": "« Le savon de la Castagne »", "visage": 3, "seuil": 2500},
]
const JAUNE := Color(0.99, 0.76, 0.12, 1)
const CREME := Color(0.984, 0.941, 0.839, 1)
const BRUN := Color(0.29, 0.165, 0.078, 1)
const GRIS := Color(0.78, 0.76, 0.73, 1)
const BRUN_GRISE := Color(0.55, 0.5, 0.46, 1)

var _equipe := 0
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
	if GameState.equipe >= 0 and not _verrouillee(GameState.equipe):
		_equipe = GameState.equipe
		_couleur = GameState.couleur
	for i in EQUIPES.size():
		var bouton: Button = grille.get_child(i)
		bouton.pressed.connect(_on_equipe.bind(i))
		bouton.custom_minimum_size = Vector2(350, 72)
		if _verrouillee(i):
			# Ligne vide réservée : l'objectif est affiché en valeur par-dessus
			bouton.text += "\n "
			bouton.custom_minimum_size.y = 100.0
			_ajouter_objectif(bouton, EQUIPES[i]["seuil"])
			_ajouter_cadenas(bouton)
	for i in COULEURS.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.pressed.connect(_on_couleur.bind(i))
		swatches.add_child(b)
	valider.pressed.connect(_on_valider)
	# Nom du savon : police du jeu en plus gras et plus grande, pour bien la lire
	var gras := FontVariation.new()
	gras.base_font = nom_label.get_theme_font("font")
	gras.variation_embolden = 0.9
	nom_label.add_theme_font_override("font", gras)
	nom_label.add_theme_font_size_override("font_size", 44)
	nom_label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.04, 1))
	nom_label.add_theme_color_override("font_outline_color", CREME)
	nom_label.add_theme_constant_override("outline_size", 4)
	savon.set_crate_texture(CRATE)
	zone.resized.connect(_place_savon)
	_place_savon()
	_on_equipe(_equipe)
	_on_couleur(_couleur)


func _place_savon() -> void:
	# Le savon s'adapte à la zone d'aperçu (plafonné à 3,2 : au-delà il déborde de la carte)
	var k := minf(minf(zone.size.x / 100.0, zone.size.y / 90.0), 3.2)
	savon.scale = Vector2(k, k)
	savon.position = (zone.size / 2.0).floor()


func _verrouillee(index: int) -> bool:
	## Vrai tant que le record n'a pas atteint le seuil de l'équipe.
	var seuil_m: int = EQUIPES[index]["seuil"]
	# Le record est en unités internes : on le convertit en centimètres d'affichage, puis en mètres
	return GameState.tuning.metres(GameState.best) < seuil_m


func _ajouter_objectif(bouton: Button, seuil_m: int) -> void:
	## Message « Atteins X m » bien visible (rouge, plus gros, contour crème) en bas du bouton verrouillé.
	var objectif := Label.new()
	objectif.text = "Atteins %d m !" % seuil_m
	objectif.add_theme_font_override("font", bouton.get_theme_font("font"))
	objectif.add_theme_font_size_override("font_size", 26)
	objectif.add_theme_color_override("font_color", Color(0.78, 0.18, 0.08, 1))
	objectif.add_theme_color_override("font_outline_color", CREME)
	objectif.add_theme_constant_override("outline_size", 6)
	objectif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objectif.anchor_left = 0.0
	objectif.anchor_right = 1.0
	objectif.anchor_top = 1.0
	objectif.anchor_bottom = 1.0
	objectif.offset_left = 8.0
	objectif.offset_right = -48.0
	objectif.offset_top = -38.0
	objectif.offset_bottom = -8.0
	objectif.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bouton.add_child(objectif)


func _ajouter_cadenas(bouton: Button) -> void:
	var cadenas: Control = CADENAS.new()
	cadenas.anchor_left = 1.0
	cadenas.anchor_right = 1.0
	cadenas.anchor_top = 0.5
	cadenas.anchor_bottom = 0.5
	cadenas.offset_left = -40.0
	cadenas.offset_right = -14.0
	cadenas.offset_top = -14.0
	cadenas.offset_bottom = 14.0
	cadenas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bouton.add_child(cadenas)


func _on_equipe(index: int) -> void:
	if _valide or _verrouillee(index):
		return
	_equipe = index
	var equipe: Dictionary = EQUIPES[index]
	nom_label.text = equipe["nom"]
	phrase_label.text = equipe["phrase"]
	_animer_texte()
	PERSONNAGE.appliquer(savon, equipe["visage"], COULEURS[_couleur])
	for i in grille.get_child_count():
		var bouton: Button = grille.get_child(i)
		var bloquee := _verrouillee(i)
		var fond := GRIS if bloquee else (JAUNE if i == index else CREME)
		_colorer(bouton, fond, i == index)
		bouton.add_theme_color_override("font_color", BRUN_GRISE if bloquee else BRUN)


func _animer_texte() -> void:
	## Quand on change de savon : le nom grandit avec un petit rebond, la phrase apparaît en fondu.
	nom_label.pivot_offset = nom_label.size * 0.5
	nom_label.scale = Vector2.ONE * 0.7
	phrase_label.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(nom_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(phrase_label, "modulate:a", 1.0, 0.5)


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
