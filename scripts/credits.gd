extends Control
## Écran des crédits. Pour ajouter une personne ou une réalisation, complète CREDITS ci-dessous :
## chaque entrée est un titre de section et sa liste de lignes (nom, rôle, accomplissement...).


const CREDITS := [
	{"titre": "Une création de game jam", "lignes": [
		"Ce jeu a été réalisé lors d'une game jam.",
		"Une game jam (« confiture de jeux ») est un événement où des équipes créent un jeu vidéo complet en un temps très court, souvent quelques jours, autour d'un thème imposé.",
	]},
	{"titre": "Développement", "lignes": ["Mathilde Pottier", "Alexandre (aleckt)", "Yoann (Iziny)"]},
	{"titre": "Graphisme et personnages", "lignes": ["Alexandre (aleckt)"]},
	{"titre": "Direction artistique et narration", "lignes": ["Mathilde Pottier"]},
	{"titre": "Musique", "lignes": ["Leon Wari : soundcloud.com/leon_wari"]},
]

@onready var liste: VBoxContainer = %Liste


func _ready() -> void:
	Musique.jouer()
	for section in CREDITS:
		var titre := Label.new()
		titre.text = section["titre"].to_upper()
		titre.add_theme_color_override("font_color", Color(0.8, 0.36, 0.14, 1))
		titre.add_theme_font_size_override("font_size", 22)
		liste.add_child(titre)
		for ligne in section["lignes"]:
			var texte := Label.new()
			texte.text = ligne
			texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # les phrases longues (définition) passent à la ligne
			texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			texte.add_theme_color_override("font_color", Color(0.29, 0.165, 0.078, 1))
			texte.add_theme_font_size_override("font_size", 26)
			liste.add_child(texte)
