extends Node2D
## Le vol. Le parcours alterne deux types de phases (jamais en même temps) :
##  - une phase OBSTACLES : des pièges de toutes sortes (sprites du dossier artwork/sprites/obstacle_*),
##  - une phase RAMPES : des étagères sur lesquelles on glisse pour recharger l'énergie.
## Tout est généré en fonction de la distance parcourue par la caméra.

## Vitesse de croisière (px/s = valeur / 60) : ralentie pour bien voir les obstacles.
@export var cruise_speed = 42000
@export var gravity = 2000
@export var jet_thrust = 4000

@onready var soap = $Soap
@onready var cam = $Camera2D
@onready var carrelage: Control = $Carrelage
@onready var flight_energy_bar: ProgressBar = %FlightEnergy
@onready var start_prompt: Label = %StartPrompt

var game_started := false
var tuning: Tuning

## Vitesse de défilement du carrelage, en part de la vitesse du savon : 0 = fixe à l'écran, 1 = fixe dans le monde.
## Plus c'est bas, moins ça scintille (confort visuel).
@export_range(0.0, 1.0, 0.05) var bg_parallax := 0.15

@export_group("Phases")
## Distance (px) avant la première phase : le temps de prendre ses marques après la propulsion de départ.
@export var premiere_phase_x := 2300.0
## Longueur (px) d'une phase d'obstacles.
@export var phase_obstacles_longueur := 4500.0
## Longueur (px) d'une phase de rampes.
@export var phase_rampes_longueur := 3200.0
## Espace vide (px) entre deux phases.
@export var transition := 450.0

@export_group("Obstacles")
## Distance (px) entre deux groupes d'obstacles : min et max.
@export var ecart_obstacles := Vector2(760.0, 980.0)
## Chance (0-1) qu'un matériau à ramasser apparaisse entre deux groupes.
@export_range(0, 1, 0.05) var bonus_spawn_proba := 0.5

@export_group("Étagères")
## Écart horizontal (px) entre deux étagères : min et max.
@export var shelf_gap := Vector2(900.0, 1250.0)
## Hauteur (px) du pied de l'étagère : hauteur variable (milieu à bas de l'écran) : on peut rater une rampe.
@export var shelf_y_range := Vector2(330.0, 600.0)

const SOAP_ECRAN_X := 0.12 # position du savon à l'écran : tout à gauche, pour voir loin devant
const ZOOM_VUE := 0.88 # la caméra dézoome un peu : on voit environ 14 % de décor en plus devant le savon
const ZONE_HAUT := 145.0 # bas du plafond
const ZONE_BAS := 776.0 # haut du sol

const OBSTACLES := [
	{"tex": preload("res://artwork/sprites/obstacle_distributeur_savon.svg"), "echelle": 0.30, "mode": "libre"},
	{"tex": preload("res://artwork/sprites/obstacle_torchon.svg"), "echelle": 0.30, "mode": "libre"},
	{"tex": preload("res://artwork/sprites/obstacle_fleur_de_douche.svg"), "echelle": 0.17, "mode": "libre", "facteur": 1.5},
	{"tex": preload("res://artwork/sprites/obstacle_attrape_mouche.svg"), "echelle": 0.18, "mode": "plafond", "largeur": 1.7},
	{"tex": preload("res://artwork/sprites/obstacle_porte_serviette.svg"), "echelle": 0.16, "mode": "plafond", "largeur": 1.7},
]
const TRAP_SCRIPT := preload("res://scripts/trap.gd")
## Plus grand côté (px) des obstacles « libres » (les matériaux sont plus petits : bonus.gd, TAILLE).
const TAILLE_OBJET := 100.0
## Effet de la caisse : vitesse en plus et gravité en plus par point de poids au-dessus de 1, énergie en plus par point d'ailes.
## Chaque caisse facilite le jeu (voir crate_data.gd) : élan, autonomie et maniabilité ne pénalisent jamais.
const POIDS_VITESSE := 0.05
const MANIABILITE_GRAVITE := 0.06
const MANIABILITE_POUSSEE := 0.05
## Endurance totale de la caisse (selon son autonomie, 0 à 5), sans étagère : chaque nouvelle caisse permet environ 300 m de plus
## (170, 470, 770, 1070, 1370, 1670 m, mesurés avec un bot). En attrapant quelques étagères (~30 %) : 450 m de plus par caisse ;
## presque la moitié d'entre elles : 550 m de plus. La table compense l'élan et la maniabilité des meilleures caisses.
## La caisse carton (rang 2) est volontairement en retrait (5,0 au lieu de 5,5) : Tripoli (1500 m) doit rester très difficile sans la baignoire.
const ENDURANCE := [1.0, 3.5, 5.0, 7.5, 8.9, 10.4]
## Distances de jeu (m) : une tortue tous les 500 m, la ligne d'arrivée (score excellent) à 2000 m.
const PAS_TORTUE_M := 500.0
const ARRIVEE_M := 2000.0
const AILES_ENERGIE := 0.6 # +60 % d'énergie par point d'autonomie (la dernière caisse a 3,4 fois l'énergie de départ)
## Halo rouge pulsant derrière chaque piège : taille (par rapport au dessin) et opacité maximale
const HALO_ECHELLE := 1.14
const HALO_ALPHA := 0.85
const HITBOX :=0.6 # part du sprite qui blesse (plus gentil que le rectangle entier)

var BONUS = preload("res://scenes/bonus.tscn")
var SHELF_SCENE = preload("res://scenes/shelf.tscn")
const SHELF_ROTATION := -0.05 # légère descente (vers le bas à droite) : on glisse pour recharger les ailes
const SHELF_SCALE := 1.2

const SCORES := {"excellent": "res://scenes/score_excellent.tscn", "bon": "res://scenes/score_bon.tscn", "moyen": "res://scenes/score_moyen.tscn", "mauvais": "res://scenes/score_mauvais.tscn", "catastrophe": "res://scenes/score_catastrophe.tscn"}

