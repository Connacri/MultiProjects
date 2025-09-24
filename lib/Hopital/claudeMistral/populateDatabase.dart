// import 'package:objectbox/objectbox.dart';
// import '../../objectBox/Entity.dart';
//
//
// Future<void> populateDatabase(Store store) async {
//   final staffBox = store.box<Staff>();
//   final dailyPlanningBox = store.box<DailyPlanning>();
//   final monthlyPlanningBox = store.box<MonthlyPlanning>();
//
//   // Create a MonthlyPlanning for October 2025
//   final monthlyPlanning = MonthlyPlanning()
//     ..month = 10
//     ..year = 2025
//     ..service = 'Rheumatology'
//     ..department = 'Hospital'
//     ..planningType = PlanningType.monthly.index
//     ..title = 'Planning October 2025'
//     ..status = PlanningStatus.draft.index;
//
//   monthlyPlanningBox.put(monthlyPlanning);
//
//   // Complete staff data
//   final staffData = {
//     'Medjadi Mohsine': {
//       'function': 'Médecin Chef Rhumatologue',
//       'grade': 'Doctor',
//       'category': PersonnelCategory.medical.index,
//       'activities': [
//         ['N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'N', 'R']
//       ]
//     },
//     'Ouadah Souad': {
//       'function': 'Médecin chef Rhumatologue',
//       'grade': 'Doctor',
//       'category': PersonnelCategory.medical.index,
//       'activities': [
//         ['N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'R', 'R', 'N', 'N', 'N', 'N', 'N', 'N', 'R']
//       ]
//     },
//     // Ajoutez ici les autres membres du personnel et leurs activités
//     // ...
//   };
//
//   for (var entry in staffData.entries) {
//     final nameParts = entry.key.split(' ');
//     final lastName = nameParts.isNotEmpty ? nameParts.last : '';
//     final firstName = nameParts.length > 1 ? nameParts.first : '';
//
//     final staff = Staff(
//       lastName: lastName,
//       firstName: firstName,
//       staffNumber: 'EMP_${DateTime.now().millisecondsSinceEpoch}',
//       function: _getFunctionIndex(entry.value['function']!),
//       grade: entry.value['grade']!,
//       category: entry.value['category'] ?? PersonnelCategory.medical.index,
//       scheduleType: ScheduleType.normal8to16.index,
//       scheduleStart: '08:00',
//       scheduleEnd: '16:00',
//       status: EmployeeStatus.active.index,
//       isActive: true,
//     );
//
//     final staffId = staffBox.put(staff);
//
//     for (var i = 0; i < entry.value['activities']!.first.length; i++) {
//       final activityCode = entry.value['activities']!.first[i];
//       final activityType = ActivityTypeHelper.fromCode(activityCode).index;
//       final date = DateTime(2025, 10, i + 1);
//
//       final dailyPlanning = DailyPlanning()
//         ..dayDate = date
//         ..dayOfMonth = i + 1
//         ..activityType = activityType
//         ..status = ActivityStatus.scheduled.index
//         ..isWeekend = date.weekday == 6 || date.weekday == 7;
//
//       dailyPlanning.staff.targetId = staffId;
//       dailyPlanning.monthlyPlanning.targetId = monthlyPlanning.id;
//
//       dailyPlanningBox.put(dailyPlanning);
//     }
//   }
// }
//
// int _getFunctionIndex(String function) {
//   switch (function) {
//     case 'Médecin Chef Rhumatologue':
//     case 'Médecin chef Rhumatologue':
//     case 'Médecin Principale En Rhumatologie':
//     case 'Médecin Généraliste Principale':
//       return HospitalFunction.rheumatologist.index;
//     case 'Infirmier Major':
//     case 'Major Nurse':
//       return HospitalFunction.majorNurse.index;
//     case 'Administrateur':
//       return HospitalFunction.administrator.index;
//     case 'Agent de bureau':
//       return HospitalFunction.officeAgent.index;
//     case 'Agent D’hygiène':
//       return HospitalFunction.hygieneAgent.index;
//     case 'Psychologues':
//       return HospitalFunction.psychologist.index;
//     case 'Chargée de la pharmacie':
//       return HospitalFunction.pharmacyManager.index;
//     case 'ATS':
//     case 'ATS principal':
//       return HospitalFunction.technicalAgent.index;
//     case 'IDE':
//     case 'Registered Nurse':
//       return HospitalFunction.registeredNurse.index;
//     case 'Hygiene Agent':
//       return HospitalFunction.hygieneAgent.index;
//     default:
//       return HospitalFunction.doctor.index;
//   }
// }
