# Planning — État d'avancement, architecture et feuille de route

> Document de suivi technique du chantier Planning / ObjectBox / CI.
>
> **Règle de travail :** toutes les modifications sont effectuées directement sur `main`. Aucun nouveau workflow CI ne doit être créé sans nécessité. L'objectif est de consolider l'existant, pas d'empiler des `V2` / `V3`.

## 1. Objectif global

Construire un module Planning robuste et maintenable avec :

- Clean Architecture / feature-first ;
- domaine indépendant de Flutter et d'ObjectBox ;
- génération de planning déterministe ;
- continuité de rotation par identité d'équipe ;
- snapshots immuables ;
- révisions explicites ;
- édition des congés et de l'ordre des équipes dans le mois courant, même après validation ;
- badge `Modifié` / `À revalider` après une modification post-validation ;
- blocage de la publication tant que la nouvelle validation n'est pas obtenue ;
- persistance ObjectBox atomique ;
- génération `build_runner` ObjectBox uniquement lorsqu'une entité/modèle concerné change ;
- un seul workflow CI existant ;
- aucun nouveau workflow CI ou branche de développement par défaut.

---

## 2. Travaux réalisés

### 2.1. Nettoyage des imports de tests

Correction de tests Planning qui utilisaient encore l'ancien nom de package `multi_projects` alors que le package courant est `kenzy`.

Travail effectué notamment sur les tests de rotation et de publication.

**Statut :** réalisé.

---

### 2.2. Restauration de la couverture de rotation

Le test `rotation_engine_test.dart` avait perdu une partie de sa couverture comportementale.

La couverture a été restaurée pour vérifier :

- continuité par identité d'équipe après changement d'ordre ;
- continuité sur février de 28 jours ;
- continuité sur février bissextile de 29 jours ;
- comportement de continuité lorsque la date est identique ;
- conservation d'un ordre d'équipe modifié.

**Commit :** `82a20f0eaf4cc750bc886be8b9ef2cbffdb9496b`

**Statut :** réalisé.

---

### 2.3. Contrat ObjectBox / build_runner

Ajout de `tool/check_objectbox_build_runner.dart` pour vérifier le contrat de génération ObjectBox :

- présence de `objectbox` ;
- présence de `objectbox_flutter_libs` ;
- présence de `objectbox_generator` ;
- présence de `build_runner` ;
- présence de `objectbox_generator` dans `pubspec.lock` ;
- présence de `lib/objectbox.g.dart` ;
- vérification minimale du contenu généré.

**Commit :** `afb1ff1688d3a6219601ea0b6d1ca198c06b0c20`

**Statut :** réalisé, mais le contrôle a ensuite été simplifié dans le workflow pour éviter de confondre validation du contrat et génération effective.

---

### 2.4. Génération ObjectBox conditionnelle dans le CI

Le workflow CI existant a été adapté pour :

1. récupérer les fichiers modifiés ;
2. détecter si une entité/modèle ObjectBox est concerné ;
3. lancer `dart run build_runner build --delete-conflicting-outputs` uniquement dans ce cas ;
4. vérifier le code ObjectBox généré ;
5. continuer avec format, analyse et tests.

Un nouvel outil a été ajouté :

`tool/should_run_objectbox_build.dart`

Il détecte notamment les marqueurs :

- `@Entity` ;
- `@Id` ;
- `@Property` ;
- `@Index` ;
- `@Unique` ;
- `@Backlink` ;
- `@Transient` ;
- `@HnswIndex` ;
- `ToOne` ;
- `ToMany` ;
- `Store`.

Les fichiers générés `lib/objectbox.g.dart`, les tests et les outils sont exclus de la détection directe.

**Commits :**

- `8077e9aafc0ec4b4081a830d0ec42df7d0dae002`
- `c98e497ea5b2ef4c392fb147c1c8ead4c1e66760`

**Statut :** réalisé.

### Attention

Le mécanisme doit être validé sur le CI réel. La détection actuelle est volontairement pragmatique et basée sur les fichiers modifiés et les marqueurs présents. Elle devra être ajustée si le projet utilise des modèles ObjectBox indirects ou des entités dont les relations sont définies dans des fichiers séparés.

**Note :** l'upgrade vers ObjectBox 5.3.2 a résolu le problème `getInvocation` sur `DartObjectImpl` qui bloquait `build_runner`. Le générateur fonctionne désormais correctement avec `analyzer 10.2.0` et `source_gen 4.2.4`.

---

### 2.5. Tests du flux édition / révision / revalidation

