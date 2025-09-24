import 'package:flutter/material.dart';

import '../../objectBox/Entity.dart';
import '../../objectbox.g.dart';

class ImportHopitalButton extends StatelessWidget {
  const ImportHopitalButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text("Importer données hôpital"),
      onPressed: () async {
        final store = await openStore();

        final staffBox = store.box<Staff>();
        final planningBox = store.box<MonthlyPlanning>();
        final dailyBox = store.box<DailyPlanning>();
        final leaveBox = store.box<Leave>();

        /// 1️⃣ Planning mensuel
        final monthlyPlanning = MonthlyPlanning()
          ..month = 10
          ..year = 2025
          ..service = "Rhumatologie"
          ..department = "Médecine"
          ..planningType = PlanningType.monthly.index
          ..status = PlanningStatus.validated.index
          ..isValidated = true
          ..title = "Planning Octobre 2025 - Rhumatologie";

        planningBox.put(monthlyPlanning);

        /// 2️⃣ Liste du personnel
        final personnels = [
          // Médecins (document 1)
          {
            "lastName": "Medjadi",
            "firstName": "Mohsine",
            "grade": "Médecin Chef Rhumatologue",
            "function": HospitalFunction.rheumatologist,
            "category": PersonnelCategory.medical
          },
          {
            "lastName": "Ouadah",
            "firstName": "Souad",
            "grade": "Médecin Chef Rhumatologue",
            "function": HospitalFunction.rheumatologist,
            "category": PersonnelCategory.medical
          },
          {
            "lastName": "Bouziane",
            "firstName": "Kheira",
            "grade": "Médecin Principale En Rhumatologie",
            "function": HospitalFunction.principalDoctor,
            "category": PersonnelCategory.medical
          },
          {
            "lastName": "Tlemsani",
            "firstName": "Naziha",
            "grade": "Médecin Généraliste Principale",
            "function": HospitalFunction.generalPractitioner,
            "category": PersonnelCategory.medical
          },
          {
            "lastName": "Boumazouzi",
            "firstName": "Hind",
            "grade": "Médecin Généraliste Principale",
            "function": HospitalFunction.generalPractitioner,
            "category": PersonnelCategory.medical
          },

          // Paramédicaux (document 1)
          {
            "lastName": "Kerarma",
            "firstName": "Djelloul",
            "grade": "Infirmier Major",
            "function": HospitalFunction.majorNurse,
            "category": PersonnelCategory.paramedical
          },
          {
            "lastName": "Meddah",
            "firstName": "Fadela",
            "grade": "Psychologue",
            "function": HospitalFunction.psychologist,
            "category": PersonnelCategory.paramedical
          },
          {
            "lastName": "Behloul",
            "firstName": "Zahra",
            "grade": "Administrateur",
            "function": HospitalFunction.administrator,
            "category": PersonnelCategory.administrative
          },
          {
            "lastName": "Zalegh",
            "firstName": "Fatima",
            "grade": "Agent de bureau",
            "function": HospitalFunction.officeAgent,
            "category": PersonnelCategory.administrative
          },
          {
            "lastName": "Baoud",
            "firstName": "Kholoud",
            "grade": "Agent de bureau",
            "function": HospitalFunction.officeAgent,
            "category": PersonnelCategory.administrative
          },
          {
            "lastName": "Naamoun",
            "firstName": "Sarra",
            "grade": "Chargée de pharmacie",
            "function": HospitalFunction.pharmacist,
            "category": PersonnelCategory.paramedical
          },
          {
            "lastName": "Nekrouf",
            "firstName": "Amel",
            "grade": "Chargée de pharmacie",
            "function": HospitalFunction.pharmacist,
            "category": PersonnelCategory.paramedical
          },
          {
            "lastName": "Bouaziz",
            "firstName": "Nacer",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical
          },
          {
            "lastName": "Rahmani",
            "firstName": "Ibtissem",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical
          },
          {
            "lastName": "Kassab",
            "firstName": "Hichem",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical
          },

          // Agents d’hygiène
          {
            "lastName": "Mohand",
            "firstName": "Fatiha",
            "grade": "Agent d’hygiène",
            "function": HospitalFunction.hygieneAgent,
            "category": PersonnelCategory.support
          },
          {
            "lastName": "Touati",
            "firstName": "Fatima",
            "grade": "Agent d’hygiène",
            "function": HospitalFunction.hygieneAgent,
            "category": PersonnelCategory.support
          },

          // Groupes de garde A
          {
            "lastName": "Behloul",
            "firstName": "Siham",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "A"
          },
          {
            "lastName": "Bouabida",
            "firstName": "Ikram",
            "grade": "ATS",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "A"
          },
          {
            "lastName": "Bakhouche",
            "firstName": "Sarra",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "A"
          },

          // Groupe B
          {
            "lastName": "Hiadsi",
            "firstName": "Souad",
            "grade": "IDE",
            "function": HospitalFunction.nurse,
            "category": PersonnelCategory.paramedical,
            "guardGroup": "B"
          },
          {
            "lastName": "Ait Menguellat",
            "firstName": "Lilia",
            "grade": "ATS",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "B"
          },
          {
            "lastName": "Kadri",
            "firstName": "Karima",
            "grade": "ATS",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "B"
          },
          {
            "lastName": "Moussa",
            "firstName": "Hadjar",
            "grade": "ATS",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "B"
          },

          // Groupe C
          {
            "lastName": "Chaabane",
            "firstName": "Abdelhamid",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "C"
          },
          {
            "lastName": "Mahdjoubi",
            "firstName": "Sami",
            "grade": "ATS",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "C"
          },
          {
            "lastName": "Ben Kara",
            "firstName": "Ahmed",
            "grade": "ATS Principal",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "C"
          },

          // Groupe D
          {
            "lastName": "Bouderouez",
            "firstName": "Fatiha",
            "grade": "IDE",
            "function": HospitalFunction.nurse,
            "category": PersonnelCategory.paramedical,
            "guardGroup": "D"
          },
          {
            "lastName": "Hamdi",
            "firstName": "Souad",
            "grade": "IDE",
            "function": HospitalFunction.nurse,
            "category": PersonnelCategory.paramedical,
            "guardGroup": "D"
          },
          {
            "lastName": "Guerle",
            "firstName": "Mohamed Yacine",
            "grade": "ATS",
            "function": HospitalFunction.technicalAgent,
            "category": PersonnelCategory.technical,
            "guardGroup": "D"
          },
        ];

        /// 3️⃣ Insertion + Planning journalier
        for (var p in personnels) {
          final staff = Staff(
            staffNumber: "EMP_${DateTime.now().microsecondsSinceEpoch}",
            lastName: p["lastName"] as String,
            firstName: p["firstName"] as String,
            grade: p["grade"] as String,
            function: (p["function"] as HospitalFunction).index,
            category: (p["category"] as PersonnelCategory).index,
            service: "Rhumatologie",
            department: "Médecine",
            scheduleType: ScheduleType.normal8to16.index,
            status: EmployeeStatus.active.index,
            guardGroup: p["guardGroup"] as String?,
            isActive: true,
            isAvailableForGuard: (p["guardGroup"] != null),
          );

          staffBox.put(staff);

          // Activités journalières de base = N
          for (int day = 1; day <= monthlyPlanning.numberOfDays; day++) {
            final date =
                DateTime(monthlyPlanning.year, monthlyPlanning.month, day);

            final daily = DailyPlanning()
              ..dayDate = date
              ..dayOfMonth = day
              ..activityType = ActivityType.normal.index
              ..status = ActivityStatus.scheduled.index
              ..isWeekend = date.weekday == 6 || date.weekday == 7;

            daily.staff.target = staff;
            daily.monthlyPlanning.target = monthlyPlanning;

            dailyBox.put(daily);
          }
        }

        /// 4️⃣ Ajout des congés (document 1)
        final leaves = [
          {
            "start": DateTime(2025, 9, 14),
            "end": DateTime(2025, 10, 5),
            "reason": "Congé annuel"
          },
          {
            "start": DateTime(2025, 9, 15),
            "end": DateTime(2025, 10, 4),
            "reason": "Congé annuel"
          },
        ];

        for (var l in leaves) {
          final leave = Leave()
            ..startDate = l["start"] as DateTime
            ..endDate = l["end"] as DateTime
            ..leaveType = LeaveType.annual.index
            ..status = LeaveStatus.approved.index
            ..reason = l["reason"] as String;
          leaveBox.put(leave);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Importation complète réussie")),
        );
      },
    );
  }
}
