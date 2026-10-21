extends HBoxContainer
## Une ligne de l'atelier = une caisse à savon (scène crate_row.tscn, une instance par caisse
## dans atelier.tscn : on choisit la caisse avec `crate`). Affiche son coût, ses stats et son état : verrouillée, à débloquer,
## débloquée (à équiper) ou équipée.

signal changed

## La caisse affichée (fichier de data/crates/).
@export var crate: CrateData

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var stats_label: Label = %StatsLabel
@onready var action_button: Button = %ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action)
	refresh()


func refresh() -> void:
	icon.texture = crate.texture
	name_label.text = crate.nom
	desc_label.text = crate.desc
	stats_label.text = "Vies %s\nAutonomie %s\nÉlan %s\nManiabilité %s" % [_pips(crate.solidite), _pips(crate.autonomie), _pips(crate.poids), _pips(crate.maniabilite)]
	if GameState.is_unlocked(crate.id):
		cost_label.text = "Débloquée"
		var is_equipped := GameState.equipped == crate.id
		action_button.text = "Équipée" if is_equipped else "Équiper"
		action_button.disabled = is_equipped
	else:
		cost_label.text = _cost_text(crate.cost)
		action_button.text = "Débloquer"
		action_button.disabled = not GameState.can_unlock(crate.id)
	_colorer_bouton(not GameState.is_unlocked(crate.id) and not action_button.disabled)


func _colorer_bouton(vert: bool) -> void:
	## Bouton vert quand on a assez d'ingrédients pour fabriquer la caisse.
	for etat in ["normal", "hover", "pressed", "focus"]:
		if vert:
			var fond := StyleBoxFlat.new()
			fond.bg_color = Color(0.42, 0.54, 0.18) if etat != "hover" else Color(0.5, 0.64, 0.22)
			fond.set_corner_radius_all(8)
			fond.set_content_margin_all(8)
			action_button.add_theme_stylebox_override(etat, fond)
		else:
			action_button.remove_theme_stylebox_override(etat)
	if vert:
		action_button.add_theme_color_override("font_color", Color.WHITE)
		action_button.add_theme_color_override("font_hover_color", Color.WHITE)
		action_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	else:
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			action_button.remove_theme_color_override(c)


func _pips(n: int) -> String:
	return "■".repeat(n) + "□".repeat(maxi(0, 4 - n))


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for mat in cost:
		parts.append("%s %d/%d" % [GameState.tuning.material(mat).nom, GameState.stock(mat), int(cost[mat])])
	return "  ·  ".join(parts)


func _on_action() -> void:
	if GameState.is_unlocked(crate.id):
		GameState.equip(crate.id)
	else:
		GameState.unlock(crate.id)
	changed.emit()
