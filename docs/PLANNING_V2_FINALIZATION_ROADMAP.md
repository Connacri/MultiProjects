# Planning V2 — Roadmap de finalisation du projet

> **Objectif final :** obtenir une version de Planning V2 compilable, testée, persistante, offline-first, fonctionnelle dans l'APK Release, puis prête pour l'intégration Supabase, Realtime, RLS et la suppression progressive du legacy.

---

# 0. Règle de finalisation

- [ ] Geler l'architecture actuelle de Planning V2
- [ ] Ne plus lancer de refonte architecturale majeure
- [ ] Corriger uniquement les erreurs bloquantes ou les incohérences démontrées par les tests
- [ ] Transformer les règles métier implicites en tests automatisés
- [ ] Valider chaque étape avant de passer à la suivante
- [ ] Ne pas intégrer Supabase avant validation complète du Planning local
- [ ] Ne pas supprimer le legacy avant validation du nouveau Planning

# PHASE 1 — 🔴 Audit et intégrité du repository

## 1.1 Vérifier la branche `main`

- [ ] Vérifier que `main` contient bien la dernière version du Planning V2
- [ ] Vérifier le dernier commit réellement déployable
- [ ] Vérifier les modifications non commitées
- [ ] Vérifier les fichiers ajoutés / supprimés
- [ ] Vérifier les éventuels conflits de merge
- [ ] Vérifier que `MyApp.dart` utilise bien le nouveau `PlanningWorkspace`
- [ ] Vérifier que l'ancien écran Planning n'est plus l'écran actif

## 1.2 Auditer `classeObjectBox.dart`

- [ ] Vérifier que le fichier n'est pas tronqué
- [ ] Vérifier toutes les anciennes boxes ObjectBox
- [ ] Vérifier `planningSnapshotBox`
- [ ] Vérifier `planningAssignmentBox`
- [ ] Vérifier `rotationStateSnapshotBox`
- [ ] Vérifier les méthodes historiques du bootstrap ObjectBox
- [ ] Vérifier l'ouverture et la fermeture du `Store`

## 1.3 Vérifier les entités ObjectBox

- [ ] Vérifier `PlanningSnapshotEntity`
- [ ] Vérifier `PlanningAssignmentEntity`
- [ ] Vérifier `RotationStateSnapshotEntity`
- [ ] Vérifier les annotations ObjectBox
- [ ] Vérifier les UID ObjectBox
- [ ] Vérifier les relations entre entités
- [ ] Vérifier la compatibilité avec les anciennes entités

# PHASE 2 — 🔴 Régénération ObjectBox

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] Exécuter `build_runner`
- [ ] Vérifier l'absence d'erreur
- [ ] Vérifier l'absence de conflit de génération
- [ ] Vérifier les UID ObjectBox
- [ ] Vérifier `objectbox.g.dart`
- [ ] Vérifier la présence des 3 nouvelles entités dans le code généré
- [ ] Vérifier qu'aucune ancienne entité n'a disparu

## Test ObjectBox minimal

- [ ] Créer un Store temporaire de test
- [ ] Ouvrir les 3 boxes Planning
- [ ] Insérer un Snapshot
- [ ] Insérer des Assignments
- [ ] Insérer un RotationStateSnapshot
- [ ] Relire les données
- [ ] Vérifier les relations métier
- [ ] Fermer le Store

# PHASE 3 — 🔴 Compilation et analyse statique

```bash
flutter pub get
flutter analyze
```

- [ ] Obtenir `0 errors`
- [ ] Corriger les constructeurs et signatures
- [ ] Vérifier `PlanningComposition.fromStore()`
- [ ] Vérifier `PlanningRepository`
- [ ] Vérifier `RotationEngine`
- [ ] Vérifier `TeamScheduleGenerator`
- [ ] Vérifier `RotationContinuityResolver`
- [ ] Vérifier `PlanningDraftPipeline`
- [ ] Vérifier `PlanningValidator`
- [ ] Vérifier tous les Use Cases
- [ ] Vérifier tous les Providers
- [ ] Vérifier `PlanningWorkspaceController`
- [ ] Vérifier `PlanningWorkspace`

