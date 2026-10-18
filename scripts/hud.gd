extends CanvasLayer
## Interface du vol (les nœuds sont dans vol.tscn). Ne contient aucune logique de jeu :
## vol.gd lui donne les chiffres et les textes à afficher.

var _popup_tween: Tween

@onready var distance_label: Label = %DistanceLabel
@onready var exit_label: Label = %ExitLabel
@onready var progress: ProgressBar = %ProgressBar
@onready var collected_label: Label = %CollectedLabel
@onready var speed_label: Label = %SpeedLabel
@onready var wings_label: Label = %WingsLabel
@onready var hint_label: Label = %HintLabel
@onready var popup_label: Label = %PopupLabel


func update_run( tuning: Tuning) -> void:
	pass

func set_hint(text: String) -> void:
	hint_label.text = text


func show_popup(text: String, duration: float) -> void:
	## Affiche un message qui s'efface tout seul après `duration` secondes.
	popup_label.text = text
	popup_label.modulate.a = 1.0
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_interval(duration - 0.4)
	_popup_tween.tween_property(popup_label, "modulate:a", 0.0, 0.4)
