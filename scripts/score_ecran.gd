extends Control
## Écran de score de fin de vol, un seul modèle pour les 5 paliers (maquettes « Score » : PNG et canvas Claude Design).
## Le palier se règle avec `mood` dans l'inspecteur (scènes score_*.tscn) : excellent, bon, moyen, mauvais, catastrophe.
## Textes, couleur d'accent et visage du savon viennent de MOODS. « Rejouer » relance un vol.

const VOL := "res://scenes/vol.tscn"
const VISAGE := preload("res://scripts/visage_savon.gd")
const INK := Color(0.984, 0.941, 0.839, 1)
const BROWN := Color(0.29, 0.165, 0.078, 1)

## « visage » : index dans visage_savon.gd (0 kawaii, 1 agressif, 2 endormi, 3 anxieux, 4 blasé, 5 fou).
var MOODS := {
	"excellent": {"accent": Color("#7A8B2E"), "label": "SCORE EXCELLENT", "series": "La bague au savon", "quote": "« Gérard demande Éléonore en mariage, elle dit oui et la bague glisse toute seule au doigt ! »", "tag": "", "next": "Éléonore prépare le grand jour, Pamela commettra-t-elle l'irréparable ?", "visage": 0},
	"bon": {"accent": Color("#C8561B"), "label": "BON SCORE", "series": "Gérard pris au piège", "quote": "« Éléonore a tout frotté ! Même Gérard y est passé ! »", "tag": "", "next": "Pamela folle de jalousie, prendra-t-elle sa revanche ?", "visage": 0},
	"moyen": {"accent": Color("#7a4a22"), "label": "SCORE MOYEN", "series": "Gérard perd de son éclat", "quote": "« Gérard s'ennuie auprès d'Éléonore, et leur histoire n'est plus aussi pétillante qu'avant. »", "tag": "", "next": "Éléonore sent-elle que Gérard lui file entre les doigts ?", "visage": 2},
	"mauvais": {"accent": Color("#3f7f8a"), "label": "MAUVAIS SCORE", "series": "Éléonore dérape", "quote": "« Éléonore a un accident de voiture et se retrouve à l'hôpital, entre la vie et la mort. »", "tag": "", "next": "Gérard au chevet d'Éléonore, mais l'accident était-il vraiment fortuit ?", "visage": 3},
	"catastrophe": {"accent": Color("#B5361F"), "label": "SCORE CATASTROPHIQUE", "series": "Pas une trace", "quote": "« On retrouve Éléonore sans vie. Le coupable a tout nettoyé, il ne reste rien. »", "tag": "", "next": "Pamela offre son épaule à Gérard, mais une tache sur sa manche la trahira-t-elle ?", "visage": 5},
}

@export_enum("excellent", "bon", "moyen", "mauvais", "catastrophe") var mood := "excellent"

## Numéro de la pose et nom de fichier des personnages (artwork/personnages/).
const MOODS_NUMERO := {"excellent": 1, "bon": 2, "moyen": 3, "mauvais": 4, "catastrophe": 5}
const MOODS_FICHIER := {"excellent": "excellent", "bon": "bon", "moyen": "moyen", "mauvais": "mauvais", "catastrophe": "catastrophique"}

@onready var pastille: PanelContainer = $Bas/Marge/Colonnes/Gauche/Entete/Pastille
@onready var pastille_texte: Label = $Bas/Marge/Colonnes/Gauche/Entete/Pastille/Texte
@onready var serie: Label = $Bas/Marge/Colonnes/Gauche/Entete/Titre
@onready var citation: Label = $Bas/Marge/Colonnes/Gauche/Citation
@onready var phrase: Label = $Bas/Marge/Colonnes/Gauche/Phrase
@onready var suite: PanelContainer = $Bas/Marge/Colonnes/Gauche/Suite
@onready var suite_texte: Label = $Bas/Marge/Colonnes/Gauche/Suite/Texte
@onready var entete: Label = $Bas/Marge/Colonnes/Droite/Carte/Contenu/EnTete
@onready var valeur: Label = $Bas/Marge/Colonnes/Droite/Carte/Contenu/Valeur
@onready var badge: Panel = $Haut/Badge
@onready var savon: Soap = %Savon


func _ready() -> void:
	Musique.arreter()
	var d: Dictionary = MOODS.get(mood, MOODS["excellent"])
	var accent: Color = d["accent"]
	# Pastille et « À SUIVRE » : texte marron sans fond
	pastille.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	suite.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_style_fond(entete, accent, 0, 6.0)
	_style_fond(badge, accent, 70)
	pastille_texte.text = d["label"]
	pastille_texte.add_theme_color_override("font_color", BROWN)
	serie.text = d["series"]
	citation.text = d["quote"]
	phrase.text = d["tag"]
	phrase.visible = d["tag"] != ""
	phrase.add_theme_color_override("font_color", accent)
	suite_texte.text = "À SUIVRE ▸ " + d["next"]
	suite_texte.add_theme_color_override("font_color", BROWN)
	valeur.add_theme_color_override("font_color", accent)
	_mettre_savon(d["visage"])
	# Gérard à gauche et Éléonore à droite, dans la pose du palier
	var numero: int = MOODS_NUMERO[mood]
	var fichier: String = MOODS_FICHIER[mood]
	$Haut/Gerard.texture = load("res://artwork/personnages/gerard-%d-%s.svg" % [numero, fichier])
	$Haut/Eleonore.texture = load("res://artwork/personnages/eleonore-%d-%s.svg" % [numero, fichier])


func _style_fond(node: Control, color: Color, radius: float, marge := 0.0) -> void:
	# Fond coloré d'un bloc (pastille, pilule, bandeau ou pastille ronde), avec une bordure brune
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BROWN
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_top = marge
	style.content_margin_bottom = marge
	style.content_margin_left = marge * 2.0
	style.content_margin_right = marge * 2.0
	node.add_theme_stylebox_override("panel" if node is PanelContainer or node is Panel else "normal", style)


func _mettre_savon(visage: int) -> void:
	# Le savon du jeu, sans ses yeux et sa bouche d'origine, avec le visage du palier
	savon.mouth_timer.stop()
	for nom in ["YeuxBlancs", "PupilleGauche", "PupilleDroite", "Bouche"]:
		savon.get_node("Visuals/" + nom).visible = false
	savon.body_color = Color(1, 0.97, 0.9, 1)
	var dessin = Control.new()
	dessin.set_script(VISAGE)
	dessin.expression = visage
	dessin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	savon.add_child(dessin)


func _on_rejouer_pressed() -> void:
	get_tree().change_scene_to_file(VOL)