# PHASE 4 — 🔴 Tests automatisés de base

```bash
flutter test
```

- [ ] Corriger tous les tests cassés
- [ ] Vérifier les tests Domain
- [ ] Vérifier les tests Use Cases
- [ ] Vérifier les tests Services
- [ ] Vérifier les tests Repositories
- [ ] Vérifier les tests Providers
- [ ] Tester Save / Load Snapshot
- [ ] Tester Save / Load Assignments
- [ ] Tester Save / Load RotationState
- [ ] Tester les transactions ObjectBox
- [ ] Vérifier Domain Identity ≠ ObjectBox Persistence ID

# PHASE 5 — 🔴 Revision / Publish

## Revision lifecycle

- [ ] Créer Revision 1
- [ ] Sauvegarder Revision 1
- [ ] Publier Revision 1
- [ ] Créer Revision 2
- [ ] Modifier Revision 2
- [ ] Sauvegarder Revision 2
- [ ] Publier Revision 2
- [ ] Vérifier que Revision 1 reste immuable

## Stale Revision

- [ ] Créer R1 Published
- [ ] Créer R2 Draft
- [ ] Créer R3 Draft
- [ ] Publier R3
- [ ] Tenter de publier R2
- [ ] Vérifier que R2 est rejetée
- [ ] Vérifier que R3 reste publiée

## Publication atomique

- [ ] Tester publication Snapshot
- [ ] Tester publication Assignments
- [ ] Tester publication RotationState
- [ ] Simuler une erreur pendant la transaction
- [ ] Vérifier le rollback
- [ ] Vérifier l'absence de données partiellement publiées
- [ ] Tester retry
- [ ] Tester concurrence

# PHASE 6 — 🔴 Tests P0 de continuité Planning

## Continuité Janvier → Février → Mars

```text
Configuration V1
    ↓
Janvier Generate
    ↓
Janvier Publish
    ↓
Février Generate
    ↓
Février Publish
    ↓
Mars Generate
```

- [ ] Vérifier que Février utilise l'état publié de Janvier
- [ ] Vérifier que Mars utilise l'état publié de Février
- [ ] Vérifier que les drafts ne servent jamais de continuité officielle

## Revision manuelle → continuité

- [ ] Générer Février
- [ ] Modifier Février
- [ ] Ajouter un Manual Override
- [ ] Publier Février
- [ ] Générer Mars
- [ ] Vérifier que Mars utilise l'état publié de Février
- [ ] Vérifier qu'un override non publié n'influence pas Mars

## Changement de `teamOrder`

```text
Avant : [A, B, C, D]
Après : [C, A, D, B]
```

- [ ] Vérifier la continuité par `teamId`
- [ ] Vérifier que l'ordre de la liste ne définit pas l'identité
- [ ] Vérifier que A, B, C et D conservent leur phase

## Historical Load

- [ ] Publier Janvier
- [ ] Modifier la configuration
- [ ] Charger Janvier
- [ ] Vérifier que Janvier est identique
- [ ] Vérifier qu'aucun recalcul n'est effectué
- [ ] Vérifier que `RotationEngine` n'est pas appelé
- [ ] Vérifier que `GeneratePlanning` n'est pas appelé

Invariant : `LOAD != GENERATE`

# PHASE 7 — 🟠 Règles métier complexes

## Availability

- [ ] Tester `available`
- [ ] Tester `unavailable`
- [ ] Tester conflit Rotation / Availability
- [ ] Tester plusieurs indisponibilités

## Leave

- [ ] Tester Rotation + Leave
- [ ] Tester Availability + Leave
- [ ] Formaliser la priorité métier

## Manual Override

- [ ] Tester Rotation + Override
- [ ] Tester Availability + Override
- [ ] Tester Leave + Override
- [ ] Tester Override publié
- [ ] Tester Override non publié

- [ ] Documenter explicitement l'ordre de priorité
- [ ] Ajouter des tests pour chaque combinaison critique

# PHASE 8 — 🟠 Gestion dynamique des équipes

## Ajout d'équipe

```text
Janvier : A B C D
Février : A B C D E
```

