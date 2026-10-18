# Les ailes et la caisse : résumé de conception

Document de référence pour le développement Godot. Il reprend les décisions prises pendant la conception (mécaniques, direction artistique, écrans). Les maquettes sont dans `docs/design/`.

## Concept

Un savon porte une caisse à savon sur le dos comme un sac à dos. Il descend une piste, la quitte, puis **vole le plus longtemps possible grâce à sa caisse ailée**. Le but est d'aller le plus loin possible, jusqu'à une ligne d'arrivée dont la distance restante est affichée. Ton : publicité de lessive de 1975, humour de soap opera ("Satisfait ou remousse !", "Plus blanc que blanc !").

Nom du jeu : **Les ailes et la caisse**. Sous-titre sur l'écran titre : "Courses de monsieurs propres".

## Boucle de jeu

1. Atelier : je débloque de nouvelles caisses à savon avec les matériaux récoltés, puis j'équipe celle que je veux.
2. Équipes : je choisis l'équipe du savon (cosmétique) et la couleur du savon.
3. Course : descente de la piste de départ (un court prologue), décollage, vol.
4. En vol : je maintiens la touche de jetpack pour monter et je la relâche pour retomber. Je rattrape des matériaux sur les étagères et j'évite les obstacles.
5. Fin : le savon tombe dans l'eau savonneuse (le vol s'arrête), ou franchit la ligne d'arrivée. Un obstacle retire une aile ; sans aile, le jetpack ne marche plus et le savon tombe.
6. Score (5 niveaux d'écran), retour à l'atelier avec les matériaux récoltés (ils sont gardés même après une chute).
7. Pose des pièges (hors prototype actuel) : je place mes pièges sur la route de l'adversaire pour la manche suivante (4 par manche pour l'instant), il fait de même pour moi.

## Vol (écran principal du jeu)

- Prologue : la piste de départ est courte. Le savon descend le tremplin. Un appui sur ESPACE dans la zone rouge (les derniers mètres du tremplin) donne un bonus de vitesse au décollage.
- Vol au jetpack, sur le principe de Jetpack Joyride ou de Flappy : on **maintient** ESPACE (ou flèche haut, W, clic gauche) pour monter, on **relâche** pour retomber.
- Défilement horizontal vers la droite. Le savon est en l'air. Sa vitesse de défilement dépend de la caisse : une caisse lourde défile plus vite, mais retombe plus vite (voir Atelier).
- Plafond : le bas d'un meuble. Il arrête la montée sans faire de mal.
- Haut de l'écran : liseret du bas d'un meuble (planche de bois, filet moutarde, feston crème). Bas de l'écran : eau savonneuse (vagues bleu canard, écume). Tomber dans l'eau termine le vol. Quelques bulles discrètes flottent toujours autour.
- Étagères : des étagères portent 2 à 4 pièces typées : planche, plume, élastique, étoile. Les étagères n'ont pas de collision : elles servent seulement d'appui visuel. Les matériaux rares n'apparaissent que plus loin : élastique à partir de 100 m, étoile à partir de 300 m (c'est la « rareté » de la page Notion). Ne pas en mettre trop.
- Obstacles : pince à linge pendue au meuble (de plus en plus longue avec la distance) et planche à clous flottante. Chaque obstacle touché retire une aile (plume), puis le savon est invulnérable pendant 1,2 s. À zéro aile, le jetpack ne marche plus et le savon tombe. La densité d'obstacles monte avec la distance : au début, la moitié des tronçons ont un obstacle ; vers la ligne d'arrivée, chaque tronçon en a un, souvent deux.
- HUD : distance parcourue (ex. 412 m dans la maquette), distance jusqu'à la ligne d'arrivée avec barre de progression (ex. 288 m sur 700 m dans la maquette), ailes restantes (3 avec la caisse classique, davantage avec les caisses solides), matériaux ramassés pendant le vol.
- Repères de distance (fanions 400, 500, 600 m dans la maquette) sur la ligne d'eau. Ligne d'arrivée en ruban à damier au bout : 800 m dans le prototype (`door_x`), 700 m dans la maquette.
- Boosters : jet de bulles (chevrons et grosses bulles). Hors prototype actuel.

## Atelier (déblocage des caisses)

L'atelier sert à **débloquer de nouvelles caisses à savon** avec les matériaux récoltés en vol, puis à choisir celle qu'on équipe. Une caisse débloquée est équipée tout de suite. La caisse de départ (classique, ailes à plumes) est gratuite et déjà débloquée. Les matériaux commencent à zéro, et ceux qu'on ramasse sont gardés même après une chute.

