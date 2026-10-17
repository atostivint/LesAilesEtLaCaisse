@tool
class_name Tuning
extends Resource
## TOUS les réglages du jeu. Ouvre `data/tuning.tres` dans l'éditeur : tout est dans l'inspecteur,
## regroupé par thème, avec une info-bulle sur chaque valeur (survole le nom).
## Unités : mètres, secondes. Seul `ppm` convertit les mètres en pixels pour l'affichage.

const STEP := 1.0 / 60.0  # pas de simulation (60 images/s)

const UPGRADES := [
	{"id": "poussee", "nom": "Poussée de départ", "desc": "Vitesse au lâcher de la piste"},
	{"id": "bulles", "nom": "Jets de bulles", "desc": "Nombre de coups de propulsion en vol"},
	{"id": "ailes", "nom": "Ailes", "desc": "Portance : planer plus longtemps"},
	{"id": "glisse", "nom": "Glisse", "desc": "Moins de frottements (piste et air)"},
]


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
## dans l'inspecteur) ; seuls les textes du jeu sont convertis en cm. 10 = la porte à 700 s'affiche 7000 cm.
@export_range(1.0, 100.0, 1.0) var display_cm_per_unit: float = 10.0
## Gravité (m/s²). Plus c'est haut, plus le savon retombe vite.
@export_range(1.0, 30.0, 0.1) var gravity: float = 9.8
## Distance de la porte de sortie = objectif du jeu (m).
@export_range(100.0, 3000.0, 10.0) var door_x: float = 1400.0

@export_group("Piste")
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
## Frottement retiré à chaque niveau de Glisse.
@export_range(0.0, 0.05, 0.001) var mu_per_level: float = 0.012
## Frottement minimum, même au niveau max de Glisse.
@export_range(0.0, 0.2, 0.005) var mu_min: float = 0.03
## Vitesse minimale sur la piste (m/s) : le savon ne s'arrête jamais.
@export_range(0.0, 5.0, 0.1) var min_ramp_speed: float = 1.0
## Taille de la zone "bon décollage" = derniers mètres du tremplin (trait rouge).
@export_range(0.5, 5.0, 0.1) var takeoff_window: float = 3.5:
	set(v):
		takeoff_window = _geo(v, takeoff_window)
## Vitesse gagnée (m/s) si on appuie ESPACE dans la zone de bon décollage.
@export_range(0.0, 15.0, 0.5) var takeoff_bonus: float = 3.0

@export_group("Vol : portance et traînée")
## Incidence au repos (degrés) : à quel point le nez est levé sans rien toucher.
@export_range(-10.0, 20.0, 0.5) var alpha0_deg: float = 5.0
## Incidence max en tirant vers le haut (↑). Plus de portance mais plus de traînée.
@export_range(0.0, 40.0, 0.5) var alpha_up_deg: float = 14.0
## Incidence max en piquant (↓). Négative = on plonge et on gagne de la vitesse.
@export_range(-40.0, 0.0, 0.5) var alpha_down_deg: float = -10.0
## Vitesse de réaction de l'inclinaison (plus haut = plus nerveux).
@export_range(1.0, 20.0, 0.5) var pitch_response: float = 6.0
## Portance par radian d'incidence (pente de la courbe de portance).
@export_range(0.0, 10.0, 0.1) var cl_slope: float = 5.0
## Portance maximale (plafond, évite de monter à l'infini en tirant fort).
@export_range(0.1, 3.0, 0.05) var cl_max: float = 1.2
## FORCE DE LA PORTANCE (∝ vitesse²). Le réglage n°1 pour la distance de planée.
@export_range(0.0, 0.1, 0.001) var lift_k: float = 0.022
## Traînée de base (frottement de l'air quand on ne tire pas).
@export_range(0.0, 1.0, 0.01) var cd0: float = 0.2
## Traînée induite : le surcoût de freinage quand on tire fort (cabrer).
@export_range(0.0, 1.0, 0.01) var cd_k: float = 0.1
## FORCE DE LA TRAÎNÉE (∝ vitesse²). Le réglage n°2 : ce qui freine le savon.
@export_range(0.0, 0.1, 0.001) var drag_k: float = 0.028