- [ ] Définir la phase initiale de E
- [ ] Formaliser la règle métier
- [ ] Ajouter un test
- [ ] Vérifier la continuité des équipes existantes
- [ ] Vérifier qu'une nouvelle équipe ne réinitialise pas la rotation globale

## Suppression d'équipe

```text
Janvier : A B C D
Février : A B C
```

- [ ] Vérifier la suppression de D dans RotationState
- [ ] Vérifier la suppression de D dans Assignments
- [ ] Vérifier la suppression de D dans Snapshot
- [ ] Générer Mars
- [ ] Vérifier que D ne réapparaît pas

# PHASE 9 — 🟠 Changement de configuration

```text
Configuration V1
    ↓
Janvier Published
    ↓
Configuration V2
    ↓
Février Generated
```

- [ ] Vérifier que Janvier reste inchangé
- [ ] Vérifier que Février utilise V2
- [ ] Vérifier que Février continue depuis Janvier
- [ ] Vérifier `configurationId`
- [ ] Vérifier `configurationVersion`
- [ ] Ajouter un test de non-régression

# PHASE 10 — 🟠 Persistence E2E

```text
Generate
    ↓
Save
    ↓
Load
    ↓
Edit
    ↓
Save Revision
    ↓
Publish
    ↓
Reload
```

- [ ] Vérifier l'identité du Planning
- [ ] Vérifier l'identité de la Revision
- [ ] Vérifier les Assignments
- [ ] Vérifier les dates
- [ ] Vérifier le RotationState
- [ ] Vérifier `configurationId` et `configurationVersion`
- [ ] Vérifier les timestamps UTC
- [ ] Vérifier l'immutabilité de l'historique

# PHASE 11 — 🔴 Test E2E Planning V2 complet

```text
Configuration V1
    ↓
Janvier Generate
    ↓
Janvier Publish
    ↓
Février Generate
    ↓
Février Revision
    ↓
Manual Override
    ↓
Février Publish
    ↓
Mars Generate
    ↓
Vérification continuité
    ↓
Changement teamOrder
    ↓
Avril Generate
    ↓
Vérification identité équipe
    ↓
Reload Janvier
    ↓
Vérification absence de recalcul
```

- [ ] Créer le test E2E
- [ ] Vérifier toutes les étapes
- [ ] Vérifier la continuité
- [ ] Vérifier les revisions
- [ ] Vérifier les overrides
- [ ] Vérifier le changement de `teamOrder`
- [ ] Vérifier l'historique
- [ ] Vérifier l'absence de recalcul
- [ ] Vérifier ObjectBox après chaque étape

> **Ce test devient le test de référence de Planning V2.**

# PHASE 12 — 🔴 Validation UI

- [ ] Vérifier que `PlanningWorkspace` est l'écran actif
- [ ] Vérifier que l'ancien Planning n'est plus affiché
- [ ] Vérifier chargement d'un Planning existant
- [ ] Vérifier création
- [ ] Vérifier édition
- [ ] Vérifier validation
- [ ] Vérifier sauvegarde
- [ ] Vérifier publication
- [ ] Vérifier rechargement
- [ ] Vérifier les états loading / error / empty / success

# PHASE 13 — 🔴 Source de vérité UI

```text
ObjectBox
    ↓
PlanningSnapshot
    ├── Planning UI
    └── PDF
```

- [ ] Vérifier que l'UI historique charge le Snapshot
- [ ] Vérifier que l'UI ne recalcule pas l'historique
- [ ] Vérifier que `LoadPlanning` ne déclenche pas `GeneratePlanning`
- [ ] Vérifier qu'un changement de configuration ne modifie pas l'historique
- [ ] Vérifier affichage = données persistées

# PHASE 14 — 🔴 PDF / Export

- [ ] Auditer le générateur PDF
- [ ] Vérifier qu'il consomme `PlanningSnapshot`
- [ ] Vérifier qu'il ne lance pas `GeneratePlanning`
- [ ] Générer un PDF depuis un Snapshot existant
- [ ] Comparer PDF et UI
- [ ] Vérifier dates, Assignments, équipes et overrides

Invariant :

