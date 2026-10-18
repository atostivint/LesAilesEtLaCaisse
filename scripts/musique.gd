extends Node
## Musique de fond, jouée sans interruption d'un écran à l'autre (autoload « Musique »).
## Les écrans de menu la lancent ; le vol et les scores l'arrêtent.


const PISTE := "res://audio/The_Bathroom.wav"

var _lecteur: AudioStreamPlayer


func _ready() -> void:
	_lecteur = AudioStreamPlayer.new()
	add_child(_lecteur)
	var piste = load(PISTE)
	if piste is AudioStreamWAV:
		piste.loop_mode = AudioStreamWAV.LOOP_FORWARD
	else:
		push_warning("Musique : impossible de charger %s" % PISTE)
	_lecteur.stream = piste


func jouer() -> void:
	if not _lecteur.playing:
		_lecteur.play()
		print("Musique : lecture de %s (volume du bus Master : %.1f dB)" % [PISTE, AudioServer.get_bus_volume_db(0)])


func arreter() -> void:
	_lecteur.stop()
