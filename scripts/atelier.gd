extends Control
## ÉCRAN 1 : l'atelier (maquette : sac à matériaux, caisses, établi). On débloque de nouvelles caisses
## à savon avec les matériaux récoltés en vol, on choisit celle qu'on équipe, puis on lance le savon.
## Les caisses sont listées depuis data/tuning.tres (`crates`) : pour en ajouter une, crée un CrateData
## dans data/crates/ et ajoute-le à `crates` dans data/tuning.tres. Rien d'autre à faire ici.
## Les pièges ne font pas partie de cet écran pour l'instant (onglet affiché, sans contenu).

## Caisse pas encore récupérée : silhouette quasi noire (on ne voit plus le dessin)
const GRISE := Color(0.06, 0.06, 0.06, 1)
const GRIS_BOUTON := Color(0.42, 0.4, 0.38, 1)
const YELLOW_BTN := Color(0.99, 0.76, 0.12, 1)
const GREEN_BTN := Color(0.55, 0.75, 0.25, 1)
const FONT := preload("res://fonts/COOPBL.TTF")
const VERT := Color(0.71, 0.85, 0.42, 1)
const CADENAS := preload("res://scripts/cadenas.gd")
const GRISE_TEXTE := Color(0.82, 0.79, 0.75, 1)
const SHAPE_ICON := preload("res://scripts/shape_icon.gd")
const PREVIEW_BASE := Vector2(100, 90)
const PERSONNAGE := preload("res://scripts/personnage.gd")
const EQUIPES := "res://scenes/equipes.tscn"
const CREAM := Color(0.984, 0.941, 0.839, 1)
const BROWN := Color(0.29, 0.165, 0.078, 1)
const YELLOW := Color(0.99, 0.76, 0.12, 1)
const GREEN := Color(0.42, 0.54, 0.18, 1)
const RED := Color(0.8, 0.36, 0.14, 1)
const OK := Color(0.42, 0.54, 0.18, 1)
const MISSING := Color(0.75, 0.2, 0.12, 1)

@onready var mat_grid: HBoxContainer = %MatGrid
@onready var crate_list: VBoxContainer = %CrateList
@onready var preview = %Preview
@onready var name_label: Label = %NameLabel
@onready var bar_solidite: ProgressBar = %BarSolidite
@onready var bar_glisse: ProgressBar = %BarGlisse
@onready var bar_vol: ProgressBar = %BarVol
@onready var bar_autonomie: ProgressBar = %BarAutonomie
@onready var cost_grid: GridContainer = %CostGrid
@onready var fabriquer_button: Button = %FabriquerButton
@onready var cadenas: Control = %Cadenas
@onready var launch_button: Button = %LaunchButton

var _selected := ""


func _ready() -> void:
	Musique.jouer()
	_selected = GameState.equipped
	# Le savon de l'aperçu porte les couleurs et le visage de l'équipe choisie
	PERSONNAGE.appliquer_choisi(preview)
	fabriquer_button.pressed.connect(_on_fabriquer)
	launch_button.pressed.connect(_on_launch)
	launch_button.grab_focus()
	_habiller_boutons()
	preview.get_parent().resized.connect(_place_preview)
	_refresh()


func _refresh() -> void:
	var tuning: Tuning = GameState.tuning
	_refresh_materials(tuning)
	_refresh_crates(tuning)
	_refresh_detail(tuning)


func _refresh_materials(tuning: Tuning) -> void:
	_clear(mat_grid)
	for i in tuning.materials.size():
		var m: MaterialData = tuning.materials[i]
		mat_grid.add_child(_material_tile(i, m, GameState.stock(m.id)))


