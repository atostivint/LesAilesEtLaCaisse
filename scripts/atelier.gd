extends Control
## ÉCRAN 1 : l'atelier. On dépense les pièces pour améliorer le savon, puis on le lance.
## Les nœuds sont dans scenes/atelier.tscn (lignes d'amélioration = scenes/upgrade_row.tscn).
## Ce script ne fait que remplir les textes et réagir aux boutons.

@onready var coins_label: Label = %CoinsLabel
@onready var info_label: Label = %InfoLabel
@onready var launch_button: Button = %LaunchButton
@onready var reset_button: Button = %ResetButton
@onready var rows: Node = %Rows


func _ready() -> void:
	for row in rows.get_children():
		row.bought.connect(_refresh)
	launch_button.pressed.connect(_on_launch)
	reset_button.pressed.connect(_on_reset)
	launch_button.grab_focus()
	_refresh()


func _refresh() -> void:
	coins_label.text = "Pièces : %d" % GameState.coins
	var lines: Array[String] = []
	lines.append("Vol n° %d" % GameState.turn)
	lines.append("Record : %s / %s" % [GameState.tuning.cm(GameState.best), GameState.tuning.cm(GameState.tuning.door_x)])
	if GameState.last_run.is_empty():
		lines.append("Premier vol : achète une amélioration ou lance-toi tel quel.")
	else:
		var r: Dictionary = GameState.last_run
		lines.append("Dernier vol : %s, +%d pièces%s" % [GameState.tuning.cm(float(r["distance"])), int(r["gain"]), " (record !)" if r["record"] else ""])
	if GameState.won:
		lines.append("ÉVADÉ au vol n° %d !" % GameState.won_turn)
	info_label.text = "\n".join(lines)
	for row in rows.get_children():
		row.refresh()


func _on_launch() -> void:
	get_tree().change_scene_to_file("res://scenes/vol.tscn")


func _on_reset() -> void:
	GameState.reset()
	_refresh()