Ajout de tests autour de `PlanningEditCoordinator` et `PlanningRevisionUiProvider`.

Les invariants couverts sont :

- modification d'un congé après validation ;
- modification de l'ordre des équipes après validation ;
- invalidation de la validation ;
- `isModified == true` ;
- `requiresRevalidation == true` ;
- `isValidated == false` ;
- création d'une nouvelle révision effective ;
- traçabilité du champ modifié ;
- rejet d'une modification post-validation sur un mois précédent.

**Commit :** `3377c3153413b65d73971c0bbdd34b2cea07a7f2`

**Statut :** réalisé.

---

### 2.6. Tests de persistance des révisions ObjectBox

Ajout de tests pour la persistance des révisions Planning.

Les tests vérifient :

- sauvegarde d'une révision modifiée/non validée ;
- restauration de `changedFields` ;
- restauration de `effectiveSnapshotId` ;
- restauration de `validated` ;
- sélection de la dernière révision d'un mois.

**Commit :** `90e0b60c5fa81985e8b8e547b572fdcbf1962443`

**Statut :** réalisé.

---

### 2.7. Tests de persistance atomique des snapshots ObjectBox

Ajout de tests pour `ObjectBoxPlanningSnapshotStore`.

Les tests couvrent :

- persistance atomique du snapshot et de ses assignments ;
- rattachement des assignments au snapshot ;
- isolation par `branchId` ;
- conservation de l'intégrité du snapshot publié lorsqu'une autre révision est ensuite persistée.

**Commit :** `d66a20fc3256d4aad1f9458d6fc7f94bd98c77df`

**Statut :** réalisé.

---

## 3. Architecture cible

```text
UI
  │
  ▼
PlanningProvider / PlanningEditorProvider
  │
  ▼
PlanningEditCoordinator
  │
  ▼
Application Use Cases
  ├── GeneratePlanning
  ├── LoadPlanning
  └── PublishPlanning
  │
  ▼
Domain
  ├── PlanningSnapshot
  ├── PlanningRevision
  ├── PlanningAssignment
  ├── RotationConfiguration
  ├── RotationStateSnapshot
  ├── PlanningValidator
  ├── PlanningRevisionPolicy
  └── RotationEngine
  │
  ▼
Repository interface
  │
  ▼
Data
  ├── ObjectBox datasource
  ├── ObjectBox repositories
  └── Domain ↔ Entity mappers
```

### Règles d'architecture

- `domain` ne dépend pas d'ObjectBox.
- `domain` ne dépend pas de Flutter.
- `presentation` ne manipule pas directement les `Box<T>` ObjectBox.
- `presentation` ne contient pas la logique métier de rotation.
- les use cases orchestrent les opérations applicatives.
- les repositories exposent des abstractions au domaine/application.
- ObjectBox reste dans `data`.
- les snapshots publiés doivent rester immuables.
- une modification du mois courant crée une nouvelle révision/snapshot effectif.
- le snapshot publié original ne doit jamais être écrasé par une modification.

---

## 4. Règle métier de modification post-validation

Le comportement attendu est :

```text
Planning publié
      │
      ▼
Modification congé / ordre équipe
      │
      ▼
Nouvelle révision
      │
      ├── status = modified
      ├── validated = false
      ├── requiresRevalidation = true
      └── badge = "Modifié • À revalider"
      │
      ▼
Validation
      │
      ├── échec → publication bloquée
      │
      └── succès
            │
            ▼
      Publication nouvelle révision
```

### Restrictions

- modification autorisée uniquement pour le mois courant ;
- les mois précédents restent verrouillés après validation ;
- une modification post-validation doit obligatoirement invalider la validation précédente ;
- le badge `Modifié` doit rester visible tant que la nouvelle version n'est pas validée ;
- la publication doit utiliser la nouvelle révision validée ;
- le snapshot publié précédent doit rester disponible pour l'historique.

---

## 5. Problèmes encore à corriger

### P0 — Lecture ObjectBox ambiguë des snapshots

`ObjectBoxPlanningSnapshotStore.findByMonth()` retourne actuellement le premier snapshot trouvé pour le mois/branche.

Cela ne permet pas de distinguer explicitement :

- snapshot publié ;
- dernier snapshot effectif ;
- snapshot d'une révision précise.

### Action à faire

Introduire explicitement :

```dart
PlanningSnapshotEntity? findPublishedByMonth({
  required int year,
  required int month,
  int? branchId,
});

PlanningSnapshotEntity? findLatestByMonth({
  required int year,
  required int month,
  int? branchId,
});

PlanningSnapshotEntity? findByRevision({
  required int year,
  required int month,
  required int revision,
  int? branchId,
});
```

