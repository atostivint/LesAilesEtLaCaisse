extends Control
## ÉCRAN 1 : l'atelier. On débloque de nouvelles caisses à savon avec les matériaux récoltés en vol,
## on choisit celle qu'on équipe, puis on lance le savon.
## Les nœuds fixes sont dans scenes/atelier.tscn ; les lignes de caisses (scenes/crate_row.tscn)
## sont créées ici, une par caisse de Tuning.CRATES.

const CRATE_ROW := preload("res://scenes/crate_row.tscn")

@onready var stock_label: Label = %StockLabel
@onready var info_label: Label = %InfoLabel
@onready var launch_button: Button = %LaunchButton
@onready var reset_button: Button = %ResetButton
@onready var rows: Node = %Rows


func _ready() -> void:
	for c in Tuning.CRATES:
		var row := CRATE_ROW.instantiate()
		row.setup(c["id"])
		row.changed.connect(_refresh)
		rows.add_child(row)
	launch_button.pressed.connect(_on_launch)
	reset_button.pressed.connect(_on_reset)
	launch_button.grab_focus()
	_refresh()


func _refresh() -> void:
	var tuning: Tuning = GameState.tuning
	var parts: Array[String] = []
	for m in Tuning.MATERIALS:
		parts.append("%s %d" % [m["nom"], GameState.stock(m["id"])])
	stock_label.text = "Matériaux : " + "   ·   ".join(parts)
	var lines: Array[String] = []
	lines.append("Vol n° %d   ·   Caisse : %s" % [GameState.turn, tuning.crate(GameState.equipped)["nom"]])
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
	get_tree().change_scene_to_file("res://scenes/vol.tscn")


func _on_reset() -> void:
	GameState.reset()
	_refresh()
