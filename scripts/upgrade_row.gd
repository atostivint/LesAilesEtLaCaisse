extends HBoxContainer
## Une ligne d'amélioration de l'atelier (scène upgrade_row.tscn, instanciée 4 fois dans atelier.tscn).
## Dans atelier.tscn, sélectionne une ligne : `upgrade_id` choisit quelle amélioration elle pilote.

signal bought

@export_enum("poussee", "bulles", "ailes", "glisse") var upgrade_id: String = "poussee"

@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var value_label: Label = %ValueLabel
@onready var pips_label: Label = %PipsLabel
@onready var buy_button: Button = %BuyButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy)
	refresh()


func refresh() -> void:
	var tuning: Tuning = GameState.tuning
	for up in Tuning.UPGRADES:
		if up["id"] == upgrade_id:
			name_label.text = up["nom"]
			desc_label.text = up["desc"]
	var lvl: int = GameState.levels[upgrade_id]
	pips_label.text = "■".repeat(lvl) + "□".repeat(tuning.max_level - lvl)
	if GameState.is_maxed(upgrade_id):
		value_label.text = "Actuel : %s (MAX)" % tuning.value_text(upgrade_id, lvl)
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		value_label.text = "%s  →  %s" % [tuning.value_text(upgrade_id, lvl), tuning.value_text(upgrade_id, lvl + 1)]
		buy_button.text = "Acheter  %d" % GameState.cost(upgrade_id)
		buy_button.disabled = not GameState.can_buy(upgrade_id)


func _on_buy() -> void:
	GameState.buy(upgrade_id)
	bought.emit()
