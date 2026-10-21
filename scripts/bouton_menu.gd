extends Button
## Bouton « Menu » commun à tous les écrans. Il ouvre un petit menu pause avec toujours les mêmes choix :
## reprendre, revenir au menu principal ou quitter le jeu. Échap l'ouvre et le ferme aussi.
## Le jeu est mis en pause tant que le menu est ouvert (utile pendant un vol).

const MENU := "res://Mathilde/main_menu.tscn"
const FONT := preload("res://fonts/COOPBL.TTF")
const BRUN := Color(0.29, 0.165, 0.078, 1)
const CREME := Color(0.984, 0.941, 0.839, 1)
const JAUNE := Color(0.99, 0.76, 0.12, 1)
const VERT := Color(0.42, 0.54, 0.18, 1)
const ROUGE := Color(0.72, 0.25, 0.12, 1)

var _calque: CanvasLayer


func _ready() -> void:
	# Reste actif quand le jeu est en pause : c'est lui qui rouvre et ferme le menu
	process_mode = Node.PROCESS_MODE_ALWAYS
	pressed.connect(_ouvrir)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_visible_in_tree():
		if _calque != null:
			_fermer()
		else:
			_ouvrir()
		get_viewport().set_input_as_handled()


func _ouvrir() -> void:
	if _calque != null:
		return
	get_tree().paused = true
	_calque = CanvasLayer.new()
	_calque.layer = 100
	_calque.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_calque)
	var voile := ColorRect.new()
	voile.color = Color(0.0, 0.0, 0.0, 0.5)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	_calque.add_child(voile)
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", _style(CREME, 28, 6, 10))
	panneau.set_anchors_preset(Control.PRESET_CENTER)
	panneau.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panneau.grow_vertical = Control.GROW_DIRECTION_BOTH
	_calque.add_child(panneau)
	var colonne := VBoxContainer.new()
	colonne.custom_minimum_size = Vector2(420, 0)
	colonne.add_theme_constant_override("separation", 14)
	panneau.add_child(colonne)
	var titre := Label.new()
	titre.text = "PAUSE"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_override("font", FONT)
	titre.add_theme_font_size_override("font_size", 40)
	titre.add_theme_color_override("font_color", BRUN)
	colonne.add_child(titre)
	colonne.add_child(_bouton("Reprendre", JAUNE, BRUN, _fermer))
	colonne.add_child(_bouton("Menu principal", VERT, Color.WHITE, _vers_menu))
	colonne.add_child(_bouton("Quitter le jeu", ROUGE, Color.WHITE, _quitter))


func _fermer() -> void:
	if _calque != null:
		_calque.queue_free()
		_calque = null
	get_tree().paused = false


func _vers_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


func _quitter() -> void:
	get_tree().quit()


func _bouton(texte: String, fond: Color, couleur_texte: Color, action: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.custom_minimum_size = Vector2(0, 60)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 28)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, couleur_texte)
	b.add_theme_stylebox_override("normal", _style(fond, 30, 5, 9))
	b.add_theme_stylebox_override("hover", _style(fond.lightened(0.15), 30, 5, 9))
	b.add_theme_stylebox_override("pressed", _style(fond, 30, 5, 9))
	b.add_theme_stylebox_override("focus", _style(fond, 30, 5, 9))
	b.pressed.connect(action)
	return b


func _style(couleur: Color, rayon: int, bord: int, bas: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = couleur
	s.border_color = BRUN
	s.border_width_left = bord
	s.border_width_top = bord
	s.border_width_right = bord
	s.border_width_bottom = bas
	s.set_corner_radius_all(rayon)
	s.content_margin_left = 24.0
	s.content_margin_right = 24.0
	s.content_margin_top = 14.0
	s.content_margin_bottom = 14.0
	return s
