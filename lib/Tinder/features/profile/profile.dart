// features/discovery/domain/entities/profile.dart
class Profile {
  final String id;
  final String fullName;
  final int age;
  final String? bio;
  final List<String> photos;
  final String city;
  final double distanceKm;

  Profile({
    required this.id,
    required this.fullName,
    required this.age,
    this.bio,
    required this.photos,
    required this.city,
    required this.distanceKm,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    final photos = List<String>.from(map['photos'] ?? []);
    return Profile(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      age: DateTime.now().year - DateTime.parse(map['date_of_birth']).year,
      bio: map['bio'],
      photos: photos,
      city: map['city'] ?? '',
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }
}
