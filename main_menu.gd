extends Control


const PARTIES_SCENE := "res://scenes/parties.tscn"
const REGLAGES_SCENE := "res://scenes/reglages.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"


func _ready() -> void:
	Musique.jouer()
	# Le volume enregistré dans les réglages s'applique dès le menu
	preload("res://scripts/reglages.gd").appliquer_volume()
	# « Continuer » n'est disponible que s'il existe au moins une partie sauvegardée
	$Boutons/Continuer.disabled = not GameState.any_save()


func _on_jouer_pressed() -> void:
	# Nouvelle partie : on choisit l'emplacement, puis l'équipe
	GameState.mode = "nouvelle"
	get_tree().change_scene_to_file(PARTIES_SCENE)


func _on_continuer_pressed() -> void:
	# Continuer : on choisit la partie à reprendre
	GameState.mode = "continuer"
	get_tree().change_scene_to_file(PARTIES_SCENE)


func _on_reglages_pressed() -> void:
	get_tree().change_scene_to_file(REGLAGES_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)