@export_group("Vol : jets de bulles (propulsion)")
## Accélération d'un jet (m/s²). Gain de vitesse ≈ poussée × durée.
@export_range(0.0, 60.0, 0.5) var thrust: float = 10.0
## Durée d'un jet (secondes).
@export_range(0.1, 5.0, 0.1) var boost_duration: float = 1.0

@export_group("Atterrissage et glisse")
## Part de la vitesse de chute rendue en rebond sur le ventre (0 = aucun rebond, 1 = balle parfaite).
@export_range(0.0, 0.95, 0.01) var bounce_restitution: float = 0.55
## Ricochet : relance verticale (m/s) par m/s de vitesse horizontale, comme un caillou qui ricoche.
## Elle diminue à chaque rebond. 0 = le rebond ne dépend que de la vitesse de chute.
@export_range(0.0, 1.0, 0.01) var bounce_skip: float = 0.3
## Frottement au contact : vitesse horizontale perdue par unité de choc (0 = patine, 1 = accroche).
@export_range(0.0, 1.5, 0.01) var bounce_friction: float = 0.35
## Nombre maximum de rebonds avant de passer à la glisse.
@export_range(0, 10) var max_bounces: int = 4
## En dessous de cette vitesse de chute (m/s), plus de rebond : le savon se pose et glisse.
@export_range(0.1, 6.0, 0.1) var bounce_min_speed: float = 1.5
## Vitesse horizontale perdue à l'impact selon la raideur de la descente (0 = rien perdu).
@export_range(0.0, 5.0, 0.1) var impact_loss: float = 1.5
## Part minimale de vitesse horizontale conservée, même sur un impact très raide.
@export_range(0.0, 1.0, 0.05) var impact_keep_min: float = 0.2
## Rotation donnée par la vitesse de chute à l'impact (rad/s par m/s). Chute rapide = le nez plonge.
@export_range(0.0, 1.0, 0.01) var touchdown_spin: float = 0.12
## Frottement quand le VENTRE du savon glisse (m/s²) : bas = glisse très loin.
@export_range(0.0, 20.0, 0.1) var belly_friction: float = 3.0
## Frottement en plus quand la CAISSE traîne dans l'eau (m/s²) : haut = arrêt net.
@export_range(0.0, 60.0, 0.5) var crate_friction: float = 18.0
## Inclinaison (degrés, nez en haut) où la caisse commence à toucher l'eau.
@export_range(0.0, 60.0, 0.5) var crate_start_deg: float = 8.0
## Inclinaison où la caisse freine à fond.
@export_range(0.0, 80.0, 0.5) var crate_full_deg: float = 20.0
## Frottement en plus quand le NEZ pique dans l'eau (m/s²).
@export_range(0.0, 60.0, 0.5) var dig_friction: float = 10.0
## Inclinaison (degrés, nez en bas) où le nez commence à piquer.
@export_range(0.0, 60.0, 0.5) var dig_start_deg: float = 10.0
## Inclinaison où le nez pique à fond.
@export_range(0.0, 80.0, 0.5) var dig_full_deg: float = 30.0
## Force qui remet le savon à plat dans l'eau (flottabilité).
@export_range(0.0, 30.0, 0.5) var level_stiffness: float = 8.0
## Amortissement de la rotation (plus haut = bascule moins longtemps).
@export_range(0.0, 10.0, 0.1) var level_damping: float = 3.0
## Couple des flèches ↑/↓ pour redresser ou basculer le savon pendant la glisse.
@export_range(0.0, 20.0, 0.5) var slide_pitch_torque: float = 5.0
## Bousculade d'un jet de bulles : couple qui fait plonger le nez (rad/s²). 0 = aucune bascule.
@export_range(0.0, 20.0, 0.5) var jet_torque: float = 4.0
## En dessous de cette vitesse (m/s), le savon est considéré arrêté.
@export_range(0.1, 5.0, 0.1) var stop_speed: float = 1.0

