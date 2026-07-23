# Planning Clean Architecture Refactor

## Contexte

Le module planning actuel est fortement couplé à l’UI et à la persistance locale. La page `TableauStaffPage` orchestre à elle seule la navigation mensuelle, la lecture ObjectBox, la sauvegarde du snapshot, la restauration des activités, les observations, et une partie de la logique métier. Le `StaffProvider` manipule directement `ObjectBox`, les `Planification`, les `ActiviteJour`, les `TimeOff`, ainsi que le snapshot mensuel.

## Ce qui existe aujourd’hui

### Entités métier déjà présentes
- `Staff`
- `ActiviteJour`
- `TimeOff`
- `Planification`
- `PlanningHebdo`
- `Branch`

### Persistance
- `ObjectBox` centralise tous les boxes, dont `staffBox`, `activiteBox`, `timeOffBox`, `planificationBox` et `planningHebdoBox`.
- Le snapshot mensuel est stocké dans `Planification.ordreEquipes` et `Planification.activitesJson` via des extensions existantes.

### Couplages à réduire
- UI ↔ ObjectBox direct
- UI ↔ règles de rotation
- UI ↔ logique de sauvegarde / chargement mensuel
- UI ↔ logique PDF
- Provider ↔ stockage local direct
- Provider ↔ logique métier de génération du planning

## Cible d’architecture

```text
lib/features/planning/
├── application/
│   ├── providers/
│   └── usecases/
├── domain/
│   ├── entities/
│   ├── enums/
│   ├── repositories/
│   └── services/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── pages/
    ├── widgets/
    └── dialogs/
```

## Responsabilités cibles

### Domain
- Définir le modèle de planning indépendant de Flutter.
- Formaliser les règles de rotation.
- Générer un mois de planning de manière déterministe.
- Valider les affectations et les transitions mois précédent / mois suivant.

### Data
- Lire / écrire ObjectBox.
- Mapper les entités ObjectBox vers les modèles du domaine.
- Préparer une future source distante sans changer le domaine.

### Application
- Orchestrer les use cases.
- Exposer l’état au travers de Provider.
- Contenir le minimum de logique d’orchestration.

### Presentation
- Afficher le planning.
- Gérer la saisie utilisateur.
- Ne jamais contenir de règle métier.

## Règles à préserver

- Rotation des équipes `A / B / C / D`.
- Compatibilité Jour / Nuit.
- Gestion des mois à 28 / 29 / 30 / 31 jours.
- Navigation mois précédent / suivant.
- Édition manuelle cellule par cellule.
- Observations par personnel.
- Congés et indisponibilités.
- Export PDF conforme à l’affichage.
- Fonctionnement offline-first.

## Problèmes à corriger pendant la refonte

1. Le changement de mois ne doit pas être déduit uniquement avec `newMonth > oldMonth`.
2. La logique de génération ne doit pas vivre dans un widget.
3. Le PDF ne doit pas recalculer le planning.
4. Les accès à ObjectBox ne doivent plus être faits depuis la page.
5. Les lectures de données doivent être regroupées dans un repository.
6. Les écritures doivent passer par des use cases transactionnels.

## Plan de migration recommandé

1. Extraire les entités du domaine.
2. Ajouter les enums et value objects.
3. Extraire un `RotationEngine` pur.
4. Extraire un service de transition mensuelle.
5. Créer le repository de planning.
6. Déplacer les appels ObjectBox dans les datasources.
7. Réduire `StaffProvider` à un orchestrateur.
8. Simplifier `TableauStaffPage`.
9. Unifier la source de vérité pour l’UI et le PDF.
10. Ajouter des tests de non-régression.

## Règle d’or

Le planning généré, affiché, sauvegardé, synchronisé et exporté doit provenir du même modèle métier.
