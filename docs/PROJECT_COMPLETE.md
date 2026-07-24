# Kenzy — Documentation complète du projet

## Aperçu

Application Flutter multi-module : gestion hospitalière (planification du personnel), hôtellerie (réservations, chambres), commerce (ventes, facturation, stocks), messagerie P2P, et réseautage social (matchs/swipes).

**Package :** `kenzy`  
**Langue :** Français (interface utilisateur et docs)

---

## Dépendances principales (pubspec.yaml)

| Package | Version | Usage |
|---|---|---|
| `flutter` | SDK | UI framework |
| `objectbox` | ^5.3.2 | Base de données locale |
| `objectbox_flutter_libs` | ^5.3.2 | Librairies natives ObjectBox |
| `objectbox_generator` | ^5.3.2 | Générateur de code ObjectBox |
| `build_runner` | ^2.15.1 | Exécuteur de génération de code |
| `firebase_core` | - | Firebase core |
| `firebase_auth` | - | Authentification Firebase |
| `cloud_firestore` | - | Base de données Firestore |
| `firebase_storage` | - | Stockage Firebase |
| `supabase_flutter` | - | Backend Supabase |
| `provider` | - | Gestion d'état |
| `cached_network_image` | - | Images réseaux mises en cache |
| `mobile_scanner` | - | Scanner QR code |
| `printing` | - | Impression PDF |
| `share_plus` | - | Partage |
| `connectivity_plus` | - | État réseau |
| `path_provider` | - | Chemins de fichiers |
| `multi_chip_select` | - | Sélection multi-étiquettes |
| `flutter_inappwebview` | - | WebView intégré |

### Versions clés résolues (ObjectBox)

- `objectbox` → **5.3.2** (upgradé de 4.x)
- `analyzer` → **10.2.0**
- `source_gen` → **4.2.4**
- `build_runner` → **2.15.1**

---

## Architecture

```
kenzy/
├── lib/
│   ├── main.dart                        # Point d'entrée
│   ├── firebase_options.dart            # Configuration Firebase
│   ├── core/theme/                      # Thème de l'application
│   ├── features/planning/              # Module Planning (Clean Architecture)
│   ├── objectBox/                       # Couche ObjectBox (entités, pages, utilitaires)
│   ├── Hopital/                        # Module Hospitalier (legacy + nouveau)
│   ├── Oauth/                          # Authentification
│   ├── checkit/                        # Module CheckIt (?) 
│   ├── dependences/                    # Dépendances / injection
│   ├── Kids/                           # Module Enfants
│   ├── l10n/                           # Internationalisation
│   └── vids/                           # Vidéos (?)
├── docs/                               # Documentation architecturale
├── test/                                # Tests
├── tool/                                # Outils CI (check_objectbox_build_runner, should_run_objectbox_build)
├── assets/                              # Ressources
├── functions/                           # Cloud Functions
├── supabase/                            # Configuration Supabase
├── webHospital/                         # Version Web (hospitalière)
├── installer/                           # Installateur
└── home/                                # Page d'accueil (?)
```

---

## Module Planning (Clean Architecture)

### Structure

```
lib/features/planning/
├── application/usecases/           # Cas d'utilisation
│   ├── generate_planning_draft.dart
│   ├── load_planning.dart
│   ├── publish_planning.dart
│   └── validate_and_publish_planning.dart
├── domain/
│   ├── entities/                   # Modèles métier (15 fichiers)
│   ├── enums/                      # ShiftType, RotationPolicy
│   ├── repositories/               # Interfaces (PlanningRepository, RotationConfigurationRepository)
│   ├── services/                   # Services métier (14 fichiers)
│   ├── rotation/                   # Moteur de rotation (bas niveau)
│   ├── continuity/                 # Continuité inter-mois
│   ├── override/                   # Raisons et modèles de dérogation
│   ├── projection/                 # Projection équipes → personnel
│   └── models/                     # Modèles de données (leave, assignment, snapshot)
├── data/
│   ├── datasources/                # Sources de données ObjectBox
│   ├── repositories/               # Implémentations des repositories
│   ├── mappers/                    # Mappers ObjectBox ↔ Domaine
│   ├── models/                     # Modèles de persistance
│   └── objectbox/                  # Entités ObjectBox
└── presentation/
    ├── providers/                  # Providers (6 fichiers)
    ├── services/                   # Services de présentation (PlanningEditCoordinator)
    └── widgets/                    # Widgets UI (17 fichiers)
```

### Entités du domaine (15)

