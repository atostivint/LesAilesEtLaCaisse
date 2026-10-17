# LesAilesEtLaCaisse

Projet Godot. Voir `project.godot` et `.mcp.json` (serveur MCP Godot).

## Orchestration des agents

### Tâches simples → sous-agents Haiku
Les tâches simples sont déléguées à des sous-agents via l'outil `Agent` avec `model: "haiku"`.

Exemples de tâches simples :
- Recherche / lecture de fichiers, grep, inventaire de la structure du projet
- Modifications mécaniques (renommage, formatage, ajout de commentaires, petits ajustements)
- Création de scènes ou nœuds Godot triviaux, génération de boilerplate
- Lancer le projet et récupérer la sortie de debug
- Mise à jour de documentation simple

Les opérations git de routine (commit, push, pull) sont **toujours** déléguées à un sous-agent Haiku quand l'utilisateur demande « commit et push ». Les décisions restent à l'agent principal (ex. branche inexistante, conflit) ; le sous-agent exécute.

Consignes :
- Donner à chaque sous-agent un brief complet et autonome (fichiers concernés, résultat attendu).
- Lancer en parallèle les tâches indépendantes.
- Vérifier le résultat (diff, sortie) avant de le déclarer terminé.

### Tâches complexes → agent principal
Conception d'architecture, logique de gameplay non triviale, débogage difficile, décisions de design : traitées directement par l'agent principal, pas déléguées à Haiku.

### Advisor (Opus)
L'advisor est configuré sur Opus (`/advisor opus`). Si une information, un avis ou une validation est nécessaire (choix d'approche, blocage, vérification avant de conclure), l'agent principal consulte l'advisor, qui peut à son tour demander des informations à Opus.

Appeler l'advisor :
- avant un travail de fond (choix d'approche),
- en cas de blocage ou de résultats incohérents,
- avant de déclarer une tâche terminée.
