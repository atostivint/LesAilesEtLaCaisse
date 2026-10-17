extends HBoxContainer
## Une ligne de l'atelier = une caisse à savon (scène crate_row.tscn, une instance par caisse,
## créées par atelier.gd). Affiche son coût, ses stats et son état : verrouillée, à débloquer,
## débloquée (à équiper) ou équipée.

signal changed

var crate_id := ""

@onready var swatch: ColorRect = %Swatch
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var cost_label: Label = %CostLabel
@onready var stats_label: Label = %StatsLabel
@onready var action_button: Button = %ActionButton


func setup(id: String) -> void:
	crate_id = id


func _ready() -> void:
	action_button.pressed.connect(_on_action)
	refresh()


func refresh() -> void:
	var tuning: Tuning = GameState.tuning
	var c := tuning.crate(crate_id)
	swatch.color = c["color"]
	name_label.text = c["nom"]
	desc_label.text = c["desc"]
	stats_label.text = "Solidité %s\nPoids %s" % [_pips(int(c["solidite"])), _pips(int(c["poids"]))]
	if GameState.is_unlocked(crate_id):
		cost_label.text = "Débloquée"
		var is_equipped := GameState.equipped == crate_id
		action_button.text = "Équipée" if is_equipped else "Équiper"
		action_button.disabled = is_equipped
	else:
		cost_label.text = _cost_text(c["cost"])
		action_button.text = "Débloquer"
		action_button.disabled = not GameState.can_unlock(crate_id)


func _pips(n: int) -> String:
	return "■".repeat(n) + "□".repeat(maxi(0, 4 - n))


func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for mat in cost:
		parts.append("%s %d/%d" % [GameState.tuning.material(mat)["nom"], GameState.stock(mat), int(cost[mat])])
	return "  ·  ".join(parts)


func _on_action() -> void:
	if GameState.is_unlocked(crate_id):
		GameState.equip(crate_id)
	else:
		GameState.unlock(crate_id)
	changed.emit()
