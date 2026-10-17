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
| `scenes/` | Scènes : `atelier` (menu/améliorations), `vol` (la course), `soap`, `upgrade_row` |
| `scripts/` | Code GDScript (`game_state.gd` est un autoload global, `flight_sim.gd` la physique du vol) |
| `data/tuning.tres` | Valeurs d'équilibrage, modifiables dans l'inspecteur de Godot |
| `tools/` | Scripts utilitaires : simulation d'équilibrage et captures d'écran automatiques |
| `docs/` | Document de conception et maquettes |

## Outils d'équilibrage

Simulation sans interface (un bot joue à la place du joueur) pour estimer les distances selon le niveau des améliorations :

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
