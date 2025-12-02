import 'package:cloud_firestore/cloud_firestore.dart';

enum EnrollmentStatus {
  pending,
  approved,
  rejected,
  cancelled,
  completed;

  String get displayName {
    switch (this) {
      case EnrollmentStatus.pending:
        return 'En attente';
      case EnrollmentStatus.approved:
        return 'Approuvée';
      case EnrollmentStatus.rejected:
        return 'Refusée';
      case EnrollmentStatus.cancelled:
        return 'Annulée';
      case EnrollmentStatus.completed:
        return 'Terminée';
    }
  }
}

enum PaymentStatus {
  pending,
  partial,
  paid,
  refunded;

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.partial:
        return 'Partiel';
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.refunded:
        return 'Remboursé';
    }
  }
}

class AttendanceRecord {
  final DateTime date;
  final bool isPresent;
  final String? notes;

  AttendanceRecord({
    required this.date,
    required this.isPresent,
    this.notes,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date']),
      isPresent: map['isPresent'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
      'notes': notes,
    };
  }
}

class EnrollmentModel {
  final String id;
  final String courseId;
  final String childId;
  final String parentId;
  final EnrollmentStatus status;
  final DateTime enrolledAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final PaymentStatus paymentStatus;
  final double? totalAmount;
  final double? paidAmount;
  final List<AttendanceRecord> attendanceHistory;
  final Map<String, dynamic>? metadata;

  EnrollmentModel({
    required this.id,
    required this.courseId,
    required this.childId,
    required this.parentId,
    required this.status,
    required this.enrolledAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    required this.paymentStatus,
    this.totalAmount,
    this.paidAmount,
    this.attendanceHistory = const [],
    this.metadata,
  });

  int get attendanceCount =>
      attendanceHistory.where((a) => a.isPresent).length;

  double get attendanceRate {
    if (attendanceHistory.isEmpty) return 0;
    return (attendanceCount / attendanceHistory.length) * 100;
  }

  double get remainingAmount {
    if (totalAmount == null) return 0;
    return totalAmount! - (paidAmount ?? 0);
  }

  bool get isFullyPaid => remainingAmount <= 0;

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnrollmentModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      childId: data['childId'] ?? '',
      parentId: data['parentId'] ?? '',
      status: EnrollmentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EnrollmentStatus.pending,
      ),
      enrolledAt: (data['enrolledAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      totalAmount: data['totalAmount']?.toDouble(),
      paidAmount: data['paidAmount']?.toDouble(),
      attendanceHistory: (data['attendanceHistory'] as List<dynamic>?)
              ?.map((a) => AttendanceRecord.fromMap(a))
              .toList() ??
          [],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'childId': childId,
      'parentId': parentId,
      'status': status.name,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'paymentStatus': paymentStatus.name,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'attendanceHistory': attendanceHistory.map((a) => a.toMap()).toList(),
      'metadata': metadata,
    };
  }

  factory EnrollmentModel.fromSupabase(Map<String, dynamic> data) {
    return EnrollmentModel(
      id: data['id'] ?? '',
      courseId: data['course_id'] ?? '',
      childId: data['child_id'] ?? '',
      parentId: data['parent_id'] ?? '',
      status: EnrollmentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => EnrollmentStatus.pending,
      ),
      enrolledAt: DateTime.parse(data['enrolled_at']),
      approvedAt: data['approved_at'] != null
          ? DateTime.parse(data['approved_at'])
          : null,
      approvedBy: data['approved_by'],
      rejectionReason: data['rejection_reason'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == data['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      totalAmount: data['total_amount']?.toDouble(),
      paidAmount: data['paid_amount']?.toDouble(),
      attendanceHistory: (data['attendance_history'] as List<dynamic>?)
              ?.map((a) => AttendanceRecord.fromMap(a))
              .toList() ??
          [],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'course_id': courseId,
      'child_id': childId,
      'parent_id': parentId,
      'status': status.name,
      'enrolled_at': enrolledAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'payment_status': paymentStatus.name,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'attendance_history': attendanceHistory.map((a) => a.toMap()).toList(),
      'metadata': metadata,
    };
  }

  EnrollmentModel copyWith({
    String? id,
    String? courseId,
    String? childId,
    String? parentId,
    EnrollmentStatus? status,
    DateTime? enrolledAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    PaymentStatus? paymentStatus,
    double? totalAmount,
    double? paidAmount,
    List<AttendanceRecord>? attendanceHistory,
    Map<String, dynamic>? metadata,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
      metadata: metadata ?? this.metadata,
    );
  }
}