const MOULURE_PERIOD := 720.0 # plus petit multiple commun des motifs de moulure_plafond.gd
var _moulures: Control
var _moulure_shift := 0.0
var _start_x := 0.0 # position x du savon au départ : la distance du vol en découle
var _collected := {} # matériaux ramassés pendant le vol (confiés à GameState à la fin)
var _termine := false # vrai dès la fin du vol : évite de changer de scène deux fois (deux pièges touchés le même frame)

## Tortues : une tous les 1000 m, avec son drapeau (4 couleurs qui se répètent). Leur carapace fait glisser
## et recharger l'énergie, comme les étagères.
const TORTUES := [
	preload("res://artwork/sprites/tortue_1.svg"),
	preload("res://artwork/sprites/tortue_2.svg"),
	preload("res://artwork/sprites/tortue_3.svg"),
	preload("res://artwork/sprites/tortue_4.svg"),
]
## Couleur du drapeau de chaque tortue (même ordre que TORTUES) : jaune, rouge, rose, bleu clair.
const COULEURS_DRAPEAU := [Color("FBD022"), Color("E5452A"), Color("F9ABBB"), Color("64C9EB")]
## Plus petite que le canard (qui mesure environ 390 px de haut) : environ 200 px.
const TORTUE_ECHELLE := 0.4
## Dessus de la carapace dans le repère du dessin de la tortue (660 x 500 px).
const TORTUE_DOS := [52, 362, 70, 280, 115, 215, 180, 195, 240, 185, 295, 205, 320, 255, 335, 290, 330, 315, 315, 330, 200, 370]
const FONT_TORTUE := preload("res://fonts/COOPBL.TTF")
var _num_tortue := 1 # numéro de la prochaine tortue (1 = 1000 m)
const EQUIPES_SCRIPT := preload("res://scripts/equipes.gd")
const SOAP_SCENE := preload("res://scenes/soap.tscn")
const TUTO := preload("res://scripts/tuto.gd")
var _tuto_ouvert := false
var _palier_annonce := 1 # prochain palier de 1000 m à annoncer au passage de la tortue
## Mécaniques de distance : le jeu se durcit avec les kilomètres, la tortue est le moment de répit.
const VITESSE_PAR_KM := 0.06 # défilement en plus par kilomètre déjà passé
const VITESSE_KM_MAX := 5.0 # au-delà, la vitesse de base ne monte plus
const VITESSE_DANS_KM := 0.08 # accélération supplémentaire au fil d'un kilomètre (retombe à la tortue)
const ECART_MIN := 1.0 # facteur minimum sur l'écart entre obstacles
const ECART_KM_MAX := 4.0 # kilomètres pour atteindre cet écart minimum
var _vitesse_base := 0.0
var _vies := 0 # pièges encaissables restants (caisse équipée : 0 = mort subite)
var _invulnerable := false
var _vies_max := 0 # nombre de vies au départ (= nombre d'ailes affichées)
var _vies_boite: HBoxContainer # rangée d'ailes : une aile = une vie
var _mat_labels := {} # id du matériau -> Label du compteur (au niveau de l'eau)
var _mat_cartes := {} # id du matériau -> carte (pour l'animer quand on en ramasse un)
var _mat_boite: HBoxContainer
var _tortue_icone: TextureRect # tortue du prochain palier (en bas à droite)
var _tortue_label: Label
const AILE_HUD := preload("res://artwork/sprites/aile_gauche.svg")
var _record_depart := 0.0 # record au début du vol : sert à savoir si un savon est nouvellement débloqué
var _zone_libre_debut := -1.0 # plage x sans obstacle ni étagère autour de la dernière tortue
var _zone_libre_fin := -1.0
const EAU_SAVON := preload("res://scripts/eau_savon.gd")
var _eau_sol: Control
var _distance_label: Label
var _phase_obstacles := true # phase en cours : obstacles ou rampes
var _next_x := 0.0 # prochaine position (monde) où générer quelque chose
var _phase_fin_x := 0.0


func _ready() -> void:
	Musique.jouer_piste(Musique.PISTE_COURSE)
	tuning = GameState.tuning
	soap.set_crate_texture(tuning.crate(GameState.equipped).texture)
	Personnage.appliquer_choisi(soap)
	# Caractéristiques de la caisse équipée : le poids donne de l'élan (plus de distance, donc un meilleur score)
	# mais le savon retombe plus vite ; les ailes (solidité) allongent l'autonomie du jet.
	var caisse := tuning.crate(id_caisse)
	_vitesse_base = cruise_speed * (1.0 + POIDS_VITESSE * (caisse.poids - 1))
	soap.cruise_speed = _vitesse_base
	soap.gravity = gravity * (1.0 - MANIABILITE_GRAVITE * caisse.maniabilite)
	soap.jet_thrust = jet_thrust * (1.0 + MANIABILITE_POUSSEE * caisse.maniabilite)
	soap.max_flight_energy *= 1.0 + AILES_ENERGIE * caisse.autonomie
	# L'énergie s'use et se recharge moins vite pour que l'endurance totale suive la table ENDURANCE
	var facteur_usure: float = ENDURANCE[clampi(caisse.autonomie, 0, ENDURANCE.size() - 1)] / (1.0 + AILES_ENERGIE * caisse.autonomie)
	soap.energy_drain_per_second /= facteur_usure
	soap.energy_recharge_per_second /= facteur_usure
	_vies = caisse.solidite
	_vies_max = caisse.solidite
	soap.flight_energy = soap.max_flight_energy
	_start_x = soap.global_position.x
	_record_depart = GameState.best
	flight_energy_bar.max_value = soap.max_flight_energy
	flight_energy_bar.value = soap.flight_energy
	_next_x = premiere_phase_x
	_phase_fin_x = _next_x + phase_obstacles_longueur
	# Le niveau se met à jour après le savon : la caméra suit sa position de l'image en cours (pas de décalage)
	process_physics_priority = 10
	cam.zoom = Vector2.ONE * ZOOM_VUE
	cam.position.x = soap.global_position.x + _decalage_camera()
	_preparer_canard()
	if not GameState.tuto_vu:
		_afficher_tuto()
	get_viewport().size_changed.connect(_fit_to_view)
	_fit_to_view()


