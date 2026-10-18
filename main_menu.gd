extends Control


const GAME_SCENE := "res://scenes/atelier.tscn"
const REGLAGES_SCENE := "res://scenes/reglages.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"


func _ready() -> void:
	Musique.jouer()
	# Le volume enregistré dans les réglages s'applique dès le menu
	preload("res://scripts/reglages.gd").appliquer_volume()


func _on_jouer_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_reglages_pressed() -> void:
	get_tree().change_scene_to_file(REGLAGES_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)
