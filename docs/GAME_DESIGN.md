# Les ailes et la caisse : résumé de conception

Document de référence pour le développement Godot. Il reprend les décisions prises pendant la conception (mécaniques, direction artistique, écrans). Les maquettes sont dans `docs/design/`.

## Concept

Un savon porte une caisse à savon sur le dos comme un sac à dos. Il descend une piste, la quitte, puis **vole le plus longtemps possible grâce à sa caisse ailée**. Le but est d'aller le plus loin possible, jusqu'à une ligne d'arrivée dont la distance restante est affichée. Ton : publicité de lessive de 1975, humour de soap opera ("Satisfait ou remousse !", "Plus blanc que blanc !").

Nom du jeu : **Les ailes et la caisse**. Sous-titre sur l'écran titre : "Courses de monsieurs propres".

## Boucle de jeu

1. Atelier : je fabrique des caisses et des pièges avec les matériaux récoltés.
2. Équipes : je choisis l'équipe du savon (cosmétique) et la couleur du savon.
3. Course : descente de piste, décollage, vol.
4. En vol : rattraper des pièces, prendre des boosters (jets de bulles), éviter des pièges.
5. Fin : le savon tombe dans l'eau savonneuse après trop de pièges (plus d'ailes), ou franchit la ligne d'arrivée.
6. Score (5 niveaux d'écran), retour à l'atelier avec les pièces récoltées.
7. Pose des pièges : je place mes pièges sur la route de l'adversaire pour la manche suivante (4 par manche pour l'instant), il fait de même pour moi.

## Vol (écran principal du jeu)

- Défilement horizontal vers la droite. Le savon est en l'air, légèrement incliné vers le haut.
- Haut de l'écran : liseret du bas d'un meuble (planche de bois, filet moutarde, feston crème). Bas de l'écran : eau savonneuse (vagues bleu canard, écume). Quelques bulles discrètes flottent toujours autour.
- HUD : distance parcourue (ex. 412 m), distance jusqu'à la ligne d'arrivée avec barre de progression (ex. 288 m sur 700 m), ailes restantes (3 plumes, une par piège encaissé avant la chute), récolte (planches, étoiles, plumes).
- Repères de distance (fanions 400, 500, 600 m) sur la ligne d'eau, ligne d'arrivée en ruban à damier au bout (700 m).
- Éléments à rattraper (pièces pour l'atelier) : planche, plume, étoile dorée. Ne pas en mettre trop.
- Boosters : jet de bulles (chevrons et grosses bulles).
- Pièges à éviter : pince à linge géante pendue au meuble, planche à clous flottante, etc. Marqués d'une pastille "!".

## Atelier (inventaire et craft)

Deux onglets : **Caisses** et **Pièges**. Même sac de matériaux pour les deux.

Matériaux (stock de départ de la maquette) : planches de pin 14, clous 40, corde 5, peinture rouge 3, bulles 6, étoiles dorées 2, plumes 16 (ex "roues"), rideau de douche 3.

La caisse de départ (caisse classique avec ailes à plumes) est gratuite et ne se fabrique pas. Les caisses à thème sont inspirées des courses Red Bull :

| Caisse | Système de vol | Coût | Solidité / Glisse / Vol |
|---|---|---|---|
| La Baignoire | ailes en rideau de douche | 6 planches, 4 plumes, 1 rideau, 2 bulles | 3 / 3 / 4 |
| Le Crayon géant | propulsion par taille-crayon | 5 planches, 8 clous, 4 plumes, 2 peintures | 2 / 5 / 3 |
| Le Sachet de nuggets | parachute en papier gras | 4 planches, 4 plumes, 1 rideau, 1 peinture | 2 / 3 / 5 |
| La Machine à laver | essorage turbo | 7 planches, 12 clous, 4 plumes, 3 bulles | 5 / 2 / 3 |
| La Baguette géante | ailes en croissants | 3 planches, 2 cordes, 4 plumes, 1 étoile | 2 / 4 / 4 |

Pièges (jauges Gêne / Surprise / Durée) :

| Piège | Effet | Coût | Jauges |
|---|---|---|---|
| La Flaque de mousse | les rivaux dérapent sans contrôle | 5 bulles, 1 rideau | 4 / 3 / 3 |
| La Planche à clous | perce les ailes, perte de vol | 3 planches, 12 clous | 5 / 2 / 4 |
| Le Filet à linge | retient la caisse quelques secondes | 3 cordes, 1 rideau, 4 clous | 4 / 4 / 2 |
| Le Canon à bulles | nuage de mousse qui masque la pente | 4 planches, 4 bulles, 4 clous | 3 / 5 / 3 |
| La Pince à linge géante | accroche la caisse et la fait pendre | 3 planches, 4 clous, 1 corde, 1 peinture | 4 / 3 / 5 |

Tous les coûts, jauges, limites (4 pièges par manche, 3 ailes) et le record de 512 m de l'écran de pose sont des **valeurs provisoires** de maquette, à équilibrer.

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

## Écran de pose des pièges

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

- Vue 2D de côté confirmée pour le vol ; comment se passe le décollage depuis la piste ?
- Durée d'une partie et longueur totale du parcours (700 m dans la maquette) ?
- Équilibrage des matériaux, coûts, jauges et nombre de pièges par manche.
- Mode adversaire : asynchrone (pièges posés pour la manche suivante) ou en direct ? Solo contre IA, ou entre amis ?
- Budget de customisation (pièces, énergie) ou libre ?
