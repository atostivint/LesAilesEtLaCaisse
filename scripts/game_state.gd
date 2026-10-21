extends Node
## Mémoire du jeu entre les scènes et entre les lancements (autoload "GameState").
## Tout ce qui doit survivre au changement de scène ou à la fermeture du jeu vit ici :
## matériaux, caisses débloquées, équipe choisie, record, n° de vol.
## Il y a trois emplacements de partie (slots) : chacun a son fichier user://save_N.json.
## Chaque partie a son propre classement : user://classement_N.json (effacé avec la partie).
##
## Pendant que le jeu tourne, ouvre l'arbre "Distant" (Remote) de l'éditeur :
## GameState > tuning te permet de modifier les réglages EN DIRECT (non sauvegardé !).

const START_CRATE := "classique"
const NB_SLOTS := 3
const CLASSEMENT_MAX := 10

var tuning: Tuning = preload("res://data/tuning.tres")
var slot := 0            # emplacement de partie en cours (0 à NB_SLOTS - 1)
var mode := ""           # "nouvelle" ou "continuer" : ce que l'écran des emplacements doit faire
var materials := {}      # matériau -> quantité en stock
var unlocked: Array[String] = [START_CRATE]
var equipped := START_CRATE
var best := 0.0          # record de distance (m)
var turn := 1            # numéro du prochain vol
var tuto_vu := false     # le tutoriel de la première partie a-t-il été lu ?
var won := false       # a-t-on déjà franchi la ligne d'arrivée ?
var won_turn := 0
var last_run := {}       # résultat du dernier vol
var last_distance := -1.0  # distance du vol précédent (unités internes, sauvegardée) ; < 0 = aucun vol encore
var equipe := -1         # index de l'équipe choisie (-1 = aucune)
var couleur := 0         # index de la couleur du savon
var classement: Array = []   # [{nom, distance, palier}], du meilleur au moins bon
var noms_connus: Array = []  # tous les prénoms déjà saisis (pour les proposer, même hors du top du classement)
var score_en_attente := false  # vrai juste après un vol : l'écran de score demande le nom
var achat_fait := false  # une caisse a déjà été fabriquée depuis le dernier vol : il faut voler avant d'en fabriquer une autre


func chemin(numero: int) -> String:
	return "user://save_%d.json" % numero


func chemin_classement(numero: int) -> String:
	return "user://classement_%d.json" % numero


func has_slot(numero: int) -> bool:
	return FileAccess.file_exists(chemin(numero))


func any_save() -> bool:
	for i in NB_SLOTS:
		if has_slot(i):
			return true
	return false


func supprimer_partie(numero: int) -> void:
	## Efface la sauvegarde de l'emplacement et son classement.
	for fichier in [chemin(numero), chemin_classement(numero)]:
		if FileAccess.file_exists(fichier):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(fichier))
	if numero == slot:
		classement = []
		noms_connus = []


func resume(numero: int) -> String:
	## Ligne de résumé d'un emplacement (pour l'écran des parties).
	if not has_slot(numero):
		return "Partie vide"
	var donnees = _lire_json(chemin(numero))
	if typeof(donnees) != TYPE_DICTIONARY:
		return "Partie vide"
	var nb_caisses: int = donnees.get("unlocked", []).size()
	var record := float(donnees.get("best", 0.0))
	return "Vol n° %d   ·   %d caisse(s)   ·   Record %s" % [int(donnees.get("turn", 1)), nb_caisses, tuning.cm(record)]


func stock(mat: String) -> int:
	return int(materials.get(mat, 0))


func collect_material(material: MaterialData) -> void:
	if material == null or material.id.is_empty():
		push_error("Cannot collect a material without a valid MaterialData ID.")
		return
	materials[material.id] = stock(material.id) + 1
	save_game()


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func raison_blocage(id: String) -> String:
	## Pourquoi on ne peut pas fabriquer cette caisse maintenant (texte pour l'atelier), "" si on peut ou si ce n'est pas une affaire de règle.
	if is_unlocked(id):
		return ""
	# Les caisses se débloquent dans l'ordre de la liste
	var index := tuning.crates.find(tuning.crate(id))
	if index > 0 and not is_unlocked(tuning.crates[index - 1].id):
		return "Fabrique d'abord : %s" % tuning.crates[index - 1].nom
	# Une seule caisse par vol : il faut jouer entre deux fabrications
	if achat_fait:
		return "Fais un vol avant la suivante"
	return ""


func can_unlock(id: String) -> bool:
	if is_unlocked(id) or raison_blocage(id) != "":
		return false
	var cost: Dictionary = tuning.crate(id).cost
	for mat in cost:
		if stock(mat) < int(cost[mat]):
			return false
	return true


