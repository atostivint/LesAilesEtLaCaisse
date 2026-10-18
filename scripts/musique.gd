extends Node
## Musique de fond, jouée en continu sur tout le jeu (autoload « Musique »).
## Elle démarre dès le lancement et ne s'arrête jamais : chaque écran peut l'appeler sans effet de bord.

const PISTE := "res://audio/The_Bathroom.wav"

var _lecteur: AudioStreamPlayer


func _ready() -> void:
	_lecteur = AudioStreamPlayer.new()
	_lecteur.bus = "Master"
	_lecteur.volume_db = 0.0
	add_child(_lecteur)
	var piste = load(PISTE)
	if piste is AudioStreamWAV:
		piste.loop_mode = AudioStreamWAV.LOOP_FORWARD
	else:
		push_warning("Musique : impossible de charger %s" % PISTE)
	_lecteur.stream = piste
	jouer()


func jouer() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	if not _lecteur.playing:
		_lecteur.play()
		print("Musique : lecture de %s" % PISTE)


func arreter() -> void:
	_lecteur.stop()
