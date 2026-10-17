extends HBoxContainer
## Une ligne de l'atelier = une caisse à savon (scène crate_row.tscn, une instance par caisse
## dans atelier.tscn : on choisit la caisse avec `crate`). Affiche son coût, ses stats et son état : verrouillée, à débloquer,
## débloquée (à équiper) ou équipée.

signal changed

## La caisse affichée (fichier de data/crates/).
@export var crate: CrateData

@onready var swatch: ColorRect = %Swatch
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var stats_label: Label = %StatsLabel
@onready var action_button: Button = %ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action)
	refresh()


func refresh() -> void:
	swatch.color = crate.color
	name_label.text = crate.nom
	desc_label.text = crate.desc
	stats_label.text = "Solidité %s\nPoids %s" % [_pips(crate.solidite), _pips(crate.poids)]
	if GameState.is_unlocked(crate.id):
		cost_label.text = "Débloquée"
		var is_equipped := GameState.equipped == crate.id
		action_button.text = "Équipée" if is_equipped else "Équiper"
		action_button.disabled = is_equipped
	else:
		cost_label.text = _cost_text(crate.cost)
		action_button.text = "Débloquer"
		action_button.disabled = not GameState.can_unlock(crate.id)


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
