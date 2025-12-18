import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';

class ActivitePersonne {
  String nom;
  String grade;
  String groupe; // Exemple: "08H-16H", "Garde 12H"
  String? equipe; // A, B, C, D
  String? mois; // "Octobre 2025"
  String? horaire; // "08h-16h", "08h-08h"
  String? obs; // Observations particulières

  /// Statuts du 1er au 31 (jours)
  List<String> jours;

  /// Optionnel : liste des congés
  List<TimeOffDTO>? conges;

  /// Optionnel : nom du service (branch)
  String? branchNom;

  ActivitePersonne({
    required this.nom,
    required this.grade,
    required this.groupe,
    this.equipe,
    this.mois,
    this.horaire,
    this.obs,
    required this.jours,
    this.conges,
    this.branchNom,
  });
}

/// DTO temporaire pour représenter un congé avant insertion dans ObjectBox
class TimeOffDTO {
  DateTime debut;
  DateTime fin;
  String? motif;

  TimeOffDTO({
    required this.debut,
    required this.fin,
    this.motif,
  });
}

final List<ActivitePersonne> activites = [
  // Personnel Médical
  ActivitePersonne(
    nom: "Medjadi Mohsine",
    grade: "Médecin Chef Rhumatologue",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Ouadah Souad",
    grade: "Médecin Principale En Rhumatologie",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Bouziane Kheira",
    grade: "Médecin Généraliste Principale",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Tlemsani Naziha",
    grade: "Médecin Généraliste Principale",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Boumazouzi Hind",
    grade: "Médecin Généraliste Principale",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Benrahal Yasmina",
    grade: "Médecin Généraliste",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),

  // 08H-16H - Personnel administratif
  ActivitePersonne(
    nom: "Kerarma Djelloul",
    grade: "Infirmier Major",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Meddah Fadela",
    grade: "Psychologue",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Bouaziz Nacer",
    grade: "ATS principal",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Rahmani Ibtissem",
    grade: "ATS principal",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Kassab Hichem",
    grade: "ATS principal",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Behloul Zahra",
    grade: "Administrateur",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Naamoun Sarra",
    grade: "Chargée de pharmacie",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Nekrouf Amel",
    grade: "Chargée de pharmacie",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Zalegh Fatima",
    grade: "Agent de bureau",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Baoud Kholoud",
    grade: "Agent de bureau",
    groupe: "08H-16H",
    mois: "Octobre 2025",
    horaire: "08h-16h",
    jours: [],
  ),

  // Groupe A
  ActivitePersonne(
    nom: "Bakhouche Sarra",
    grade: "ATS",
    groupe: "Garde 12H",
    equipe: "A",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Behloul Sihem",
    grade: "ATS",
    groupe: "Garde 12H",
    equipe: "A",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Bouabida Ikram",
    grade: "ATS principal",
    groupe: "Garde 12H",
    equipe: "A",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),

  // Groupe B
  ActivitePersonne(
    nom: "Hiadsi Souad",
    grade: "ATS principal",
    groupe: "Garde 12H",
    equipe: "B",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Ait Menguellat Lilia",
    grade: "ATS principal",
    groupe: "Garde 12H",
    equipe: "B",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Kadri Karima",
    grade: "ATS principal",
    groupe: "Garde 12H",
    equipe: "B",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Moussa Hadjar",
    grade: "ATS principal",
    groupe: "Garde 12H",
    equipe: "B",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),

  // Groupe C
  ActivitePersonne(
    nom: "Chaabane Abdelhamid",
    grade: "IDE",
    groupe: "Garde 12H",
    equipe: "C",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Mahdjoubi Sami",
    grade: "IDE",
    groupe: "Garde 12H",
    equipe: "C",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Ben Kara Ahmed",
    grade: "ATS",
    groupe: "Garde 12H",
    equipe: "C",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),

  // Groupe D
  ActivitePersonne(
    nom: "Bouderouez Fatiha",
    grade: "IDE",
    groupe: "Garde 12H",
    equipe: "D",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Hamdi Souad",
    grade: "IDE",
    groupe: "Garde 12H",
    equipe: "D",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Guerle Mohamed Yacine",
    grade: "ATS",
    groupe: "Garde 12H",
    equipe: "D",
    mois: "Septembre 2025",
    horaire: "24h",
    jours: [],
  ),
//Hygiéne
  ActivitePersonne(
    nom: "Mohand Fatiha",
    grade: "Agent d'hygiène",
    groupe: "08h-12h",
    mois: "Octobre 2025",
    horaire: "12h",
    jours: [],
  ),
  ActivitePersonne(
    nom: "Touati Fatima",
    grade: "Agent d'hygiène",
    groupe: "08h-12h",
    mois: "Octobre 2025",
    horaire: "12h",
    jours: [],
  ),
];

