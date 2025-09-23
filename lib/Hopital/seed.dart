// lib/tools/seed.dart
import 'package:flutter/material.dart';

import '../objectBox/Entity.dart';
import '../objectbox.g.dart';

/// DatabaseSeeder — seed ObjectBox with personnel, groups, months and provide helpers
/// Usage:
///   DatabaseSeeder(store).seed(); // to insert personnels & groups
///   DatabaseSeeder(store).seedAndImportMatrix(...); // to import plannings from matrix
class DatabaseSeeder {
  final Store store;

  DatabaseSeeder(this.store);

  // -----------------------
  // configuration initiale
  // -----------------------
  final List<Map<String, String>> _personnelData = [
    // Médecins (document médecin)
    {
      'nom': 'Medjadi',
      'prenom': 'Mohsine',
      'fonction': 'Rhumatologue',
      'grade': 'Médecin Chef',
      'service': 'Service de Rhumatologie'
    },
    {
      'nom': 'Ouadah',
      'prenom': 'Souad',
      'fonction': 'Rhumatologue',
      'grade': 'Médecin Chef',
      'service': 'Service de Rhumatologie'
    },
    {
      'nom': 'Bouziane',
      'prenom': 'Kheira',
      'fonction': 'Rhumatologue',
      'grade': 'Médecin Principale',
      'service': 'Service de Rhumatologie'
    },
    {
      'nom': 'Telmsani',
      'prenom': 'Naziha',
      'fonction': 'Médecin Généraliste',
      'grade': 'Médecin Principale',
      'service': 'Service Général'
    },
    {
      'nom': 'Boumazouzi',
      'prenom': 'Hind',
      'fonction': 'Médecin Généraliste',
      'grade': 'Médecin Principale',
      'service': 'Service Général'
    },

    // Paramédical / administratif (extraits)
    {
      'nom': 'Kerarma',
      'prenom': 'Djelloul',
      'fonction': 'I.SSP',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Meddah',
      'prenom': 'Fadela',
      'fonction': 'Psychologue',
      'grade': '',
      'service': 'Psychologie'
    },
    {
      'nom': 'Rezgui',
      'prenom': 'Nouria',
      'fonction': 'Administrateur',
      'grade': '',
      'service': 'Administration'
    },
    {
      'nom': 'Behloul',
      'prenom': 'Zahra',
      'fonction': 'Administrateur',
      'grade': '',
      'service': 'Administration'
    },
    {
      'nom': 'Zalegh',
      'prenom': 'Fatima',
      'fonction': 'Agent Administratif',
      'grade': '',
      'service': 'Bureau'
    },
    {
      'nom': 'Baoud',
      'prenom': 'Kholoud',
      'fonction': 'Agent Administratif',
      'grade': '',
      'service': 'Bureau'
    },
    {
      'nom': 'Naamoun',
      'prenom': 'Sarra',
      'fonction': 'Chargée de pharmacie',
      'grade': '',
      'service': 'Pharmacie'
    },
    {
      'nom': 'Nekrouf',
      'prenom': 'Amel',
      'fonction': 'Chargée de pharmacie',
      'grade': '',
      'service': 'Pharmacie'
    },
    {
      'nom': 'Bouaziz',
      'prenom': 'Nacer',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Rahmani',
      'prenom': 'Ibtissem',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Kassab',
      'prenom': 'Hichem',
      'fonction': 'ATS Principal',
      'grade': '',
      'service': 'Paramédical'
    },

    // Groupes & ATS/IDE list (plus complet)
    {
      'nom': 'Bakhouche',
      'prenom': 'Sarra',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Behloul',
      'prenom': 'Sihem',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Bouabida',
      'prenom': 'Ikram',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Hiadsi',
      'prenom': 'Souad',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Ait Menguellat',
      'prenom': 'Lilia',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Kadri',
      'prenom': 'Karima',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Moussa',
      'prenom': 'Hadjar',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Chaabane',
      'prenom': 'Abdelhamid',
      'fonction': 'ISSP',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Mahdjoubi',
      'prenom': 'Sami',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Ben Kara',
      'prenom': 'Ahmed',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Bouderouez',
      'prenom': 'Saliha',
      'fonction': 'IDE',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Hamedi',
      'prenom': 'Souad',
      'fonction': 'IDE',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Guerle',
      'prenom': 'Yacine',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Fellag',
      'prenom': 'Karima',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Hallal',
      'prenom': 'Mohamed',
      'fonction': 'ATS',
      'grade': '',
      'service': 'Paramédical'
    },

    // Hygiène / agents
    {
      'nom': 'Mohand',
      'prenom': 'Fatiha',
      'fonction': 'Agent d\'hygiène',
      'grade': '',
      'service': 'Hygiène'
    },
    {
      'nom': 'Touati',
      'prenom': 'Fatima',
      'fonction': 'Agent d\'hygiène',
      'grade': '',
      'service': 'Hygiène'
    },
    {
      'nom': 'Said',
      'prenom': 'Khiera',
      'fonction': 'Agent d\'hygiène',
      'grade': '',
      'service': 'Hygiène'
    },

    // Autres variantes / orthographes vues
    {
      'nom': 'Kadri',
      'prenom': 'Khadra',
      'fonction': 'Mise en disponibilité',
      'grade': '',
      'service': 'Paramédical'
    },
    {
      'nom': 'Kassabi',
      'prenom': 'Hichem',
      'fonction': 'ATS Principal',
      'grade': '',
      'service': 'Paramédical'
    },
  ];

