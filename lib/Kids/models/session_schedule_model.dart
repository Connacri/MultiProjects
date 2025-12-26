import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour représenter une session de cours planifiée
/// Utilisé pour la timeline hebdomadaire dans le ParentDashboard
class SessionSchedule {
  final String id;
  final String courseId;
  final String enrollmentId;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCancelled;
  final String? cancellationReason;
  final int currentEnrollment;
  final int maxCapacity;
  final String? location;
  final Map<String, dynamic>? metadata;

  SessionSchedule({
    required this.id,
    required this.courseId,
    required this.enrollmentId,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.startDate,
    required this.endDate,
    this.isCancelled = false,
    this.cancellationReason,
    required this.currentEnrollment,
    required this.maxCapacity,
    this.location,
    this.metadata,
  });

  /// Vérifie si la session est planifiée pour une date donnée
  bool isScheduledFor(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    // Vérifier si la date est dans la plage
    if (normalizedDate.isBefore(normalizedStart) ||
        normalizedDate.isAfter(normalizedEnd)) {
      return false;
    }

    // Vérifier si c'est le bon jour de la semaine
    return date.weekday == dayOfWeek.index + 1;
  }

  /// Désérialisation depuis Supabase
  factory SessionSchedule.fromSupabase(Map<String, dynamic> data) {
    return SessionSchedule(
      id: data['id'] ?? '',
      courseId: data['course_id'] ?? '',
      enrollmentId: data['enrollment_id'] ?? '',
      dayOfWeek: DayOfWeek.values[data['day_of_week'] ?? 0],
      timeSlot: TimeSlot.fromMap(data['time_slot'] ?? {}),
      startDate: DateTime.parse(data['start_date']),
      endDate: DateTime.parse(data['end_date']),
      isCancelled: data['is_cancelled'] ?? false,
      cancellationReason: data['cancellation_reason'],
      currentEnrollment: data['current_enrollment'] ?? 0,
      maxCapacity: data['max_capacity'] ?? 30,
      location: data['location'],
      metadata: data['metadata'],
    );
  }

  /// Sérialisation vers Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'course_id': courseId,
      'enrollment_id': enrollmentId,
      'day_of_week': dayOfWeek.index,
      'time_slot': timeSlot.toMap(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_cancelled': isCancelled,
      'cancellation_reason': cancellationReason,
      'current_enrollment': currentEnrollment,
      'max_capacity': maxCapacity,
      'location': location,
      'metadata': metadata,
    };
  }

  /// Désérialisation depuis Firestore
  factory SessionSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionSchedule(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      enrollmentId: data['enrollmentId'] ?? '',
      dayOfWeek: DayOfWeek.values[data['dayOfWeek'] ?? 0],
      timeSlot: TimeSlot.fromMap(data['timeSlot'] ?? {}),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isCancelled: data['isCancelled'] ?? false,
      cancellationReason: data['cancellationReason'],
      currentEnrollment: data['currentEnrollment'] ?? 0,
      maxCapacity: data['maxCapacity'] ?? 30,
      location: data['location'],
      metadata: data['metadata'],
    );
  }

  /// Sérialisation vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'enrollmentId': enrollmentId,
      'dayOfWeek': dayOfWeek.index,
      'timeSlot': timeSlot.toMap(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isCancelled': isCancelled,
      'cancellationReason': cancellationReason,
      'currentEnrollment': currentEnrollment,
      'maxCapacity': maxCapacity,
      'location': location,
      'metadata': metadata,
    };
  }

  SessionSchedule copyWith({
    String? id,
    String? courseId,
    String? enrollmentId,
    DayOfWeek? dayOfWeek,
    TimeSlot? timeSlot,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCancelled,
    String? cancellationReason,
    int? currentEnrollment,
    int? maxCapacity,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return SessionSchedule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCancelled: isCancelled ?? this.isCancelled,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Énumération des jours de la semaine
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Lundi';
      case DayOfWeek.tuesday:
        return 'Mardi';
      case DayOfWeek.wednesday:
        return 'Mercredi';
      case DayOfWeek.thursday:
        return 'Jeudi';
      case DayOfWeek.friday:
        return 'Vendredi';
      case DayOfWeek.saturday:
        return 'Samedi';
      case DayOfWeek.sunday:
        return 'Dimanche';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Lun';
      case DayOfWeek.tuesday:
        return 'Mar';
      case DayOfWeek.wednesday:
        return 'Mer';
      case DayOfWeek.thursday:
        return 'Jeu';
      case DayOfWeek.friday:
        return 'Ven';
      case DayOfWeek.saturday:
        return 'Sam';
      case DayOfWeek.sunday:
        return 'Dim';
    }
  }

  /// Crée un DayOfWeek depuis un DateTime
  static DayOfWeek fromDateTime(DateTime date) {
    // DateTime.weekday renvoie 1-7 (lundi-dimanche)
    return DayOfWeek.values[date.weekday - 1];
  }
}

/// Modèle pour représenter un créneau horaire

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  String get displayTime {
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool overlaps(TimeSlot other) {
    return startTime.isBefore(other.endTime) &&
        endTime.isAfter(other.startTime);
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.parse(map['startTime']),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : DateTime.parse(map['endTime']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
  }
}
