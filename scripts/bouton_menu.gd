extends Button
## Bouton « Menu » commun à tous les écrans : ramène au menu principal.

const MENU := "res://Mathilde/main_menu.tscn"


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	get_tree().change_scene_to_file(MENU)