  // groupes extraits (source: planning medecin docx)
  final Map<String, List<List<String>>> _groupMembers = {
    'Groupe A': [
      ['Behloul', 'Sihem'],
      ['Bouabida', 'Ikram'],
      ['Bakhouche', 'Sarra'],
    ],
    'Groupe B': [
      ['Hiadsi', 'Souad'],
      ['Ait Menguellat', 'Lilia'],
      ['Kadri', 'Karima'],
      ['Moussa', 'Hadjar'],
    ],
    'Groupe C': [
      ['Chaabane', 'Abdelhamid'],
      ['Mahdjoubi', 'Sami'],
      ['Ben Kara', 'Ahmed'],
    ],
    'Groupe D': [
      ['Bouderouez', 'Saliha'],
      ['Hamdi', 'Souad'],
      ['Guerle', 'Yacine'],
    ],
  };

  // index in-memory pour accéder rapidement aux personnels (clé = "nom|prenom" lowercase)
  final Map<String, Personnel> _personnelIndex = {};

  String _keyOf(String nom, String prenom) =>
      '${nom.trim().toLowerCase()}|${prenom.trim().toLowerCase()}';

  /// find or create personnel in box. ALWAYS returns a Personnel (never null).
  Personnel findOrCreatePersonnel(Box<Personnel> box,
      {required String nom,
      required String prenom,
      String fonction = '',
      String grade = '',
      String service = ''}) {
    final key = _keyOf(nom, prenom);
    if (_personnelIndex.containsKey(key)) return _personnelIndex[key]!;

    // try find in box by query
    final q = box
        .query(Personnel_.nom
            .equals(nom, caseSensitive: false)
            .and(Personnel_.prenom.equals(prenom, caseSensitive: false)))
        .build();
    final found = q.findFirst();
    q.close();

    if (found != null) {
      _personnelIndex[key] = found;
      return found;
    }

    // not found -> create and save
    final p = Personnel(
      nom: nom,
      prenom: prenom,
      fonction: fonction,
      grade: grade,
      service: service,
    );
    final id = box.put(p);
    p.id = id;
    _personnelIndex[key] = p;
    return p;
  }

  /// convert a short status string (N, R, G, CM, RE/RÉ) -> StatutActivite
  StatutActivite _statutFromString(String s) {
    final t = s.trim().toLowerCase();
    if (t == 'n' || t == 'normal') return StatutActivite.normal;
    if (t == 'r' || t == 'repos') return StatutActivite.repos;
    if (t == 'g' || t == 'garde') return StatutActivite.garde;
    if (t == 're' ||
        t == 'ré' ||
        t == 'recup' ||
        t == 'récupération' ||
        t == 'récup') return StatutActivite.recuperation;
    if (t == 'c' || t == 'congé' || t == 'conge') return StatutActivite.conge;
    if (t == 'cm' ||
        t == 'congé maternité' ||
        t == 'conge maternité' ||
        t == 'conge maladie' ||
        t == 'cmal') return StatutActivite.congeMaladie;
    // default safe fallback
    return StatutActivite.normal;
  }