| Fichier | Classe | Rôle |
|---|---|---|
| `planning_snapshot.dart` | `PlanningSnapshot` | Snapshot mensuel immuable |
| `planning_assignment.dart` | `PlanningAssignment` | Affectation personnel/jour |
| `planning_revision.dart` | `PlanningRevision` | Révision post-validation |
| `rotation_configuration.dart` | `RotationConfiguration` | Configuration de rotation (ordre équipes, cycle, politique) |
| `rotation_state.dart` | `RotationState` | État de rotation (date + shifts par équipe) |
| `rotation_state_snapshot.dart` | `RotationStateSnapshot` | Snapshot persisté de l'état de rotation |
| `rotation_period.dart` | `RotationPeriod` | Période de validité d'une configuration |
| `staff_member.dart` | `StaffMember` | Membre du personnel |
| `staff_leave.dart` | `StaffLeave` | Congé d'un membre |
| `staff_availability.dart` | `StaffAvailability` | Disponibilité (enum + classe) |
| `planning_override.dart` | `PlanningOverride` | Dérogation manuelle |
| `planning_input.dart` | `PlanningInput` | Entrée de génération |
| `planning_publication.dart` | `PlanningPublication` | Résultat de publication |
| `planning_snapshot_metadata.dart` | `PlanningSnapshotMetadata` + `PlanningSnapshotStatus` | Métadonnées + statut |
| `planning.dart` | `Planning` | Planning legacy/mensuel |

### Enums

| Fichier | Enum | Valeurs |
|---|---|---|
| `shift_type.dart` | `ShiftType` | `day`, `night`, `rest`, `leave`, `training`, `activity`, `other` |
| `rotation_policy.dart` | `RotationPolicy` | `fixedReference`, `continueFromPreviousPublished` |

### Repositories (interfaces)

| Fichier | Interface | Méthodes |
|---|---|---|
| `planning_repository.dart` | `PlanningRepository` | `findPublishedByMonth`, `findLatestByMonth`, `findByRevision`, `findPreviousPublished`, `saveRevision`, `publishRevision` |
| `rotation_configuration_repository.dart` | `RotationConfigurationRepository` | `findById`, `findActive`, `findPeriodFor` |

### Services domaine (14)

| Fichier | Classe | Rôle |
|---|---|---|
| `rotation_engine.dart` | `RotationEngine` | Moteur de rotation (génération de planning, calcul de shift) |
| `generate_planning.dart` | `GeneratePlanning` | Orchestration de génération complète |
| `publish_planning.dart` | `PublishPlanning` | Validation + publication |
| `planning_validator.dart` | `PlanningValidator` + `PlanningValidationResult` | Validation des snapshots |
| `planning_revision_policy.dart` | `PlanningRevisionPolicy` | Politique de révision post-validation |
| `rotation_continuity_policy.dart` | `RotationContinuityPolicy` | Politique de continuité |
| `rotation_continuity_resolver.dart` | `RotationContinuityResolver` | Résolution de l'état de continuité |
| `rotation_state_builder.dart` | `RotationStateBuilder` | Construction de l'état de rotation |
| `planning_cache_policy.dart` | `PlanningCacheKey`, `PlanningCachePolicy`, `PlanningSnapshotMetadata` | Politique de cache |
| `planning_draft_pipeline.dart` | `PlanningDraftPipeline` | Pipeline de traitement du draft |
| `planning_override_applier.dart` | `PlanningOverrideApplier` | Application des dérogations |
| `staff_availability_applier.dart` | `StaffAvailabilityApplier` | Application des disponibilités |
| `team_schedule_generator.dart` | `TeamScheduleGenerator` | Génération du calendrier par équipe |
| `planning_integrity_checker.dart` | `PlanningIntegrityChecker` | Vérification d'intégrité |

### Couche Data

#### Datasources (2)

| Fichier | Classe | Rôle |
|---|---|---|
| `objectbox_planning_datasource.dart` | `ObjectBoxPlanningDataSource` | Datasource ObjectBox pour les snapshots (v2 + legacy) |
| `objectbox_planning_revision_datasource.dart` | `ObjectBoxPlanningRevisionDataSource` | Datasource ObjectBox pour les révisions |

#### Repositories Data (4)

| Fichier | Classe | Implémente | Rôle |
|---|---|---|---|
| `objectbox_planning_repository.dart` | `ObjectBoxPlanningRepository` | `PlanningRepository` | Repository principal planning |
| `objectbox_planning_revision_repository.dart` | `ObjectBoxPlanningRevisionRepository` | - | Repository révisions |
| `objectbox_planning_snapshot_store.dart` | `ObjectBoxPlanningSnapshotStore` | - | Stockage atomique des snapshots |
| `objectbox_rotation_configuration_repository.dart` | `ObjectBoxRotationConfigurationRepository` | `RotationConfigurationRepository` | Repository configuration rotation |

