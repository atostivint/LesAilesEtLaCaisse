extends Control
## ÉCRAN 1 : l'atelier. On débloque de nouvelles caisses à savon avec les matériaux récoltés en vol,
## on choisit celle qu'on équipe, puis on lance le savon.
## Tous les nœuds sont dans scenes/atelier.tscn, y compris une ligne de caisse (crate_row.tscn) par
## caisse : pour en ajouter une, crée un CrateData (data/crates/), ajoute-le à `crates` dans data/tuning.tres,
## puis duplique une ligne ici et glisse-le dans son champ `crate`.

@onready var stock_label: Label = %StockLabel
@onready var info_label: Label = %InfoLabel
@onready var launch_button: Button = %LaunchButton
@onready var reset_button: Button = %ResetButton
@onready var rows: Node = %Rows


func _ready() -> void:
	for row in rows.get_children():
		row.changed.connect(_refresh)
	launch_button.pressed.connect(_on_launch)
	reset_button.pressed.connect(_on_reset)
	launch_button.grab_focus()
	_refresh()


func _refresh() -> void:
	var tuning: Tuning = GameState.tuning
	var parts: Array[String] = []
	for m in tuning.materials:
		parts.append("%s %d" % [m.nom, GameState.stock(m.id)])
	stock_label.text = "Matériaux : " + "   ·   ".join(parts)
	var lines: Array[String] = []
	lines.append("Vol n° %d   ·   Caisse : %s" % [GameState.turn, tuning.crate(GameState.equipped).nom])
	lines.append("Record : %s / %s" % [tuning.cm(GameState.best), tuning.cm(tuning.door_x)])
	if GameState.last_run.is_empty():
		lines.append("Premier vol : ramasse des pièces sur les étagères pour débloquer d'autres caisses.")
	else:
		var r: Dictionary = GameState.last_run
		lines.append("Dernier vol : %s, récolte : %s%s" % [tuning.cm(float(r["distance"])), tuning.collected_text(r["collected"]), " (record !)" if r["record"] else ""])
	if GameState.won:
		lines.append("Ligne d'arrivée franchie au vol n° %d !" % GameState.won_turn)
	info_label.text = "\n".join(lines)
	for row in rows.get_children():
		row.refresh()


func _on_launch() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _on_reset() -> void:
	GameState.reset()
	_refresh()
