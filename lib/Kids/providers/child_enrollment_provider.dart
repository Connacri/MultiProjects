import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/child_model_complete.dart';
import '../models/enrollment_model_complete.dart';
import '../models/session_schedule_model.dart';
import '../services/hybrid_cloud_service.dart';
import '../services/image_storage_service.dart';

class ChildEnrollmentProvider extends ChangeNotifier {
  final HybridCloudService _cloudService = HybridCloudService();
  final ImageStorageService _imageService = ImageStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChildModel> _children = [];
  List<EnrollmentModel> _enrollments = [];
  List<SessionSchedule> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<ChildModel> get children => _children;

  List<EnrollmentModel> get enrollments => _enrollments;

  List<SessionSchedule> get schedules => _schedules;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> loadChildren(String parentId) async {
    try {
      _setLoading(true);
      _clearError();

      final snapshot = await _firestore
          .collection('children')
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      _children =
          snapshot.docs.map((doc) => ChildModel.fromFirestore(doc)).toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des enfants: $e');
      _setLoading(false);
    }
  }

  Future<bool> addChild({
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required ChildGender gender,
    File? photo,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      String? photoUrl;
      if (photo != null) {
        photoUrl = await _imageService.uploadUserProfileImage(
          imageFile: photo,
          userId: '$parentId-${DateTime.now().millisecondsSinceEpoch}',
          isProfileImage: true,
        );
      }

      final docRef = _firestore.collection('children').doc();
      final child = ChildModel(
        id: docRef.id,
        parentId: parentId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: photoUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo ?? MedicalInfo(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(child.toFirestore());
      _children.add(child);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de l\'enfant: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateChild({
    required String childId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    ChildGender? gender,
    File? newPhoto,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final index = _children.indexWhere((c) => c.id == childId);
      if (index == -1) {
        throw Exception('Enfant non trouvé');
      }

      String? photoUrl = _children[index].photoUrl;
      if (newPhoto != null) {
        photoUrl = await _imageService.uploadUserProfileImage(
          imageFile: newPhoto,
          userId: childId,
          isProfileImage: true,
        );
      }

      final updatedChild = _children[index].copyWith(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrl: photoUrl,
        schoolGrade: schoolGrade,
        medicalInfo: medicalInfo,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('children')
          .doc(childId)
          .update(updatedChild.toFirestore());

      _children[index] = updatedChild;

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteChild(String childId) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore.collection('children').doc(childId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _children.removeWhere((c) => c.id == childId);
      _enrollments.removeWhere((e) => e.childId == childId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> enrollChild({
    required String courseId,
    required String childId,
    required String parentId,
    double? totalAmount,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final docRef = _firestore.collection('enrollments').doc();
      final enrollment = EnrollmentModel(
        id: docRef.id,
        courseId: courseId,
        childId: childId,
        parentId: parentId,
        status: EnrollmentStatus.pending,
        enrolledAt: DateTime.now(),
        paymentStatus: PaymentStatus.pending,
        totalAmount: totalAmount,
        paidAmount: 0,
      );

      await docRef.set(enrollment.toFirestore());
      _enrollments.add(enrollment);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'inscription: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadEnrollments(String parentId) async {
    try {
      _setLoading(true);
      _clearError();

      final snapshot = await _firestore
          .collection('enrollments')
          .where('parentId', isEqualTo: parentId)
          .get();

      _enrollments = snapshot.docs
          .map((doc) => EnrollmentModel.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des inscriptions: $e');
      _setLoading(false);
    }
  }

  Future<bool> approveEnrollment(String enrollmentId, String approverId) async {
    try {
      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index == -1) return false;

      final updatedEnrollment = _enrollments[index].copyWith(
        status: EnrollmentStatus.approved,
        approvedAt: DateTime.now(),
        approvedBy: approverId,
      );

      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .update(updatedEnrollment.toFirestore());

      _enrollments[index] = updatedEnrollment;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'approbation: $e');
      return false;
    }
  }

  Future<bool> rejectEnrollment(String enrollmentId, String reason) async {
    try {
      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index == -1) return false;

      final updatedEnrollment = _enrollments[index].copyWith(
        status: EnrollmentStatus.rejected,
        rejectionReason: reason,
      );

      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .update(updatedEnrollment.toFirestore());

      _enrollments[index] = updatedEnrollment;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors du rejet: $e');
      return false;
    }
  }

  Future<bool> recordAttendance({
    required String enrollmentId,
    required DateTime date,
    required bool isPresent,
    String? notes,
  }) async {
    try {
      final index = _enrollments.indexWhere((e) => e.id == enrollmentId);
      if (index == -1) return false;

      final attendance = AttendanceRecord(
        date: date,
        isPresent: isPresent,
        notes: notes,
      );

      final updatedHistory = List<AttendanceRecord>.from(
        _enrollments[index].attendanceHistory,
      )..add(attendance);

      final updatedEnrollment = _enrollments[index].copyWith(
        attendanceHistory: updatedHistory,
      );

      await _firestore
          .collection('enrollments')
          .doc(enrollmentId)
          .update(updatedEnrollment.toFirestore());

      _enrollments[index] = updatedEnrollment;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'enregistrement de présence: $e');
      return false;
    }
  }

  Future<void> loadSchedules(String courseId) async {
    try {
      _setLoading(true);
      _clearError();

      final snapshot = await _firestore
          .collection('schedules')
          .where('courseId', isEqualTo: courseId)
          .where('isCancelled', isEqualTo: false)
          .get();

      _schedules = snapshot.docs
          .map((doc) => SessionSchedule.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des horaires: $e');
      _setLoading(false);
    }
  }

  Future<void> loadAllSchedulesForParent(String parentId) async {
    try {
      _setLoading(true);
      _clearError();

      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: EnrollmentStatus.approved.name)
          .get();

      final courseIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toSet()
          .toList();

      if (courseIds.isEmpty) {
        _schedules = [];
        _setLoading(false);
        return;
      }

      final schedulesSnapshot = await _firestore
          .collection('schedules')
          .where('courseId', whereIn: courseIds)
          .where('isCancelled', isEqualTo: false)
          .get();

      _schedules = schedulesSnapshot.docs
          .map((doc) => SessionSchedule.fromFirestore(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors du chargement des horaires: $e');
      _setLoading(false);
    }
  }

  List<SessionSchedule> getSchedulesForDate(DateTime date) {
    return _schedules
        .where((schedule) =>
            schedule.isScheduledFor(date) && !schedule.isCancelled)
        .toList();
  }

  List<SessionSchedule> getWeekSchedules(DateTime startOfWeek) {
    final weekSchedules = <SessionSchedule>[];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      weekSchedules.addAll(getSchedulesForDate(date));
    }
    return weekSchedules;
  }

  Map<DateTime, List<SessionSchedule>> groupSchedulesByDate(
    DateTime startDate,
    DateTime endDate,
  ) {
    final grouped = <DateTime, List<SessionSchedule>>{};
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
      grouped[dateKey] = getSchedulesForDate(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return grouped;
  }

  List<EnrollmentModel> getChildEnrollments(String childId) {
    return _enrollments.where((e) => e.childId == childId).toList();
  }

  List<EnrollmentModel> getApprovedEnrollments(String childId) {
    return _enrollments
        .where((e) =>
            e.childId == childId && e.status == EnrollmentStatus.approved)
        .toList();
  }

  int getTotalEnrollmentsCount() {
    return _enrollments.length;
  }

  int getApprovedEnrollmentsCount() {
    return _enrollments
        .where((e) => e.status == EnrollmentStatus.approved)
        .length;
  }

  int getPendingEnrollmentsCount() {
    return _enrollments
        .where((e) => e.status == EnrollmentStatus.pending)
        .length;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearData() {
    _children.clear();
    _enrollments.clear();
    _schedules.clear();
    notifyListeners();
  }
}