#### Entités ObjectBox (5 fichiers, 6 classes `@Entity`)

| Fichier | Classe | Relations |
|---|---|---|
| `planning_snapshot_entity.dart` | `PlanningSnapshotEntity` | `ToOne<RotationStateSnapshotEntity>`, `ToMany<PlanningAssignmentEntity>` (Backlink) |
| | `PlanningAssignmentEntity` | `ToOne<PlanningSnapshotEntity>` |
| `rotation_state_snapshot_entity.dart` | `RotationStateSnapshotEntity` | - |
| `rotation_configuration_entity.dart` | `RotationConfigurationEntity` | - |
| | `RotationPeriodEntity` | - |
| | `PlanningOverrideEntity` | - |
| `planning_revision_entity.dart` | `PlanningRevisionEntity` | - |

#### Mappers (5)

| Fichier | Classe | Rôle |
|---|---|---|
| `planning_snapshot_mapper.dart` | `PlanningSnapshotMapper` | ObjectBox ↔ Domaine + Legacy ↔ Domaine |
| `planning_objectbox_mapper.dart` | `PlanningObjectBoxMapper` | Mapping ObjectBox ↔ Domaine (v2) |
| `planning_revision_mapper.dart` | `PlanningRevisionMapper` | Mapping révisions |
| `rotation_configuration_mapper.dart` | `RotationConfigurationMapper` | Mapping configuration rotation |
| `legacy_planning_mapper.dart` | `LegacyPlanningMapper` | Mapping legacy (Planification/ActiviteJour) |

### Couche Application (4 use cases)

| Fichier | Classe | Rôle |
|---|---|---|
| `generate_planning_draft.dart` | `GeneratePlanningDraft` (+ `PlanningAlreadyExistsException`) | Génération d'un draft |
| `load_planning.dart` | `LoadPlanning` | Chargement d'un planning existant |
| `publish_planning.dart` | `PublishPlanning` (+ `InvalidPlanningException`) | Publication |
| `validate_and_publish_planning.dart` | `ValidateAndPublishPlanning` (+ `InvalidPlanningException`) | Validation + Publication |

### Couche Présentation

#### Providers (6)

| Fichier | Classe | Extends | Rôle |
|---|---|---|---|
| `planning_provider.dart` | `PlanningProvider` | `ChangeNotifier` | Coordination workflow planning |
| `planning_editor_provider.dart` | `PlanningEditorProvider` | `ChangeNotifier` | Édition du draft |
| `planning_history_provider.dart` | `PlanningHistoryProvider` | `ChangeNotifier` | Consultation historique |
| `planning_revision_ui_provider.dart` | `PlanningRevisionUiProvider` | `ChangeNotifier` | État UI des révisions |
| `planning_validation_provider.dart` | `PlanningValidationProvider` | `ChangeNotifier` | État UI de validation |
| `rotation_configuration_provider.dart` | `RotationConfigurationProvider` | `ChangeNotifier` | Configuration rotation |

#### Services Présentation (1)

| Fichier | Classe | Rôle |
|---|---|---|
| `planning_edit_coordinator.dart` | `PlanningEditCoordinator` | Coordination édition post-validation |

#### Widgets (17)

| Fichier | Widget | Rôle |
|---|---|---|
| `editable_planning_month_grid.dart` | Grille mensuelle éditable | |
| `editable_planning_snapshot_grid.dart` | Grille snapshot éditable | |
| `planning_assignment_editor_dialog.dart` | Dialogue d'édition d'affectation | |
| `planning_draft_editor.dart` | Éditeur de draft | |
| `planning_draft_grid_workspace.dart` | Espace de travail grille draft | |
| `planning_history_panel.dart` | Panneau d'historique | |
| `planning_month_grid.dart` | Grille mensuelle (lecture) | |
| `planning_publish_gate.dart` | Porte de publication | |
| `planning_revision_status_badge.dart` | Badge statut révision | |
| `planning_validation_panel.dart` | Panneau de validation | |
| `planning_validation_workspace.dart` | Espace de travail validation | |
| `planning_workflow_actions.dart` | Actions du workflow | |
| `planning_workspace_controller.dart` | Contrôleur d'espace de travail | |
| `planning_workspace_editor.dart` | Éditeur d'espace de travail | |
| `planning_workspace_flow.dart` | Flux d'espace de travail | |
| `planning_workspace.dart` | Espace de travail principal | |
| `rotation_team_order_editor.dart` | Éditeur d'ordre des équipes | |

