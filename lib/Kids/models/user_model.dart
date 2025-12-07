import 'package:cloud_firestore/cloud_firestore.dart'
    show Timestamp, DocumentSnapshot;

class AppLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  AppLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  bool get hasLocation => latitude != 0.0 && longitude != 0.0;

  factory AppLocation.fromMap(Map<String, dynamic> map) {
    return AppLocation(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      city: map['city'],
      country: map['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  AppLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
  }) {
    return AppLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}

enum UserRole {
  parent,
  school,
  coach,
  autres;

  String toJson() => name;

  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere(
      (role) => role.name == json,
      orElse: () => UserRole.parent,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.school:
        return 'School';
      case UserRole.coach:
        return 'Coach';
      case UserRole.autres:
        return 'Autres';
    }
  }
}

class UserProfileImages {
  final String? profileImageFirebase;
  final String? profileImageSupabase;
  final String? coverImageFirebase;
  final String? coverImageSupabase;
  final DateTime? lastUpdated;

  UserProfileImages({
    this.profileImageFirebase,
    this.profileImageSupabase,
    this.coverImageFirebase,
    this.coverImageSupabase,
    this.lastUpdated,
  });

  factory UserProfileImages.fromMap(Map<String, dynamic> map) {
    return UserProfileImages(
      profileImageFirebase: map['profileImageFirebase'],
      profileImageSupabase: map['profileImageSupabase'],
      coverImageFirebase: map['coverImageFirebase'],
      coverImageSupabase: map['coverImageSupabase'],
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] is Timestamp
              ? (map['lastUpdated'] as Timestamp).toDate()
              : DateTime.parse(map['lastUpdated']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileImageFirebase': profileImageFirebase,
      'profileImageSupabase': profileImageSupabase,
      'coverImageFirebase': coverImageFirebase,
      'coverImageSupabase': coverImageSupabase,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  String? get profileImage => profileImageFirebase ?? profileImageSupabase;

  String? get coverImage => coverImageFirebase ?? coverImageSupabase;

  UserProfileImages copyWith({
    String? profileImageFirebase,
    String? profileImageSupabase,
    String? coverImageFirebase,
    String? coverImageSupabase,
    DateTime? lastUpdated,
  }) {
    return UserProfileImages(
      profileImageFirebase: profileImageFirebase ?? this.profileImageFirebase,
      profileImageSupabase: profileImageSupabase ?? this.profileImageSupabase,
      coverImageFirebase: coverImageFirebase ?? this.coverImageFirebase,
      coverImageSupabase: coverImageSupabase ?? this.coverImageSupabase,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final DateTime? deactivatedAt;
  final DateTime? scheduledDeletionDate;
  final UserProfileImages profileImages;
  final AppLocation? location;
  final String? bio;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.deactivatedAt,
    this.scheduledDeletionDate,
    UserProfileImages? profileImages,
    this.location,
    this.bio,
    this.phoneNumber,
    this.metadata,
  }) : profileImages = profileImages ?? UserProfileImages();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromJson(data['role'] ?? 'parent'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      deactivatedAt: data['deactivatedAt'] != null
          ? (data['deactivatedAt'] as Timestamp).toDate()
          : null,
      scheduledDeletionDate: data['scheduledDeletionDate'] != null
          ? (data['scheduledDeletionDate'] as Timestamp).toDate()
          : null,
      profileImages: data['profileImages'] != null
          ? UserProfileImages.fromMap(data['profileImages'])
          : UserProfileImages(),
      location: data['location'] != null
          ? AppLocation.fromMap(data['location'])
          : null,
      bio: data['bio'],
      phoneNumber: data['phoneNumber'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'deactivatedAt':
          deactivatedAt != null ? Timestamp.fromDate(deactivatedAt!) : null,
      'scheduledDeletionDate': scheduledDeletionDate != null
          ? Timestamp.fromDate(scheduledDeletionDate!)
          : null,
      'profileImages': profileImages.toMap(),
      'location': location?.toMap(),
      'bio': bio,
      'phoneNumber': phoneNumber,
      'metadata': metadata,
    };
  }

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromJson(data['role'] ?? 'parent'),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      isActive: data['is_active'] ?? true,
      deactivatedAt: data['deactivated_at'] != null
          ? DateTime.parse(data['deactivated_at'])
          : null,
      scheduledDeletionDate: data['scheduled_deletion_date'] != null
          ? DateTime.parse(data['scheduled_deletion_date'])
          : null,
      profileImages: data['profile_images'] != null
          ? UserProfileImages.fromMap(data['profile_images'])
          : UserProfileImages(),
      location: data['location'] != null
          ? AppLocation.fromMap(data['location'])
          : null,
      bio: data['bio'],
      phoneNumber: data['phone_number'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'email': email,
      'name': name,
      'role': role.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'deactivated_at': deactivatedAt?.toIso8601String(),
      'scheduled_deletion_date': scheduledDeletionDate?.toIso8601String(),
      'profile_images': profileImages.toMap(),
      'location': location?.toMap(),
      'bio': bio,
      'phone_number': phoneNumber,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DateTime? deactivatedAt,
    DateTime? scheduledDeletionDate,
    UserProfileImages? profileImages,
    AppLocation? location,
    String? bio,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      scheduledDeletionDate:
          scheduledDeletionDate ?? this.scheduledDeletionDate,
      profileImages: profileImages ?? this.profileImages,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      metadata: metadata ?? this.metadata,
    );
  }

  int? getDaysUntilDeletion() {
    if (scheduledDeletionDate == null) return null;
    final now = DateTime.now();
    final difference = scheduledDeletionDate!.difference(now);
    return difference.inDays;
  }

  bool canReactivate() {
    if (!isActive && scheduledDeletionDate != null) {
      return DateTime.now().isBefore(scheduledDeletionDate!);
    }
    return false;
  }
}

class LocationSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  LocationSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['lon']),
      city: json['address']?['city'] ??
          json['address']?['town'] ??
          json['address']?['village'],
      country: json['address']?['country'],
    );
  }
}
