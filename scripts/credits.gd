extends Control
## Écran des crédits. Pour ajouter une personne ou une réalisation, complète CREDITS ci-dessous :
## chaque entrée est un titre de section et sa liste de lignes (nom, rôle, accomplissement...).


const CREDITS := [
	{"titre": "Développement", "lignes": ["Mathilde"]},
	{"titre": "Graphisme et personnages", "lignes": ["À compléter"]},
	{"titre": "Musique", "lignes": ["Leon Wari : soundcloud.com/leon_wari"]},
	{"titre": "Ce que nous avons accompli", "lignes": ["À compléter"]},
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
			texte.add_theme_color_override("font_color", Color(0.29, 0.165, 0.078, 1))
			texte.add_theme_font_size_override("font_size", 26)
			liste.add_child(texte)
