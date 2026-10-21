extends Control
## Écran des réglages. Pour l'instant : le volume de la musique.
## Le réglage est enregistré dans user://reglages.cfg et réappliqué au lancement du menu (voir appliquer_volume).
## Le bus audio « Musique » est utilisé s'il existe, sinon le bus principal « Master ».

const FICHIER := "user://reglages.cfg"
const SECTION := "audio"
const CLE := "volume_musique"

@onready var curseur: HSlider = %Curseur
@onready var valeur: Label = %Valeur


func _ready() -> void:
	Musique.jouer()
	_ajouter_bouton_retour()
	curseur.value = _lire_volume()
	_afficher(curseur.value)
	curseur.value_changed.connect(_on_volume_change)


func _on_volume_change(v: float) -> void:
	_afficher(v)
	_appliquer(v)
	var cfg := ConfigFile.new()
	cfg.load(FICHIER)
	cfg.set_value(SECTION, CLE, v)
	cfg.save(FICHIER)


func _afficher(v: float) -> void:
	valeur.text = "%d %%" % roundi(v * 100.0)


static func appliquer_volume() -> void:
	## À appeler au lancement : remet le volume enregistré sur le bus.
	var cfg := ConfigFile.new()
	var v := 1.0
	if cfg.load(FICHIER) == OK:
		v = float(cfg.get_value(SECTION, CLE, 1.0))
	_appliquer(v)


static func _appliquer(v: float) -> void:
	var bus := AudioServer.get_bus_index("Musique")
	if bus == -1:
		bus = 0
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))


func _lire_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(FICHIER) == OK:
		return float(cfg.get_value(SECTION, CLE, 1.0))
	return 1.0


func _ajouter_bouton_retour() -> void:
	## Bouton « Retour » sous les paramètres (sous la carte des réglages) : revient au menu principal.
	var brun := Color(0.29, 0.165, 0.078, 1)
	var b := Button.new()
	b.text = "← Retour"
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_font_override("font", preload("res://fonts/COOPBL.TTF"))
	b.add_theme_font_size_override("font_size", 24)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color(0.984, 0.941, 0.839, 1) if c != "font_hover_color" else brun)
	for etat in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.99, 0.76, 0.12, 1) if etat == "hover" else brun
		s.set_corner_radius_all(22)
		s.content_margin_left = 20.0
		s.content_margin_right = 20.0
		s.content_margin_top = 6.0
		s.content_margin_bottom = 6.0
		b.add_theme_stylebox_override(etat, s)
	b.pressed.connect(func(): get_tree().change_scene_to_file("res://Mathilde/main_menu.tscn"))
	$Marge/Main.add_child(b) # dernier enfant de la colonne : il apparaît sous la carte des paramètres
