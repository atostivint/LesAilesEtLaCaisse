@tool
class_name MaterialData
extends Resource
## Un matériau ramassé sur les étagères (un fichier .tres dans data/materials/).
## L'apparence de chaque pièce est dans scenes/pickup.tscn (un enfant par id).

@export var id := ""
@export var nom := ""
## Distance (unités internes) à partir de laquelle il apparaît (rareté : 100 / 200 / 300 / 400).
@export var from := 0.0
## Fréquence parmi les matériaux disponibles.
@export var weight := 1.0
## Dessin du matériau (artwork/materiaux/) affiché dans le sac de l'atelier.
@export var icone: Texture2D
