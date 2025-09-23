import 'package:flutter/material.dart';
import 'package:kenzy/Hopital/seed.dart';
import 'package:provider/provider.dart';

import '../objectBox/Entity.dart';
import '../objectBox/classeObjectBox.dart';
import 'ActiviteHebdoPage.dart';
import 'PlanningMoisPage.dart';
import 'PlanningMoisPageSynfusion.dart';
import 'Providers.dart';

class HomePageH extends StatelessWidget {
  const HomePageH({super.key});

  @override
  Widget build(BuildContext context) {
    final personnels = context.watch<PersonnelProvider>().personnels;
    final personnelProvider = context.read<PersonnelProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏥 Gestion Planning"),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final seeder = DatabaseSeeder(context.read<ObjectBox>().store);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 300));
              seeder.seed();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Base remplie avec succès")),
              );
            },
            child: const Text("Remplir la base"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Section Personnels
          buildSection(
            context,
            title: "👨‍⚕️ Personnels",
            child: Column(
              children: personnels.map((personnel) {
                return ListTile(
                  title: Text("${personnel.nom} ${personnel.prenom}"),
                  subtitle: Text(
                    (personnel.grade.isNotEmpty &&
                            personnel.fonction.isNotEmpty)
                        ? 'Grade : ${personnel.grade} - Fonction : ${personnel.fonction}'
                        : (personnel.fonction.isNotEmpty)
                            ? 'Fonction : ${personnel.fonction}'
                            : 'Grade : ${personnel.grade}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showPersonnelDialog(
                          context,
                          provider: personnelProvider,
                          personnel: personnel,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDeletePersonnel(context, personnel),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            onAdd: () =>
                _showPersonnelDialog(context, provider: personnelProvider),
          ),

          const SizedBox(height: 20),
          buildGroupesSection(context),

          const SizedBox(height: 20),
          buildSection(
            context,
            title: "📅 Planning Mensuel",
            child: ListTile(
              title: const Text("Voir le planning du mois courant"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                final now = DateTime.now();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanningMoisPage(
                      annee: now.year,
                      mois: now.month,
                    ),
                  ),
                );
              },
            ),
          ),
          buildSection(
            context,
            title: "📅 Planning Mensuel (Synfusion)",
            child: ListTile(
              title: const Text("Voir le planning du mois courant Synfusion"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanningMoisPageSynfusion(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          buildSection(
            context,
            title: "🗓️ Planning Hebdo",
            child: ListTile(
              title: const Text("Voir le planning hebdomadaire"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiviteHebdoPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Bloc réutilisable pour sections
  Widget buildSection(BuildContext context,
      {required String title, required Widget child, VoidCallback? onAdd}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (onAdd != null)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: onAdd,
                  ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  /// ================== DIALOG AJOUT / EDIT ==================
  void _showPersonnelDialog(
    BuildContext context, {
    required PersonnelProvider provider,
    Personnel? personnel,
  }) {
    final nomCtrl = TextEditingController(text: personnel?.nom ?? "");
    final prenomCtrl = TextEditingController(text: personnel?.prenom ?? "");
    final fonctionCtrl = TextEditingController(text: personnel?.fonction ?? "");
    final gradeCtrl = TextEditingController(text: personnel?.grade ?? "");

    final allGroupes = context.read<GroupeTravailProvider>().groupes;

    const List<String> services = [
      "Médecins",
      "Bureau",
      "Infirmiers",
      "Femmes de ménage"
    ];

    String? selectedService =
        services.contains(personnel?.service) ? personnel!.service : null;
    GroupeTravail? selectedGroupe = personnel?.groupeTravail.target;

    // ← Ici tu définis la fonction
    List<GroupeTravail> groupesForService(String? service) {
      if (service == null) return [];
      switch (service) {
        case "Médecins":
          return allGroupes.where((g) => g.nom.contains("Médecin")).toList();
        case "Bureau":
          return allGroupes
              .where((g) => g.nom == "Administration" || g.nom == "Pharmacie")
              .toList();
        case "Infirmiers":
          // ✅ inclure tes groupes A/B/C/D
          return allGroupes
              .where((g) => ["A", "B", "C", "D"].contains(g.nom))
              .toList();
        case "Femmes de ménage":
          return allGroupes.where((g) => g.nom.contains("Ménage")).toList();
        default:
          return [];
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setState) {
            // Filtrer les groupes selon le service sélectionné
            final filteredGroupes = groupesForService(selectedService);

            // Vérifier si le groupe sélectionné est encore valide
            if (selectedGroupe != null &&
                !filteredGroupes.any((g) => g.id == selectedGroupe!.id)) {
              selectedGroupe = null;
            }

            return AlertDialog(
              title: Text(personnel == null
                  ? "Ajouter un personnel"
                  : "Modifier personnel"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomCtrl,
                      decoration: const InputDecoration(labelText: "Nom"),
                    ),
                    TextField(
                      controller: prenomCtrl,
                      decoration: const InputDecoration(labelText: "Prénom"),
                    ),
                    TextField(
                      controller: fonctionCtrl,
                      decoration: const InputDecoration(labelText: "Fonction"),
                    ),
                    TextField(
                      controller: gradeCtrl,
                      decoration: const InputDecoration(labelText: "Grade"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedService,
                      decoration: const InputDecoration(labelText: "Service"),
                      items: services
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (service) {
                        setState(() {
                          selectedService = service;
                          selectedGroupe = null; // reset groupe
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (filteredGroupes.isNotEmpty)
                      DropdownButtonFormField<GroupeTravail>(
                        value: selectedGroupe,
                        decoration: const InputDecoration(
                            labelText: "Groupe de travail"),
                        items: filteredGroupes
                            .map((g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.nom),
                                ))
                            .toList(),
                        onChanged: (groupe) {
                          setState(() {
                            selectedGroupe = groupe;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nomCtrl.text.isEmpty || selectedService == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Nom et service sont obligatoires !")),
                      );
                      return;
                    }

                    if (personnel == null) {
                      final newPersonnel = Personnel(
                        nom: nomCtrl.text,
                        prenom: prenomCtrl.text,
                        fonction: fonctionCtrl.text,
                        grade: gradeCtrl.text,
                        service: selectedService!,
                      );
                      if (selectedGroupe != null)
                        newPersonnel.groupeTravail.target = selectedGroupe;
                      provider.addPersonnel(newPersonnel);
                    } else {
                      personnel
                        ..nom = nomCtrl.text
                        ..prenom = prenomCtrl.text
                        ..fonction = fonctionCtrl.text
                        ..grade = gradeCtrl.text
                        ..service = selectedService!;
                      personnel.groupeTravail.target = selectedGroupe;
                      provider.updatePersonnel(personnel);
                    }

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ================== CONFIRM DELETE ==================
  void _confirmDeletePersonnel(BuildContext context, Personnel p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Voulez-vous supprimer ${p.nom} ${p.prenom} ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              context.read<PersonnelProvider>().deletePersonnel(p.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void showGroupeDialog2(BuildContext context, {GroupeTravail? groupe}) {
    final nomCtrl = TextEditingController(text: groupe?.nom ?? "");
    String? selectedService = groupe?.service;

    const List<String> services = [
      "Médecins",
      "Bureau",
      "Infirmiers",
      "Femmes de ménage"
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (innerContext, setState) => AlertDialog(
          title: Text(groupe == null ? "Ajouter un groupe" : "Modifier groupe"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(labelText: "Nom du groupe"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedService,
                  decoration: const InputDecoration(
                    labelText: "Service",
                    hintText: "Choisir un service",
                  ),
                  items: services
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedService = value);
                  },
                  validator: (value) =>
                      value == null ? 'Le service est obligatoire' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.isEmpty || selectedService == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nom et service sont obligatoires !"),
                    ),
                  );
                  return;
                }

                final provider = context.read<GroupeTravailProvider>();
                if (groupe == null) {
                  provider.addGroupe(
                    GroupeTravail(
                      nom: nomCtrl.text,
                      service: selectedService!,
                    ),
                  );
                } else {
                  groupe.nom = nomCtrl.text;
                  groupe.service = selectedService!;
                  provider.updateGroupe(groupe);
                }

                Navigator.pop(dialogContext);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

// --- Build groupes section ---
  Widget buildGroupesSection(BuildContext context) {
    final groupes = context.watch<GroupeTravailProvider>().groupes;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Text("📂 Groupes de travail",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                IconButton(
                  onPressed: () => showGroupeDialog2(context),
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                ),
              ],
            ),
            const Divider(),
            ...groupes.map((g) => ListTile(
                  title: Text("${g.nom} (${g.service})"), // affiche le service
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showGroupeDialog2(context, groupe: g),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteGroupe(context, g),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Confirmation suppression groupe
  void _confirmDeleteGroupe(BuildContext context, GroupeTravail g) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Voulez-vous supprimer le groupe ${g.nom} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GroupeTravailProvider>().deleteGroupe(g.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}
