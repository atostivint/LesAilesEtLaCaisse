extends Node
## Musique de fond (autoload « Musique »).
## Par défaut : The_Bathroom.wav, sur les menus et le reste du jeu. Le vol (course) et les scores
## jouent Electrosw_nvx.wav via jouer_piste(PISTE_COURSE). Une piste ne redémarre pas si on la redemande.
## Le WAV est lu directement (sans passer par l'import de Godot) : son format est lu dans son en-tête.
## Le MP3 est lu de la même façon, depuis ses octets.

const PISTE := "res://audio/The_Bathroom.wav"
const PISTE_COURSE := "res://audio/Electrosw_nvx.wav"
## Volume de la piste de course, réglé sur celui de la musique des menus (mesuré : la course est 5,5 dB plus forte).
const VOLUME_COURSE_DB := -5.5

var _lecteur: AudioStreamPlayer
var _chrono := 0.0
var _piste := ""


func _ready() -> void:
	_lecteur = AudioStreamPlayer.new()
	_lecteur.bus = "Master"
	_lecteur.volume_db = 0.0
	add_child(_lecteur)
	jouer()


func jouer() -> void:
	jouer_piste(PISTE)


func jouer_piste(chemin: String) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	if chemin != _piste:
		_piste = chemin
		_lecteur.stop()
		_lecteur.stream = _charger(chemin)
		_lecteur.volume_db = VOLUME_COURSE_DB if chemin == PISTE_COURSE else 0.0
		if _lecteur.stream == null:
			push_warning("Musique : impossible de lire %s" % chemin)
	if _lecteur.stream and not _lecteur.playing:
		_lecteur.play()
		print("Musique : lecture de %s (durée %.1f s, boucle de %.1f à %.1f s)" % [chemin, _lecteur.stream.get_length(), 0.0, _fin_boucle(_lecteur.stream)])


func arreter() -> void:
	_lecteur.stop()


func _process(delta: float) -> void:
	# Diagnostic : état du lecteur et niveau du bus Master toutes les 2 secondes (sortie de Godot)
	_chrono += delta
	if _chrono >= 2.0:
		_chrono = 0.0
		print("Musique : en lecture=%s, niveau Master=%.1f dB" % [_lecteur.playing, AudioServer.get_bus_peak_volume_left_db(0, 0)])


func _charger(chemin: String) -> AudioStream:
	var octets := FileAccess.get_file_as_bytes(chemin)
	if octets.is_empty():
		# Fichier brut introuvable (cas de certains exports) : on prend la ressource importée par Godot
		return _importe(chemin)
	if chemin.ends_with(".mp3"):
		var mp3 := AudioStreamMP3.load_from_buffer(octets)
		if mp3:
			mp3.loop = true
		return mp3
	return _charger_wav(chemin)


func _importe(chemin: String) -> AudioStream:
	var s := load(chemin) as AudioStream
	if s is AudioStreamWAV:
		# Sans fin de boucle, le son s'arrête au bout de quelques secondes : on boucle sur toute la durée
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
	elif s is AudioStreamMP3:
		s.loop = true
	return s


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
	onde.loop_end = donnees.size() / (2 * canaux) # toute la durée : même boucle que dans l'export
	return onde


func _fin_boucle(flux: AudioStream) -> float:
	## Fin de la boucle en secondes (diagnostic : les pistes doivent boucler sur la même durée utile).
	if flux is AudioStreamWAV:
		return float(flux.loop_end) / flux.mix_rate
	return flux.get_length()