func _afficher_tuto() -> void:
	## Première partie : tutoriel de 3 slides avant de pouvoir lancer le savon (il ne s'affiche qu'une fois par partie).
	_tuto_ouvert = true
	start_prompt.hide()
	var tuto := TUTO.new()
	tuto.termine.connect(func():
		_tuto_ouvert = false
		start_prompt.show()
		GameState.tuto_vu = true
		GameState.save_game())
	add_child(tuto)


func _preparer_canard() -> void:
	## Le dos du canard devient la ligne de glissade du savon : on la donne au savon (métadonnée « ride »).
	var canard: StaticBody2D = $Canard
	var dos: PackedVector2Array = canard.get_node("Dos").polygon
	var ligne := PackedVector2Array()
	for i in range(1, 15): # points du dessus : de la tête au bout de la queue
		ligne.append(canard.to_global(dos[i]))
	canard.set_meta("ride", ligne)


func _input(event: InputEvent) -> void:
	# Un clic sur le bouton Menu ne lance pas le vol
	if event is InputEventMouseButton and $HUD/BoutonMenu.get_global_rect().has_point(event.position):
		return
	if not game_started and not _tuto_ouvert and event.is_action_pressed("thrust"):
		_start_game()


func _start_game() -> void:
	if game_started:
		return
	game_started = true
	soap.start_flight($Canard.get_meta("ride"))
	start_prompt.hide()
	_maj_compteur()
	_maj_vies()
	_creer_distance()


func _creer_distance() -> void:
	## Compteur de distance en mètres (une tortue tous les 1000 m ; les savons se débloquent à 1000, 2000, 3000 m).
	_distance_label = Label.new()
	_distance_label.position = Vector2(17.0, 72.0)
	_distance_label.add_theme_font_size_override("font_size", 28)
	_distance_label.add_theme_color_override("font_color", Color(0.984, 0.941, 0.839))
	_distance_label.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.078))
	_distance_label.add_theme_constant_override("outline_size", 12)
	$HUD.add_child(_distance_label)
	_creer_tortue_hud()


func _distance_unites() -> float:
	## Distance parcourue depuis le départ, en unités internes (px / ppm), comme GameState.best.
	return maxf(0.0, soap.global_position.x - _start_x) / tuning.ppm


func _process(_delta: float) -> void:
	flight_energy_bar.value = soap.flight_energy
	if _distance_label:
		var metres := tuning.metres(_distance_unites())
		_distance_label.text = "Distance : %d m" % int(metres)
		_maj_tortue_hud(metres)
		# Une tortue franchie = un palier de 1000 m : annonce (et nouveau savon si c'est un record)
		if metres >= _palier_annonce * PAS_TORTUE_M:
			_annoncer_palier(_palier_annonce)
			_teinter_carrelage(_palier_annonce)
			_palier_annonce += 1


func _teinter_carrelage(numero: int) -> void:
	## Le carrelage de fond prend en douceur la couleur du drapeau de la tortue qu'on vient de passer.
	var couleur: Color = COULEURS_DRAPEAU[(numero - 1) % COULEURS_DRAPEAU.size()]
	create_tween().tween_property(carrelage, "teinte", couleur, 1.0)


func _progression() -> float:
	## Difficulté de la distance, en « paliers » de 1000 m : la partie entière = tortues passées, la partie
	## décimale = avancement vers la prochaine. Elle sert à accélérer le défilement et à resserrer les obstacles.
	return tuning.metres(_distance_unites()) / 1000.0


func _facteur_vitesse() -> float:
	## Dents de scie : le défilement accélère au fil du kilomètre, retombe un peu à la tortue (on souffle),
	## et chaque kilomètre repart plus vite que le précédent (plafonné).
	var p := _progression()
	var km := minf(floorf(p), VITESSE_KM_MAX)
	return 1.0 + VITESSE_PAR_KM * km + VITESSE_DANS_KM * fmod(p, 1.0)


## Les tortues se voient mieux : le défilement ralentit en les approchant (jusqu'à RALENTI_MIN), puis repart.
const RALENTI_AVANT_M := 250.0 # distance (m) avant la tortue où le ralentissement commence
const RALENTI_APRES_M := 100.0 # distance (m) après la tortue pour retrouver la vitesse normale
const RALENTI_MIN := 0.65 # vitesse au niveau de la tortue (1 = normale)
const ANNONCE_TORTUE_M := 120.0 # le bandeau « tortue » apparaît à cette distance
var _tortue_annoncee := 0 # numéro de la dernière tortue annoncée par le bandeau


func _facteur_tortue() -> float:
	var metres := tuning.metres(_distance_unites())
	var avant := _palier_annonce * PAS_TORTUE_M - metres # distance jusqu'à la prochaine tortue
	var f := lerpf(RALENTI_MIN, 1.0, smoothstep(0.0, 1.0, clampf(avant / RALENTI_AVANT_M, 0.0, 1.0)))
	if _palier_annonce > 1:
		var apres := metres - (_palier_annonce - 1) * PAS_TORTUE_M # distance depuis la dernière tortue
		f = minf(f, lerpf(RALENTI_MIN, 1.0, smoothstep(0.0, 1.0, clampf(apres / RALENTI_APRES_M, 0.0, 1.0))))
	return f


