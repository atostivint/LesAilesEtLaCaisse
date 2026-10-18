class_name Personnage
extends Node
## Le personnage choisi (équipe + couleur du savon) : un seul endroit pour l'appliquer partout
## (menu, jeu, scores, équipes). Appelé avec `Personnage.appliquer(savon, equipe, couleur)`.
## Les yeux et les bouches viennent du dépôt (artwork/yeux/ et artwork/sprites/savon_bleu_bouche_*.svg).


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
## Par équipe (dans l'ordre de l'écran des équipes) : un type d'yeux et un index de bouche du savon
## (0 grimace, 1 sourire, 2 moue, 3 inquiète, 4 surprise).
const YEUX := [
	"res://artwork/yeux/yeux_ronds.svg",
	"res://artwork/yeux/yeux_en_colere.svg",
	"res://artwork/yeux/yeux_plisses.svg",
	"res://artwork/yeux/savon_bleu_yeux_inquiets.svg",
]
# Une seule bouche, celle du dépôt, pour tous les personnages (index 1 : sourire)
const BOUCHES := [1, 1, 1, 1]


static func appliquer(savon, equipe: int, couleur_corps: Color) -> void:
	## Remplace les yeux et la bouche d'origine du savon par ceux de l'équipe, et règle sa couleur.
	var index := clampi(equipe, 0, YEUX.size() - 1)
	savon.mouth_timer.stop()
	for nom in ["PupilleGauche", "PupilleDroite"]:
		savon.get_node("Visuals/" + nom).visible = false
	var yeux: Sprite2D = savon.get_node("Visuals/YeuxBlancs")
	yeux.visible = true
	# Espace entre les yeux et la bouche : les yeux remontent, la bouche descend
	yeux.position = Vector2(0, -10)
	yeux.texture = load(YEUX[index])
	var bouche: Sprite2D = savon.get_node("Visuals/Bouche")
	bouche.visible = true
	bouche.position = Vector2(0, 12)
	bouche.texture = savon.mouths[BOUCHES[index]]
	savon.body_color = couleur_corps


static func appliquer_choisi(savon) -> void:
	## Applique le personnage enregistré dans GameState (équipe et couleur ; équipe 2 et couleur 1 par défaut).
	var equipe: int = GameState.equipe if GameState.equipe >= 0 else 1
	appliquer(savon, equipe, COULEURS[GameState.couleur])
