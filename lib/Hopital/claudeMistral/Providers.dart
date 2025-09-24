import 'package:flutter/material.dart';

import '../../objectBox/Entity.dart';
import '../../objectbox.g.dart';

class StaffProvider with ChangeNotifier {
  List<Staff> _staffs = [];

  List<Staff> get staffs => _staffs;

  void addStaff(Staff staff) {
    _staffs.add(staff);
    notifyListeners();
  }

  void updateStaff(int index, Staff staff) {
    if (index >= 0 && index < _staffs.length) {
      _staffs[index] = staff;
      notifyListeners();
    } else {
      throw RangeError('Index out of range');
    }
  }

  void removeStaff(int index) {
    if (index >= 0 && index < _staffs.length) {
      _staffs.removeAt(index);
      notifyListeners();
    } else {
      throw RangeError('Index out of range');
    }
  }
}

class MonthlyPlanningProvider with ChangeNotifier {
  List<MonthlyPlanning> _monthlyPlannings = [];

  List<MonthlyPlanning> get monthlyPlannings => _monthlyPlannings;

  void addMonthlyPlanning(MonthlyPlanning monthlyPlanning) {
    _monthlyPlannings.add(monthlyPlanning);
    notifyListeners();
  }

  void updateMonthlyPlanning(int index, MonthlyPlanning monthlyPlanning) {
    if (index >= 0 && index < _monthlyPlannings.length) {
      _monthlyPlannings[index] = monthlyPlanning;
      notifyListeners();
    } else {
      throw RangeError('Index out of range');
    }
  }

  void removeMonthlyPlanning(int index) {
    if (index >= 0 && index < _monthlyPlannings.length) {
      _monthlyPlannings.removeAt(index);
      notifyListeners();
    } else {
      throw RangeError('Index out of range');
    }
  }
}

class HospitalServiceProvider with ChangeNotifier {
  List<HospitalService> _hospitalServices = [];

  List<HospitalService> get hospitalServices => _hospitalServices;

  void addHospitalService(HospitalService hospitalService) {
    _hospitalServices.add(hospitalService);
    notifyListeners();
  }

  void updateHospitalService(int index, HospitalService hospitalService) {
    if (index >= 0 && index < _hospitalServices.length) {
      _hospitalServices[index] = hospitalService;
      notifyListeners();
    } else {
      throw RangeError('Index out of range');
    }
  }

  void removeHospitalService(int index) {
    if (index >= 0 && index < _hospitalServices.length) {
      _hospitalServices.removeAt(index);
      notifyListeners();
    } else {
      throw RangeError('Index out of range');
    }
  }
}

class DailyPlanningProvider with ChangeNotifier {
  late final Box<DailyPlanning> _dailyPlanningBox;
  late final Box<Employee> _staffBox;

  DailyPlanningProvider(Store store) {
    _dailyPlanningBox = Box<DailyPlanning>(store);
    _staffBox = Box<Employee>(store);
  }

  // Helper method to convert DateTime to timestamp
  int _dateTimeToTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  // Récupérer tous les plannings quotidiens
  List<DailyPlanning> getAllDailyPlannings() {
    return _dailyPlanningBox.getAll();
  }