// Fonction corrigée pour insérer les activités
void insertActivites(List<ActivitePersonne> liste) {
  final objectBox = ObjectBox();
  final staffBox = objectBox.staffBox;
  final activiteBox = objectBox.activiteBox;
  final branchBox = objectBox.branchBox;
  final timeOffBox = objectBox.timeOffBox;

  // ⚠️ Nettoyer les tables (à utiliser seulement si tu veux repartir à zéro)
  activiteBox.removeAll();
  staffBox.removeAll();
  branchBox.removeAll();
  timeOffBox.removeAll();

  for (var e in liste) {
    // 1️⃣ Vérifier/créer la Branch (service)
    Branch branch = branchBox
            .query(Branch_.branchNom.equals(e.branchNom!))
            .build()
            .findFirst() ??
        Branch(branchNom: e.branchNom!);

    branchBox.put(branch);

    // 2️⃣ Créer le Staff et lui affecter la Branch
    final staff = Staff(
      nom: e.nom,
      grade: e.grade,
      groupe: e.groupe,
      equipe: e.equipe,
      // obs: e.obs,
    );

    staff.branch.target = branch; // liaison OneToOne
    final staffId = staffBox.put(staff);

    print(
        "✅ Staff inséré: ${staff.nom}, ID: $staffId, Branch: ${branch.branchNom}");

    // 3️⃣ Insérer les activités (planning des jours)
    for (int i = 0; i < e.jours.length && i < 31; i++) {
      final activite = ActiviteJour(
        jour: i + 1,
        statut: e.jours[i],
      );

      activite.staff.target = staff; // liaison vers staff
      activiteBox.put(activite);
    }

    // 4️⃣ Insérer les congés si dispo
    if (e.conges != null) {
      for (var conge in e.conges!) {
        final timeOff = TimeOff(
          debut: conge.debut,
          fin: conge.fin,
          motif: conge.motif,
        );

        timeOff.staff.target = staff;
        timeOffBox.put(timeOff);
      }
    }
  }
}

Future<void> assignRhumatologieToAllStaffs() async {
  final objectBox = ObjectBox();
  final branchBox = objectBox.branchBox;
  final staffBox = objectBox.staffBox;

  // 1️⃣ Vérifier si la branche "Rhumatologie" existe déjà
  final query =
      branchBox.query(Branch_.branchNom.equals("Rhumatologie")).build();
  Branch? branch = query.findFirst();
  query.close();

  // 2️⃣ Si elle n’existe pas, on la crée et on l’enregistre dans le box
  if (branch == null) {
    branch = Branch(branchNom: "Rhumatologie");
    final branchId = branchBox.put(branch);
    print("✅ Nouvelle branche créée : Rhumatologie (ID: $branchId)");
  } else {
    // 🔹 On la remet dans le box au cas où elle aurait été modifiée ailleurs
    branchBox.put(branch);
    print("ℹ️ Branche existante trouvée : Rhumatologie (ID: ${branch.id})");
  }

  // 3️⃣ Récupérer tous les staffs existants
  final staffs = staffBox.getAll();

  if (staffs.isEmpty) {
    print("⚠️ Aucun staff trouvé. Aucun changement effectué.");
    return;
  }

  // 4️⃣ Assigner la branche Rhumatologie à tous les staffs
  for (var staff in staffs) {
    staff.branch.target = branch;
    staffBox.put(staff);
    print("👤 ${staff.nom} → Branche : ${branch.branchNom}");
  }

  // 5️⃣ Vérification de cohérence (optionnelle)
  final count =
      staffBox.getAll().where((s) => s.branch.target?.id == branch!.id).length;
  print(
      "--- ✅ Tous les staffs (${count}) sont assignés à ${branch.branchNom} ---");
}

