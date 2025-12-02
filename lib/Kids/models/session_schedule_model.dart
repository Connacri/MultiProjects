import 'package:cloud_firestore/cloud_firestore.dart';

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
    return displayName.substring(0, 3);
  }

  static DayOfWeek fromDateTime(DateTime date) {
    return DayOfWeek.values[date.weekday - 1];
  }
}

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
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
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

class SessionSchedule {
  final String id;
  final String courseId;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final String? location;
  final String? instructorId;
  final int maxCapacity;
  final int currentEnrollment;
  final bool isRecurring;
  final DateTime? specificDate;
  final bool isCancelled;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionSchedule({
    required this.id,
    required this.courseId,
    required this.dayOfWeek,
    required this.timeSlot,
    this.location,
    this.instructorId,
    required this.maxCapacity,
    this.currentEnrollment = 0,
    this.isRecurring = true,
    this.specificDate,
    this.isCancelled = false,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAvailableSpots => currentEnrollment < maxCapacity;
  int get availableSpots => maxCapacity - currentEnrollment;

  bool isScheduledFor(DateTime date) {
    if (specificDate != null) {
      return date.year == specificDate!.year &&
          date.month == specificDate!.month &&
          date.day == specificDate!.day;
    }
    return DayOfWeek.fromDateTime(date) == dayOfWeek;
  }

  DateTime getNextOccurrence(DateTime from) {
    DateTime next = from;
    while (!isScheduledFor(next)) {
      next = next.add(const Duration(days: 1));
    }
    return DateTime(
      next.year,
      next.month,
      next.day,
      timeSlot.startTime.hour,
      timeSlot.startTime.minute,
    );
  }

  factory SessionSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionSchedule(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      dayOfWeek: DayOfWeek.values.firstWhere(
        (d) => d.name == data['dayOfWeek'],
        orElse: () => DayOfWeek.monday,
      ),
      timeSlot: TimeSlot.fromMap(data['timeSlot']),
      location: data['location'],
      instructorId: data['instructorId'],
      maxCapacity: data['maxCapacity'] ?? 30,
      currentEnrollment: data['currentEnrollment'] ?? 0,
      isRecurring: data['isRecurring'] ?? true,
      specificDate: data['specificDate'] != null
          ? (data['specificDate'] as Timestamp).toDate()
          : null,
      isCancelled: data['isCancelled'] ?? false,
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'dayOfWeek': dayOfWeek.name,
      'timeSlot': timeSlot.toMap(),
      'location': location,
      'instructorId': instructorId,
      'maxCapacity': maxCapacity,
      'currentEnrollment': currentEnrollment,
      'isRecurring': isRecurring,
      'specificDate':
          specificDate != null ? Timestamp.fromDate(specificDate!) : null,
      'isCancelled': isCancelled,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SessionSchedule.fromSupabase(Map<String, dynamic> data) {
    return SessionSchedule(
      id: data['id'] ?? '',
      courseId: data['course_id'] ?? '',
      dayOfWeek: DayOfWeek.values.firstWhere(
        (d) => d.name == data['day_of_week'],
        orElse: () => DayOfWeek.monday,
      ),
      timeSlot: TimeSlot.fromMap(data['time_slot']),
      location: data['location'],
      instructorId: data['instructor_id'],
      maxCapacity: data['max_capacity'] ?? 30,
      currentEnrollment: data['current_enrollment'] ?? 0,
      isRecurring: data['is_recurring'] ?? true,
      specificDate: data['specific_date'] != null
          ? DateTime.parse(data['specific_date'])
          : null,
      isCancelled: data['is_cancelled'] ?? false,
      cancellationReason: data['cancellation_reason'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'course_id': courseId,
      'day_of_week': dayOfWeek.name,
      'time_slot': timeSlot.toMap(),
      'location': location,
      'instructor_id': instructorId,
      'max_capacity': maxCapacity,
      'current_enrollment': currentEnrollment,
      'is_recurring': isRecurring,
      'specific_date': specificDate?.toIso8601String(),
      'is_cancelled': isCancelled,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SessionSchedule copyWith({
    String? id,
    String? courseId,
    DayOfWeek? dayOfWeek,
    TimeSlot? timeSlot,
    String? location,
    String? instructorId,
    int? maxCapacity,
    int? currentEnrollment,
    bool? isRecurring,
    DateTime? specificDate,
    bool? isCancelled,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionSchedule(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      location: location ?? this.location,
      instructorId: instructorId ?? this.instructorId,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      isRecurring: isRecurring ?? this.isRecurring,
      specificDate: specificDate ?? this.specificDate,
      isCancelled: isCancelled ?? this.isCancelled,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}