func _annoncer_tortue_proche(numero: int) -> void:
	## Bandeau au-dessus de l'écran quand une tortue approche : « Tortue 500 m dans 120 m ! »
	var bandeau := Label.new()
	bandeau.text = "Tortue %d m dans %d m !" % [int(numero * PAS_TORTUE_M), int(ANNONCE_TORTUE_M)]
	bandeau.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bandeau.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	bandeau.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bandeau.offset_top = 90.0
	bandeau.add_theme_font_override("font", FONT_TORTUE)
	bandeau.add_theme_font_size_override("font_size", 38)
	bandeau.add_theme_color_override("font_color", Color(0.99, 0.76, 0.12))
	bandeau.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.078))
	bandeau.add_theme_constant_override("outline_size", 10)
	$HUD.add_child(bandeau)
	var tween := create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(bandeau, "modulate:a", 0.0, 0.5)
	tween.tween_callback(bandeau.queue_free)


func _facteur_ecart() -> float:
	## Écart entre les obstacles : de 1 au départ à ECART_MIN après quelques kilomètres.
	return lerpf(1.0, ECART_MIN, clampf(_progression() / ECART_KM_MAX, 0.0, 1.0))


func _annoncer_palier(numero: int) -> void:
	## Bandeau au passage de la tortue n° `numero` : « 1000 m ! », avec le savon débloqué s'il est nouveau.
	var texte := "%d m !" % int(numero * PAS_TORTUE_M)
	var equipes: Array = EQUIPES_SCRIPT.EQUIPES
	var equipe := _equipe_de_la_tortue(numero)
	if equipe >= 0 and tuning.metres(_record_depart) < numero * PAS_TORTUE_M:
		texte += "\nNouveau savon débloqué : %s" % equipes[equipe]["nom"]
	var bandeau := Label.new()
	bandeau.text = texte
	bandeau.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bandeau.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	bandeau.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bandeau.offset_top = 220.0
	bandeau.add_theme_font_override("font", FONT_TORTUE)
	bandeau.add_theme_font_size_override("font_size", 46)
	bandeau.add_theme_color_override("font_color", Color(0.984, 0.941, 0.839))
	bandeau.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.078))
	bandeau.add_theme_constant_override("outline_size", 12)
	bandeau.pivot_offset = bandeau.size * 0.5
	$HUD.add_child(bandeau)
	var tween := create_tween()
	tween.tween_property(bandeau, "scale", Vector2.ONE * 1.15, 0.12)
	tween.tween_property(bandeau, "scale", Vector2.ONE, 0.12)
	tween.tween_interval(2.2)
	tween.tween_property(bandeau, "modulate:a", 0.0, 0.5)
	tween.tween_callback(bandeau.queue_free)


func _decalage_camera() -> float:
	## Écart entre le centre de la caméra et le savon pour que le savon soit aux 2/5 de l'écran en partant de la gauche.
	return get_viewport_rect().size.x / cam.zoom.x * (0.5 - SOAP_ECRAN_X)


func _physics_process(delta: float) -> void:
	if not game_started:
		return
	# La caméra reste collée au savon : il ne bouge jamais à l'écran en x (seulement en haut et en bas),
	# c'est le décor qui défile. Même si le savon ralentit sur une rampe, il ne sort pas de l'écran.
	var avant: float = cam.position.x
	soap.cruise_speed = _vitesse_base * _facteur_vitesse() * _facteur_tortue()
	if _tortue_annoncee < _palier_annonce and _palier_annonce * PAS_TORTUE_M - tuning.metres(_distance_unites()) <= ANNONCE_TORTUE_M:
		_tortue_annoncee = _palier_annonce
		_annoncer_tortue_proche(_palier_annonce)
	cam.position.x = soap.global_position.x + _decalage_camera()
	var dx: float = cam.position.x - avant
	carrelage.position.x += dx * (1.0 - bg_parallax)
	%Ceiling.position.x += dx
	%Ground.position.x += dx
	# Les moulures glissent à contre-sens de la caméra, comme le carrelage (même parallaxe)
	_moulure_shift -= dx * bg_parallax
	_place_moulures()
	_generer_parcours()
	_nettoyer_derriere()


func _fit_to_view() -> void:
	## Plafond, sol et moulures couvrent toute la zone visible (la fenêtre peut être plus large ou plus haute
	## que 1456x819 : le contenu est étendu, jamais étiré).
	var view: Vector2 = get_viewport_rect().size / cam.zoom.x # zone visible dans le monde (la caméra est dézoomée)
	var half_w := view.x * 0.5 + 40.0
	var left: float = cam.position.x - half_w
	var w := half_w * 2.0
	var top: float = cam.position.y - view.y * 0.5 - 10.0
	var bottom: float = cam.position.y + view.y * 0.5 + 10.0

	var ceiling: StaticBody2D = %Ceiling
	ceiling.scale = Vector2.ONE
	ceiling.position = Vector2(left, 0.0)
	var c_top := minf(-2.0, top)
	ceiling.get_node("Polygon2D").polygon = PackedVector2Array([Vector2(0, c_top), Vector2(0, 145), Vector2(w, 145), Vector2(w, c_top)])
	var c_shape: CollisionShape2D = ceiling.get_node("CollisionShape2D")
	c_shape.shape = RectangleShape2D.new()
	c_shape.shape.size = Vector2(w, 145.0 - c_top)
	c_shape.position = Vector2(w * 0.5, (145.0 + c_top) * 0.5)
	_moulures = ceiling.get_node("Moulures")
	_moulures.size = Vector2(w + 2.0 * MOULURE_PERIOD, 145.0)
	_place_moulures()

	var ground: Area2D = %Ground
	ground.scale = Vector2.ONE
	ground.position = Vector2(left, 776.0)
	var g_bottom := maxf(83.0, bottom - 776.0)
	ground.get_node("Polygon2D").polygon = PackedVector2Array([Vector2(0, -2), Vector2(0, g_bottom), Vector2(w, g_bottom), Vector2(w, -2)])
	var g_shape: CollisionShape2D = ground.get_node("CollisionShape2D")
	g_shape.shape = RectangleShape2D.new()
	g_shape.shape.size = Vector2(w, g_bottom + 2.0)
	g_shape.position = Vector2(w * 0.5, (g_bottom - 2.0) * 0.5)
	# Le sol est de l'eau savonneuse (vagues et bulles de mousse, comme sur les écrans de score)
	ground.get_node("Polygon2D").visible = false
	if _eau_sol == null:
		_eau_sol = Control.new()
		_eau_sol.set_script(EAU_SAVON)
		_eau_sol.couleur = Color(0.2, 0.45, 0.85, 1)
		_eau_sol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ground.add_child(_eau_sol)
	_eau_sol.position = Vector2(0.0, -16.0)
	_eau_sol.size = Vector2(w, g_bottom + 16.0)