class PlanningHebdoData {
  static List<Map<String, dynamic>> getExamplePlanning() {
    return [
      {
        'nom': 'Medjadi Mohsine',
        'grade': 'Médecin Chef Rhumatologue',
        'dimanche': 'Service Biothérapie',
        'lundi': 'DMO',
        'mardi': 'Visite Générale',
        'mercredi': 'Consultation E.P.S.P Ben Smir',
        'jeudi': 'Journée Pédagogique',
      },
      {
        'nom': 'Ouadah Souad',
        'grade': 'Médecin Principale En Rhumatologie',
        'dimanche': 'Journée Pédagogique',
        'lundi': 'Consultation E.P.S.P Mers El Kebir',
        'mardi': 'Visite Générale',
        'mercredi': 'DMO',
        'jeudi': 'Service Biothérapie',
      },
      {
        'nom': 'Bouziane Kheira',
        'grade': 'Médecin Généraliste Principale',
        'dimanche': 'Consultation E.P.S.P Ben Smir',
        'lundi': 'Journée Pédagogique',
        'mardi': 'Visite Générale',
        'mercredi': 'Service',
        'jeudi': 'DMO',
      },
      {
        'nom': 'Tlemsani Naziha',
        'grade': 'Médecin Généraliste Principale',
        'dimanche': 'Service',
        'lundi': 'Service',
        'mardi': 'Consultation E.P.S.P Ben Smir',
        'mercredi': 'Service',
        'jeudi': 'Service',
      },
      {
        'nom': 'Boumazouzi Hind',
        'grade': 'Médecin Généraliste Principale',
        'dimanche': 'Service',
        'lundi': 'Service',
        'mardi': 'Visite Générale',
        'mercredi': 'Service',
        'jeudi': 'Consultation E.P.S.P Ben Smir',
      },
      {
        'nom': 'Benrahal Yasmina',
        'grade': 'Médecin Généraliste',
        'dimanche': 'Service',
        'lundi': 'Service',
        'mardi': 'Visite Générale',
        'mercredi': 'Service',
        'jeudi': 'Consultation E.P.S.P Ben Smir',
      },
    ];
  }

  /// Fonction pour insérer les données exemple dans ObjectBox
  static Future<void> insertExampleData(
      Store store, Box<Staff> staffBox, Box<PlanningHebdo> planningBox) async {
    final data = getExamplePlanning();

    for (var item in data) {
      // Créer ou récupérer le staff
      Staff? staff = staffBox
          .query(Staff_.nom.equals(item['nom'] as String))
          .build()
          .findFirst();

      if (staff == null) {
        staff = Staff(
          nom: item['nom'] as String,
          grade: item['grade'] as String,
          groupe: '08H-16H',
        );
        staffBox.put(staff);
      }

      // Créer le planning hebdo
      final planning = PlanningHebdo(
        dimanche: item['dimanche'] as String?,
        lundi: item['lundi'] as String?,
        mardi: item['mardi'] as String?,
        mercredi: item['mercredi'] as String?,
        jeudi: item['jeudi'] as String?,
        vendredi: item['vendredi'] as String?,
        samedi: item['samedi'] as String?,
      );

      planning.staff.target = staff;
      planningBox.put(planning);

      print('✅ Planning créé pour ${staff.nom}');
    }
  }

  /// Types d'activités courants
  static List<TypeActivite> getTypesActivites() {
    return [
      TypeActivite(
        code: 'DMO',
        libelle: 'DMO',
        description: 'Densitométrie Osseuse',
        couleurHex: 0xFF2196F3,
      ),
      TypeActivite(
        code: 'VG',
        libelle: 'Visite Générale',
        couleurHex: 0xFF4CAF50,
      ),
      TypeActivite(
        code: 'CONS',
        libelle: 'Consultation',
        description: 'Consultation externe',
        couleurHex: 0xFFFF9800,
      ),
      TypeActivite(
        code: 'CONS_EPSP',
        libelle: 'Consultation E.P.S.P',
        description: 'Consultation Établissement Public de Santé de Proximité',
        couleurHex: 0xFF9C27B0,
      ),
      TypeActivite(
        code: 'SERV',
        libelle: 'Service',
        description: 'Service hospitalier',
        couleurHex: 0xFF607D8B,
      ),
      TypeActivite(
        code: 'JP',
        libelle: 'Journée Pédagogique',
        couleurHex: 0xFFE91E63,
      ),
      TypeActivite(
        code: 'BIOTHER',
        libelle: 'Biothérapie',
        description: 'Service Biothérapie',
        couleurHex: 0xFF00BCD4,
      ),
    ];
  }
}
