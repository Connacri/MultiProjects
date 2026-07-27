import 'dart:convert';

import '../../../../../objectBox/Entity.dart';
import '../../../../../objectBox/classeObjectBox.dart';
import '../../../../../objectbox.g.dart';
import '../../../../SupabaseHospitalService.dart';

class HospitalPdfSeedImportService {
  HospitalPdfSeedImportService({
    ObjectBox? objectBox,
    SupabaseHospitalService? supabaseService,
  })  : _objectBox = objectBox ?? ObjectBox(),
        _supabaseService = supabaseService ?? SupabaseHospitalService();

  final ObjectBox _objectBox;
  final SupabaseHospitalService _supabaseService;

  Future<HospitalSeedImportResult> importAout2026() async {
    final branch = _upsertBranch('Rhumatologie');
    final staffSeeds = _buildAout2026Seeds();

    final obsByStaff = <int, String?>{};
    var staffCount = 0;
    var timeOffCount = 0;

    for (final seed in staffSeeds) {
      final staff = _upsertStaff(seed, branch);

      if (seed.observation != null && seed.observation!.trim().isNotEmpty) {
        obsByStaff[staff.id] = seed.observation!.trim();
      }

      if (seed.leaves.isNotEmpty) {
        timeOffCount += _replaceLeavesForStaff(staff.id, seed.leaves);
      }

      staffCount++;
    }

    await _saveMonthlyObservationSnapshot(
      year: 2026,
      month: 8,
      obsByStaff: obsByStaff,
    );

    await _supabaseService.exportAllToSupabase();

    return HospitalSeedImportResult(
      staffCount: staffCount,
      timeOffCount: timeOffCount,
      observationCount: obsByStaff.length,
    );
  }

  Branch _upsertBranch(String branchName) {
    final query = _objectBox.branchBox
        .query(Branch_.branchNom.equals(branchName))
        .build();
    final existing = query.findFirst();
    query.close();

    final branch = existing ?? Branch(branchNom: branchName);
    branch.branchNom = branchName;
    _objectBox.branchBox.put(branch);
    return branch;
  }

  Staff _upsertStaff(_SeedStaff seed, Branch branch) {
    final query = _objectBox.staffBox.query(Staff_.nom.equals(seed.nom)).build();
    final existing = query.findFirst();
    query.close();

    final staff = existing ??
        Staff(
          nom: seed.nom,
          grade: seed.grade,
          groupe: seed.groupe,
          equipe: seed.equipe,
          ordre: seed.ordre,
        );

    staff.nom = seed.nom;
    staff.grade = seed.grade;
    staff.groupe = seed.groupe;
    staff.equipe = seed.equipe;
    staff.ordre = seed.ordre;
    staff.branch.target = branch;

    _objectBox.staffBox.put(staff);
    return staff;
  }

  int _replaceLeavesForStaff(int staffId, List<_SeedLeave> leaves) {
    final existingQuery = _objectBox.timeOffBox
        .query(TimeOff_.staff.equals(staffId))
        .build();
    final existing = existingQuery.find();
    existingQuery.close();

    for (final old in existing) {
      _objectBox.timeOffBox.remove(old.id);
    }

    var inserted = 0;
    for (final leave in leaves) {
      final timeOff = TimeOff(
        debut: leave.debut,
        fin: leave.fin,
        motif: leave.motif,
      );
      final staff = _objectBox.staffBox.get(staffId);
      if (staff == null) continue;
      timeOff.staff.target = staff;
      _objectBox.timeOffBox.put(timeOff);
      inserted++;
    }
    return inserted;
  }

  Future<void> _saveMonthlyObservationSnapshot({
    required int year,
    required int month,
    required Map<int, String?> obsByStaff,
  }) async {
    final query = _objectBox.planificationBox
        .query(Planification_.mois.equals(month) &
            Planification_.annee.equals(year))
        .build();
    var planif = query.findFirst();
    query.close();

    planif ??= Planification(mois: month, annee: year, ordreEquipes: 'A,B,C,D');

    final observations = obsByStaff.entries
        .map(
          (entry) => {
            'staffId': entry.key,
            'obs': entry.value,
          },
        )
        .toList();

    planif.activitesJson = jsonEncode({
      'observations': observations,
      'activites': <Map<String, Object?>>[],
    });

    _objectBox.planificationBox.put(planif);
  }

