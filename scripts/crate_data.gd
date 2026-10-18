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
## Ailes en plus (plumes encaissables).
@export_range(0, 4) var solidite := 1
## Élan : le savon défile plus vite, mais retombe plus vite et monte moins bien.
@export_range(1, 4) var poids := 1
## Matériaux nécessaires pour la débloquer : {id du matériau: quantité}. Vide = gratuite.
@export var cost: Dictionary = {}
@export var color := Color.WHITE
## Dessin de la caisse portée par le savon en vol (artwork/sprites/caisse_*.svg).
@export var texture: Texture2D