Matériaux (les 4 types du prototype) :

- **Planche** : la plus fréquente, disponible dès le départ.
- **Plume** : disponible dès le départ.
- **Élastique** : à partir de 100 m.
- **Étoile** : à partir de 300 m, la plus rare.

Les clous, la corde, la peinture et le rideau de la maquette reviendront avec les pièges. Les bulles ne sont pas dans le prototype actuel.

Les caisses sont inspirées des courses Red Bull. Solidité = nombre d'ailes en plus : une caisse a 2 ailes + sa solidité. Poids = élan : le savon défile plus vite (+1,5 m/s par point de poids au-dessus de 1), mais retombe plus vite (+12 % de gravité par point) et monte moins bien. Les coûts sont **provisoires** (`data/crates/`).

| Caisse | Description | Coût (matériaux) | Solidité / Poids |
|---|---|---|---|
| Caisse classique | La caisse de départ, ailes à plumes. | gratuite | 1 / 1 |
| Caisse cercueil | Propulsion par taille-crayon : plus solide. | 5 planches, 5 élastiques | 2 / 1 |
| Caisse carton | Ailes en carton, boulonnées et peintes. | 5 peintures, 5 boulons, 5 cartons | 1 / 1 |
| Caisse baignoire | Ailes en rideau de douche : lourde, rapide, fragile. | 3 planches, 2 élastiques, 2 peintures, 2 boulons, 1 carton | 1 / 2 |
| Caisse baguette | Ailes en croissants : solide et rapide. | 5 planches, 3 élastiques, 3 peintures, 2 boulons, 3 cartons | 3 / 2 |
| Caisse poisson | La plus lourde : très solide, très rapide. | 7 planches, 5 élastiques, 4 peintures, 4 boulons, 4 cartons | 2 / 3 |

### Pièges (hors prototype actuel)

Dans la maquette, l'atelier a deux onglets, **Caisses** et **Pièges**, avec le même sac de matériaux. Les pièges ne sont pas dans le prototype actuel. Le tableau ci-dessous est la maquette (jauges Gêne / Surprise / Durée) :

| Piège | Effet | Coût | Jauges |
|---|---|---|---|
| La Flaque de mousse | les rivaux dérapent sans contrôle | 5 bulles, 1 rideau | 4 / 3 / 3 |
| La Planche à clous | perce les ailes, perte de vol | 3 planches, 12 clous | 5 / 2 / 4 |
| Le Filet à linge | retient la caisse quelques secondes | 3 cordes, 1 rideau, 4 clous | 4 / 4 / 2 |
| Le Canon à bulles | nuage de mousse qui masque la pente | 4 planches, 4 bulles, 4 clous | 3 / 5 / 3 |
| La Pince à linge géante | accroche la caisse et la fait pendre | 3 planches, 4 clous, 1 corde, 1 peinture | 4 / 3 / 5 |

Les coûts, jauges, limites (4 pièges par manche) et le record de 512 m de l'écran de pose sont des **valeurs provisoires** de maquette, à équilibrer.

## Équipes savon (cosmétiques uniquement)

