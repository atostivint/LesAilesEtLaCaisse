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
