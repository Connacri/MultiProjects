import 'package:cloud_firestore/cloud_firestore.dart';

enum ChildGender { male, female, other }

class MedicalInfo {
  final List<String> allergies;
  final List<String> medications;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? bloodType;
  final String? additionalNotes;

  MedicalInfo({
    this.allergies = const [],
    this.medications = const [],
    this.emergencyContact,
    this.emergencyPhone,
    this.bloodType,
    this.additionalNotes,
  });

  factory MedicalInfo.fromMap(Map<String, dynamic> map) {
    return MedicalInfo(
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      bloodType: map['bloodType'],
      additionalNotes: map['additionalNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allergies': allergies,
      'medications': medications,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'bloodType': bloodType,
      'additionalNotes': additionalNotes,
    };
  }
}

class ChildModel {
  final String id;
  final String parentId;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final ChildGender gender;
  final String? photoUrl;
  final String? schoolGrade;
  final MedicalInfo medicalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    this.schoolGrade,
    required this.medicalInfo,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName';

  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  factory ChildModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChildModel(
      id: doc.id,
      parentId: data['parentId'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      gender: ChildGender.values.firstWhere(
        (g) => g.name == data['gender'],
        orElse: () => ChildGender.other,
      ),
      photoUrl: data['photoUrl'],
      schoolGrade: data['schoolGrade'],
      medicalInfo: data['medicalInfo'] != null
          ? MedicalInfo.fromMap(data['medicalInfo'])
          : MedicalInfo(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentId': parentId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender.name,
      'photoUrl': photoUrl,
      'schoolGrade': schoolGrade,
      'medicalInfo': medicalInfo.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  factory ChildModel.fromSupabase(Map<String, dynamic> data) {
    return ChildModel(
      id: data['id'] ?? '',
      parentId: data['parent_id'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      dateOfBirth: DateTime.parse(data['date_of_birth']),
      gender: ChildGender.values.firstWhere(
        (g) => g.name == data['gender'],
        orElse: () => ChildGender.other,
      ),
      photoUrl: data['photo_url'],
      schoolGrade: data['school_grade'],
      medicalInfo: data['medical_info'] != null
          ? MedicalInfo.fromMap(data['medical_info'])
          : MedicalInfo(),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'parent_id': parentId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender.name,
      'photo_url': photoUrl,
      'school_grade': schoolGrade,
      'medical_info': medicalInfo.toMap(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  ChildModel copyWith({
    String? id,
    String? parentId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    ChildGender? gender,
    String? photoUrl,
    String? schoolGrade,
    MedicalInfo? medicalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ChildModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      schoolGrade: schoolGrade ?? this.schoolGrade,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}