---

## Module ObjectBox Core

### `lib/objectBox/classeObjectBox.dart`

**Classe `ObjectBox`** — Singleton central de la base ObjectBox. Contient **tous les Box** :
- `userBox`, `crudBox`, `produitBox`, `approvisionnementBox`, `fournisseurBox`, `factureBox`, `ligneFacture`, `clientBox`, `deletedProduct`, `annonces`
- `roomBox`, `reservationBox`, `guestBox`, `employeeBox`, `hotelBox`, `roomCategory`, `boardBasis`, `extraService`, `reservationExtra`, `seasonalPricing`
- `staffBox`, `activiteBox`, `branchBox`, `timeOffBox`, `planificationBox`, `planningHebdoBox`, `typeActiviteBox`
- `messageBox`, `conversationBox`, `messageReceiptBox`, `conversationParticipantBox`, `messageSyncQueueBox`, `messageSearchIndexBox`
- `swipeQueueBox`, `matchBox`, `profileBox`

Méthodes principales : `init()`, `dispose()`, `close()`, `deleteDatabase()`, `exportDatabase()`, `exportAllToJson()`, `importAllFromJson()`, `exportProduitsToCsv()`, `importProduitsFromCsv()`

### `lib/objectBox/Entity.dart`

Toutes les entités ObjectBox legacy dans un seul fichier (~1500 lignes) :

| Entité | Usage |
|---|---|
| `Usero` | Utilisateur (auth locale) |
| `Crud` | Traçabilité CRUD (createdBy, updatedBy, dates) |
| `Produit` | Produit/Article avec stock, QR codes, prix |
| `Approvisionnement` | Approvisionnement lié à Produit et Fournisseur |
| `Fournisseur` | Fournisseur |
| `Client` | Client |
| `Document` | Facture/Document (achat/vente) |
| `LigneDocument` | Ligne de document/facture |
| `DeletedProduct` | Produit supprimé (historique) |
| `Annonces` | Annonces (titre/prix/lien) |
| `Hotel` | Hôtel (nom, étages, chambres, photos) |
| `Room` | Chambre (code, statut, catégorie, photos) |
| `RoomCategory` | Catégorie de chambre (prix, équipements) |
| `BoardBasis` | Formule d'hébergement |
| `ExtraService` | Service supplémentaire |
| `ReservationExtra` | Réservation de service supplémentaire |
| `SeasonalPricing` | Tarification saisonnière |
| `Guest` | Client/Hôte |
| `Reservation` | Réservation (chambre, dates, prix, extras) |
| `Employee` | Employé (réception) |
| `Staff` | Personnel hospitalier (nom, grade, groupe, équipe) |
| `ActiviteJour` | Activité journalière legacy |
| `Branch` | Succursale/Branche |
| `TimeOff` | Congé du personnel |
| `Planification` | Planification mensuelle legacy |
| `PlanningHebdo` | Planning hebdomadaire |
| `TypeActivite` | Type d'activité |
| `Message` | Message P2P |
| `Conversation` | Conversation P2P |
| `MessageReceipt` | Accusé de réception P2P |
| `ConversationParticipant` | Participant à une conversation |
| `MessageSyncQueue` | File de synchronisation P2P |
| `MessageSearchIndex` | Index de recherche P2P |
| `SwipeQueue` | File d'attente de swipe (social) |
| `Match` | Match (social) |
| `Profile` | Profil (social) |

---

## Module Hopital

| Fichier | Classe | Rôle |
|---|---|---|
| `TableauStaff.dart` | (Widget/Page) | Planning principal (legacy UI, forteresse de logique métier) |
| `StaffProvider.dart` | (Provider) | Provider legacy (manipule ObjectBox directement) |
| `SupabaseHospitalService.dart` | Service | Synchronisation Supabase des données hospitalières |
| `ActivitePersonne.dart` | DTO/Datasource | DTO legacy pour les activités par personne |
| `Planning_pdf.dart` | Service | Génération PDF du planning |
| `PlanningHebdoWidget.dart` | Widget | Widget planning hebdomadaire |
| `Planning_pdf.dart` | Widget | Export PDF planning |
| `p2p/` | (dossier) | Module de messagerie P2P (ObjectBox sync) |
| `p2p/objectbox_p2p.dart` | `ObjectBoxP2P` | Classe principale P2P |
| `p2p/messenger/` | | Composants du messenger (providers, manager) |

