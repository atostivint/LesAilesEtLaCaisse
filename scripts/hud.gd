extends CanvasLayer
## Interface du vol (les nœuds sont dans vol.tscn). Ne contient aucune logique de jeu :
## vol.gd lui donne les chiffres et les textes à afficher.

@onready var distance_label: Label = %DistanceLabel
@onready var exit_label: Label = %ExitLabel
@onready var progress: ProgressBar = %ProgressBar
@onready var collected_label: Label = %CollectedLabel
@onready var speed_label: Label = %SpeedLabel
@onready var wings_label: Label = %WingsLabel
@onready var hint_label: Label = %HintLabel
@onready var popup_label: Label = %PopupLabel
@onready var result_root: Control = %ResultRoot
@onready var result_label: Label = %ResultLabel
@onready var return_label: Label = %ReturnLabel


func update_run(sim: FlightSim, tuning: Tuning) -> void:
	distance_label.text = "Distance : %s" % tuning.cm(sim.x)
	exit_label.text = "Sortie dans %s" % tuning.cm(maxf(0.0, tuning.door_x - sim.x))
	progress.max_value = tuning.door_x
	progress.value = sim.x
	collected_label.text = "Récolte : %s" % tuning.collected_text(sim.collected)
	speed_label.text = "Vitesse : %s" % tuning.cm_speed(sim.speed())
	wings_label.text = "Ailes : %s" % ("♥".repeat(sim.wings) + "♡".repeat(sim.max_wings - sim.wings))


func set_hint(text: String) -> void:
	hint_label.text = text


func set_popup(text: String) -> void:
	popup_label.text = text


func show_result(text: String) -> void:
	result_label.text = text
	result_root.visible = true


func set_return_prompt(shown: bool) -> void:
	return_label.visible = shown
