extends Control


const EQUIPES_SCENE := "res://scenes/equipes.tscn"
const GAME_SCENE := "res://scenes/atelier.tscn"
const REGLAGES_SCENE := "res://scenes/reglages.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"


func _ready() -> void:
	Musique.jouer()
	# Le volume enregistré dans les réglages s'applique dès le menu
	preload("res://scripts/reglages.gd").appliquer_volume()
	# « Continuer » n'est disponible que s'il existe une partie sauvegardée
	$Boutons/Continuer.disabled = not GameState.has_save()


func _on_jouer_pressed() -> void:
	# Nouvelle partie : progression remise à zéro, puis choix de l'équipe
	GameState.reset()
	get_tree().change_scene_to_file(EQUIPES_SCENE)


func _on_continuer_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_reglages_pressed() -> void:
	get_tree().change_scene_to_file(REGLAGES_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)
