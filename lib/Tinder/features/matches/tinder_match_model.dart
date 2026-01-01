// lib/Tinder/features/matches/models/tinder_match.dart

/// Modèle représentant un match dans l'app de dating
class TinderMatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime matchedAt;
  final DateTime? lastMessageAt;
  final DateTime? lastReadAt;
  final bool isActive;

  // ✅ Informations de l'autre utilisateur (calculées)
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String? lastMessagePreview;

  TinderMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchedAt,
    this.lastMessageAt,
    this.lastReadAt,
    required this.isActive,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.lastMessagePreview,
  });

  /// ✅ Factory depuis JSON Supabase
  factory TinderMatch.fromMap(Map<String, dynamic> json, String currentUserId) {
    final user1Id = json['user1_id'] as String;
    final user2Id = json['user2_id'] as String;

    // Déterminer qui est l'autre utilisateur
    final otherUserId = user1Id == currentUserId ? user2Id : user1Id;

    // Parser les profils (si joints via .select('*, profiles!user1_id(*), profiles!user2_id(*)'))
    final user1Profile = json['profiles_user1'] as Map<String, dynamic>?;
    final user2Profile = json['profiles_user2'] as Map<String, dynamic>?;

    final otherProfile = user1Id == currentUserId ? user2Profile : user1Profile;

    return TinderMatch(
      id: json['id'] as String,
      user1Id: user1Id,
      user2Id: user2Id,
      matchedAt: DateTime.parse(json['matched_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      otherUserId: otherUserId,
      otherUserName: otherProfile?['full_name'] as String? ?? 'Utilisateur',
      otherUserPhoto: otherProfile != null && otherProfile['photos'] != null
          ? (otherProfile['photos'] as List).isNotEmpty
              ? otherProfile['photos'][0] as String?
              : null
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
    );
  }

  /// ✅ Copie avec modifications
  TinderMatch copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? matchedAt,
    DateTime? lastMessageAt,
    DateTime? lastReadAt,
    bool? isActive,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhoto,
    String? lastMessagePreview,
  }) {
    return TinderMatch(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      matchedAt: matchedAt ?? this.matchedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isActive: isActive ?? this.isActive,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhoto: otherUserPhoto ?? this.otherUserPhoto,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