Puis ajouter des tests de régression.

**Priorité : P0**

---

### P0 — Atomicité métier de la publication

Vérifier que la publication d'une nouvelle révision :

1. valide le snapshot ;
2. écrit le nouveau snapshot ;
3. marque l'ancien snapshot comme historique/publication précédente si nécessaire ;
4. met à jour la révision ;
5. ne laisse jamais un état partiellement publié.

L'opération doit être atomique au niveau ObjectBox ou orchestrée avec une transaction unique.

**Priorité : P0**

---

### P0 — Séparer clairement `published` et `effective/latest`

Le stockage doit permettre de répondre sans ambiguïté à :

- « Quel planning est actuellement publié ? »
- « Quelle est la dernière version modifiée ? »
- « Quelle version était publiée avant modification ? »
- « Quelle version dois-je afficher dans l'historique ? »

**Priorité : P0**

---

### P1 — Consolider les modèles `V2` / `V3`

L'audit a identifié plusieurs variantes historiques de modèles/services/repositories Planning.

À faire :

- identifier les classes réellement utilisées ;
- supprimer les variantes mortes ;
- conserver une seule source de vérité par concept ;
- ne jamais recycler un UID ObjectBox déjà utilisé ;
- conserver les anciens modèles uniquement si nécessaires à la migration ;
- documenter les migrations.

**Priorité : P1**

---

### P1 — Vérifier les UIDs ObjectBox

Avant toute suppression ou fusion d'entités :

- inspecter `objectbox-model.json` ;
- identifier les UIDs existants ;
- vérifier les UIDs des entités et propriétés ;
- éviter toute réutilisation d'UID ;
- lancer `build_runner` après consolidation ;
- vérifier le diff du modèle généré.

**Priorité : P1**

---

### P1 — Tests de migration ObjectBox

Ajouter des tests pour :

- ouverture d'une base existante ;
- migration du modèle ;
- conservation des snapshots publiés ;
- conservation des révisions ;
- conservation des assignments ;
- compatibilité après génération `build_runner`.

**Priorité : P1**

---

### P1 — Provider et orchestration

Vérifier que `PlanningProvider` ne duplique pas la logique métier.

Le Provider doit :

- appeler les use cases ;
- gérer l'état UI ;
- exposer les erreurs ;
- déclencher les notifications ;
- ne pas calculer la rotation lui-même ;
- ne pas accéder directement à ObjectBox.

**Priorité : P1**

---

### P1 — Unifier les flux UI / PDF / export

Toutes les sorties doivent consommer le même snapshot métier :

```text
PlanningSnapshot validé
      ├── UI
      ├── PDF
      ├── Excel/CSV
      └── partage/export
```

Aucune logique de recalcul indépendante ne doit exister dans les exports.

**Priorité : P1**

---

### P1 — Badge `Modifié`

Vérifier l'implémentation UI sur :

- desktop ;
- mobile ;
- mois courant ;
- planning validé puis modifié ;
- planning modifié puis revalidé ;
- historique.

Le badge doit disparaître uniquement après validation/publication réussie de la nouvelle révision.

**Priorité : P1**

---

### P2 — Tests d'intégration complets

Scénario cible :

```text
Generate
  ↓
Validate
  ↓
Publish
  ↓
Edit leave
  ↓
Modified badge
  ↓
Revalidation required
  ↓
Validation
  ↓
Publish revision 2
  ↓
Reload app
  ↓
Revision 2 restored
  ↓
Revision 1 remains in history
```

Même scénario pour :

- changement d'ordre des équipes ;
- changement de congés ;
- combinaison congés + ordre ;
- changement de configuration ;
- plusieurs révisions successives.

**Priorité : P2**

---

## 6. CI et qualité

### Déjà en place

Le workflow CI existant exécute :

```text
flutter pub get
        ↓
Détection changement ObjectBox
        ↓
build_runner conditionnel
        ↓
Vérification ObjectBox généré
        ↓
dart format
        ↓
flutter analyze
        ↓
Planning tests
        ↓
Full test suite
```

### Contraintes

- ne pas créer un second workflow pour ObjectBox ;
- ne pas multiplier les workflows CI ;
- garder le workflow actuel comme quality gate principal ;
- exécuter `build_runner` uniquement lorsqu'une modification pertinente le nécessite ;
- ne pas générer silencieusement des fichiers et les ignorer.

---

## 7. Ordre d'exécution recommandé

### Étape 1 — Snapshot reads

