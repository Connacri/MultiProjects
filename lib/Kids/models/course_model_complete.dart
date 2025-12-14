import 'package:cloud_firestore/cloud_firestore.dart';

enum CourseCategory {
  mathematics,
  sciences,
  languages,
  arts,
  sports,
  technology,
  music,
  other;

  String get displayName {
    switch (this) {
      case CourseCategory.mathematics:
        return 'Mathématiques';
      case CourseCategory.sciences:
        return 'Sciences';
      case CourseCategory.languages:
        return 'Langues';
      case CourseCategory.arts:
        return 'Arts';
      case CourseCategory.sports:
        return 'Sports';
      case CourseCategory.technology:
        return 'Technologie';
      case CourseCategory.music:
        return 'Musique';
      case CourseCategory.other:
        return 'Autre';
    }
  }
}

enum CourseSeason {
  spring,
  summer,
  fall,
  winter,
  yearRound;

  String get displayName {
    switch (this) {
      case CourseSeason.spring:
        return 'Printemps';
      case CourseSeason.summer:
        return 'Été';
      case CourseSeason.fall:
        return 'Automne';
      case CourseSeason.winter:
        return 'Hiver';
      case CourseSeason.yearRound:
        return 'Toute l\'année';
    }
  }
}

class CourseLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  CourseLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  factory CourseLocation.fromMap(Map<String, dynamic> map) {
    return CourseLocation(
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
}

/// Modèle d'image de cours adapté pour Supabase
class CourseImage {
  final String id;
  final String? supabaseUrl;
  final String localPath;
  final bool isSynced;
  final DateTime uploadedAt;

  CourseImage({
    required this.id,
    this.supabaseUrl,
    required this.localPath,
    required this.isSynced,
    required this.uploadedAt,
  });

  /// Désérialisation depuis Supabase (JSONB)
  factory CourseImage.fromMap(Map<String, dynamic> map) {
    return CourseImage(
      id: map['id'] ?? '',
      supabaseUrl: map['supabaseUrl'] ?? map['supabase_url'],
      localPath: map['localPath'] ?? map['local_path'] ?? '',
      isSynced: map['isSynced'] ?? map['is_synced'] ?? false,
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'].toString())
          : (map['uploaded_at'] != null
              ? DateTime.parse(map['uploaded_at'].toString())
              : DateTime.now()),
    );
  }

  /// Sérialisation pour Supabase (JSONB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supabase_url': supabaseUrl,
      'local_path': localPath,
      'is_synced': isSynced,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  /// CopyWith pour créer une copie modifiée
  CourseImage copyWith({
    String? id,
    String? supabaseUrl,
    String? localPath,
    bool? isSynced,
    DateTime? uploadedAt,
  }) {
    return CourseImage(
      id: id ?? this.id,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      localPath: localPath ?? this.localPath,
      isSynced: isSynced ?? this.isSynced,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  String toString() {
    return 'CourseImage(id: $id, supabaseUrl: $supabaseUrl, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CourseImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final CourseCategory category;
  final double? price;

  // ✅ REMOVED: Currency n'existe plus
  final CourseSeason season;
  final DateTime seasonStartDate;
  final DateTime seasonEndDate;
  final CourseLocation location;
  final List<CourseImage> images;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int maxStudents;
  final int currentStudents;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    // ✅ REMOVED: Pas de currency
    required this.season,
    required this.seasonStartDate,
    required this.seasonEndDate,
    required this.location,
    required this.images,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.maxStudents = 30,
    this.currentStudents = 0,
    this.tags = const [],
    this.metadata,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: CourseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => CourseCategory.other,
      ),
      price: data['price']?.toDouble(),
      // ✅ REMOVED: Pas de currency
      season: CourseSeason.values.firstWhere(
        (e) => e.name == data['season'],
        orElse: () => CourseSeason.yearRound,
      ),
      seasonStartDate: (data['seasonStartDate'] as Timestamp).toDate(),
      seasonEndDate: (data['seasonEndDate'] as Timestamp).toDate(),
      location: CourseLocation.fromMap(data['location'] ?? {}),
      images: (data['images'] as List<dynamic>?)
              ?.map((img) => CourseImage.fromMap(img))
              .toList() ??
          [],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      maxStudents: data['maxStudents'] ?? 30,
      currentStudents: data['currentStudents'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'price': price,
      // ✅ REMOVED: Pas de currency
      'season': season.name,
      'seasonStartDate': Timestamp.fromDate(seasonStartDate),
      'seasonEndDate': Timestamp.fromDate(seasonEndDate),
      'location': location.toMap(),
      'images': images.map((img) => img.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'tags': tags,
      'metadata': metadata,
    };
  }

  factory CourseModel.fromSupabase(Map<String, dynamic> data) {
    return CourseModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: CourseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => CourseCategory.other,
      ),
      price: data['price']?.toDouble(),
      // ✅ REMOVED: Pas de currency
      season: CourseSeason.values.firstWhere(
        (e) => e.name == data['season'],
        orElse: () => CourseSeason.yearRound,
      ),
      seasonStartDate: DateTime.parse(data['season_start_date']),
      seasonEndDate: DateTime.parse(data['season_end_date']),
      location: CourseLocation.fromMap(data['location'] ?? {}),
      images: (data['images'] as List<dynamic>?)
              ?.map((img) => CourseImage.fromMap(img))
              .toList() ??
          [],
      createdBy: data['created_by'] ?? '',
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      isActive: data['is_active'] ?? true,
      maxStudents: data['max_students'] ?? 30,
      currentStudents: data['current_students'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'price': price,
      // ✅ REMOVED: Pas de currency
      'season': season.name,
      'season_start_date': seasonStartDate.toIso8601String(),
      'season_end_date': seasonEndDate.toIso8601String(),
      'location': location.toMap(),
      'images': images.map((img) => img.toMap()).toList(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'tags': tags,
      'metadata': metadata,
    };
  }

  bool isAvailableNow() {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(seasonStartDate) &&
        now.isBefore(seasonEndDate) &&
        currentStudents < maxStudents;
  }

  bool hasAvailableSpots() {
    return currentStudents < maxStudents;
  }

  int get availableSpots => maxStudents - currentStudents;

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    CourseCategory? category,
    double? price,
    // ✅ REMOVED: Pas de currency
    CourseSeason? season,
    DateTime? seasonStartDate,
    DateTime? seasonEndDate,
    CourseLocation? location,
    List<CourseImage>? images,
    String? createdBy,
    String? createdByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? maxStudents,
    int? currentStudents,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      // ✅ REMOVED: Pas de currency
      season: season ?? this.season,
      seasonStartDate: seasonStartDate ?? this.seasonStartDate,
      seasonEndDate: seasonEndDate ?? this.seasonEndDate,
      location: location ?? this.location,
      images: images ?? this.images,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      maxStudents: maxStudents ?? this.maxStudents,
      currentStudents: currentStudents ?? this.currentStudents,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}