---

## CI / Outils

### `.github/workflows/` — Workflow CI unique

Étapes :
1. `flutter pub get`
2. Détection de changement ObjectBox (`tool/should_run_objectbox_build.dart`)
3. `build_runner` conditionnel (si une entité a changé)
4. Vérification du code ObjectBox généré (`tool/check_objectbox_build_runner.dart`)
5. `dart format`
6. `flutter analyze`
7. Tests Planning
8. Tests complets

### `tool/should_run_objectbox_build.dart`

Détecte les marqueurs ObjectBox dans les fichiers modifiés : `@Entity`, `@Id`, `@Property`, `@Index`, `@Unique`, `@Backlink`, `@Transient`, `@HnswIndex`, `ToOne`, `ToMany`, `Store`.

### `tool/check_objectbox_build_runner.dart`

Vérifie le contrat de génération : présence des dépendances, de `objectbox.g.dart`, validation minimale du contenu.

---

## Règles métier clés (Planning)

1. **Rotation :** Cycle 4 jours (JOUR → NUIT → REPOS → REPOS), 4 équipes déphasées.
2. **Snapshots immuables :** Un planning publié n'est jamais recalculé.
3. **Continuité :** L'état de rotation du mois précédent est persisté et utilisé pour le mois suivant.
4. **Révisions :** Une modification post-validation crée une nouvelle révision (jamais d'écrasement).
5. **Badge `Modifié`** : Visible tant que la revalidation n'est pas obtenue.
6. **Publication atomique :** Snapshot + état de rotation + assignments dans une seule transaction ObjectBox.
7. **Mois précédents verrouillés :** Seul le mois courant est modifiable après validation.

---

## Problèmes restants (flutter analyze : 725)

### Planning Feature (pre-existing, non liés à l'upgrade)

| Erreur | Fichier | Cause |
|---|---|---|
| `findByMonth` non défini sur `PlanningRepository` | `load_planning.dart`, `generate_planning_draft.dart`, etc. | L'interface `PlanningRepository` a été refactorée (méthodes renommées) |
| `exists` non défini sur `PlanningRepository` | `publish_planning.dart`, etc. | Méthode manquante |
| `publish` non défini sur `PlanningRepository` | `publish_planning.dart` | L'interface utilise `publishRevision` |
| `saveVersion` non défini sur `RotationConfigurationRepository` | `rotation_configuration_provider.dart` | Méthode manquante dans l'interface |
| `ObjectBox` class non trouvée dans `rotation_configuration_repository.dart` | Import manquant ? | Déjà dans l'import mais... |
| `RotationConfigurationV2` / `RotationEngineV2` non trouvés | `planning_input.dart`, `rotation_state_builder.dart` | Fichiers `V2` supprimés ou renommés |
| `continuePreviousMonth` non trouvé dans `RotationPolicy` | `rotation_continuity_policy.dart` | Constante d'enum manquante |

### Legacy ObjectBox (warnings uniquement)

- `withOpacity` déprécié → utiliser `withValues()` (dans tous les fichiers tests/legacy)
- Variables locales inutilisées, imports inutiles, `unnecessary_non_null_assertion`
- `dead_null_aware_expression` (opérande gauche non null)
- Widgets `@immutable` avec champs non `final`

---

## Corrections effectuées

| Date | Fichier | Correction |
|---|---|---|
| 24/07 | `pubspec.yaml` | Upgrade `objectbox` → `^5.3.2`, `objectbox_flutter_libs` → `^5.3.2`, `objectbox_generator` → `^5.3.2`, `build_runner` → `^2.15.1` |
| 24/07 | `lib/objectBox/Entity.dart` | `import '../objectbox.g.dart'` → `import 'package:objectbox/objectbox.dart'` (fichier généré n'existait pas) |
| 24/07 | `docs/planning_snapshot_entity.dart` | Ajouté `import 'rotation_state_snapshot_entity.dart'` (type non résolu → null check crash dans le générateur) |
| 24/07 | `lib/objectbox-model.json` | Supprimé (stale 4.x) puis regénéré par ObjectBox 5.x |
| 24/07 | `planning_snapshot_store.dart` (×2), `planning_datasource.dart`, `rotation_configuration_repository.dart` | `runInTx` → `runInTransaction` (API ObjectBox 5) |
| 24/07 | `planning_snapshot_store.dart` | Ajouté `import '../../../../objectbox.g.dart'` pour `PlanningSnapshotEntity_` |
