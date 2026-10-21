extends CanvasLayer
## Tutoriel de la première partie : un pop-up de 3 slides (déplacement, pièges et matériaux, tortues et rampes).
## Il se construit entièrement dans ce script. Le signal `termine` part quand le joueur clique sur « J'ai compris ».

signal termine

const FONT := preload("res://fonts/COOPBL.TTF")
const CREME := Color(0.984, 0.941, 0.839, 1)
const BRUN := Color(0.29, 0.165, 0.078, 1)
const JAUNE := Color(0.99, 0.76, 0.12, 1)

## Chaque slide : un titre et des lignes [image, texte]. L'image peut être vide.
const SLIDES := [
	{
		"titre": "Faire voler le savon",
		"lignes": [
			["res://artwork/sprites/caisse_savon.svg", "MAINTIENS Espace, Entrée, ↑, W ou le clic gauche : tes ailes battent et te font monter."],
			["", "Relâche : tu retombes. Dose tes battements d'ailes pour passer entre les obstacles."],
			["", "Tes ailes s'épuisent avec le temps : surveille la barre d'énergie en haut à gauche."],
		],
	},
	{
		"titre": "Pièges et matériaux",
		"lignes": [
			["res://artwork/sprites/obstacle_torchon.svg", "ÉVITE les pièges (torchons, fleurs de douche, attrape-mouches...). Selon ta caisse, tu en encaisses plus ou moins : sans vie restante, c'est la chute."],
			["res://artwork/sprites/materiau_bois.svg", "RAMASSE les matériaux entourés d'un halo jaune : ils servent à fabriquer de meilleures caisses à l'atelier."],
		],
	},
	{
		"titre": "Tortues et rampes",
		"lignes": [
			["res://artwork/sprites/tortue_1.svg", "Une tortue t'attend dans l'eau tous les 500 m : elle mesure ta distance. Atteindre celle qui porte un savon le débloque : Alep (500 m), Tripoli (1500 m), Castille (2500 m) !"],
			["", "Les RAMPES (les étagères) te font glisser et RECHARGENT tes ailes : pose-toi sur leur dessus."],
		],
	},
]

var _index := 0
var _titre: Label
var _contenu: VBoxContainer
var _precedent: Button
var _suivant: Button
var _pastilles: Label


func _ready() -> void:
	layer = 50
	var voile := ColorRect.new()
	voile.color = Color(0.0, 0.0, 0.0, 0.55)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)

	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", _style(CREME, 8))
	panneau.custom_minimum_size = Vector2(860, 0)
	panneau.set_anchors_preset(Control.PRESET_CENTER)
	panneau.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panneau.grow_vertical = Control.GROW_DIRECTION_BOTH
	voile.add_child(panneau)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	panneau.add_child(colonne)

	_titre = _label("", 44)
	_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonne.add_child(_titre)

	_contenu = VBoxContainer.new()
	_contenu.custom_minimum_size = Vector2(0, 300)
	_contenu.add_theme_constant_override("separation", 22)
	colonne.add_child(_contenu)

	_pastilles = _label("", 30)
	_pastilles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	colonne.add_child(_pastilles)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 16)
	colonne.add_child(boutons)
	_precedent = _bouton("Précédent", CREME)
	_precedent.pressed.connect(func(): _aller(_index - 1))
	boutons.add_child(_precedent)
	_suivant = _bouton("Suivant", JAUNE)
	_suivant.pressed.connect(_on_suivant)
	boutons.add_child(_suivant)
	_aller(0)


func _aller(index: int) -> void:
	_index = clampi(index, 0, SLIDES.size() - 1)
	var slide: Dictionary = SLIDES[_index]
	_titre.text = slide["titre"]
	for enfant in _contenu.get_children():
		_contenu.remove_child(enfant)
		enfant.queue_free()
	for ligne in slide["lignes"]:
		_contenu.add_child(_ligne(ligne[0], ligne[1]))
	_suivant.text = "J'ai compris !" if _index == SLIDES.size() - 1 else "Suivant"
	_precedent.visible = _index > 0
	var pastilles: Array[String] = []
	for i in SLIDES.size():
		pastilles.append("●" if i == _index else "○")
	_pastilles.text = " ".join(pastilles)


func _on_suivant() -> void:
	if _index == SLIDES.size() - 1:
		termine.emit()
		queue_free()
	else:
		_aller(_index + 1)


func _ligne(image: String, texte: String) -> Control:
	var rangee := HBoxContainer.new()
	rangee.add_theme_constant_override("separation", 20)
	var vignette := TextureRect.new()
	vignette.custom_minimum_size = Vector2(110, 90)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if image != "":
		vignette.texture = load(image)
	rangee.add_child(vignette)
	var label := _label(texte, 26)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rangee.add_child(label)
	return rangee


func _label(texte: String, taille: int) -> Label:
	var label := Label.new()
	label.text = texte
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", taille)
	label.add_theme_color_override("font_color", BRUN)
	return label


func _bouton(texte: String, fond: Color) -> Button:
	var bouton := Button.new()
	bouton.text = texte
	bouton.focus_mode = Control.FOCUS_NONE # Espace n'active pas le bouton : il sert au jet
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.custom_minimum_size = Vector2(0, 56)
	bouton.add_theme_font_override("font", FONT)
	bouton.add_theme_font_size_override("font_size", 26)
	for couleur in ["font_color", "font_hover_color", "font_pressed_color"]:
		bouton.add_theme_color_override(couleur, BRUN)
	for etat in ["normal", "hover", "pressed"]:
		bouton.add_theme_stylebox_override(etat, _style(fond, 4))
	return bouton


func _style(fond: Color, bordure: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = BRUN
	style.set_border_width_all(bordure)
	style.border_width_bottom = bordure + 3
	style.set_corner_radius_all(24)
	style.content_margin_left = 32.0
	style.content_margin_right = 32.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	return style