  List<_SeedStaff> _buildAout2026Seeds() {
    return [
      // Médecins
      _SeedStaff(
        nom: 'Medjadi Mohsine',
        grade: 'Médecin Chef Rhumatologue',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Ouadah Souad',
        grade: 'Médecin Principal en Rhumatologie',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Bouziane Kheira',
        grade: 'Médecin Principal en Rhumatologie',
        groupe: '08h-16h',
        observation: 'Congé (10/08 - 24/08)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 8, 10),
            fin: DateTime(2026, 8, 24),
            motif: 'Congé',
          ),
        ],
      ),
      _SeedStaff(
        nom: 'Tlemsani Naziha',
        grade: 'Médecin Généraliste',
        groupe: '08h-16h',
        observation: 'recup 03/8/26 - 05/8/26\nCongé (19/07 - 02/08)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 8, 3),
            fin: DateTime(2026, 8, 5),
            motif: 'recup',
          ),
          _SeedLeave(
            debut: DateTime(2026, 7, 19),
            fin: DateTime(2026, 8, 2),
            motif: 'Congé',
          ),
        ],
      ),
      _SeedStaff(
        nom: 'Boumazouzi Hind',
        grade: 'Médecin Généraliste',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Benrahal Yasmina',
        grade: 'Médecin Généraliste',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),

      // Personnel 08h-16h
      _SeedStaff(
        nom: 'Kerarma Djelloul',
        grade: 'I.SSP Surveillant Médical',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Meddah Fadela',
        grade: 'Psychologue',
        groupe: '08h-16h',
        observation: 'Congé (02/08 - 31/08)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 8, 2),
            fin: DateTime(2026, 8, 31),
            motif: 'Congé',
          ),
        ],
      ),
      _SeedStaff(
        nom: 'Behloul Zahra',
        grade: 'Administrateur',
        groupe: '08h-16h',
        observation: 'Congé (03/08 - 01/09)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 8, 3),
            fin: DateTime(2026, 9, 1),
            motif: 'Congé',
          ),
        ],
      ),
      _SeedStaff(
        nom: 'Zalegh Fatima',
        grade: 'Agent de bureau',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Baoud Kholoud',
        grade: 'Agent de bureau',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Naamoun Sarra',
        grade: 'Chargée de pharmacie',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Bouaziz Nacer',
        grade: 'ATS principal',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Rahmani Ibtissem',
        grade: 'ATS principal',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Kassab Hichem',
        grade: 'ATS principal',
        groupe: '08h-16h',
        observation: '08h-16h',
      ),
      _SeedStaff(
        nom: 'Djaziri Cherifa',
        grade: 'Chargé de pharmacie',
        groupe: '08h-16h',
        observation: 'Congé (26/07 - 13/08)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 7, 26),
            fin: DateTime(2026, 8, 13),
            motif: 'Congé',
          ),
        ],
      ),

      // 16h / Garde 24H
      _SeedStaff(
        nom: 'Bakhouche Sarra',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'A',
      ),
      _SeedStaff(
        nom: 'Behloul Sihem',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'A',
      ),
      _SeedStaff(
        nom: 'Bouabida Ikram',
        grade: 'ATS principal',
        groupe: 'Garde 24H',
        equipe: 'A',
      ),
      _SeedStaff(
        nom: 'Ben Kara Ahmed',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'A',
      ),
      _SeedStaff(
        nom: 'Kadri Karima',
        grade: 'ATS principal',
        groupe: 'Garde 24H',
        equipe: 'B',
      ),
      _SeedStaff(
        nom: 'Hiadsi Souad',
        grade: 'ATS principal',
        groupe: 'Garde 24H',
        equipe: 'B',
      ),
      _SeedStaff(
        nom: 'Belhadj kacem fatima',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'B',
      ),
      _SeedStaff(
        nom: 'Chaabane Abdelhamid',
        grade: 'infirmier major',
        groupe: 'Garde 24H',
        equipe: 'C',
        observation: 'Congé (25/08 - 23/09)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 8, 25),
            fin: DateTime(2026, 9, 23),
            motif: 'Congé',
          ),
        ],
      ),
      _SeedStaff(
        nom: 'Mahdjoubi Sami',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'C',
      ),
      _SeedStaff(
        nom: 'Belarbi Mohamed',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'C',
        observation: 'Congé (20/07 - 18/08)',
        leaves: [
          _SeedLeave(
            debut: DateTime(2026, 7, 20),
            fin: DateTime(2026, 8, 18),
            motif: 'Congé',
          ),
        ],
      ),
      _SeedStaff(
        nom: 'Bouderouez Fatiha',
        grade: 'IDE',
        groupe: 'Garde 24H',
        equipe: 'C',
      ),
      _SeedStaff(
        nom: 'Isselma Mohamed Nabi',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'D',
      ),
      _SeedStaff(
        nom: 'Hamdi Souad',
        grade: 'IDE',
        groupe: 'Garde 24H',
        equipe: 'D',
      ),
      _SeedStaff(
        nom: 'Moussa Hadjar',
        grade: 'ATS principal',
        groupe: 'Garde 24H',
        equipe: 'D',
      ),
      _SeedStaff(
        nom: 'Guerle Mohamed Yacine',
        grade: 'ATS',
        groupe: 'Garde 24H',
        equipe: 'D',
      ),

      // Agents d'hygiène
      _SeedStaff(
        nom: 'Mohand Fatiha',
        grade: "Agent d'hygiène",
        groupe: '12h',
        observation: '12h',
      ),
      _SeedStaff(
        nom: 'Touati Fatima',
        grade: "Agent d'hygiène",
        groupe: '12h',
        observation: '12h',
      ),
    ];
  }
}

class HospitalSeedImportResult {
  const HospitalSeedImportResult({
    required this.staffCount,
    required this.timeOffCount,
    required this.observationCount,
  });

  final int staffCount;
  final int timeOffCount;
  final int observationCount;
}

class _SeedStaff {
  const _SeedStaff({
    required this.nom,
    required this.grade,
    required this.groupe,
    this.equipe,
    this.observation,
    this.ordre,
    this.leaves = const [],
  });

  final String nom;
  final String grade;
  final String groupe;
  final String? equipe;
  final String? observation;
  final int? ordre;
  final List<_SeedLeave> leaves;
}

class _SeedLeave {
  const _SeedLeave({
    required this.debut,
    required this.fin,
    required this.motif,
  });

  final DateTime debut;
  final DateTime fin;
  final String motif;
}
