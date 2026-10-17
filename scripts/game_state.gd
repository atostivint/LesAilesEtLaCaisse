extends Node
## Mémoire du jeu entre les scènes (autoload "GameState").
## Atelier et Vol sont deux scènes différentes : tout ce qui doit survivre au
## changement de scène (matériaux, caisses débloquées, record, n° de vol) vit ici.
##
## Pendant que le jeu tourne, ouvre l'arbre "Distant" (Remote) de l'éditeur :
## GameState > tuning te permet de modifier les réglages EN DIRECT (non sauvegardé !).

const START_CRATE := "classique"

var tuning: Tuning = preload("res://data/tuning.tres")
var materials := {}      # matériau -> quantité en stock
var unlocked: Array[String] = [START_CRATE]
var equipped := START_CRATE
var best := 0.0          # record de distance (m)
var turn := 1            # numéro du prochain vol
var won := false         # a-t-on déjà franchi la ligne d'arrivée ?
var won_turn := 0
var last_run := {}       # résultat du dernier vol


func _ready() -> void:
	reset()


func stock(mat: String) -> int:
	return int(materials.get(mat, 0))


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func can_unlock(id: String) -> bool:
	if is_unlocked(id):
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


func equip(id: String) -> void:
	if is_unlocked(id):
		equipped = id


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
	turn += 1
	return last_run


func reset() -> void:
	materials = {}
	unlocked = [START_CRATE]
	equipped = START_CRATE
	best = 0.0
	turn = 1
	won = false
	won_turn = 0
	last_run = {}
