extends Control
## ÉCRAN 1 : l'atelier (maquette : sac à matériaux, caisses, établi). On débloque de nouvelles caisses
## à savon avec les matériaux récoltés en vol, on choisit celle qu'on équipe, puis on lance le savon.
## Les caisses sont listées depuis data/tuning.tres (`crates`) : pour en ajouter une, crée un CrateData
## dans data/crates/ et ajoute-le à `crates` dans data/tuning.tres. Rien d'autre à faire ici.
## Les pièges ne font pas partie de cet écran pour l'instant (onglet affiché, sans contenu).

const GRISE := Color(0.4, 0.4, 0.4, 1)
const GRIS_BOUTON := Color(0.72, 0.72, 0.72, 1)
const YELLOW_BTN := Color(0.99, 0.76, 0.12, 1)
const FONT := preload("res://fonts/COOPBL.TTF")
const SHAPE_ICON := preload("res://scripts/shape_icon.gd")
const PREVIEW_SCALE := 1.4
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
@onready var preview: TextureRect = %Preview
@onready var name_label: Label = %NameLabel
@onready var bar_solidite: ProgressBar = %BarSolidite
@onready var bar_glisse: ProgressBar = %BarGlisse
@onready var bar_vol: ProgressBar = %BarVol
@onready var cost_grid: GridContainer = %CostGrid
@onready var fabriquer_button: Button = %FabriquerButton
@onready var cadenas: Control = %Cadenas
@onready var launch_button: Button = %LaunchButton

var _selected := ""


func _ready() -> void:
	Musique.jouer()
	_selected = GameState.equipped
	fabriquer_button.pressed.connect(_on_fabriquer)
	launch_button.pressed.connect(_on_launch)
	launch_button.grab_focus()
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
		mat_grid.add_child(_material_tile(i, m.nom, GameState.stock(m.id)))


func _refresh_crates(tuning: Tuning) -> void:
	_clear(crate_list)
	for c in tuning.crates:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 64)
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
		texts.add_child(_card_label(c.nom, 18, FONT, BROWN))
		var style := _card_style(YELLOW if c.id == _selected else CREAM, 30, 2)
		style.border_width_bottom = 3
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("focus", style)
		button.pressed.connect(_select.bind(c.id))
		crate_list.add_child(button)


func _refresh_detail(tuning: Tuning) -> void:
	var c := tuning.crate(_selected)
	preview.texture = c.texture
	# Caisse non construite : illustration grisée ; cadenas fermé. Construite : couleurs normales, cadenas ouvert
	var construite := GameState.is_unlocked(c.id)
	preview.modulate = Color.WHITE if construite else GRISE
	cadenas.open = construite
	cadenas.queue_redraw()
	var style := _card_style(YELLOW_BTN if construite else GRIS_BOUTON, 30, 3)
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		fabriquer_button.add_theme_stylebox_override(etat, style)
	_place_preview()
	name_label.text = c.nom
	# Barres : poids (lourd = plus rapide), vies (ailes = coups encaissables), temps de vol (léger = vole plus longtemps)
	bar_solidite.value = 100.0 * c.poids / 4.0
	bar_glisse.value = 100.0 * (tuning.wings_base + tuning.wings_per_solidity * c.solidite) / 6.0
	bar_vol.value = 100.0 * (5 - c.poids) / 4.0
	# Toujours 6 emplacements (nom + quantité), les vides restent blancs pour garder la hauteur
	_clear(cost_grid)
	var mats := c.cost.keys()
	for i in 6:
		if i < mats.size():
			var mat: String = mats[i]
			var needed := int(c.cost[mat])
			var have := GameState.stock(mat)
			cost_grid.add_child(_card_label(tuning.material(mat).nom, 16, null, BROWN))
			var amount := _card_label("%d / %d" % [have, needed], 16, null, OK if have >= needed else MISSING)
			amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cost_grid.add_child(amount)
		else:
			cost_grid.add_child(_card_label(" ", 16, null, BROWN))
			cost_grid.add_child(_card_label(" ", 16, null, BROWN))
	if GameState.is_unlocked(c.id):
		var equipped := GameState.equipped == c.id
		fabriquer_button.text = "Équipée" if equipped else "Équiper  ▸"
		fabriquer_button.disabled = equipped
	else:
		fabriquer_button.text = "Fabriquer  ▸"
		fabriquer_button.disabled = not GameState.can_unlock(c.id)


func _place_preview() -> void:
	# Image à la même échelle pour toutes les caisses, centrée dans la zone d'aperçu
	if preview.texture == null:
		return
	var sz := preview.texture.get_size() * PREVIEW_SCALE
	var box := preview.get_parent() as Control
	preview.size = sz
	preview.position = ((box.size - sz) / 2.0).floor()


func _select(id: String) -> void:
	_selected = id
	_refresh()


func _on_fabriquer() -> void:
	if GameState.is_unlocked(_selected):
		GameState.equip(_selected)
	else:
		GameState.unlock(_selected)
	_refresh()


func _on_equipes_pressed() -> void:
	get_tree().change_scene_to_file(EQUIPES)


func _on_launch() -> void:
	get_tree().change_scene_to_file("res://scenes/vol.tscn")


func _material_tile(index: int, nom: String, count: int) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(90, 96)
	tile.add_theme_stylebox_override("panel", _card_style(CREAM, 14, 4))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	# Icône provisoire (forme géométrique) en attendant les illustrations
	var icon = SHAPE_ICON.new()
	icon.shape = index
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var name_text := Label.new()
	name_text.text = nom
	name_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_text.add_theme_color_override("font_color", BROWN)
	name_text.add_theme_font_size_override("font_size", 14)
	var count_text := Label.new()
	count_text.text = "x%d" % count
	count_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_text.add_theme_color_override("font_color", RED)
	count_text.add_theme_font_size_override("font_size", 20)
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


func _card_style(bg: Color, radius := 30, border := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
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
