extends Control


const PARTIES_SCENE := "res://scenes/parties.tscn"
const REGLAGES_SCENE := "res://scenes/reglages.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"
const VERT := Color(0.42, 0.54, 0.18, 1)
const MARRON := Color(0.29, 0.165, 0.078, 1)
const BLANC := Color(1, 1, 1, 1)


func _ready() -> void:
	Musique.jouer()
	# Le volume enregistré dans les réglages s'applique dès le menu
	preload("res://scripts/reglages.gd").appliquer_volume()
	# « Continuer » n'est disponible que s'il existe au moins une partie sauvegardée
	$Boutons/Continuer.disabled = not GameState.any_save()
	if GameState.any_save():
		# Une partie existe : « Continuer » passe en haut, en vert ; « Nouvelle partie » reprend le style marron
		$Boutons.move_child($Boutons/Continuer, 0)
		_habiller($Boutons/Continuer, VERT)
		_habiller($Boutons/Jouer, MARRON)
	else:
		# Pas de partie : « Nouvelle partie » en haut, en vert
		_habiller($Boutons/Jouer, VERT)
		_habiller($Boutons/Continuer, MARRON)


func _habiller(bouton: Button, couleur: Color) -> void:
	## Style d'un bouton : vert (texte marron au survol) ou marron (texte vert au survol), texte blanc de base.
	var survol := MARRON if couleur == VERT else VERT
	var style := StyleBoxFlat.new()
	style.bg_color = couleur
	style.border_color = Color(0.2, 0.11, 0.05, 1)
	style.border_width_left = 6
	style.border_width_top = 6
	style.border_width_right = 6
	style.border_width_bottom = 10
	style.corner_radius_top_left = 40
	style.corner_radius_top_right = 40
	style.corner_radius_bottom_right = 40
	style.corner_radius_bottom_left = 40
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	for etat in ["normal", "hover", "pressed", "focus"]:
		bouton.add_theme_stylebox_override(etat, style)
	bouton.add_theme_color_override("font_color", BLANC)
	bouton.add_theme_color_override("font_hover_color", survol)
	bouton.add_theme_color_override("font_pressed_color", survol)
	bouton.add_theme_color_override("font_focus_color", survol)


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
