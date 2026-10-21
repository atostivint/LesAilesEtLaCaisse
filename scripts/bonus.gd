extends Area2D
## Un matériau à ramasser. Pour qu'on comprenne qu'il faut le récupérer : halo lumineux qui pulse,
## flottement haut/bas, étincelles, et un petit « +1 » qui s'envole quand on l'attrape.

signal soap_entered(material: MaterialData)

const FONT := preload("res://fonts/COOPBL.TTF")
const HALO_COLOR := Color(1.0, 0.93, 0.35, 0.5)
const BRUN := Color(0.29, 0.165, 0.078, 1)
## Plus grand côté (px) du matériau à l'écran (plus petit que les obstacles, voir level.gd).
const TAILLE := 64.0

var material_data: MaterialData
var _halo: Polygon2D
var _etincelles: CPUParticles2D


func _ready() -> void:
	var centre: Vector2 = $MateriauPapier.position
	# Halo derrière l'icône
	_halo = Polygon2D.new()
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		points.append(Vector2(cos(a), sin(a)) * TAILLE * 0.6)
	_halo.polygon = points
	_halo.color = HALO_COLOR
	_halo.position = centre
	_halo.show_behind_parent = true
	add_child(_halo)
	move_child(_halo, 0)
	# Étincelles autour
	_etincelles = CPUParticles2D.new()
	_etincelles.position = centre
	_etincelles.amount = 8
	_etincelles.lifetime = 0.9
	_etincelles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_etincelles.emission_sphere_radius = TAILLE * 0.45
	_etincelles.gravity = Vector2(0, -30)
	_etincelles.initial_velocity_min = 5.0
	_etincelles.initial_velocity_max = 20.0
	_etincelles.scale_amount_min = 2.0
	_etincelles.scale_amount_max = 4.0
	_etincelles.color = Color(1.0, 0.95, 0.5, 0.9)
	add_child(_etincelles)
	# Pulsation du halo et flottement de l'ensemble
	var pulse := create_tween().set_loops()
	pulse.tween_property(_halo, "scale", Vector2(1.25, 1.25), 0.6).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(_halo, "color:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_halo, "scale", Vector2(0.85, 0.85), 0.6).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(_halo, "color:a", 0.5, 0.6).set_trans(Tween.TRANS_SINE)
	for noeud in [$MateriauPapier, _halo, _etincelles]:
		var base: Vector2 = noeud.position
		var flotte := create_tween().set_loops()
		flotte.tween_property(noeud, "position:y", base.y - 6.0, 0.7).set_trans(Tween.TRANS_SINE)
		flotte.tween_property(noeud, "position:y", base.y + 6.0, 0.7).set_trans(Tween.TRANS_SINE)


func setup(data: MaterialData) -> void:
	material_data = data
	var icone: Sprite2D = $MateriauPapier
	icone.texture = material_data.icone
	# Taille normalisée : le plus grand bord fait TAILLE px, quel que soit le dessin
	if icone.texture != null:
		icone.scale = Vector2.ONE * TAILLE / maxf(icone.texture.get_width(), icone.texture.get_height())
	($CollisionShape2D.shape as CircleShape2D).radius = TAILLE * 0.5 + 8.0


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Soap":
		if material_data == null:
			push_error("Bonus: configure its MaterialData before collecting it.")
			return
		soap_entered.emit(material_data)
		_popup()
		queue_free()


func _popup() -> void:
	## « +1 Bois » qui monte et s'efface à l'endroit du ramassage.
	var parent := get_parent()
	if parent == null:
		return
	var label := Label.new()
	label.text = "+1 %s" % material_data.nom
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.35))
	label.add_theme_color_override("font_outline_color", BRUN)
	label.add_theme_constant_override("outline_size", 10)
	label.position = global_position + Vector2(-20.0, -50.0)
	label.z_index = 20
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.tween_callback(label.queue_free)
