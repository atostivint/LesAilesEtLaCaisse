extends Control


const GAME_SCENE := "res://scenes/atelier.tscn"


func _on_jouer_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