func _place_moulures() -> void:
	if _moulures:
		_moulures.position = Vector2(-MOULURE_PERIOD + fposmod(_moulure_shift, MOULURE_PERIOD), -2.0)


# --- Parcours : phases obstacles / rampes -----------------------------------------

func _generer_parcours() -> void:
	## Génère devant la caméra, une phase après l'autre : obstacles seuls, puis rampes seules, etc.
	_placer_tortue()
	while cam.position.x + 1000.0 >= _next_x:
		if _next_x >= _zone_libre_debut and _next_x < _zone_libre_fin:
			_next_x = _zone_libre_fin
			continue
		if _next_x >= _phase_fin_x:
			_phase_obstacles = not _phase_obstacles
			_next_x += transition
			_phase_fin_x = _next_x + (phase_obstacles_longueur if _phase_obstacles else phase_rampes_longueur)
			continue
		if _phase_obstacles:
			_groupe_obstacles(_next_x)
			_next_x += randf_range(ecart_obstacles.x, ecart_obstacles.y) * _facteur_ecart()
		else:
			_spawn_shelf(_next_x)
			_next_x += randf_range(shelf_gap.x, shelf_gap.y)


func _placer_tortue() -> void:
	## Une tortue tous les 1000 m (distance affichée) : elle apparaît bien avant d'être à l'écran.
	var km_px := PAS_TORTUE_M * 100.0 / tuning.display_cm_per_unit * tuning.ppm
	var marque := _start_x + _num_tortue * km_px
	if cam.position.x + 2400.0 < marque:
		return
	_spawn_tortue(marque, _num_tortue)
	_zone_libre_debut = marque - 700.0
	_zone_libre_fin = marque + 500.0 * TORTUE_ECHELLE + 700.0
	_num_tortue += 1


func _spawn_tortue(x: float, numero: int) -> void:
	var tortue := StaticBody2D.new()
	# Posée sur l'eau savonneuse : le bas du dessin trempe un peu dans la surface (ZONE_BAS)
	tortue.position = Vector2(x, ZONE_BAS + 12.0 - 500.0 * TORTUE_ECHELLE)
	tortue.scale = Vector2.ONE * TORTUE_ECHELLE
	tortue.add_to_group("shelves") # on glisse sur sa carapace et l'énergie se recharge
	tortue.set_meta("glide_boost", 1.0)
	tortue.set_meta("rebond", 520.0) # la carapace finit près de l'eau : fort rebond pour ne pas y retomber
	tortue.set_meta("recharge_part", 0.1) # moment de répit : toucher la carapace remplit les ailes
	# Halo doré pulsant derrière la tortue : on la repère de loin
	var halo := Polygon2D.new()
	var contour_halo := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		contour_halo.append(Vector2(330.0 + cos(a) * 400.0, 250.0 + sin(a) * 320.0))
	halo.polygon = contour_halo
	halo.color = Color(1.0, 0.93, 0.35, 0.4)
	tortue.add_child(halo)
	var image := Sprite2D.new()
	image.texture = TORTUES[(numero - 1) % TORTUES.size()]
	image.centered = false
	tortue.add_child(image)
	var dos := CollisionPolygon2D.new()
	var contour := PackedVector2Array()
	for i in TORTUE_DOS.size() / 2:
		contour.append(Vector2(TORTUE_DOS[i * 2], TORTUE_DOS[i * 2 + 1]))
	dos.polygon = contour
	tortue.add_child(dos)
	# Ligne de glissade : le dessus de la carapace, de gauche à droite
	var ligne := PackedVector2Array()
	for i in 8:
		ligne.append(tortue.transform * Vector2(TORTUE_DOS[i * 2], TORTUE_DOS[i * 2 + 1]))
	tortue.set_meta("ride", ligne)
	# Distance écrite sur le drapeau
	var etiquette := Label.new()
	etiquette.text = "%d m" % int(numero * PAS_TORTUE_M)
	etiquette.position = Vector2(448.0, 72.0)
	etiquette.add_theme_font_override("font", FONT_TORTUE)
	etiquette.add_theme_font_size_override("font_size", 80) # la tortue est réduite : le texte reste lisible
	etiquette.add_theme_color_override("font_color", Color(0.984, 0.941, 0.839, 1))
	etiquette.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.078, 1))
	etiquette.add_theme_constant_override("outline_size", 12)
	tortue.add_child(etiquette)
	add_child(tortue) # d'abord dans l'arbre : le savon d'équipe a besoin de ses nœuds prêts (@onready)
	_poser_savon_equipe(tortue, numero)
	var pulse_halo := halo.create_tween().set_loops()
	pulse_halo.tween_property(halo, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	pulse_halo.tween_property(halo, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _equipe_de_la_tortue(numero: int) -> int:
	## Index de l'équipe qui se débloque à la distance de cette tortue (seuil des équipes), -1 s'il n'y en a pas.
	## Seuils : Alep 500 m (caisse cercueil), Tripoli 1500 m (caisse baignoire), Castille 2500 m (dernière caisse).
	var equipes: Array = EQUIPES_SCRIPT.EQUIPES
	for i in equipes.size():
		if int(equipes[i]["seuil"]) > 0 and is_equal_approx(float(equipes[i]["seuil"]), numero * PAS_TORTUE_M):
			return i
	return -1


func _poser_savon_equipe(tortue: Node2D, numero: int) -> void:
	## La tortue qui marque le seuil d'une équipe porte son savon (500 m = Alep, 1500 m = Tripoli, 2500 m = Castille).
	## Les autres tortues n'ont pas de savon.
	var equipes: Array = EQUIPES_SCRIPT.EQUIPES
	var equipe := _equipe_de_la_tortue(numero)
	if equipe < 0:
		return
	var savon: Soap = SOAP_SCENE.instantiate()
	savon.name = "SavonEquipe" # pas « Soap » : les pièges et l'eau réagissent à ce nom
	savon.collision_layer = 0
	savon.collision_mask = 0
	savon.set_physics_process(false)
	savon.scale = Vector2.ONE * 1.8 # la tortue est réduite (TORTUE_ECHELLE) : on compense
	savon.position = Vector2(215.0, 95.0)
	tortue.add_child(savon) # dans l'arbre avant d'appliquer l'apparence (ses @onready doivent être prêts)
	Personnage.appliquer(savon, equipes[equipe]["visage"], Personnage.COULEURS[equipe % Personnage.COULEURS.size()])
	savon.wings_player.play("flap")
	var nom := Label.new()
	nom.text = equipes[equipe]["nom"]
	nom.position = Vector2(100.0, -70.0)
	nom.add_theme_font_override("font", FONT_TORTUE)
	nom.add_theme_font_size_override("font_size", 70)
	nom.add_theme_color_override("font_color", Color(0.99, 0.76, 0.12))
	nom.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.078))
	nom.add_theme_constant_override("outline_size", 12)
	tortue.add_child(nom)