Pas de capacités uniques. Une équipe change la couleur du dessus et des côtés de la caisse, la couleur des sangles du savon et le petit symbole sur le savon (repris sur la carte d'équipe). La couleur du savon est libre (8 teintes).

| Équipe | Couleur | Symbole |
|---|---|---|
| Alep | vert laurier #5f7a2a | feuilles de laurier |
| Marseille | bleu #3a6f9a | branche d'olivier |
| Noir | anthracite #44403c | goutte |
| Castille | rouge #B5361F | château |
| Glycérine | orange #E8942A | étincelles |
| Lavande | violet #7d5a8f | brin de lavande |

Couleurs de savon : Crème #F7EBCB, Rose poudré #E8A5A0, Jaune soleil #EBC24A, Vert avocat #A8B85C, Bleu poudre #9FC3C4, Lilas #B9A0C8, Orange #E89A4C, Charbon #3E2A22.

## Écrans de score

Cinq niveaux selon la distance, avec le même savon et sa caisse ailée, et un texte de feuilleton :

| Niveau | Série | Citation | Accroche | Suite |
|---|---|---|---|---|
| Excellent | La gloire de Madame | « Éléonore a tout frotté. Même le passé de Gérard. » | Plus blanc que blanc ! | Le notaire arrive avec un chiffon. |
| Bon | Les secrets de l'évier | « Propre, chéri. Presque trop propre. Qu'est-ce que tu caches ? » | Ça brille, mais il reste une trace ! | La facture du pressing. |
| Moyen | Passions mal rincées | « Il a frotté à moitié. Elle a pardonné à moitié. » | À moitié propre, à moitié pardonné ! | Philippe cache-t-il un second tablier ? |
| Mauvais | Larmes et lessive | « Tu as fait tomber le savon, et notre mariage avec. » | Une tache qui ne part pas à 30 degrés ! | La tache partira-t-elle un jour ? |
| Catastrophe | Le grand désastre domestique | « QUI A OSÉ ? Henriette, tu as toujours jalousé mes rideaux ! » | Aucune lessive ne lavera cet affront ! | Une jumelle oubliée et un détachant miracle. |

Chaque écran a un score en "000", un bouton "Rejouer" et la mention "Satisfait ou remousse !". Les expressions du savon changent selon le niveau (ravi, content, mitigé, en larmes, paniqué). Sur "mauvais" et "catastrophe" la caisse se détache du savon.

## Écran de pose des pièges (hors prototype actuel)

Vue de côté de la route de l'adversaire : meuble en haut, eau en bas, règle de distance (0 à 700 m), drapeau du record, ligne d'arrivée, trajectoire en pointillés, 8 emplacements (certains au-delà du record de l'adversaire). Inventaire des pièges prêts en bas (quantités, un piège sélectionné), compteur "3 / 4 posés" et bouton "Valider".

## Direction artistique : pub années 70 (1975)

- Aplats, contours marron épais (5 px), ombres décalées, coins arrondis, léger grain de points.
- Palette : marron #3e2412 (contours, texte), crème #F3E5C0 et #FBF1D6 (panneaux), moutarde #E3A72F, orange brûlé #C8561B, orange de fond #D9822B, vert avocat #7A8B2E, bleu canard #5B9A9A, rouge tomate #B5361F. Bois des caisses #c98d4f, eau #5B9A9A.
- Typos (Google Fonts) : **Caprasimo** pour les titres (remplissage crème, contour marron, double ombre moutarde puis orange), **Shrikhand** pour les slogans, **Josefin Sans** (500 et 700) pour les libellés en majuscules espacées.
- Fond : carrelage de cuisine années 70 (étoiles) avec joints fins et transparents pour éviter l'effet grillage.
- Panneaux : crème, bordure marron 5 px, rayon 24 px, ombre pleine décalée de 7 px. Boutons en pilule. Badges en étoile ou en pastille ("en couleurs !", "Nouveau !").
- Savon : vue de face, corps arrondi crème (#FBF1D6) avec contour marron de 8 px, bras rouille, visage simple (yeux, joues roses, bouche), sangles rouille ou couleur d'équipe, caisse ailée au-dessus (ailes à plumes crème, caisse en bois avec bandeau rouille et étiquette moutarde "SAVON").
- Tous les véhicules sont ailés ou volants (jamais de roues) : plumes, ailes en tissu, hélice, parachute.

## Contenu des maquettes

`docs/design/sources/` contient les écrans en HTML (planches 1456 x 819 px) :

| Fichier | Écran |
|---|---|
| `Titre.dc.html` | Écran titre |
| `Main.dc.html` | Atelier (interactif : caisses et pièges, craft) |
| `Equipes.dc.html` | Choix de l'équipe et de la couleur du savon (interactif) |
| `Vol.dc.html` | En plein vol |
| `Pieges.dc.html` | Pose des pièges |
| `Score.dc.html` | Écran de score excellent (composant partagé, prop `mood`) |
| `Bon.dc.html`, `Moyen.dc.html`, `Mauvais.dc.html`, `Catastrophe.dc.html` | Autres niveaux de score |

Ces fichiers sont des maquettes, pas du code de jeu : ils servent de référence visuelle (positions, couleurs, formes SVG) à reproduire dans Godot.

## Questions ouvertes

- Durée d'une partie et longueur totale du parcours (800 m dans le prototype, 700 m dans la maquette) ?
- Équilibrage des coûts des caisses, des matériaux, de la densité d'obstacles et, plus tard, des jauges et du nombre de pièges par manche.
- Mode adversaire : asynchrone (pièges posés pour la manche suivante) ou en direct ? Solo contre IA, ou entre amis ?