```text
PDF(snapshot)
=
UI(snapshot)
=
Persisted Snapshot
```

# PHASE 15 — 🔴 Offline-first

```text
Application
    ↓
Offline
    ↓
Load Planning local
    ↓
Edit
    ↓
Save ObjectBox
    ↓
Close App
    ↓
Restart App
    ↓
Load local
```

- [ ] Tester démarrage sans réseau
- [ ] Charger un Planning local
- [ ] Modifier le Planning
- [ ] Sauvegarder localement
- [ ] Fermer et redémarrer
- [ ] Vérifier la persistance
- [ ] Vérifier les revisions locales
- [ ] Vérifier l'historique
- [ ] Vérifier qu'aucun appel réseau n'est obligatoire

# PHASE 16 — 🔴 CI/CD GitHub Actions

Workflow cible :

```text
Push
    ↓
flutter pub get
    ↓
build_runner
    ↓
flutter analyze
    ↓
flutter test
    ↓
flutter build apk --release
```

- [ ] Vérifier la présence du workflow GitHub Actions
- [ ] Vérifier le déclenchement sur `main`
- [ ] Vérifier le déclenchement sur Pull Request
- [ ] Ajouter `flutter pub get`
- [ ] Ajouter `build_runner`
- [ ] Ajouter `flutter analyze`
- [ ] Ajouter `flutter test`
- [ ] Ajouter `flutter build apk --release`
- [ ] Vérifier le succès du workflow
- [ ] Vérifier l'artifact APK
- [ ] Vérifier qu'un commit cassé bloque la CI

# PHASE 17 — 🔴 Build Release et Smoke Test

```bash
flutter build apk --release
```

- [ ] Générer l'APK Release
- [ ] Installer l'APK
- [ ] Vérifier `PlanningWorkspace`
- [ ] Vérifier ObjectBox
- [ ] Vérifier création / édition / validation / publication
- [ ] Vérifier persistence
- [ ] Redémarrer l'application
- [ ] Vérifier le rechargement
- [ ] Vérifier l'absence de crash

# PHASE 18 — 🟠 Supabase

> À commencer uniquement après validation complète du Planning local.

- [ ] Définir le modèle Supabase
- [ ] Définir les tables Planning / Assignments / Revisions / Configurations
- [ ] Créer le repository Supabase
- [ ] Définir ObjectBox comme source locale
- [ ] Définir la stratégie de synchronisation
- [ ] Définir la résolution de conflits
- [ ] Implémenter Pull / Push / Retry
- [ ] Implémenter Offline Queue
- [ ] Implémenter Auth
- [ ] Définir les rôles
- [ ] Implémenter RLS
- [ ] Tester les policies RLS
- [ ] Définir les événements Realtime
- [ ] Synchroniser les changements avec ObjectBox
- [ ] Gérer reconnexion et conflits

# PHASE 19 — 🟠 Migration progressive du Legacy

> À faire uniquement lorsque Planning V2 est validé en production.

- [ ] Identifier les consommateurs de `PlanningHebdoProvider`
- [ ] Identifier les consommateurs de `TypeActiviteProvider`
- [ ] Identifier les anciennes UI
- [ ] Identifier les anciennes routes
- [ ] Migrer les écrans restants
- [ ] Migrer les services restants
- [ ] Migrer les tests
- [ ] Supprimer les dépendances inutilisées
- [ ] Supprimer le typedef `TeamShift`
- [ ] Supprimer `PlanningHebdoProvider`
- [ ] Supprimer `TypeActiviteProvider`
- [ ] Supprimer les anciennes UI et routes
- [ ] Régénérer ObjectBox
- [ ] Relancer tous les tests

# PHASE 20 — 🔴 Release Candidate

## Architecture

- [ ] Architecture gelée
- [ ] Clean Architecture validée
- [ ] Composition Root validée
- [ ] Dependency Injection validée

## Persistence

- [ ] ObjectBox généré
- [ ] ObjectBox testé
- [ ] Persistence E2E validée

## Métier

