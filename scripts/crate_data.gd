@tool
class_name CrateData
extends Resource
## Une caisse à savon (un fichier .tres dans data/crates/). Les valeurs sont PROVISOIRES.
## Pour en ajouter une : duplique un .tres, ajoute-le à `crates` dans data/tuning.tres,
## puis glisse-le dans une ligne de scenes/atelier.tscn.

## Identifiant interne (sauvegarde, déblocage).
@export var id := ""
@export var nom := ""
@export var desc := ""
## Les trois niveaux ne font que FACILITER le jeu : plus la caisse est haut dans la liste, plus c'est facile.
## Vies : nombre de pièges que le savon peut toucher sans mourir (0 = mort subite, 1 = un seul piège).
@export_range(0, 5) var solidite := 0
## Autonomie : l'énergie des ailes est plus grande (+60 % par point) et s'use beaucoup moins vite (environ 300 m de plus par point).
@export_range(0, 5) var autonomie := 0
## Élan : le savon défile plus vite, donc va plus loin avec la même énergie (+5 % par point au-dessus de 1).
@export_range(1, 4) var poids := 1
## Maniabilité : le savon réagit mieux au jet (gravité -6 %, poussée +5 % par point).
@export_range(0, 5) var maniabilite := 0
## Matériaux nécessaires pour la débloquer : {id du matériau: quantité}. Vide = gratuite.
@export var cost: Dictionary = {}
@export var color := Color.WHITE
## Dessin de la caisse portée par le savon en vol (artwork/sprites/caisse_*.svg).
@export var texture: Texture2D
