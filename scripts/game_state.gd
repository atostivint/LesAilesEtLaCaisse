extends Node
## Mémoire du jeu entre les scènes (autoload "GameState").
## Atelier et Vol sont deux scènes différentes : tout ce qui doit survivre au
## changement de scène (pièces, niveaux, record, n° de tour) vit ici.
##
## Pendant que le jeu tourne, ouvre l'arbre "Distant" (Remote) de l'éditeur :
## GameState > tuning te permet de modifier les réglages EN DIRECT (non sauvegardé !).

var tuning: Tuning = preload("res://data/tuning.tres")
var coins := 0
var levels := {"poussee": 0, "bulles": 0, "ailes": 0, "glisse": 0}
var best := 0.0          # record de distance (m)
var turn := 1            # numéro du prochain vol
var won := false         # a-t-on déjà franchi la porte ?
var won_turn := 0
var last_run := {}       # résultat du dernier vol


func _ready() -> void:
	coins = tuning.start_coins


func stats(lv: Dictionary = levels) -> Dictionary:
	return tuning.stats_for(lv)


func cost(id: String) -> int:
	return tuning.cost_for(levels[id])


func is_maxed(id: String) -> bool:
	return levels[id] >= tuning.max_level


func can_buy(id: String) -> bool:
	return not is_maxed(id) and coins >= cost(id)


func buy(id: String) -> void:
	if can_buy(id):
		coins -= cost(id)
		levels[id] += 1


func apply_result(distance: float, reached_door: bool) -> Dictionary:
	## Appelé à la fin d'un vol : crédite les pièces, met à jour le record, passe au tour suivant.
	var is_record := distance > best
	var gain := tuning.reward_for(distance, is_record, reached_door)
	coins += gain
	if is_record:
		best = distance
	if reached_door and not won:
		won = true
		won_turn = turn
	last_run = {
		"distance": distance, "gain": gain, "record": is_record,
		"door": reached_door, "turn": turn,
	}
	turn += 1
	return last_run


func reset() -> void:
	coins = tuning.start_coins
	levels = {"poussee": 0, "bulles": 0, "ailes": 0, "glisse": 0}
	best = 0.0
	turn = 1
	won = false
	won_turn = 0
	last_run = {}