  /// Create PlanningMois and return it
  PlanningMois _createMonth(
      Box<PlanningMois> planningBox, int year, int month) {
    final p = PlanningMois(annee: year, mois: month);
    planningBox.put(p);
    return p;
  }

  /// Add affectations for one personnel given a list of status strings length = daysInMonth
  void _addAffectationsForRow({
    required Box<AffectationJour> affectationBox,
    required Box<PlanningMois> planningBox,
    required Box<Personnel> personnelBox,
    required Personnel personnel,
    required PlanningMois month,
    required int year,
    required int monthNumber,
    required List<String> statuses,
  }) {
    final daysInMonth = DateUtils.getDaysInMonth(year, monthNumber);
    final count = statuses.length;
    if (count != daysInMonth) {
      // throw or adapt: we will trim or extend default 'N' to fit daysInMonth
      if (count > daysInMonth) {
        statuses = statuses.sublist(0, daysInMonth);
      } else {
        final pad = List<String>.filled(daysInMonth - count, 'N');
        statuses = [...statuses, ...pad];
      }
    }

    final List<AffectationJour> toPut = [];
    for (var i = 0; i < daysInMonth; i++) {
      final day = i + 1;
      final date = DateTime(year, monthNumber, day);
      final statStr = statuses[i];
      final statut = _statutFromString(statStr);

      final a = AffectationJour(date: date, statut: statut.index)
        ..personnel.target = personnel
        ..planningMois.target = month;
      toPut.add(a);
    }
    affectationBox.putMany(toPut);
  }

  /// Public seed function (create all personnel and groups; months created empty)
  void seed() {
    final personnelBox = store.box<Personnel>();
    final groupeBox = store.box<GroupeTravail>();
    final planningBox = store.box<PlanningMois>();
    final affectationBox = store.box<AffectationJour>();
    final activiteBox = store.box<ActiviteHebdo>();
    final obsBox = store.box<Observation>();

    // --- Insert all personnels (idempotent: findOrCreate ensures no duplicates) ---
    final created = <Personnel>[];
    for (final m in _personnelData) {
      final p = findOrCreatePersonnel(
        personnelBox,
        nom: m['nom'] ?? '',
        prenom: m['prenom'] ?? '',
        fonction: m['fonction'] ?? '',
        grade: m['grade'] ?? '',
        service: m['service'] ?? '',
      );
      created.add(p);
    }

    // Build list of all personnels currently in db (fresh)
    final personnels = personnelBox.getAll();

    // --- Create groupes and attach members ---
    final groupes = <GroupeTravail>[];
    _groupMembers.forEach((gName, members) {
      final g = GroupeTravail(nom: gName, service: '');
      groupeBox.put(g); // save early to get id
      groupes.add(g);

      for (final m in members) {
        final nom = m[0];
        final prenom = m[1];
        final key = _keyOf(nom, prenom);
        // try find in in-memory index or in box:
        Personnel? found = _personnelIndex[key];
        if (found == null) {
          // try to find among saved personnels
          found = personnels.firstWhere(
              (x) =>
                  x.nom.trim().toLowerCase() == nom.trim().toLowerCase() &&
                  x.prenom.trim().toLowerCase() == prenom.trim().toLowerCase(),
              orElse: () => findOrCreatePersonnel(personnelBox,
                  nom: nom, prenom: prenom));
        }
        g.membres.add(found);
      }
      groupeBox.put(g); // update with members
    });

    // --- Create some PlanningMois entries (months present in the docs) ---
    final monthsToCreate = [
      {'y': 2025, 'm': 3},
      {'y': 2025, 'm': 4},
      {'y': 2025, 'm': 5},
      {'y': 2025, 'm': 7},
      {'y': 2025, 'm': 9},
    ];
    final createdPlannings = <PlanningMois>[];
    for (final mm in monthsToCreate) {
      final p = _createMonth(planningBox, mm['y']!, mm['m']!);
      createdPlannings.add(p);
    }

    // --- Example: How to add affectations from a matrix (row per personnel)
    // You must supply a List<Map> where each map:
    //  { 'nom': 'Medjadi', 'prenom': 'Mohsine', 'year':2025, 'month':9, 'statuses': ['N','N','R', ...] }
    //
    // I don't assume the full daily matrix here to avoid guessing. Use the helper below to import exactly.
    //
    // Example (uncomment & adapt if you have a matrix for one person):
    //
    // final medj = findOrCreatePersonnel(personnelBox, nom: 'Medjadi', prenom: 'Mohsine');
    // _addAffectationsForRow(
    //   affectationBox: affectationBox,
    //   planningBox: planningBox,
    //   personnelBox: personnelBox,
    //   personnel: medj,
    //   month: createdPlannings.firstWhere((p)=>p.annee==2025 && p.mois==9),
    //   year: 2025,
    //   monthNumber: 9,
    //   statuses: ['N','N','R','N', /* ... total 30 for sept */],
    // );

    // --- Optionally create ActiviteHebdo entries (empty placeholders for medecins)
    // If you prefer, you can import exact weekly activities via a matrix similar to the affectations.
    for (final docMed in [
      'Medjadi Mohsine',
      'Ouadah Souad',
      'Bouziane Kheira',
      'Telmsani Naziha',
      'Boumazouzi Hind'
    ]) {
      final parts = docMed.split(' ');
      final nom = parts[0];
      final prenom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final p = findOrCreatePersonnel(personnelBox, nom: nom, prenom: prenom);
      // create default placeholders for each weekday present in the doc (Dimanche->Jeudi)
      const jours = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi"];
      final acts = <ActiviteHebdo>[];
      for (final j in jours) {
        final a = ActiviteHebdo(jour: j, activite: '—')..personnel.target = p;
        acts.add(a);
      }
      activiteBox.putMany(acts);
    }

    // --- Observations placeholders (if you want them empty, else import exact ones similarly) ---
    // Example of adding one observation based on doc note:
    final maybeOuadah =
        findOrCreatePersonnel(personnelBox, nom: 'Ouadah', prenom: 'Souad');
    final obs = Observation(
      type: 'Congé',
      details: 'Congé signalé dans doc (ex. congé 11j à partir du 08/09/2025)',
      dateDebut: DateTime(2025, 9, 8),
      dateFin: DateTime(2025, 9, 18),
    )..personnel.target = maybeOuadah;
    obsBox.put(obs);

    // --- Final summary imprimé ---
    final totalPersonnel = personnelBox.count();
    final totalGroups = groupeBox.count();
    final totalPlannings = planningBox.count();
    final totalAffectations = affectationBox.count();
    final totalActivites = activiteBox.count();
    final totalObs = obsBox.count();

    print('✅ Seed terminé.');
    print(' Personnels: $totalPersonnel');
    print(' Groupes: $totalGroups');
    print(' Plannings mois: $totalPlannings');
    print(' Affectations (jours): $totalAffectations');
    print(' Activites hebdo: $totalActivites');
    print(' Observations: $totalObs');
  }