  // Récupérer les plannings quotidiens pour un employé spécifique
  List<DailyPlanning> getDailyPlanningsForEmployee(int staffId) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour une période spécifique
  List<DailyPlanning> getDailyPlanningsForPeriod(
      DateTime startDate, DateTime endDate) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(
            _dateTimeToTimestamp(startDate), _dateTimeToTimestamp(endDate)))
        .build()
        .find();
  }

  // Ajouter un nouveau planning quotidien
  void addDailyPlanning(DailyPlanning dailyPlanning) {
    _dailyPlanningBox.put(dailyPlanning);
    notifyListeners();
  }

  // Mettre à jour un planning quotidien existant
  void updateDailyPlanning(DailyPlanning dailyPlanning) {
    _dailyPlanningBox.put(dailyPlanning);
    notifyListeners();
  }

  // Supprimer un planning quotidien
  void deleteDailyPlanning(int id) {
    _dailyPlanningBox.remove(id);
    notifyListeners();
  }

  // Récupérer un planning quotidien par son ID
  DailyPlanning? getDailyPlanningById(int id) {
    return _dailyPlanningBox.get(id);
  }

  // Récupérer les plannings quotidiens pour un mois spécifique
  List<DailyPlanning> getDailyPlanningsForMonth(int month, int year) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(
            _dateTimeToTimestamp(startDate), _dateTimeToTimestamp(endDate)))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé et une période spécifique
  List<DailyPlanning> getDailyPlanningsForEmployeeAndPeriod(
      int staffId, DateTime startDate, DateTime endDate) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.dayDate.between(
                _dateTimeToTimestamp(startDate), _dateTimeToTimestamp(endDate)))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé et un mois spécifique
  List<DailyPlanning> getDailyPlanningsForEmployeeAndMonth(
      int staffId, int month, int year) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.dayDate.between(
                _dateTimeToTimestamp(startDate), _dateTimeToTimestamp(endDate)))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un jour spécifique
  List<DailyPlanning> getDailyPlanningsForDay(DateTime day) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.equals(_dateTimeToTimestamp(day)))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé et un jour spécifique
  List<DailyPlanning> getDailyPlanningsForEmployeeAndDay(
      int staffId, DateTime day) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.dayDate.equals(_dateTimeToTimestamp(day)))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un type d'activité spécifique
  List<DailyPlanning> getDailyPlanningsForActivityType(int activityType) {
    return _dailyPlanningBox
        .query(DailyPlanning_.activityType.equals(activityType))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé et un type d'activité spécifique
  List<DailyPlanning> getDailyPlanningsForEmployeeAndActivityType(
      int staffId, int activityType) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.activityType.equals(activityType))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un statut spécifique
  List<DailyPlanning> getDailyPlanningsForStatus(int status) {
    return _dailyPlanningBox
        .query(DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé et un statut spécifique
  List<DailyPlanning> getDailyPlanningsForEmployeeAndStatus(
      int staffId, int status) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour une période et un type d'activité spécifiques
  List<DailyPlanning> getDailyPlanningsForPeriodAndActivityType(
      DateTime startDate, DateTime endDate, int activityType) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.activityType.equals(activityType))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour une période et un statut spécifiques
  List<DailyPlanning> getDailyPlanningsForPeriodAndStatus(
      DateTime startDate, DateTime endDate, int status) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un mois et un type d'activité spécifiques
  List<DailyPlanning> getDailyPlanningsForMonthAndActivityType(
      int month, int year, int activityType) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.activityType.equals(activityType))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un mois et un statut spécifiques
  List<DailyPlanning> getDailyPlanningsForMonthAndStatus(
      int month, int year, int status) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé, une période et un type d'activité spécifiques
  List<DailyPlanning> getDailyPlanningsForEmployeePeriodAndActivityType(
      int staffId, DateTime startDate, DateTime endDate, int activityType) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.activityType.equals(activityType))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un employé, une période et un statut spécifiques
  List<DailyPlanning> getDailyPlanningsForEmployeePeriodAndStatus(
      int staffId, DateTime startDate, DateTime endDate, int status) {
    return _dailyPlanningBox
        .query(DailyPlanning_.staff.equals(staffId) &
            DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un mois, un type d'activité et un statut spécifiques
  List<DailyPlanning> getDailyPlanningsForMonthActivityTypeAndStatus(
      int month, int year, int activityType, int status) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.between(_dateTimeToTimestamp(startDate),
                _dateTimeToTimestamp(endDate)) &
            DailyPlanning_.activityType.equals(activityType) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un jour et un type d'activité spécifiques
  List<DailyPlanning> getDailyPlanningsForDayAndActivityType(
      DateTime day, int activityType) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.equals(_dateTimeToTimestamp(day)) &
            DailyPlanning_.activityType.equals(activityType))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un jour et un statut spécifiques
  List<DailyPlanning> getDailyPlanningsForDayAndStatus(
      DateTime day, int status) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.equals(_dateTimeToTimestamp(day)) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Récupérer les plannings quotidiens pour un jour, un type d'activité et un statut spécifiques
  List<DailyPlanning> getDailyPlanningsForDayActivityTypeAndStatus(
      DateTime day, int activityType, int status) {
    return _dailyPlanningBox
        .query(DailyPlanning_.dayDate.equals(_dateTimeToTimestamp(day)) &
            DailyPlanning_.activityType.equals(activityType) &
            DailyPlanning_.status.equals(status))
        .build()
        .find();
  }

  // Générer un rapport pour un employé et une période spécifiques
  Map<String, dynamic> generateReportForEmployeeAndPeriod(
      int staffId, DateTime startDate, DateTime endDate) {
    final plannings =
        getDailyPlanningsForEmployeeAndPeriod(staffId, startDate, endDate);
    final staff = _staffBox.get(staffId);
    final report = <String, dynamic>{
      'staff': staff?.fullName,
      'period':
          '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
      'totalPlannings': plannings.length,
      'activityTypes': <String, int>{},
      'statuses': <String, int>{},
    };
    for (final planning in plannings) {
      final activityType =
          ActivityType.values[planning.activityType].toString();
      final status = ActivityStatus.values[planning.status].toString();
      report['activityTypes'][activityType] =
          (report['activityTypes'][activityType] ?? 0) + 1;
      report['statuses'][status] = (report['statuses'][status] ?? 0) + 1;
    }
    return report;
  }

  // Générer un rapport pour une période spécifique
  Map<String, dynamic> generateReportForPeriod(
      DateTime startDate, DateTime endDate) {
    final plannings = getDailyPlanningsForPeriod(startDate, endDate);
    final report = <String, dynamic>{
      'period':
          '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
      'totalPlannings': plannings.length,
      'activityTypes': <String, int>{},
      'statuses': <String, int>{},
    };
    for (final planning in plannings) {
      final activityType =
          ActivityType.values[planning.activityType].toString();
      final status = ActivityStatus.values[planning.status].toString();
      report['activityTypes'][activityType] =
          (report['activityTypes'][activityType] ?? 0) + 1;
      report['statuses'][status] = (report['statuses'][status] ?? 0) + 1;
    }
    return report;
  }

  // Générer un rapport pour un mois spécifique
  Map<String, dynamic> generateReportForMonth(int month, int year) {
    final plannings = getDailyPlanningsForMonth(month, year);
    final report = <String, dynamic>{
      'month': month,
      'year': year,
      'totalPlannings': plannings.length,
      'activityTypes': <String, int>{},
      'statuses': <String, int>{},
    };
    for (final planning in plannings) {
      final activityType =
          ActivityType.values[planning.activityType].toString();
      final status = ActivityStatus.values[planning.status].toString();
      report['activityTypes'][activityType] =
          (report['activityTypes'][activityType] ?? 0) + 1;
      report['statuses'][status] = (report['statuses'][status] ?? 0) + 1;
    }
    return report;
  }

  // Générer des statistiques pour un employé et une période spécifiques
  Map<String, dynamic> generateStatisticsForEmployeeAndPeriod(
      int staffId, DateTime startDate, DateTime endDate) {
    final plannings =
        getDailyPlanningsForEmployeeAndPeriod(staffId, startDate, endDate);
    final staff = _staffBox.get(staffId);
    final statistics = <String, dynamic>{
      'staff': staff?.fullName,
      'period':
          '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
      'totalPlannings': plannings.length,
      'activityTypes': <String, int>{},
      'statuses': <String, int>{},
      'workDays': 0,
      'restDays': 0,
      'guardDays': 0,
      'leaveDays': 0,
    };
    for (final planning in plannings) {
      final activityType = ActivityType.values[planning.activityType];
      final status = ActivityStatus.values[planning.status].toString();
      statistics['activityTypes'][activityType.toString()] =
          (statistics['activityTypes'][activityType.toString()] ?? 0) + 1;
      statistics['statuses'][status] =
          (statistics['statuses'][status] ?? 0) + 1;
      switch (activityType) {
        case ActivityType.normal:
          statistics['workDays'] = statistics['workDays'] + 1;
          break;
        case ActivityType.guard:
          statistics['guardDays'] = statistics['guardDays'] + 1;
          break;
        case ActivityType.rest:
        case ActivityType.recovery:
          statistics['restDays'] = statistics['restDays'] + 1;
          break;
        case ActivityType.leave:
        case ActivityType.sickLeave:
          statistics['leaveDays'] = statistics['leaveDays'] + 1;
          break;
        default:
          break;
      }
    }
    return statistics;
  }

  // Générer des statistiques pour une période spécifique
  Map<String, dynamic> generateStatisticsForPeriod(
      DateTime startDate, DateTime endDate) {
    final plannings = getDailyPlanningsForPeriod(startDate, endDate);
    final statistics = <String, dynamic>{
      'period':
          '${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}',
      'totalPlannings': plannings.length,
      'activityTypes': <String, int>{},
      'statuses': <String, int>{},
      'workDays': 0,
      'restDays': 0,
      'guardDays': 0,
      'leaveDays': 0,
    };
    for (final planning in plannings) {
      final activityType = ActivityType.values[planning.activityType];
      final status = ActivityStatus.values[planning.status].toString();
      statistics['activityTypes'][activityType.toString()] =
          (statistics['activityTypes'][activityType.toString()] ?? 0) + 1;
      statistics['statuses'][status] =
          (statistics['statuses'][status] ?? 0) + 1;
      switch (activityType) {
        case ActivityType.normal:
          statistics['workDays'] = statistics['workDays'] + 1;
          break;
        case ActivityType.guard:
          statistics['guardDays'] = statistics['guardDays'] + 1;
          break;
        case ActivityType.rest:
        case ActivityType.recovery:
          statistics['restDays'] = statistics['restDays'] + 1;
          break;
        case ActivityType.leave:
        case ActivityType.sickLeave:
          statistics['leaveDays'] = statistics['leaveDays'] + 1;
          break;
        default:
          break;
      }
    }
    return statistics;
  }

  // Générer des statistiques pour un mois spécifique
  Map<String, dynamic> generateStatisticsForMonth(int month, int year) {
    final plannings = getDailyPlanningsForMonth(month, year);
    final statistics = <String, dynamic>{
      'month': month,
      'year': year,
      'totalPlannings': plannings.length,
      'activityTypes': <String, int>{},
      'statuses': <String, int>{},
      'workDays': 0,
      'restDays': 0,
      'guardDays': 0,
      'leaveDays': 0,
    };
    for (final planning in plannings) {
      final activityType = ActivityType.values[planning.activityType];
      final status = ActivityStatus.values[planning.status].toString();
      statistics['activityTypes'][activityType.toString()] =
          (statistics['activityTypes'][activityType.toString()] ?? 0) + 1;
      statistics['statuses'][status] =
          (statistics['statuses'][status] ?? 0) + 1;
      switch (activityType) {
        case ActivityType.normal:
          statistics['workDays'] = statistics['workDays'] + 1;
          break;
        case ActivityType.guard:
          statistics['guardDays'] = statistics['guardDays'] + 1;
          break;
        case ActivityType.rest:
        case ActivityType.recovery:
          statistics['restDays'] = statistics['restDays'] + 1;
          break;
        case ActivityType.leave:
        case ActivityType.sickLeave:
          statistics['leaveDays'] = statistics['leaveDays'] + 1;
          break;
        default:
          break;
      }
    }
    return statistics;
  }
}
