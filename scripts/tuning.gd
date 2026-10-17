@tool
class_name Tuning
extends Resource
## TOUS les réglages du jeu. Ouvre `data/tuning.tres` dans l'éditeur : tout est dans l'inspecteur,
## regroupé par thème, avec une info-bulle sur chaque valeur (survole le nom).
## Unités : mètres, secondes. Seul `ppm` convertit les mètres en pixels pour l'affichage.
## Les caisses et les matériaux (valeurs provisoires) sont des Resources listées dans « Contenu ».

const STEP := 1.0 / 60.0  # pas de simulation (60 images/s)

## Matériaux ramassés sur les étagères (apparaissent à partir de `from`, fréquence `weight`) et caisses à
## savon à débloquer (voir la page Notion « Mécaniques »). Ce sont des Resources : un fichier .tres par
## élément dans data/materials/ et data/crates/, éditable dans l'inspecteur. PROVISOIRE : à équilibrer.
@export_group("Contenu")
@export var materials: Array[MaterialData] = []
@export var crates: Array[CrateData] = []


func crate(id: String) -> CrateData:
	for c in crates:
		if c.id == id:
			return c
	return crates[0]


func material(id: String) -> MaterialData:
	for m in materials:
		if m.id == id:
			return m
	return materials[0]


# Les réglages de géométrie passent par ce helper qui prévient la prévisualisation
# de la piste dans l'éditeur (signal `changed`).
func _geo(v: float, current: float) -> float:
	if not is_equal_approx(v, current):
		emit_changed.call_deferred()
	return v


@export_group("Monde")
## Pixels par mètre à l'écran. Ne change PAS le gameplay, seulement la taille affichée.
@export_range(5.0, 60.0, 0.5) var ppm: float = 20.0:
	set(v):
		ppm = _geo(v, ppm)
## AFFICHAGE : centimètres affichés par unité interne. La physique reste en unités internes (notées "m"
## dans l'inspecteur) ; seuls les textes du jeu sont convertis en cm. 10 = une distance de 800 s'affiche 8000 cm.
@export_range(1.0, 100.0, 1.0) var display_cm_per_unit: float = 10.0
## Distance de la ligne d'arrivée = objectif du niveau (m).
@export_range(100.0, 3000.0, 10.0) var door_x: float = 800.0
## Hauteur du plafond (le bas du meuble) au-dessus de l'eau (m). Le savon ne peut pas le dépasser.
@export_range(10.0, 60.0, 1.0) var ceiling: float = 28.0

@export_group("Piste")
## Gravité sur la piste (m/s²).
@export_range(1.0, 30.0, 0.1) var gravity: float = 9.8
## Vitesse au départ de la piste (m/s).
@export_range(5.0, 40.0, 0.5) var ramp_v0: float = 18.0
## Hauteur du départ au-dessus de l'eau (m). Plus haut = plus de vitesse acquise.
@export_range(0.0, 60.0, 0.5) var ramp_start_h: float = 10.0:
	set(v):
		ramp_start_h = _geo(v, ramp_start_h)
## Longueur totale de la piste courbe (m).
@export_range(5.0, 120.0, 0.5) var ramp_len: float = 26.0:
	set(v):
		ramp_len = _geo(v, ramp_len)
## Pente tout en haut de la piste (degrés vers le bas). Plus raide = départ plus violent.
@export_range(0.0, 85.0, 0.5) var ramp_top_deg: float = 45.0:
	set(v):
		ramp_top_deg = _geo(v, ramp_top_deg)
## Angle à la sortie de la piste (degrés vers le haut) = angle de décollage.
## La pente tourne progressivement de ramp_top_deg (vers le bas) à cet angle : c'est ce qui l'arrondit.
@export_range(0.0, 70.0, 0.5) var ramp_lip_deg: float = 25.0:
	set(v):
		ramp_lip_deg = _geo(v, ramp_lip_deg)
## Frottement sur la piste sans amélioration (0 = glisse parfaite).
@export_range(0.0, 0.5, 0.005) var mu_base: float = 0.14
## Vitesse minimale sur la piste (m/s) : le savon ne s'arrête jamais.
@export_range(0.0, 5.0, 0.1) var min_ramp_speed: float = 1.0
## Taille de la zone "bon décollage" = derniers mètres du tremplin (trait rouge).
@export_range(0.5, 5.0, 0.1) var takeoff_window: float = 3.5:
	set(v):
		takeoff_window = _geo(v, takeoff_window)
## Vitesse gagnée (m/s) si on appuie ESPACE dans la zone de bon décollage.
@export_range(0.0, 15.0, 0.5) var takeoff_bonus: float = 3.0

