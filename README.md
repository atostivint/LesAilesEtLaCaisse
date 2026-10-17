# Les ailes et la caisse

Jeu Godot : un savon, une caisse à savon ailée, une piste, et le plus long vol possible jusqu'à la ligne d'arrivée. Sous-titre : « Courses de monsieurs propres ».

Le concept, les mécaniques et les écrans sont décrits dans [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md). Les maquettes sont dans [docs/design/](docs/design/).

## Démarrer

1. Installer **Godot 4.7** (version standard, pas .NET) : <https://godotengine.org/download>
2. Cloner le dépôt :
   ```bash
   git clone https://github.com/atostivint/LesAilesEtLaCaisse.git
   ```
3. Dans Godot : **Importer** → sélectionner `project.godot` → **Importer et éditer**.
4. Lancer le jeu avec **F5** (scène principale : `scenes/atelier.tscn`).

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
