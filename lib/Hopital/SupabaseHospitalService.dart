import 'package:supabase_flutter/supabase_flutter.dart';
import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import '../objectbox.g.dart';

class SupabaseHospitalService {
  final SupabaseClient _client = Supabase.instance.client;
  final ObjectBox _objectBox = ObjectBox();

  /// Exporte toutes les données de l'hôpital vers Supabase
  Future<void> exportAllToSupabase() async {
    print('🚀 Début de l\'exportation vers Supabase...');

    try {
      // 1. Exporter les branches
      await _exportBranches();
      
      // 2. Exporter les staffs
      await _exportStaffs();
      
      // 3. Exporter les types d'activités
      await _exportTypeActivites();
      
      // 4. Exporter les activités
      await _exportActiviteJours();
      
      // 5. Exporter les congés
      await _exportTimeOffs();
      
      // 6. Exporter les planifications
      await _exportPlanifications();
      
      // 7. Exporter les plannings hebdomadaires
      await _exportPlanningHebdos();

      print('✅ Exportation terminée avec succès !');
    } catch (e) {
      print('❌ Erreur lors de l\'exportation : $e');
      rethrow;
    }
  }

  Future<void> _exportBranches() async {
    final branches = _objectBox.branchBox.getAll();
    if (branches.isEmpty) return;

    final data = branches.map((b) => {
      'id': b.id,
      'branch_nom': b.branchNom,
    }).toList();

    await _client.from('branches').upsert(data);
    print('📦 ${branches.length} branches exportées');
  }

  Future<void> _exportStaffs() async {
    final staffs = _objectBox.staffBox.getAll();
    if (staffs.isEmpty) return;

    final data = staffs.map((s) => {
      'id': s.id,
      'nom': s.nom,
      'grade': s.grade,
      'groupe': s.groupe,
      'equipe': s.equipe,
      'ordre': s.ordre,
      'branch_id': s.branch.targetId != 0 ? s.branch.targetId : null,
    }).toList();

    await _client.from('staffs').upsert(data);
    print('📦 ${staffs.length} staffs exportés');
  }

  Future<void> _exportTypeActivites() async {
    final types = _objectBox.typeActiviteBox.getAll();
    if (types.isEmpty) return;

    final data = types.map((t) => {
      'id': t.id,
      'code': t.code,
      'libelle': t.libelle,
      'description': t.description,
      'couleur_hex': t.couleurHex,
    }).toList();

    await _client.from('type_activites').upsert(data);
    print('📦 ${types.length} types d\'activités exportés');
  }

  Future<void> _exportActiviteJours() async {
    final activites = _objectBox.activiteBox.getAll();
    if (activites.isEmpty) return;

    // Supabase might have limits on the number of rows per insert
    // We'll chunk it if necessary, but for now let's try direct upsert
    final data = activites.map((a) => {
      'id': a.id,
      'jour': a.jour,
      'statut': a.statut,
      'staff_id': a.staff.targetId != 0 ? a.staff.targetId : null,
    }).toList();

    // Chunking to avoid large payload issues
    for (var i = 0; i < data.length; i += 1000) {
      final end = (i + 1000 < data.length) ? i + 1000 : data.length;
      await _client.from('activite_jours').upsert(data.sublist(i, end));
    }
    
    print('📦 ${activites.length} activités exportées');
  }

  Future<void> _exportTimeOffs() async {
    final timeOffs = _objectBox.timeOffBox.getAll();
    if (timeOffs.isEmpty) return;

    final data = timeOffs.map((t) => {
      'id': t.id,
      'debut': t.debut.toIso8601String(),
      'fin': t.fin.toIso8601String(),
      'motif': t.motif,
      'staff_id': t.staff.targetId != 0 ? t.staff.targetId : null,
    }).toList();

    await _client.from('time_offs').upsert(data);
    print('📦 ${timeOffs.length} congés exportés');
  }

  Future<void> _exportPlanifications() async {
    final planifications = _objectBox.planificationBox.getAll();
    if (planifications.isEmpty) return;

    final data = planifications.map((p) => {
      'id': p.id,
      'mois': p.mois,
      'annee': p.annee,
      'ordre_equipes': p.ordreEquipes,
      'branch_id': p.branch.targetId != 0 ? p.branch.targetId : null,
      'activites_json': p.activitesJson != null ? p.activitesJson : null,
    }).toList();

    await _client.from('planifications').upsert(data);
    print('📦 ${planifications.length} planifications exportées');
  }

  Future<void> _exportPlanningHebdos() async {
    final plannings = _objectBox.planningHebdoBox.getAll();
    if (plannings.isEmpty) return;

    final data = plannings.map((p) => {
      'id': p.id,
      'staff_id': p.staff.targetId != 0 ? p.staff.targetId : null,
      'dimanche': p.dimanche,
      'lundi': p.lundi,
      'mardi': p.mardi,
      'mercredi': p.mercredi,
      'jeudi': p.jeudi,
      'vendredi': p.vendredi,
      'samedi': p.samedi,
      'date_debut': p.dateDebut?.toIso8601String(),
      'date_fin': p.dateFin?.toIso8601String(),
    }).toList();

    await _client.from('planning_hebdos').upsert(data);
    print('📦 ${plannings.length} plannings hebdomadaires exportés');
  }
}
