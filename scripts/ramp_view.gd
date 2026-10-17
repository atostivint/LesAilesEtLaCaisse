@tool
extends Node2D
## Aperçu de la piste, VISIBLE DANS L'ÉDITEUR : modifie la section "Piste" de data/tuning.tres
## et la forme se met à jour toute seule. Les nœuds enfants Body (polygone) et TakeoffZone
## (trait rouge = zone de bon décollage) existent dans la scène ; ce script ne fait que
## recalculer leurs points depuis les réglages.

@export var tuning: Tuning = preload("res://data/tuning.tres"):
	set(v):
		if tuning != null and tuning.changed.is_connected(rebuild):
			tuning.changed.disconnect(rebuild)
		tuning = v
		if tuning != null:
			tuning.changed.connect(rebuild)
		rebuild()


func _ready() -> void:
	if tuning != null and not tuning.changed.is_connected(rebuild):
		tuning.changed.connect(rebuild)
	rebuild()


func rebuild() -> void:
	if tuning == null or not is_inside_tree():
		return
	var body := get_node_or_null("Body") as Polygon2D
	var zone := get_node_or_null("TakeoffZone") as Line2D
	# La piste est une courbe : on l'échantillonne en 48 points.
	var n := 48
	var curve := PackedVector2Array()
	for i in n + 1:
		var m := tuning.ramp_point(tuning.ramp_len * i / n)
		curve.append(tuning.to_px(m.x, m.y))
	var start := tuning.ramp_point(0.0)
	var end := tuning.ramp_point(tuning.ramp_len)
	if body != null:
		var poly := PackedVector2Array([tuning.to_px(start.x, 0.0)])
		poly.append_array(curve)
		poly.append(tuning.to_px(end.x, 0.0))
		body.polygon = poly
	if zone != null:
		var zpts := PackedVector2Array()
		var z0 := tuning.ramp_len - tuning.takeoff_window
		for i in 9:
			var m := tuning.ramp_point(z0 + tuning.takeoff_window * i / 8.0)
			zpts.append(tuning.to_px(m.x, m.y))
		zone.points = zpts