  /// Helper to import a full matrix (rows) in one call (convenience)
  ///
  /// rows: List of maps { 'nom': 'Medjadi', 'prenom': 'Mohsine', 'year':2025, 'month':9, 'statuses': ['N','R','N', ...] }
  void importMatrix(List<Map<String, dynamic>> rows) {
    final personnelBox = store.box<Personnel>();
    final planningBox = store.box<PlanningMois>();
    final affectationBox = store.box<AffectationJour>();

    // cache planning months
    final Map<String, PlanningMois> monthIndex = {};
    PlanningMois getOrCreateMonth(int year, int month) {
      final key = '$year|$month';
      if (monthIndex.containsKey(key)) return monthIndex[key]!;
      final q = planningBox
          .query(PlanningMois_.annee
              .equals(year)
              .and(PlanningMois_.mois.equals(month)))
          .build();
      final exists = q.findFirst();
      q.close();
      if (exists != null) {
        monthIndex[key] = exists;
        return exists;
      }
      final p = PlanningMois(annee: year, mois: month);
      planningBox.put(p);
      monthIndex[key] = p;
      return p;
    }

    for (final r in rows) {
      final nom = r['nom'] as String;
      final prenom = r['prenom'] as String;
      final year = r['year'] as int;
      final month = r['month'] as int;
      final statuses = List<String>.from(r['statuses'] as List);
      final personnel =
          findOrCreatePersonnel(personnelBox, nom: nom, prenom: prenom);
      final pm = getOrCreateMonth(year, month);
      _addAffectationsForRow(
        affectationBox: affectationBox,
        planningBox: planningBox,
        personnelBox: personnelBox,
        personnel: personnel,
        month: pm,
        year: year,
        monthNumber: month,
        statuses: statuses,
      );
    }
  }
}
