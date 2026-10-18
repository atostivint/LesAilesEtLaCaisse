# Les ailes et la caisse

> *Courses de monsieurs propres. Satisfait ou remoussé !*

Un savon, une caisse à savon ailée, une piste et un seul but : **voler le plus loin possible** jusqu'à la ligne d'arrivée. Le tout dans l'esprit d'une publicité de lessive de 1975, avec un humour de feuilleton télé.

## Le jeu

- **Décolle** : descends le tremplin et appuie sur Espace dans la zone rouge pour un bonus de vitesse.
- **Vole** : maintiens Espace (ou flèche haut, W, Entrée, clic gauche) pour monter, relâche pour retomber, comme dans Jetpack Joyride.
- **Ramasse** planches, plumes, élastiques et étoiles sur les étagères, et évite les pinces à linge et les planches à clous. Chaque obstacle te coûte une aile ; sans aile, le savon tombe dans l'eau savonneuse.
- **Améliore** ta caisse à l'atelier avec les matériaux récoltés : caisse cercueil, carton, baignoire, baguette, poisson. Plus elle est lourde, plus elle file, mais plus elle retombe vite.
- **Savoure** l'écran de score : cinq niveaux, de « La gloire de Madame » au « Grand désastre domestique ».

Le concept complet, les mécaniques et la direction artistique sont dans [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md). Les maquettes sont dans [docs/design/](docs/design/).

## Télécharger et jouer

Les versions Windows, macOS et Linux se téléchargent sur la page itch.io du jeu. Aucune installation : décompresser et lancer.

- **macOS** : l'application n'est pas signée. Au premier lancement, clic droit sur l'app, puis « Ouvrir ».
- **Linux** : rendre le fichier exécutable (`chmod +x LesAilesEtLaCaisse.x86_64`).

## Compiler les versions

Les presets d'export (`export_presets.cfg`) sont dans le dépôt. Avec les modèles d'export Godot 4.7 installés :

```bash
godot --headless --path . --export-release "Windows" builds/windows/LesAilesEtLaCaisse.exe
godot --headless --path . --export-release "Linux" builds/linux/LesAilesEtLaCaisse.x86_64
godot --headless --path . --export-release "macOS" builds/macos/LesAilesEtLaCaisse.zip
```

Sur Mac, remplacer `godot` par `/Applications/Godot.app/Contents/MacOS/Godot`. Le dossier `builds/` est ignoré par git.

## Développer

### Démarrer

1. Installer **Godot 4.7** (version standard, pas .NET) : <https://godotengine.org/download>
2. Cloner le dépôt :
   ```bash
   git clone https://github.com/atostivint/LesAilesEtLaCaisse.git
   ```
3. Dans Godot : **Importer** → sélectionner `project.godot` → **Importer et éditer**.
4. Lancer le jeu avec **F5** (scène principale : `Mathilde/main_menu.tscn`).

Le premier import crée le dossier `.godot/` (cache local, ignoré par git). C'est normal.

## Structure

| Dossier | Contenu |
|---|---|
| `scenes/` | Scènes : `atelier` (déblocage et choix des caisses, une ligne `crate_row` par caisse), `vol` (la course au jetpack, avec son HUD) et les éléments du décor, chacun dessiné dans sa scène : `soap`, `shelf`, `pince`, `clous`, `warning_badge`, `pickup`, `distance_marker` |
| `scripts/` | Code GDScript : `game_state.gd` (autoload global), `flight_sim.gd` (physique du vol), `course.gd` (parcours généré depuis une graine), `course_view.gd` (place les scènes du parcours), `vol.gd` et `hud.gd` (écran de vol et interface), `atelier.gd` et `crate_row.gd` (atelier), plus de petits scripts attachés aux scènes du décor |
| `data/tuning.tres` | Valeurs d'équilibrage, modifiables dans l'inspecteur de Godot. Elle liste aussi les caisses et les matériaux (champs « Contenu ») |
| `data/crates/*.tres`, `data/materials/*.tres` | Une Resource par caisse (`CrateData`) et par matériau (`MaterialData`), éditable dans l'inspecteur. Pour ajouter une caisse : duplique un `.tres`, ajoute-le à `crates` dans `data/tuning.tres`, puis duplique une ligne de `scenes/atelier.tscn` et choisis-la dans son champ `crate` |
| `tools/` | Scripts utilitaires : simulation d'équilibrage et captures d'écran automatiques |
| `docs/` | Document de conception et maquettes |

## Outils d'équilibrage

Simulation sans interface (un bot joue chaque caisse à la place du joueur) pour estimer le nombre de tours nécessaires pour tout débloquer :

```bash
godot --headless --path . -s tools/simulate.gd
```

Sur Mac, remplacer `godot` par `/Applications/Godot.app/Contents/MacOS/Godot`.

Captures d'écran automatiques des écrans (fenêtre réelle) :

```bash
godot --path . -s tools/screenshots.gd -- ./captures
```

## Travailler à plusieurs

- Ne pas commiter `.godot/` (déjà dans `.gitignore`).
- Les fichiers `.uid` à côté des scripts **doivent** être commités : ils gardent les références entre scènes.
- Pour éviter les conflits sur les `.tscn`, éviter de modifier la même scène à deux en même temps.
- Les commits et la documentation sont en français.

## Fichiers liés à Claude Code (facultatifs)

`CLAUDE.md` et `.mcp.json` ne servent qu'à Claude Code. Si vous n'utilisez pas cet outil, vous pouvez les ignorer : le projet fonctionne sans.