func _refresh_crates(tuning: Tuning) -> void:
	_clear(crate_list)
	for c in tuning.crates:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 50)
		# Contenu de la carte : nom et description à gauche, compteur en pastille à droite
		var content := HBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 18
		content.offset_right = -18
		content.offset_top = 6
		content.offset_bottom = -8
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(texts)
		var construite := GameState.is_unlocked(c.id)
		var nom_label := _card_label(c.nom, 18, FONT, BROWN if construite else GRISE_TEXTE)
		texts.add_child(nom_label)
		# Cadenas à droite : seulement tant que la caisse n'est pas fabriquée (aucun cadenas sur une caisse fabriquée)
		if not construite:
			var cadenas_carte = CADENAS.new()
			cadenas_carte.open = false
			cadenas_carte.custom_minimum_size = Vector2(34, 40)
			cadenas_carte.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cadenas_carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(cadenas_carte)
		var fond := YELLOW if (c.id == _selected and construite) else (GRIS_BOUTON if not construite else CREAM)
		var style := _card_style(fond, 30, 2)
		style.border_width_bottom = 3
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("focus", style)
		button.pressed.connect(_select.bind(c.id))
		crate_list.add_child(button)


func _refresh_detail(tuning: Tuning) -> void:
	var c := tuning.crate(_selected)
	preview.set_crate_texture(c.texture)
	# Caisse non construite : savon avec ses ailes grisé ; cadenas fermé. Construite : couleurs normales, cadenas ouvert
	var construite := GameState.is_unlocked(c.id)
	preview.modulate = Color.WHITE if construite else GRISE
	cadenas.visible = not construite # pas de cadenas sur une caisse fabriquée
	cadenas.queue_redraw()
	# Bouton : jaune pour équiper, vert quand les matériaux sont réunis (prêt à fabriquer), gris sinon
	var fond_bouton := YELLOW_BTN if construite else (GREEN_BTN if GameState.can_unlock(c.id) else GRIS_BOUTON)
	var style := _card_style(fond_bouton, 30, 3)
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		fabriquer_button.add_theme_stylebox_override(etat, style)
	_place_preview()
	name_label.text = c.nom
	# Barres : élan (vitesse), autonomie (énergie des ailes), maniabilité. Plus c'est plein, plus le jeu est facile.
	bar_solidite.value = 100.0 * c.poids / 4.0
	bar_glisse.value = 100.0 * c.solidite / 5.0 # vies : 0 = mort subite
	bar_autonomie.value = 100.0 * (1 + c.autonomie) / 6.0
	bar_vol.value = 100.0 * (1 + c.maniabilite) / 6.0
	# Toujours 6 emplacements (nom + quantité), les vides restent blancs pour garder la hauteur
	_clear(cost_grid)
	var mats := c.cost.keys()
	for i in 6:
		if i < mats.size():
			var mat: String = mats[i]
			var needed := int(c.cost[mat])
			var have := GameState.stock(mat)
			var nom := _card_label(tuning.material(mat).nom, 22, FONT, BROWN)
			nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cost_grid.add_child(nom)
			var amount := _card_label("%d / %d" % [have, needed], 22, FONT, OK if have >= needed else MISSING)
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cost_grid.add_child(amount)
		else:
			cost_grid.add_child(_card_label(" ", 22, FONT, BROWN))
			cost_grid.add_child(_card_label(" ", 22, FONT, BROWN))
	if GameState.is_unlocked(c.id):
		var equipped := GameState.equipped == c.id
		fabriquer_button.text = "Équipée" if equipped else "Équiper  ▸"
		fabriquer_button.disabled = equipped
	else:
		# Règles : caisses dans l'ordre, une seule fabrication par vol (le texte du bouton explique ce qui manque)
		var raison := GameState.raison_blocage(c.id)
		fabriquer_button.text = raison if raison != "" else "Fabriquer  ▸"
		fabriquer_button.disabled = not GameState.can_unlock(c.id)


func _place_preview() -> void:
	# Savon à la même échelle pour toutes les caisses, centré dans la zone d'aperçu (même calcul que l'écran des équipes)
	var box := preview.get_parent() as Control
	var k := minf(minf(box.size.x / PREVIEW_BASE.x, box.size.y / PREVIEW_BASE.y), 3.2)
	preview.scale = Vector2(k, k)
	preview.position = (box.size / 2.0).floor()


func _select(id: String) -> void:
	_selected = id
	_refresh()