- [ ] Continuité 3 mois validée
- [ ] Revision → continuité validée
- [ ] Team reorder validé
- [ ] Team add validé
- [ ] Team removal validé
- [ ] Configuration V1 → V2 validée
- [ ] Availability validée
- [ ] Leave validé
- [ ] Override precedence validée

## Historique et publication

- [ ] Snapshot immuable
- [ ] Historical Load validé
- [ ] Load sans recalcul validé
- [ ] Stale revision validée
- [ ] Publication atomique validée
- [ ] Transaction failure validée
- [ ] Retry validé

## UI / Export / Offline

- [ ] PlanningWorkspace validé
- [ ] CRUD validé
- [ ] Validation validée
- [ ] Publication validée
- [ ] Reload validé
- [ ] PDF basé sur Snapshot
- [ ] PDF = UI
- [ ] Démarrage offline validé
- [ ] Modification offline validée
- [ ] Persistence offline validée

## CI/CD / Release

- [ ] GitHub Actions vert
- [ ] `flutter analyze` vert
- [ ] `flutter test` vert
- [ ] `flutter build apk --release` vert
- [ ] APK Release généré
- [ ] APK installé
- [ ] Smoke test effectué
- [ ] Aucun bug P0
- [ ] Aucun bug P1 bloquant

# 🎯 Ordre d'exécution recommandé

## P0 — Bloquant

1. [ ] Audit `classeObjectBox.dart`
2. [ ] Régénération `objectbox.g.dart`
3. [ ] `flutter analyze`
4. [ ] `flutter test`
5. [ ] `flutter build apk --release`
6. [ ] Vérification CI GitHub Actions
7. [ ] Smoke test APK
8. [ ] E2E Janvier → Février → Mars
9. [ ] Revision → continuité
10. [ ] Team reorder
11. [ ] Historical load sans recalcul
12. [ ] Atomic Publish
13. [ ] Stale Revision
14. [ ] E2E Planning V2 complet

## P1 — Important

15. [ ] Availability
16. [ ] Leave
17. [ ] Override precedence
18. [ ] Configuration V1 → V2
19. [ ] Ajout équipe
20. [ ] Suppression équipe
21. [ ] Persistence E2E complète
22. [ ] UI = Snapshot
23. [ ] PDF = Snapshot
24. [ ] Offline-first

## P2 — Après stabilisation

25. [ ] Supabase Repository
26. [ ] Synchronisation Offline → Online
27. [ ] Conflict Resolution
28. [ ] Realtime
29. [ ] RLS
30. [ ] Migration progressive Legacy
31. [ ] Suppression des anciens Providers
32. [ ] Suppression des anciennes UI
33. [ ] Release Candidate
34. [ ] Release Production

# 🏁 Définition de « Planning V2 terminé »

Planning V2 sera considéré comme finalisé lorsque :

```text
ObjectBox
    ✅
    ↓
Compilation
    ✅
    ↓
CI
    ✅
    ↓
Tests unitaires
    ✅
    ↓
Tests intégration
    ✅
    ↓
Tests E2E métier
    ✅
    ↓
PlanningWorkspace
    ✅
    ↓
CRUD
    ✅
    ↓
Revision / Publish
    ✅
    ↓
Continuité
    ✅
    ↓
Historique immuable
    ✅
    ↓
Offline-first
    ✅
    ↓
PDF depuis Snapshot
    ✅
    ↓
APK Release
    ✅
    ↓
Smoke Test
    ✅
    ↓
Supabase
    ✅
    ↓
Realtime
    ✅
    ↓
RLS
    ✅
    ↓
Legacy supprimé
    ✅
    ↓
RELEASE PRODUCTION
```

## Critère final

> **Une seule source de vérité : `PlanningSnapshot`.**

Le système final doit respecter :

```text
GENERATE
    ↓
PlanningSnapshot
    ↓
ObjectBox
    ├── UI
    ├── PDF
    └── Sync Supabase

LOAD
    ↓
PlanningSnapshot
    ↓
Aucun recalcul
```

La finalisation doit donc suivre cette règle : **d'abord rendre Planning V2 local, compilable et testable ; ensuite prouver sa robustesse métier ; ensuite seulement ajouter la synchronisation distante et supprimer le legacy.**
