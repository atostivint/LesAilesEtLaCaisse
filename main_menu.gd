extends Control


const PARTIES_SCENE := "res://scenes/parties.tscn"
const REGLAGES_SCENE := "res://scenes/reglages.tscn"
const CREDITS_SCENE := "res://scenes/credits.tscn"


func _ready() -> void:
	Musique.jouer()
	# Le volume enregistré dans les réglages s'applique dès le menu
	preload("res://scripts/reglages.gd").appliquer_volume()
	# « Continuer » n'existe à l'écran que s'il y a au moins une partie sauvegardée (jamais au premier lancement)
	$Boutons/Continuer.visible = GameState.any_save()
	# 5 boutons : on les resserre pour qu'ils tiennent à l'écran
	$Boutons.add_theme_constant_override("separation", 10)
	for bouton in $Boutons.get_children():
		bouton.custom_minimum_size.y = 66.0
	# Si une partie est en cours : « Continuer » passe au-dessus (en vert, bouton principal) et « Nouvelle partie » dessous
	if GameState.any_save():
		var jouer: Button = $Boutons/Jouer
		var continuer: Button = $Boutons/Continuer
		_echanger_styles(jouer, continuer)
		$Boutons.move_child(continuer, 0)
		continuer.grab_focus()


func _echanger_styles(a: Button, b: Button) -> void:
	## Échange l'apparence de deux boutons (styles et couleurs de texte), pour changer le bouton « principal ».
	for style in ["normal", "pressed", "hover", "focus"]:
		var sa := a.get_theme_stylebox(style)
		var sb := b.get_theme_stylebox(style)
		a.add_theme_stylebox_override(style, sb)
		b.add_theme_stylebox_override(style, sa)
	for couleur in ["font_color", "font_focus_color", "font_pressed_color", "font_hover_color"]:
		var ca := a.get_theme_color(couleur)
		var cb := b.get_theme_color(couleur)
		a.add_theme_color_override(couleur, cb)
		b.add_theme_color_override(couleur, ca)


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


func _on_quitter_pressed() -> void:
	get_tree().quit()
