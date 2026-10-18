extends Node
## Musique de fond, jouée en continu sur tout le jeu (autoload « Musique »).
## Elle démarre dès le lancement et ne s'arrête jamais : chaque écran peut l'appeler sans effet de bord.
## Le WAV est lu directement (sans passer par l'import de Godot) : son format est lu dans son en-tête.

const PISTE := "res://audio/The_Bathroom.wav"

var _lecteur: AudioStreamPlayer
var _chrono := 0.0


func _ready() -> void:
	_lecteur = AudioStreamPlayer.new()
	_lecteur.bus = "Master"
	_lecteur.volume_db = 0.0
	add_child(_lecteur)
	_lecteur.stream = _charger_wav(PISTE)
	if _lecteur.stream == null:
		push_warning("Musique : impossible de lire %s" % PISTE)
	jouer()


func jouer() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	if _lecteur.stream and not _lecteur.playing:
		_lecteur.play()
		print("Musique : lecture de %s (durée %.1f s)" % [PISTE, _lecteur.stream.get_length()])


func arreter() -> void:
	_lecteur.stop()


func _process(delta: float) -> void:
	# Diagnostic : état du lecteur et niveau du bus Master toutes les 2 secondes (sortie de Godot)
	_chrono += delta
	if _chrono >= 2.0:
		_chrono = 0.0
		print("Musique : en lecture=%s, niveau Master=%.1f dB" % [_lecteur.playing, AudioServer.get_bus_peak_volume_left_db(0, 0)])


func _charger_wav(chemin: String) -> AudioStreamWAV:
	## Lit un WAV PCM directement : format (canaux, fréquence, bits) puis données.
	var octets := FileAccess.get_file_as_bytes(chemin)
	if octets.size() < 44 or octets.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var canaux := 2
	var frequence := 44100
	var bits := 16
	var donnees := PackedByteArray()
	var pos := 12
	while pos + 8 <= octets.size():
		var id := octets.slice(pos, pos + 4).get_string_from_ascii()
		var taille := octets.decode_u32(pos + 4)
		if id == "fmt ":
			canaux = octets.decode_u16(pos + 10)
			frequence = octets.decode_u32(pos + 12)
			bits = octets.decode_u16(pos + 22)
		elif id == "data":
			donnees = octets.slice(pos + 8, mini(pos + 8 + taille, octets.size()))
			break
		pos += 8 + taille + (taille % 2)
	if donnees.is_empty() or bits != 16:
		return null
	var onde := AudioStreamWAV.new()
	onde.format = AudioStreamWAV.FORMAT_16_BITS
	onde.mix_rate = frequence
	onde.stereo = canaux == 2
	onde.data = donnees
	onde.loop_mode = AudioStreamWAV.LOOP_FORWARD
	onde.loop_begin = 0
	onde.loop_end = donnees.size() / (2 * canaux)
	return onde