func _groupe_obstacles(x: float) -> void:
	## Un groupe : un obstacle au plafond, un obstacle en l'air, ou un duo haut + bas avec un passage au milieu.
	# Pas de duo haut + bas pendant le premier kilomètre : le début est lisible, la difficulté monte ensuite
	var p_duo := clampf(_progression() * 0.35, 0.0, 0.35)
	var tirage := randf() * 0.65 # obstacle seul : 0-0,3 au plafond, 0,3-0,65 en l'air
	if randf() < p_duo:
		tirage = 0.9 # duo
	if tirage < 0.3:
		_spawn_obstacle(_choisir("plafond"), x)
	elif tirage < 0.65:
		_spawn_obstacle(_choisir("libre"), x)
	else:
		var haut: Dictionary = _choisir("libre")
		var bas: Dictionary = _choisir("libre")
		var h_haut: float = haut["tex"].get_height() * _echelle(haut)
		var h_bas: float = bas["tex"].get_height() * _echelle(bas)
		var y_haut := ZONE_HAUT + 30.0 + randf_range(0.0, 80.0) + h_haut * 0.5
		var bord_bas := minf(ZONE_BAS - 10.0, ZONE_BAS - 30.0 - randf_range(0.0, 60.0))
		var y_bas := bord_bas - h_bas * 0.5
		# Passage garanti d'au moins 190 px entre les deux
		if (y_bas - h_bas * 0.5) - (y_haut + h_haut * 0.5) >= 190.0:
			_spawn_obstacle(haut, x, y_haut)
			_spawn_obstacle(bas, x + 140.0, y_bas)
		else:
			_spawn_obstacle(_choisir("libre"), x)
	if randf() < bonus_spawn_proba:
		# Une petite traînée de 1 à 3 matériaux en arc : plus de choses à attraper, moins d'ennui entre deux obstacles
		var bx := x + randf_range(ecart_obstacles.x, ecart_obstacles.y) * 0.5
		var by := randf_range(300.0, 600.0)
		for i in randi_range(1, 2):
			_spawn_bonus(bx + i * 90.0, by - sin(i * 0.9) * 60.0)


func _choisir(mode: String) -> Dictionary:
	var candidats := OBSTACLES.filter(func(o): return o["mode"] == mode)
	return candidats.pick_random()


func _echelle(def: Dictionary) -> float:
	## Les obstacles libres ont la même taille que les matériaux (TAILLE_OBJET) ; ceux du plafond gardent leur échelle (ils sont longs).
	if def["mode"] == "libre":
		var taille: Vector2 = def["tex"].get_size()
		# « facteur » : certains pièges (la fleur de douche violette) sont encore plus gros
		return TAILLE_OBJET * float(def.get("facteur", 1.0)) / maxf(taille.x, taille.y)
	return def["echelle"]


func _spawn_obstacle(def: Dictionary, x: float, y := -1.0) -> void:
	var tex: Texture2D = def["tex"]
	var echelle := _echelle(def)
	# « largeur » : étirement horizontal des pièges qui pendent (très fins à l'origine, donc peu visibles)
	var etirement := Vector2(float(def.get("largeur", 1.0)), 1.0)
	var taille: Vector2 = tex.get_size() * echelle * etirement
	if y < 0.0:
		if def["mode"] == "plafond":
			y = ZONE_HAUT - 4.0 + taille.y * 0.5 # accroché au plafond
		else:
			y = randf_range(ZONE_HAUT + 40.0 + taille.y * 0.5, ZONE_BAS - 40.0 - taille.y * 0.5)
	var piege := Area2D.new()
	piege.set_script(TRAP_SCRIPT)
	piege.position = Vector2(x, y)
	var forme := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = taille * HITBOX
	forme.shape = rect
	piege.add_child(forme)
	# Halo rouge derrière le piège (même dessin, un peu plus grand, teinté) : il se détache du carrelage et se repère de loin
	var halo := Sprite2D.new()
	halo.texture = tex
	halo.scale = Vector2.ONE * echelle * HALO_ECHELLE
	halo.modulate = Color(1.0, 0.12, 0.08, HALO_ALPHA)
	piege.add_child(halo)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * echelle * etirement
	piege.add_child(sprite)
	piege.add_to_group("traps")
	piege.body_entered.connect(piege._on_body_entered)
	piege.soap_entered.connect(hit_soap)
	add_child(piege)
	# Le halo pulse doucement : un piège « respire », le décor non
	var pulsation := halo.create_tween().set_loops()
	pulsation.tween_property(halo, "modulate:a", HALO_ALPHA * 0.45, 0.45).set_trans(Tween.TRANS_SINE)
	pulsation.tween_property(halo, "modulate:a", HALO_ALPHA, 0.45).set_trans(Tween.TRANS_SINE)