func unlock(id: String) -> void:
	## Débloque une caisse (dépense les matériaux) et l'équipe tout de suite.
	if not can_unlock(id):
		return
	var cost: Dictionary = tuning.crate(id).cost
	for mat in cost:
		materials[mat] = stock(mat) - int(cost[mat])
	unlocked.append(id)
	equipped = id
	achat_fait = true
	save_game()


func equip(id: String) -> void:
	if is_unlocked(id):
		equipped = id
		save_game()


func apply_result(distance: float, reached_door: bool, collected: Dictionary) -> Dictionary:
	## Appelé à la fin d'un vol : garde les matériaux ramassés (même après une chute),
	## met à jour le record, passe au vol suivant.
	var is_record := distance > best
	for mat in collected:
		materials[mat] = stock(mat) + int(collected[mat])
	if is_record:
		best = distance
	if reached_door and not won:
		won = true
		won_turn = turn
	last_run = {
		"distance": distance, "collected": collected.duplicate(), "record": is_record,
		"door": reached_door, "turn": turn,
	}
	last_distance = distance
	turn += 1
	score_en_attente = true
	achat_fait = false # un nouveau vol vient d'être joué : on peut fabriquer à nouveau
	save_game()
	return last_run


func set_equipe(index: int, couleur_index: int) -> void:
	equipe = index
	couleur = couleur_index
	save_game()


func nouvelle_partie(numero: int) -> void:
	## Démarre une partie vide dans l'emplacement donné (les autres ne sont pas touchés).
	slot = numero
	reset()


func charger_partie(numero: int) -> bool:
	slot = numero
	_charger_classement()
	return _charger_slot()


func ajouter_au_classement(nom: String, distance: float, palier: String) -> void:
	## Ajoute un score (distance en unités internes) et garde les meilleurs.
	classement.append({"nom": nom, "distance": distance, "palier": palier})
	if not noms_connus.has(nom):
		noms_connus.append(nom)
	classement.sort_custom(func(a, b): return a["distance"] > b["distance"])
	if classement.size() > CLASSEMENT_MAX:
		classement.resize(CLASSEMENT_MAX)
	_sauver_json(chemin_classement(slot), {"classement": classement, "noms": noms_connus})


func reset() -> void:
	## Efface la progression de l'emplacement en cours, classement compris.
	classement = []
	noms_connus = []
	if FileAccess.file_exists(chemin_classement(slot)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(chemin_classement(slot)))
	materials = {}
	unlocked = [START_CRATE]
	equipped = START_CRATE
	best = 0.0
	turn = 1
	won = false
	tuto_vu = false
	won_turn = 0
	last_run = {}
	last_distance = -1.0
	score_en_attente = false
	achat_fait = false
	equipe = -1
	couleur = 0
	save_game()


func save_game() -> void:
	_sauver_json(chemin(slot), {
		"materials": materials, "unlocked": unlocked, "equipped": equipped, "best": best,
		"turn": turn, "won": won, "won_turn": won_turn, "tuto_vu": tuto_vu, "equipe": equipe, "couleur": couleur,
		"achat_fait": achat_fait, "last_distance": last_distance,
	})


func _charger_slot() -> bool:
	var donnees = _lire_json(chemin(slot))
	if typeof(donnees) != TYPE_DICTIONARY:
		return false
	materials = donnees.get("materials", {})
	unlocked.clear()
	for id in donnees.get("unlocked", [START_CRATE]):
		unlocked.append(str(id))
	equipped = str(donnees.get("equipped", START_CRATE))
	best = float(donnees.get("best", 0.0))
	turn = int(donnees.get("turn", 1))
	won = bool(donnees.get("won", false))
	won_turn = int(donnees.get("won_turn", 0))
	# Une sauvegarde d'avant le tutoriel : le joueur a déjà joué, inutile de le lui imposer
	tuto_vu = bool(donnees.get("tuto_vu", turn > 1))
	equipe = int(donnees.get("equipe", -1))
	couleur = int(donnees.get("couleur", 0))
	achat_fait = bool(donnees.get("achat_fait", false))
	last_distance = float(donnees.get("last_distance", -1.0))
	last_run = {}
	score_en_attente = false
	return true


func _charger_classement() -> void:
	## Charge le classement de l'emplacement en cours (vide si la partie n'en a pas encore).
	classement = []
	noms_connus = []
	var donnees = _lire_json(chemin_classement(slot))
	if typeof(donnees) == TYPE_DICTIONARY:
		classement = donnees.get("classement", [])
		noms_connus = donnees.get("noms", [])


func _sauver_json(fichier: String, donnees: Dictionary) -> void:
	var f := FileAccess.open(fichier, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(donnees))


func _lire_json(fichier: String):
	if not FileAccess.file_exists(fichier):
		return null
	var f := FileAccess.open(fichier, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())