- `findPublishedByMonth()`
- `findLatestByMonth()`
- `findByRevision()`
- tests associés.

### Étape 2 — Publication atomique

- use case `PublishPlanning` ;
- repository ;
- transaction ObjectBox ;
- tests d'échec partiel.

### Étape 3 — Consolidation ObjectBox

- audit des entités ;
- audit des UIDs ;
- suppression des doublons morts ;
- génération ObjectBox ;
- migration.

### Étape 4 — Provider

- vérifier que les Providers restent fins ;
- déplacer la logique métier résiduelle vers application/domain.

### Étape 5 — UI de révision

- badge `Modifié` ;
- badge `À revalider` ;
- publication désactivée si non validé.

### Étape 6 — Exports

- UI/PDF/Excel/CSV sur le même snapshot validé.

### Étape 7 — Tests E2E Planning

- génération ;
- validation ;
- publication ;
- édition ;
- revalidation ;
- nouvelle publication ;
- reload ObjectBox ;
- historique.

---

## 8. Commits réalisés pendant ce chantier

| Commit | Sujet | Statut |
|---|---|---|---|
| `b51ca593213ebe8791e256615c8ecad9723b4efd` | Correction imports rotation | Réalisé |
| `7f3e5637aba48aaac8f83bfef77d645ac876f735` | Correction imports publish gate | Réalisé |
| `82a20f0eaf4cc750bc886be8b9ef2cbffdb9496b` | Restauration tests continuité rotation | Réalisé |
| `afb1ff1688d3a6219601ea0b6d1ca198c06b0c20` | Contrat ObjectBox build_runner | Réalisé |
| `9199edeff25708c3e22af3c66886db386b655216` | Génération ObjectBox conditionnelle CI | Réalisé |
| `8077e9aafc0ec4b4081a830d0ec42df7d0dae002` | Détection changement entités ObjectBox | Réalisé |
| `c98e497ea5b2ef4c392fb147c1c8ead4c1e66760` | build_runner conditionnel | Réalisé |
| `3377c3153413b65d73971c0bbdd34b2cea07a7f2` | Tests édition/revalidation | Réalisé |
| `90e0b60c5fa81985e8b8e547b572fdcbf1962443` | Tests persistance révisions ObjectBox | Réalisé |
| `d66a20fc3256d4aad1f9458d6fc7f94bd98c77df` | Tests snapshots ObjectBox atomiques | Réalisé |
| `659f4651c724d7b3b18322e95f7f1f0fdfaf919b` | Upgrade ObjectBox 4→5.3.2, fix build_runner | Réalisé |
| `3cabef5bb1360b21044a0e91656064e2070f9d65` | Fix runInTx restant | Réalisé |

> Les commits ci-dessus sont ceux identifiés pendant le chantier courant. En cas de divergence entre cet historique et `main`, la branche `main` et son historique Git font foi.

---

## 9. Definition of Done

Le chantier Planning sera considéré comme terminé lorsque :

- [ ] un seul modèle domaine par concept ;
- [ ] un seul modèle ObjectBox actif par concept ;
- [ ] aucun doublon `V2` / `V3` inutile ;
- [ ] UIDs ObjectBox vérifiés et stables ;
- [ ] migration ObjectBox testée ;
- [ ] snapshot publié immuable ;
- [ ] snapshot latest/effective distinct du snapshot publié ;
- [ ] lecture par mois non ambiguë ;
- [ ] lecture par révision disponible ;
- [ ] publication atomique ;
- [ ] édition du mois courant après validation fonctionnelle ;
- [ ] édition d'un mois précédent bloquée ;
- [ ] badge `Modifié` fonctionnel ;
- [ ] badge `À revalider` fonctionnel ;
- [ ] publication impossible si la révision n'est pas validée ;
- [ ] historique des révisions conservé ;
- [ ] `PlanningProvider` sans logique métier dupliquée ;
- [ ] ObjectBox absent du domaine et de la présentation ;
- [ ] UI/PDF/export basés sur le même snapshot ;
- [ ] build_runner ObjectBox conditionnel ;
- [ ] CI existant vert ;
- [ ] tests unitaires verts ;
- [ ] tests d'intégration verts ;
- [ ] tests de migration verts.

---

## 10. Prochaine action immédiate

**Corriger `ObjectBoxPlanningSnapshotStore` pour rendre les lectures de snapshot explicites et déterministes :**

```text
findPublishedByMonth
findLatestByMonth
findByRevision
```

Puis ajouter les tests associés avant de poursuivre la consolidation ObjectBox et la publication atomique.