func _spawn_bonus(x: float, y: float) -> void:
	var material := _pick_bonus_material()
	if material == null:
		return
	var bonus = BONUS.instantiate()
	bonus.position = Vector2(x, y) # l'icône est centrée sur le nœud
	bonus.add_to_group("bonus")
	bonus.setup(material)
	bonus.soap_entered.connect(apply_bonus)
	add_child(bonus)


func _spawn_shelf(x: float) -> void:
	## Étagère-rampe (elle recharge l'énergie quand on glisse dessus), au milieu de l'écran.
	var shelf: Node2D = SHELF_SCENE.instantiate()
	shelf.position = Vector2(x, randf_range(shelf_y_range.x, shelf_y_range.y))
	shelf.rotation = SHELF_ROTATION
	shelf.scale = Vector2.ONE * SHELF_SCALE # plus longue : on a le temps de glisser
	# Ligne de glissade (dessus de l'étagère) : le savon qui la touche la suit jusqu'au bout
	var poly: PackedVector2Array = shelf.get_node("CollisionPolygon2D").polygon
	var ligne := PackedVector2Array()
	for i in [0, 5, 4]:
		ligne.append(shelf.transform * poly[i])
	shelf.set_meta("ride", ligne)
	add_child(shelf)


func _nettoyer_derriere() -> void:
	## Supprime étagères, pièges et bonus restés loin derrière la caméra.
	var limite: float = cam.position.x - 1400.0
	for groupe in ["shelves", "traps", "bonus"]:
		for n in get_tree().get_nodes_in_group(groupe):
			if n is Node2D and n.global_position.x < limite:
				n.queue_free()


func die():
	_terminer_vol()

func hit_soap():
	## Piège touché : une vie en moins (invulnérable un court instant) ; sans vie restante, le vol se termine.
	if _termine or _invulnerable:
		return
	if _vies <= 0:
		_terminer_vol()
		return
	_vies -= 1
	_maj_vies()
	_invulnerable = true
	var clignote := create_tween().set_loops(int(tuning.invuln_time / 0.2))
	clignote.tween_property(soap, "modulate:a", 0.35, 0.1)
	clignote.tween_property(soap, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(tuning.invuln_time).timeout
	soap.modulate.a = 1.0
	_invulnerable = false


func _maj_vies() -> void:
	## Les vies sont des ailes : une aile = une vie. Une vie perdue grise l'aile (la caisse a au plus 5 ailes).
	if _vies_boite == null:
		_vies_boite = HBoxContainer.new()
		_vies_boite.add_theme_constant_override("separation", 4)
		# Fond brun translucide : les ailes blanches se détachent de la moulure du plafond
		var fond_ailes := PanelContainer.new()
		var style_ailes := StyleBoxFlat.new()
		style_ailes.bg_color = Color(0.29, 0.165, 0.078, 0.6)
		style_ailes.set_corner_radius_all(16)
		style_ailes.content_margin_left = 8.0
		style_ailes.content_margin_right = 8.0
		style_ailes.content_margin_top = 2.0
		style_ailes.content_margin_bottom = 2.0
		fond_ailes.add_theme_stylebox_override("panel", style_ailes)
		fond_ailes.position = Vector2(17.0, 108.0)
		fond_ailes.add_child(_vies_boite)
		$HUD.add_child(fond_ailes)
		for i in _vies_max:
			var aile := TextureRect.new()
			aile.texture = AILE_HUD
			aile.custom_minimum_size = Vector2(58.0, 48.0)
			aile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			aile.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			aile.pivot_offset = aile.custom_minimum_size * 0.5
			_vies_boite.add_child(aile)
		if _vies_max == 0:
			var mort := Label.new()
			mort.text = "Aucune aile : un piège et c'est fini"
			mort.add_theme_font_size_override("font_size", 20)
			mort.add_theme_color_override("font_color", Color(1.0, 0.7, 0.65))
			mort.add_theme_color_override("font_outline_color", Color(0.29, 0.165, 0.078))
			mort.add_theme_constant_override("outline_size", 8)
			_vies_boite.add_child(mort)
	for i in _vies_boite.get_child_count():
		var aile := _vies_boite.get_child(i) as TextureRect
		if aile == null:
			continue
		var cible := Color.WHITE if i < _vies else Color(0.2, 0.2, 0.2, 0.35)
		if aile.modulate != cible:
			# L'aile perdue gonfle un instant puis se grise
			var tween := aile.create_tween()
			tween.tween_property(aile, "scale", Vector2.ONE * 1.5, 0.1)
			tween.tween_property(aile, "scale", Vector2.ONE, 0.2)
			tween.parallel().tween_property(aile, "modulate", cible, 0.3)

func _terminer_vol() -> void:
	## Fin de vol (chute ou piège) : on enregistre le résultat, puis on passe à l'écran de score du palier.
	if _termine:
		return
	_termine = true
	var distance := _distance_unites()
	# Arrivée = 2000 m (score excellent)
	var precedente := GameState.last_distance # à lire avant apply_result, qui la remplace
	GameState.apply_result(distance, tuning.metres(distance) >= ARRIVEE_M, _collected)
	# Différé : on peut être dans un callback physique (piège ou sol touché), où changer de scène est interdit
	get_tree().change_scene_to_file.call_deferred(SCORES[_palier(distance, precedente)])

func _palier(distance: float, precedente: float) -> String:
	## Le palier compare ce vol au précédent : le premier vol est « moyen », puis l'écart en mètres décide
	## (moins de 100 m = moyen, 100 à 250 = bon / mauvais, plus de 250 = excellent / catastrophe).
	var m := tuning.metres(distance)
	if m >= ARRIVEE_M:
		return "excellent"
	if precedente < 0.0:
		return "moyen"
	var ecart := m - tuning.metres(precedente)
	if absf(ecart) < 100.0:
		return "moyen"
	if ecart > 0.0:
		return "excellent" if ecart > 250.0 else "bon"
	return "catastrophe" if ecart < -250.0 else "mauvais"

func apply_bonus(material: MaterialData) -> void:
	if material == null or material.id.is_empty():
		return
	_collected[material.id] = int(_collected.get(material.id, 0)) + 1
	_maj_compteur()


func _maj_compteur() -> void:
	## Matériaux : une carte par matériau, au niveau de l'eau, avec son dessin et son total (stock de l'atelier + vol en cours).
	if _mat_boite == null:
		_mat_boite = HBoxContainer.new()
		_mat_boite.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		_mat_boite.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_mat_boite.offset_left = 20.0
		_mat_boite.offset_bottom = -14.0
		_mat_boite.add_theme_constant_override("separation", 10)
		$HUD.add_child(_mat_boite)
		for m in tuning.materials:
			var carte := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.984, 0.941, 0.839, 0.92)
			style.border_color = Color(0.29, 0.165, 0.078)
			style.set_border_width_all(3)
			style.border_width_bottom = 5
			style.set_corner_radius_all(16)
			style.content_margin_left = 8.0
			style.content_margin_right = 12.0
			style.content_margin_top = 4.0
			style.content_margin_bottom = 4.0
			carte.add_theme_stylebox_override("panel", style)
			var ligne := HBoxContainer.new()
			ligne.add_theme_constant_override("separation", 6)
			carte.add_child(ligne)
			var icone := TextureRect.new()
			icone.texture = m.icone
			icone.custom_minimum_size = Vector2(46.0, 46.0)
			icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ligne.add_child(icone)
			var nombre := Label.new()
			nombre.text = str(_total_materiau(m.id)) # le stock de l'atelier, pas 0
			nombre.custom_minimum_size = Vector2(34.0, 0.0)
			nombre.add_theme_font_override("font", FONT_TORTUE)
			nombre.add_theme_font_size_override("font_size", 32)
			nombre.add_theme_color_override("font_color", Color(0.29, 0.165, 0.078))
			ligne.add_child(nombre)
			_mat_boite.add_child(carte)
			_mat_labels[m.id] = nombre
			_mat_cartes[m.id] = carte
	for id in _mat_labels:
		var n := _total_materiau(id)
		var nombre: Label = _mat_labels[id]
		if nombre.text != str(n):
			nombre.text = str(n)
			# La carte gonfle un instant : on voit lequel vient d'augmenter
			var carte: PanelContainer = _mat_cartes[id]
			carte.pivot_offset = carte.size * 0.5
			var tween := carte.create_tween()
			tween.tween_property(carte, "scale", Vector2.ONE * 1.25, 0.1)
			tween.tween_property(carte, "scale", Vector2.ONE, 0.18)


