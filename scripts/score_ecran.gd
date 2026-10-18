extends Control
## Écran de score de fin de vol, un seul modèle pour les 5 paliers (maquettes « Score » : PNG et canvas Claude Design).
## Le palier se règle avec `mood` dans l'inspecteur (scènes score_*.tscn) : excellent, bon, moyen, mauvais, catastrophe.
## Après un vol, un pop-up demande le nom du joueur pour l'ajouter au classement.
## « Classement » affiche les meilleurs scores ; « Rejouer » relance un vol.

const VOL := "res://scenes/vol.tscn"
const INK := Color(0.984, 0.941, 0.839, 1)
const BROWN := Color(0.29, 0.165, 0.078, 1)
const CREME_PANNEAU := Color(0.984, 0.941, 0.839, 1)

## Textes du palier. « visage » ne sert plus (le personnage est celui du joueur).
var MOODS := {
	"excellent": {"accent": Color("#7A8B2E"), "label": "SCORE EXCELLENT", "series": "La bague au savon", "quote": "« Gérard demande Éléonore en mariage, elle dit oui et la bague glisse toute seule au doigt ! »", "tag": "", "next": "Éléonore prépare le grand jour, Pamela commettra-t-elle l'irréparable ?"},
	"bon": {"accent": Color("#C8561B"), "label": "BON SCORE", "series": "Gérard pris au piège", "quote": "« Éléonore a tout frotté ! Même Gérard y est passé ! »", "tag": "", "next": "Pamela folle de jalousie, prendra-t-elle sa revanche ?"},
	"moyen": {"accent": Color("#7a4a22"), "label": "SCORE MOYEN", "series": "Gérard perd de son éclat", "quote": "« Gérard s'ennuie auprès d'Éléonore, et leur histoire n'est plus aussi pétillante qu'avant. »", "tag": "", "next": "Éléonore sent-elle que Gérard lui file entre les doigts ?"},
	"mauvais": {"accent": Color("#3f7f8a"), "label": "MAUVAIS SCORE", "series": "Éléonore dérape", "quote": "« Éléonore a un accident de voiture et se retrouve à l'hôpital, entre la vie et la mort. »", "tag": "", "next": "Gérard au chevet d'Éléonore, mais l'accident était-il vraiment fortuit ?"},
	"catastrophe": {"accent": Color("#B5361F"), "label": "SCORE CATASTROPHIQUE", "series": "Pas une trace", "quote": "« On retrouve Éléonore sans vie. Le coupable a tout nettoyé, il ne reste rien. »", "tag": "", "next": "Pamela offre son épaule à Gérard, mais une tache sur sa manche la trahira-t-elle ?"},
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
@onready var droite: VBoxContainer = $Bas/Marge/Colonnes/Droite
@onready var savon: Soap = %Savon

var _popup_nom: Control
var _champ_nom: LineEdit
var _liste_noms: VBoxContainer
var _classement_panneau: Control


func _ready() -> void:
	var d: Dictionary = MOODS.get(mood, MOODS["excellent"])
	var accent: Color = d["accent"]
	# Pastille et « À SUIVRE » : texte marron sans fond
	pastille.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	suite.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_style_fond(entete, accent, 0, 6.0)
	pastille_texte.text = d["label"]
	pastille_texte.add_theme_color_override("font_color", BROWN)
	serie.text = d["series"]
	citation.text = d["quote"]
	# Texte réduit seulement quand la phrase est longue : même mise en page sur tous les paliers
	citation.add_theme_font_size_override("font_size", 34 if String(d["quote"]).length() <= 100 else 28)
	phrase.text = d["tag"]
	phrase.visible = d["tag"] != ""
	phrase.add_theme_color_override("font_color", accent)
	suite_texte.text = "À SUIVRE ▸ " + d["next"]
	suite_texte.add_theme_color_override("font_color", BROWN)
	suite_texte.add_theme_font_size_override("font_size", 20 if String(d["next"]).length() <= 80 else 17)
	# Score : la distance du dernier vol, dans l'unité du jeu
	var distance := _distance_du_vol()
	valeur.text = GameState.tuning.cm(distance)
	valeur.add_theme_font_size_override("font_size", 56)
	valeur.add_theme_color_override("font_color", accent)
	Personnage.appliquer_choisi(savon)
	# Gérard à gauche et Éléonore à droite, dans la pose du palier
	var numero: int = MOODS_NUMERO[mood]
	var fichier: String = MOODS_FICHIER[mood]
	$Haut/Gerard.texture = load("res://artwork/personnages/gerard-%d-%s.svg" % [numero, fichier])
	$Haut/Eleonore.texture = load("res://artwork/personnages/eleonore-%d-%s.svg" % [numero, fichier])
	# Bouton classement, juste au-dessus de Rejouer
	var bouton_classement := Button.new()
	bouton_classement.text = "Classement"
	bouton_classement.custom_minimum_size = Vector2(0, 48)
	bouton_classement.add_theme_color_override("font_color", BROWN)
	bouton_classement.add_theme_font_override("font", $Bas/Marge/Colonnes/Droite/Rejouer.get_theme_font("font"))
	bouton_classement.add_theme_font_size_override("font_size", 24)
	bouton_classement.add_theme_stylebox_override("normal", _style_bouton(CREME_PANNEAU))
	bouton_classement.add_theme_stylebox_override("hover", _style_bouton(Color(0.99, 0.76, 0.12, 1)))
	bouton_classement.pressed.connect(_afficher_classement)
	droite.add_child(bouton_classement)
	droite.move_child(bouton_classement, $Bas/Marge/Colonnes/Droite/Rejouer.get_index())
	_construire_popup_nom()
	_construire_classement()
	if GameState.score_en_attente:
		_popup_nom.show()


func _distance_du_vol() -> float:
	if GameState.last_run.is_empty():
		return 0.0
	return float(GameState.last_run["distance"])


func _style_fond(node: Control, color: Color, radius: float, marge := 0.0) -> void:
	# Fond coloré d'un bloc (bandeau ou pastille ronde), avec une bordure brune
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


func _style_bouton(couleur: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = couleur
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.border_color = BROWN
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 7
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	return style


func _style_panneau() -> StyleBoxFlat:
	var style := _style_bouton(CREME_PANNEAU)
	style.border_width_bottom = 8
	style.content_margin_left = 28.0
	style.content_margin_top = 24.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 24.0
	return style


func _construire_popup_nom() -> void:
	## Pop-up « NOUVEAU SCORE » : le joueur entre son nom pour le classement.
	_popup_nom = _fenetre_centree(480)
	var contenu: VBoxContainer = _popup_nom.get_node("Panneau/Contenu")
	contenu.add_child(_texte("NOUVEAU SCORE", 36, BROWN, GameState.tuning.cm(_distance_du_vol())))
	contenu.add_child(_texte("Entre ton nom pour le classement :", 22, BROWN))
	_champ_nom = LineEdit.new()
	_champ_nom.max_length = 16
	_champ_nom.placeholder_text = "Ton nom"
	_champ_nom.add_theme_font_size_override("font_size", 24)
	_champ_nom.text_submitted.connect(func(_t): _valider_nom())
	contenu.add_child(_champ_nom)
	# Prénoms déjà utilisés : cliquables, 4 visibles, le reste en défilant sur le côté
	contenu.add_child(_texte("Prénoms déjà utilisés", 20, BROWN))
	var defilement := ScrollContainer.new()
	defilement.custom_minimum_size = Vector2(0, 4 * 44 + 3 * 6)
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	contenu.add_child(defilement)
	_liste_noms = VBoxContainer.new()
	_liste_noms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste_noms.add_theme_constant_override("separation", 6)
	defilement.add_child(_liste_noms)
	_champ_nom.text_changed.connect(_rafraichir_noms)
	_rafraichir_noms("")
	var bouton := Button.new()
	bouton.text = "Ajouter au classement"
	bouton.custom_minimum_size = Vector2(0, 52)
	bouton.add_theme_color_override("font_color", BROWN)
	bouton.add_theme_font_size_override("font_size", 24)
	bouton.add_theme_stylebox_override("normal", _style_bouton(Color(0.99, 0.76, 0.12, 1)))
	bouton.add_theme_stylebox_override("hover", _style_bouton(Color(0.99, 0.82, 0.3, 1)))
	bouton.pressed.connect(_valider_nom)
	contenu.add_child(bouton)


func _construire_classement() -> void:
	## Tableau du classement (les meilleurs scores enregistrés).
	_classement_panneau = _fenetre_centree(560)
	var contenu: VBoxContainer = _classement_panneau.get_node("Panneau/Contenu")
	contenu.add_child(_texte("CLASSEMENT", 36, BROWN))
	var liste := VBoxContainer.new()
	liste.name = "Liste"
	contenu.add_child(liste)
	var fermer := Button.new()
	fermer.text = "Fermer"
	fermer.custom_minimum_size = Vector2(0, 48)
	fermer.add_theme_color_override("font_color", BROWN)
	fermer.add_theme_font_size_override("font_size", 24)
	fermer.add_theme_stylebox_override("normal", _style_bouton(CREME_PANNEAU))
	fermer.pressed.connect(func(): _classement_panneau.hide())
	contenu.add_child(fermer)


func _fenetre_centree(largeur: float) -> Control:
	## Un voile sombre et un panneau crème au centre de l'écran (pop-up).
	var fenetre := Control.new()
	fenetre.set_anchors_preset(Control.PRESET_FULL_RECT)
	fenetre.mouse_filter = Control.MOUSE_FILTER_STOP
	var voile := ColorRect.new()
	voile.color = Color(0.0, 0.0, 0.0, 0.45)
	voile.set_anchors_preset(Control.PRESET_FULL_RECT)
	fenetre.add_child(voile)
	var panneau := PanelContainer.new()
	panneau.name = "Panneau"
	panneau.add_theme_stylebox_override("panel", _style_panneau())
	panneau.custom_minimum_size = Vector2(largeur, 0)
	panneau.set_anchors_preset(Control.PRESET_CENTER)
	panneau.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panneau.grow_vertical = Control.GROW_DIRECTION_BOTH
	fenetre.add_child(panneau)
	var contenu := VBoxContainer.new()
	contenu.name = "Contenu"
	contenu.add_theme_constant_override("separation", 14)
	panneau.add_child(contenu)
	fenetre.hide()
	add_child(fenetre)
	return fenetre


func _texte(texte: String, taille: int, couleur: Color, sous_titre := "") -> Control:
	var bloc := VBoxContainer.new()
	var titre := Label.new()
	titre.text = texte
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", taille)
	titre.add_theme_color_override("font_color", couleur)
	bloc.add_child(titre)
	if sous_titre != "":
		var sous := Label.new()
		sous.text = sous_titre
		sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sous.add_theme_font_size_override("font_size", 22)
		sous.add_theme_color_override("font_color", BROWN)
		bloc.add_child(sous)
	return bloc


func _valider_nom() -> void:
	var nom := _champ_nom.text.strip_edges()
	if nom == "":
		nom = "Anonyme"
	GameState.ajouter_au_classement(nom, _distance_du_vol(), mood)
	GameState.score_en_attente = false
	_popup_nom.hide()
	_afficher_classement()


func _afficher_classement() -> void:
	var liste: VBoxContainer = _classement_panneau.get_node("Panneau/Contenu/Liste")
	for enfant in liste.get_children():
		enfant.queue_free()
	if GameState.classement.is_empty():
		liste.add_child(_texte("Pas encore de score.", 22, BROWN))
	for i in GameState.classement.size():
		var entree: Dictionary = GameState.classement[i]
		var ligne := Label.new()
		ligne.text = "%d.  %s   ·   %s" % [i + 1, entree["nom"], GameState.tuning.cm(float(entree["distance"]))]
		ligne.add_theme_font_size_override("font_size", 24)
		ligne.add_theme_color_override("font_color", BROWN)
		liste.add_child(ligne)
	_classement_panneau.show()


func _on_rejouer_pressed() -> void:
	get_tree().change_scene_to_file(VOL)


func _rafraichir_noms(filtre: String) -> void:
	## Remplit la liste des prénoms déjà utilisés (ceux du classement), filtrés par ce qui est tapé.
	for enfant in _liste_noms.get_children():
		enfant.queue_free()
	var vus := {}
	for nom in GameState.noms_connus:
		if vus.has(nom) or (filtre != "" and not nom.to_lower().contains(filtre.strip_edges().to_lower())):
			continue
		vus[nom] = true
		var bouton := Button.new()
		bouton.text = nom
		bouton.custom_minimum_size = Vector2(0, 44)
		bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bouton.add_theme_color_override("font_color", BROWN)
		bouton.add_theme_font_size_override("font_size", 22)
		bouton.add_theme_stylebox_override("normal", _style_bouton(CREME_PANNEAU))
		bouton.pressed.connect(_choisir_nom.bind(nom))
		_liste_noms.add_child(bouton)


func _choisir_nom(nom: String) -> void:
	_champ_nom.text = nom
	_champ_nom.caret_column = nom.length()