@export_group("Vol : jetpack")
## Vitesse de défilement de base (m/s) d'une caisse de poids 1.
@export_range(5.0, 40.0, 0.5) var cruise_speed: float = 13.0
## Vitesse de défilement en plus par point de poids au-dessus de 1 (m/s) : l'élan des caisses lourdes.
@export_range(0.0, 6.0, 0.1) var cruise_per_weight: float = 1.5
## Vitesse à laquelle le savon rejoint sa vitesse de défilement après la piste (m/s²).
@export_range(0.5, 20.0, 0.5) var speed_ease: float = 3.0
## Gravité en vol (m/s²).
@export_range(5.0, 60.0, 0.5) var jet_gravity: float = 24.0
## Poussée du jetpack quand on maintient la touche (m/s²). Doit dépasser la gravité pour monter.
@export_range(10.0, 90.0, 0.5) var jet_thrust: float = 46.0
## Gravité en plus par point de poids au-dessus de 1 (0.12 = +12 %) : les caisses lourdes retombent plus vite.
@export_range(0.0, 0.5, 0.01) var weight_gravity: float = 0.12
## Vitesse verticale maximale vers le haut (m/s).
@export_range(2.0, 40.0, 0.5) var rise_max: float = 13.0
## Vitesse verticale maximale vers le bas (m/s).
@export_range(2.0, 40.0, 0.5) var fall_max: float = 16.0
## Rayon du savon pour les collisions avec obstacles et pièces (m).
@export_range(0.3, 3.0, 0.1) var soap_radius: float = 1.1

@export_group("Caisses")
## Ailes (plumes) d'une caisse de solidité 0.
@export_range(0, 6) var wings_base: int = 2
## Ailes en plus par point de solidité.
@export_range(0, 3) var wings_per_solidity: int = 1
## Temps d'invulnérabilité après un piège touché (s).
@export_range(0.2, 4.0, 0.1) var invuln_time: float = 1.2

@export_group("Parcours")
## Graine du parcours. 0 = un parcours différent à chaque vol ; autre valeur = toujours le même.
@export var course_seed: int = 0
## Distance avant la première étagère (m).
@export_range(10.0, 200.0, 5.0) var course_start: float = 50.0
## Temps (s) entre deux apparitions de tronçon (un Timer de vol.tscn). Un tronçon = une étagère et, souvent, un obstacle.
@export_range(0.5, 10.0, 0.1) var spawn_interval: float = 3.0
## Distance (m) devant le savon où apparaît chaque nouveau tronçon (au-delà de l'écran).
@export_range(40.0, 200.0, 5.0) var spawn_ahead: float = 90.0
## Longueur d'un tronçon (m).
@export_range(20.0, 120.0, 1.0) var segment_min: float = 40.0
@export_range(20.0, 120.0, 1.0) var segment_max: float = 52.0
## Chance d'un obstacle par tronçon au début, puis à la ligne d'arrivée (la difficulté monte).
@export_range(0.0, 1.0, 0.05) var obstacle_chance_start: float = 0.5
@export_range(0.0, 1.0, 0.05) var obstacle_chance_end: float = 1.0
## Chance d'un deuxième obstacle dans le tronçon, à la ligne d'arrivée (0 au début).
@export_range(0.0, 1.0, 0.05) var second_obstacle_end: float = 0.8

# --- Calculs dérivés (pas des réglages) ----------------------------------------

func stats_for(crate_id: String) -> Dictionary:
	## Transforme une caisse en valeurs utilisées par la physique.
	var c := crate(crate_id)
	var w: int = c.poids
	return {
		"wings": wings_base + wings_per_solidity * c.solidite,
		"cruise": cruise_speed + cruise_per_weight * (w - 1),
		"gravity": jet_gravity * (1.0 + weight_gravity * (w - 1)),
		"v0": ramp_v0,
		"mu": mu_base,
	}


func cm(v: float) -> String:
	## Longueur interne -> texte en centimètres.
	return "%d cm" % int(v * display_cm_per_unit)


func cm_speed(v: float) -> String:
	return "%d cm/s" % int(v * display_cm_per_unit)


func collected_text(collected: Dictionary) -> String:
	## "5 planches, 2 plumes" (ou "rien") pour l'atelier et l'écran de vol.
	var parts: Array[String] = []
	for m in materials:
		var n := int(collected.get(m.id, 0))
		if n > 0:
			parts.append("%d %s%s" % [n, m.nom.to_lower(), "s" if n > 1 else ""])
	return "rien" if parts.is_empty() else ", ".join(parts)


# --- Géométrie de la piste (partagée par la simulation et la prévisualisation) ---

func ramp_slope(dist: float) -> float:
	## Angle de la piste en radians (positif = elle monte) à `dist` mètres du départ.
	## L'angle varie en continu de -ramp_top_deg à +ramp_lip_deg : la piste est une courbe lisse.
	var f := clampf(dist / ramp_len, 0.0, 1.0)
	return lerpf(-deg_to_rad(ramp_top_deg), deg_to_rad(ramp_lip_deg), f)


func ramp_point(dist: float) -> Vector2:
	## Point de la piste (x, altitude) à `dist` mètres du départ (intégrale exacte de la courbe).
	var d := clampf(dist, 0.0, ramp_len)
	var th0 := -deg_to_rad(ramp_top_deg)
	var th1 := deg_to_rad(ramp_lip_deg)
	var k := (th1 - th0) / ramp_len  # rad par mètre de piste
	var th := th0 + k * d
	if absf(k) < 0.00001:
		return Vector2(d * cos(th0), ramp_start_h + d * sin(th0))
	return Vector2((sin(th) - sin(th0)) / k, ramp_start_h + (cos(th0) - cos(th)) / k)


func to_px(xm: float, ym: float) -> Vector2:
	## Mètres (x, altitude) -> pixels du monde (y vers le bas, l'eau est à y = 0).
	return Vector2(xm * ppm, -ym * ppm)
