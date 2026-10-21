extends Control
## Écran des parties : trois emplacements. « Nouvelle partie » vide un emplacement et passe par les équipes ;
## « Continuer » reprend une partie existante et ouvre l'atelier.

const EQUIPES := "res://scenes/equipes.tscn"
const ATELIER := "res://scenes/atelier.tscn"
const FONT := preload("res://fonts/COOPBL.TTF")
const BRUN := Color(0.29, 0.165, 0.078, 1)
const CREME := Color(0.984, 0.941, 0.839, 1)
const JAUNE := Color(0.99, 0.76, 0.12, 1)

@onready var cartes: HBoxContainer = %Cartes

var _a_supprimer := -1  # emplacement en attente de confirmation de suppression
var _dialogue: ConfirmationDialog


func _ready() -> void:
	Musique.jouer()
	_dialogue = ConfirmationDialog.new()
	_dialogue.title = "Supprimer la partie"
	_dialogue.dialog_text = "Supprimer cette partie ? Cette action est définitive."
	_dialogue.ok_button_text = "Supprimer"
	_dialogue.get_cancel_button().text = "Annuler"
	_dialogue.confirmed.connect(_on_supprimer_confirme)
	_habiller_dialogue()
	add_child(_dialogue)
	_afficher_cartes()


func _habiller_dialogue() -> void:
	## Fenêtre de confirmation dans la DA : crème, bordure brune, police du jeu.
	_dialogue.min_size = Vector2i(560, 0)
	_dialogue.add_theme_stylebox_override("panel", _style(CREME, 24, 6, 10))
	_dialogue.add_theme_stylebox_override("embedded_border", _style(CREME, 24, 6, 10))
	_dialogue.add_theme_stylebox_override("embedded_unfocused_border", _style(CREME, 24, 6, 10))
	_dialogue.add_theme_font_override("title_font", FONT)
	_dialogue.add_theme_font_size_override("title_font_size", 30)
	_dialogue.add_theme_color_override("title_color", BRUN)
	var texte := _dialogue.get_label()
	texte.add_theme_font_override("font", FONT)
	texte.add_theme_font_size_override("font_size", 24)
	texte.add_theme_color_override("font_color", BRUN)
	_habiller_bouton(_dialogue.get_ok_button(), JAUNE)
	_habiller_bouton(_dialogue.get_cancel_button(), CREME)


func _habiller_bouton(bouton: Button, fond: Color) -> void:
	bouton.custom_minimum_size = Vector2(190, 56)
	bouton.add_theme_font_override("font", FONT)
	bouton.add_theme_font_size_override("font_size", 24)
	bouton.add_theme_color_override("font_color", BRUN)
	bouton.add_theme_color_override("font_hover_color", BRUN)
	for etat in ["normal", "hover", "pressed", "focus"]:
		bouton.add_theme_stylebox_override(etat, _style(fond, 30, 6, 10))


func _afficher_cartes() -> void:
	for ancienne in cartes.get_children():
		cartes.remove_child(ancienne)
		ancienne.queue_free()
	for i in GameState.NB_SLOTS:
		# « Continuer » ne montre que les parties commencées
		if GameState.mode != "nouvelle" and not GameState.has_slot(i):
			continue
		cartes.add_child(_carte(i))


func _carte(numero: int) -> Control:
	var carte := PanelContainer.new()
	carte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carte.add_theme_stylebox_override("panel", _style(CREME, 24, 6, 10))
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 16)
	carte.add_child(contenu)
	var entete := HBoxContainer.new()
	contenu.add_child(entete)
	var titre := Label.new()
	titre.text = "Partie %d" % (numero + 1)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titre.add_theme_font_override("font", FONT)
	titre.add_theme_font_size_override("font_size", 34)
	titre.add_theme_color_override("font_color", BRUN)
	entete.add_child(titre)
	var existe := GameState.has_slot(numero)
	if existe:
		var poubelle := Button.new()
		poubelle.text = "🗑"
		poubelle.tooltip_text = "Supprimer cette partie"
		poubelle.flat = true
		poubelle.add_theme_font_size_override("font_size", 30)
		poubelle.add_theme_color_override("font_color", BRUN)
		poubelle.pressed.connect(_on_poubelle.bind(numero))
		entete.add_child(poubelle)
	var resume := Label.new()
	resume.text = GameState.resume(numero)
	resume.autowrap_mode = TextServer.AUTOWRAP_WORD
	resume.add_theme_font_size_override("font_size", 20)
	resume.add_theme_color_override("font_color", BRUN)
	var bouton := Button.new()
	bouton.custom_minimum_size = Vector2(0, 60)
	bouton.add_theme_font_override("font", FONT)
	bouton.add_theme_font_size_override("font_size", 26)
	bouton.add_theme_color_override("font_color", BRUN)
	bouton.add_theme_stylebox_override("normal", _style(JAUNE, 30, 6, 10))
	bouton.add_theme_stylebox_override("hover", _style(CREME, 30, 6, 10))
	bouton.add_theme_stylebox_override("pressed", _style(JAUNE, 30, 6, 10))
	bouton.add_theme_stylebox_override("focus", _style(JAUNE, 30, 6, 10))
	bouton.add_theme_stylebox_override("disabled", _style(Color(0.72, 0.72, 0.72, 1), 30, 6, 10))
	if GameState.mode == "nouvelle":
		bouton.text = "Nouvelle partie" if not existe else "Remplacer"
		bouton.pressed.connect(_on_nouvelle.bind(numero))
	else:
		bouton.text = "Continuer"
		bouton.pressed.connect(_on_continuer.bind(numero))
	contenu.add_child(bouton)
	contenu.add_child(resume)
	return carte


func _style(couleur: Color, rayon: int, bord: int, bas: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = couleur
	style.border_color = BRUN
	style.border_width_left = bord
	style.border_width_top = bord
	style.border_width_right = bord
	style.border_width_bottom = bas
	style.corner_radius_top_left = rayon
	style.corner_radius_top_right = rayon
	style.corner_radius_bottom_right = rayon
	style.corner_radius_bottom_left = rayon
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


func _on_nouvelle(numero: int) -> void:
	GameState.nouvelle_partie(numero)
	get_tree().change_scene_to_file(EQUIPES)


func _on_continuer(numero: int) -> void:
	if GameState.charger_partie(numero):
		get_tree().change_scene_to_file(ATELIER)


func _on_poubelle(numero: int) -> void:
	_a_supprimer = numero
	_dialogue.popup_centered()


func _on_supprimer_confirme() -> void:
	GameState.supprimer_partie(_a_supprimer)
	_a_supprimer = -1
	_afficher_cartes()
