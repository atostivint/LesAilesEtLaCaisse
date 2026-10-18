@tool
extends Node2D
## Le savon du jeu (scène scenes/soap.tscn, avec ses ailes, son regard et sa bouche déjà animés)
## qui court de long en large sur l'étagère du menu, la caisse équipée sur le dos.
## Les bras et les jambes sont dessinés ici, en deux segments (coude et genou pliés, en L),
## attachés au corps, et balancés en alternance. Le corps se penche vers l'avant et rebondit à chaque foulée.
## Unités : celles du Coureur, donc agrandies par `soap_scale`.


## Agrandissement du savon sur le menu (x5 par rapport à la taille de base de la scène).
@export var soap_scale := 5.0
## Vitesse de course, en unités du Coureur par seconde (avant agrandissement).
@export var speed := 60.0
## Limites de la course sur la planche, en pixels de l'écran (le corps fait environ 280 px de large).
@export var left_x := 150.0
@export var right_x := 430.0

const CRATE := preload("res://artwork/sprites/caisse_savon.svg")
## Longueur des segments (unités du Coureur) : cuisse puis mollet, bras puis avant-bras.
const THIGH := 6.5
const SHIN := 6.5
const UPPER_ARM := 6.0
const FOREARM := 6.0
## Hauteur des hanches au-dessus de la planche : jambes tendues + demi-hauteur du corps.
const LEG := THIGH + SHIN
const BODY_HALF_H := 16.8
## Les hanches sont posées sur le bas du rectangle du corps (0 = exactement sur le bord).
const HIP_INSIDE := 0.0
## Les épaules sont placées à l'intérieur du corps, pour que les bras restent collés.
const HIP_X := 12.0
const SHOULDER_X := 22.0
const SHOULDER_INSIDE := 10.0
## Inclinaison du corps vers l'avant (radians), dans le sens de la course.
const LEAN := 0.12
const OUTLINE := Color(0.29, 0.165, 0.078, 1)
const LIMB := Color(0.25, 0.55, 0.85, 1)
const SPEED_LINE := Color(1, 1, 1, 0.6)

var _dir := 1.0
var _phase := 0.0
var _bob := 0.0
var _limbs: Node2D

@onready var soap: Soap = $Savon


func _ready() -> void:
	# Dans l'éditeur, le script du savon ne tourne pas : on laisse le savon tel quel
	if Engine.is_editor_hint():
		return
	soap.set_crate_texture(CRATE)
	Personnage.appliquer_choisi(soap)
	soap.thrusting = true
	# Les membres sont dessinés dans un enfant placé après le savon : ils passent devant le corps
	_limbs = Node2D.new()
	add_child(_limbs)
	_limbs.draw.connect(_draw_limbs)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Aller-retour sur la planche
	position.x += _dir * speed * soap_scale * delta
	if position.x >= right_x:
		position.x = right_x
		_dir = -1.0
	elif position.x <= left_x:
		position.x = left_x
		_dir = 1.0
	# Pas de miroir : le savon et son texte restent toujours à l'endroit, seule la course change de sens
	scale = Vector2(soap_scale, soap_scale)
	# Cadence de foulée proportionnelle à la vitesse
	_phase += delta * speed * 0.12
	# Rebond à chaque demi-foulée, corps penché vers l'avant
	_bob = absf(sin(_phase)) * 2.0
	soap.position = Vector2(0.0, -(LEG + BODY_HALF_H) - _bob)
	soap.rotation = (LEAN + sin(_phase * 2.0) * 0.03) * _dir
	_limbs.queue_redraw()


func _draw_limbs() -> void:
	var hip_y := -LEG + HIP_INSIDE - _bob
	var shoulder_y := -LEG - SHOULDER_INSIDE - _bob
	# Lignes de vitesse derrière le savon (du côté opposé à la course)
	for i in 3:
		var y := -10.0 - i * 14.0
		var length := 14.0 + 6.0 * sin(_phase + i)
		var x := -40.0 * _dir
		_limbs.draw_line(Vector2(x, y), Vector2(x - length * _dir, y), SPEED_LINE, 1.0)
	for side in [-1.0, 1.0]:
		var step: float = _phase + (0.0 if side < 0.0 else PI)
		# Jambe en L : la cuisse se balance, le mollet se plie vers l'arrière, plus fort quand le pied se lève
		var thigh_angle := sin(step) * 0.7
		var knee_bend := 0.9 + 0.5 * maxf(0.0, cos(step))
		var hip := _attach(Vector2(HIP_X * side, hip_y))
		var knee := hip + _dir_of(thigh_angle) * THIGH
		var foot := knee + _dir_of(thigh_angle - knee_bend) * SHIN
		_draw_jointed(hip, knee, foot)
		# Bras en L : le coude se plie vers l'avant, en opposition à la jambe du même côté
		var arm_angle := sin(step + PI) * 1.0
		var elbow_bend := 1.2
		var shoulder := _attach(Vector2(SHOULDER_X * side, shoulder_y))
		var elbow := shoulder + _dir_of(arm_angle) * UPPER_ARM
		var hand := elbow + _dir_of(arm_angle + elbow_bend) * FOREARM
		_draw_jointed(shoulder, elbow, hand)


# Suit la rotation du corps : un point d'attache reste collé au corps quand il s'incline
func _attach(point: Vector2) -> Vector2:
	var pivot := soap.position
	return pivot + (point - pivot).rotated(soap.rotation)


func _dir_of(angle: float) -> Vector2:
	# Angle mesuré depuis la verticale vers le bas
	# Miroir selon le sens de la course : jambes et bras se retournent quand le savon repart à gauche
	return Vector2(sin(angle) * _dir, cos(angle))


func _draw_jointed(a: Vector2, b: Vector2, c: Vector2) -> void:
	_limbs.draw_polyline(PackedVector2Array([a, b, c]), OUTLINE, 2.4)
	_limbs.draw_polyline(PackedVector2Array([a, b, c]), LIMB, 1.1)
