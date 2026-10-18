extends Control
## Écran des parties : trois emplacements.
## « Nouvelle partie » affiche les trois emplacements (vide ou à remplacer) et passe par les équipes.
## « Continuer » n'affiche que les parties existantes, avec une poubelle pour les supprimer.

const EQUIPES := "res://scenes/equipes.tscn"
const ATELIER := "res://scenes/atelier.tscn"
const FONT := preload("res://fonts/COOPBL.TTF")
const BRUN := Color(0.29, 0.165, 0.078, 1)
const CREME := Color(0.984, 0.941, 0.839, 1)
const JAUNE := Color(0.99, 0.76, 0.12, 1)

@onready var cartes: HBoxContainer = %Cartes


func _ready() -> void:
	Musique.jouer()
	_afficher()


func _afficher() -> void:
	## Reconstruit les cartes : en « Continuer », seules les parties existantes sont listées.
	for enfant in cartes.get_children():
		cartes.remove_child(enfant)
		enfant.queue_free()
	var a_montrer: Array[int] = []
	for i in GameState.NB_SLOTS:
		if GameState.mode == "nouvelle" or GameState.has_slot(i):
			a_montrer.append(i)
	if a_montrer.is_empty():
		var vide := Label.new()
		vide.text = "Aucune partie sauvegardée"
		vide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vide.add_theme_font_override("font", FONT)
		vide.add_theme_font_size_override("font_size", 32)
		vide.add_theme_color_override("font_color", CREME)
		vide.add_theme_color_override("font_outline_color", BRUN)
		vide.add_theme_constant_override("outline_size", 8)
		cartes.add_child(vide)
		return
	for numero in a_montrer:
		cartes.add_child(_carte(numero))


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
	if GameState.mode != "nouvelle":
		entete.add_child(_bouton_poubelle(numero))
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


func _bouton_poubelle(numero: int) -> Button:
	## Bouton poubelle : supprime la partie de cet emplacement.
	var poubelle := Button.new()
	poubelle.custom_minimum_size = Vector2(56, 48)
	poubelle.tooltip_text = "Supprimer cette partie"
	poubelle.add_theme_stylebox_override("normal", _style(CREME, 16, 4, 6))
	poubelle.add_theme_stylebox_override("hover", _style(JAUNE, 16, 4, 6))
	poubelle.add_theme_stylebox_override("pressed", _style(JAUNE, 16, 4, 6))
	poubelle.add_theme_stylebox_override("focus", _style(CREME, 16, 4, 6))
	var icone := Control.new()
	icone.custom_minimum_size = Vector2(34, 34)
	icone.position = Vector2(11, 7)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icone.draw.connect(_dessiner_poubelle.bind(icone))
	poubelle.add_child(icone)
	poubelle.pressed.connect(_on_supprimer.bind(numero))
	return poubelle


func _dessiner_poubelle(icone: Control) -> void:
	icone.draw_line(Vector2(4, 9), Vector2(30, 9), BRUN, 3.0)
	icone.draw_line(Vector2(12, 5), Vector2(22, 5), BRUN, 3.0)
	icone.draw_rect(Rect2(8, 12, 18, 19), BRUN, false, 3.0)
	icone.draw_line(Vector2(14, 16), Vector2(14, 27), BRUN, 2.0)
	icone.draw_line(Vector2(20, 16), Vector2(20, 27), BRUN, 2.0)


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


func _on_supprimer(numero: int) -> void:
	GameState.supprimer_partie(numero)
	_afficher()