@export_group("Améliorations")
## Niveau maximum de chaque amélioration.
@export_range(1, 20) var max_level: int = 8
## Vitesse au lâcher sans amélioration (m/s).
@export_range(0.0, 30.0, 0.5) var v0_base: float = 22.0
## Vitesse au lâcher gagnée par niveau de Poussée (m/s).
@export_range(0.0, 10.0, 0.1) var v0_per_level: float = 2.0
## Jets de bulles au niveau 0.
@export_range(0, 10) var charges_base: int = 1
## Portance en plus par niveau d'Ailes (0.25 = +25 % du niveau de base).
@export_range(0.0, 1.0, 0.01) var lift_per_level: float = 0.25
## Traînée en moins par niveau de Glisse.
@export_range(0.0, 0.2, 0.005) var drag_per_level: float = 0.05
## Traînée minimale (multiplicateur), même au niveau max.
@export_range(0.05, 1.0, 0.05) var drag_min: float = 0.5

@export_group("Économie")
## Pièces au tout début.
@export_range(0, 500) var start_coins: int = 35
## Prix du niveau 1 d'une amélioration.
@export_range(1.0, 500.0, 1.0) var cost_base: float = 30.0
## Multiplicateur de prix à chaque niveau (1.5 = +50 %).
@export_range(1.0, 3.0, 0.05) var cost_growth: float = 1.5
## Pièces gagnées par mètre parcouru.
@export_range(0.0, 5.0, 0.05) var coin_per_m: float = 0.35
## Pièces gagnées à chaque vol, quoi qu'il arrive.
@export_range(0, 200) var flat_reward: int = 5
## Bonus de pièces pour un nouveau record.
@export_range(0, 500) var record_bonus: int = 15
## Bonus de pièces pour avoir franchi la porte.
@export_range(0, 1000) var door_bonus: int = 100


# --- Calculs dérivés (pas des réglages) ----------------------------------------

func stats_for(levels: Dictionary) -> Dictionary:
	## Transforme les niveaux d'amélioration en valeurs utilisées par la physique.
	var lp: int = levels["poussee"]
	var lb: int = levels["bulles"]
	var la: int = levels["ailes"]
	var lg: int = levels["glisse"]
	return {
		"v0": v0_base + v0_per_level * lp,
		"charges": charges_base + lb,
		"lift": 1.0 + lift_per_level * la,
		"drag": maxf(drag_min, 1.0 - drag_per_level * lg),
		"mu": maxf(mu_min, mu_base - mu_per_level * lg),
	}


func cost_for(level: int) -> int:
	## Prix pour passer de `level` à `level + 1`.
	return int(round(cost_base * pow(cost_growth, level)))


func reward_for(distance: float, is_record: bool, reached_door: bool) -> int:
	var gain := int(distance * coin_per_m) + flat_reward
	if is_record:
		gain += record_bonus
	if reached_door:
		gain += door_bonus
	return gain


func cm(v: float) -> String:
	## Longueur interne -> texte en centimètres.
	return "%d cm" % int(v * display_cm_per_unit)


func cm_speed(v: float) -> String:
	return "%d cm/s" % int(v * display_cm_per_unit)


func value_text(id: String, level: int) -> String:
	## Valeur d'une amélioration à un niveau donné (pour l'atelier).
	var lv := {"poussee": 0, "bulles": 0, "ailes": 0, "glisse": 0}
	lv[id] = level
	var st := stats_for(lv)
	match id:
		"poussee":
			return cm_speed(float(st["v0"]))
		"bulles":
			return "%d jets" % int(st["charges"])
		"ailes":
			return "portance x%.2f" % float(st["lift"])
		"glisse":
			return "traînée x%.2f" % float(st["drag"])
	return ""


# --- Géométrie de la piste (partagée par la simulation et la prévisualisation) ---

func ramp_length() -> float:
	return ramp_len


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