func _creer_tortue_hud() -> void:
	## En bas à droite : la tortue du prochain palier et la distance qui reste jusqu'à elle.
	var carte := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.984, 0.941, 0.839, 0.92)
	style.border_color = Color(0.29, 0.165, 0.078)
	style.set_border_width_all(3)
	style.border_width_bottom = 5
	style.set_corner_radius_all(16)
	style.content_margin_left = 10.0
	style.content_margin_right = 16.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	carte.add_theme_stylebox_override("panel", style)
	carte.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	carte.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	carte.grow_vertical = Control.GROW_DIRECTION_BEGIN
	carte.offset_right = -20.0
	carte.offset_bottom = -14.0
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	carte.add_child(ligne)
	_tortue_icone = TextureRect.new()
	_tortue_icone.custom_minimum_size = Vector2(84.0, 64.0)
	_tortue_icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tortue_icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ligne.add_child(_tortue_icone)
	_tortue_label = Label.new()
	_tortue_label.add_theme_font_override("font", FONT_TORTUE)
	_tortue_label.add_theme_font_size_override("font_size", 30)
	_tortue_label.add_theme_color_override("font_color", Color(0.29, 0.165, 0.078))
	ligne.add_child(_tortue_label)
	$HUD.add_child(carte)


func _maj_tortue_hud(metres: float) -> void:
	if _tortue_label == null:
		return
	_tortue_icone.texture = TORTUES[(_palier_annonce - 1) % TORTUES.size()]
	_tortue_label.text = "%d m" % maxi(0, ceili(_palier_annonce * PAS_TORTUE_M - metres))

func _pick_bonus_material() -> MaterialData:
	if tuning.materials.is_empty():
		push_error("Cannot spawn a material bonus: Tuning has no materials.")
		return null

	# Les matériaux s'ajoutent petit à petit : chacun n'apparaît qu'à partir de sa distance (`from`, en mètres)
	var metres := tuning.metres(_distance_unites())
	var total_weight := 0.0
	for material in tuning.materials:
		if material == null or material.weight < 0.0:
			push_error("Cannot spawn a material bonus: a configured material is null or has negative weight.")
			return null
		if metres >= material.from:
			total_weight += material.weight
	if total_weight <= 0.0:
		push_error("Cannot spawn a material bonus: all configured material weights are zero.")
		return null

	var roll := randf() * total_weight
	var last_weighted_material: MaterialData
	for material in tuning.materials:
		if material.weight <= 0.0 or metres < material.from:
			continue
		last_weighted_material = material
		roll -= material.weight
		if roll < 0.0:
			return material
	return last_weighted_material


func _on_ground_body_entered(body: Node2D) -> void:
	if body.name == "Soap":
		die()


func _total_materiau(id: String) -> int:
	## Quantité affichée en vol = stock de l'atelier + ce qui est ramassé pendant ce vol (même total que dans l'atelier).
	var stock := GameState.stock(id)
	return stock + int(_collected.get(id, 0))
