class_name Personnage
extends Node
## Le personnage choisi (équipe + couleur du savon) : un seul endroit pour l'appliquer partout
## (menu, jeu, scores, équipes). Appelé avec `Personnage.appliquer(savon, visage, couleur)`.

const VISAGE := preload("res://scripts/visage_savon.gd")
const COULEURS := [
	Color(0.984, 0.941, 0.839, 1),
	Color(0.9, 0.6, 0.62, 1),
	Color(0.92, 0.75, 0.25, 1),
	Color(0.55, 0.68, 0.3, 1),
	Color(0.62, 0.8, 0.85, 1),
	Color(0.7, 0.6, 0.85, 1),
	Color(0.9, 0.55, 0.25, 1),
	Color(0.24, 0.16, 0.12, 1),
]


static func appliquer_choisi(savon) -> void:
	## Applique le personnage enregistré dans GameState (équipe et couleur ; équipe 2 et couleur 1 par défaut).
	var equipe: int = GameState.equipe if GameState.equipe >= 0 else 1
	appliquer(savon, equipe, COULEURS[GameState.couleur])


static func appliquer(savon, visage_index: int, couleur_corps: Color) -> void:
	## Remplace les yeux et la bouche d'origine du savon par le visage de l'équipe, et règle sa couleur.
	savon.mouth_timer.stop()
	for nom in ["YeuxBlancs", "PupilleGauche", "PupilleDroite", "Bouche"]:
		savon.get_node("Visuals/" + nom).visible = false
	savon.body_color = couleur_corps
	var visage = savon.get_node_or_null("Visage")
	if visage == null:
		visage = Control.new()
		visage.set_script(VISAGE)
		visage.name = "Visage"
		visage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		savon.add_child(visage)
	visage.expression = visage_index
	visage.queue_redraw()