func _on_fabriquer() -> void:
	if GameState.is_unlocked(_selected):
		GameState.equip(_selected)
	else:
		GameState.unlock(_selected)
	_refresh()


func _on_savon_pressed() -> void:
	get_tree().change_scene_to_file(EQUIPES)


func _on_launch() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _material_tile(index: int, materiau: MaterialData, count: int) -> PanelContainer:
	var tile := PanelContainer.new()
	# Tuiles étalées sur toute la largeur de la card, plus grandes et plus marquées
	tile.custom_minimum_size = Vector2(90, 100)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", _card_style(CREAM, 18, 5))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	if materiau.icone:
		# Dessin du matériau
		var image := TextureRect.new()
		image.texture = materiau.icone
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(0, 46)
		image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(image)
	else:
		# Pas encore de dessin : forme géométrique provisoire
		var icon = SHAPE_ICON.new()
		icon.shape = index
		icon.custom_minimum_size = Vector2(36, 36)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
	var name_text := Label.new()
	name_text.text = materiau.nom
	name_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_text.add_theme_color_override("font_color", BROWN)
	name_text.add_theme_font_override("font", FONT)
	name_text.add_theme_font_size_override("font_size", 16)
	var count_text := Label.new()
	count_text.text = "x%d" % count
	count_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_text.add_theme_color_override("font_color", RED)
	count_text.add_theme_font_override("font", FONT)
	count_text.add_theme_font_size_override("font_size", 26)
	box.add_child(name_text)
	box.add_child(count_text)
	tile.add_child(box)
	return tile


func _card_label(text: String, size: int, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	if font:
		label.add_theme_font_override("font", font)
	return label


func _bouton_rejouer(bg: Color, survol: bool) -> StyleBoxFlat:
	## Même style que le bouton « Rejouer » de l'écran des scores : brun au repos, vert au survol (bordure brune).
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	if survol:
		style.border_color = BROWN
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 8
	style.corner_radius_top_left = 40
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_right = 40
	style.corner_radius_bottom_left = 40
	return style


func _card_style(bg: Color, radius := 30, border := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_color = BROWN
	style.border_width_left = border
	style.border_width_top = border
	style.border_width_right = border
	style.border_width_bottom = border + 4
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _habiller_boutons() -> void:
	# Lancer le savon : même bouton que « Valider mon savon » (écran des équipes) — brun, texte blanc, vert au survol
	var marron := StyleBoxFlat.new()
	marron.bg_color = BROWN
	marron.border_color = Color(0.2, 0.11, 0.05, 1)
	marron.content_margin_left = 22.0
	marron.content_margin_right = 22.0
	marron.content_margin_top = 10.0
	marron.content_margin_bottom = 10.0
	marron.border_width_left = 6
	marron.border_width_top = 6
	marron.border_width_right = 6
	marron.border_width_bottom = 10
	marron.set_corner_radius_all(40)
	for etat in ["normal", "hover", "pressed", "focus"]:
		launch_button.add_theme_stylebox_override(etat, marron)
	launch_button.add_theme_color_override("font_color", Color.WHITE)
	launch_button.add_theme_color_override("font_focus_color", Color.WHITE)
	launch_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	launch_button.add_theme_color_override("font_hover_color", Color(0.42, 0.54, 0.18, 1))
	launch_button.add_theme_font_size_override("font_size", 26)
	launch_button.custom_minimum_size = Vector2(0, 56)
	# Équipes : au survol, fond crème et texte orange
	var savon_button: Button = get_node("Margin/Main/Haut/Boutons/BoutonsBox/SavonButton")
	for etat in ["hover", "pressed", "focus"]:
		savon_button.add_theme_stylebox_override(etat, _card_style(CREAM, 40, 6))
	call_deferred("_animer_lancer")


func _animer_lancer() -> void:
	launch_button.pivot_offset = launch_button.size / 2.0
	var pulsation := create_tween().set_loops()
	pulsation.tween_property(launch_button, "scale", Vector2(1.05, 1.05), 0.7).set_trans(Tween.TRANS_SINE)
	pulsation.tween_property(launch_button, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
