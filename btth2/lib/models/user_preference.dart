class UserPreference {
  final String userId;
  final List<String> favoriteTags;
  final List<String> preferredCourses;
  final Map<String, int> tagInteractions; // tag -> interaction count
  final DateTime updatedAt;

  UserPreference({
    required this.userId,
    this.favoriteTags = const ['flutter', 'mobile', 'database'],
    this.preferredCourses = const ['Lập trình di động'],
    this.tagInteractions = const {},
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'favorite_tags': favoriteTags,
      'preferred_courses': preferredCourses,
      'tag_interactions': tagInteractions,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserPreference.fromMap(Map<String, dynamic> map, {required String fallbackUserId}) {
    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    Map<String, int> parseInteractions(dynamic raw) {
      if (raw is Map) {
        final Map<String, int> res = {};
        raw.forEach((key, val) {
          res[key.toString()] = int.tryParse(val.toString()) ?? 1;
        });
        return res;
      }
      return {};
    }

    return UserPreference(
      userId: map['user_id']?.toString() ?? fallbackUserId,
      favoriteTags: parseList(map['favorite_tags']).isEmpty
          ? ['flutter', 'mobile', 'database']
          : parseList(map['favorite_tags']),
      preferredCourses: parseList(map['preferred_courses']).isEmpty
          ? ['Lập trình di động']
          : parseList(map['preferred_courses']),
      tagInteractions: parseInteractions(map['tag_interactions']),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  UserPreference copyWith({
    String? userId,
    List<String>? favoriteTags,
    List<String>? preferredCourses,
    Map<String, int>? tagInteractions,
    DateTime? updatedAt,
  }) {
    return UserPreference(
      userId: userId ?? this.userId,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      preferredCourses: preferredCourses ?? this.preferredCourses,
      tagInteractions: tagInteractions ?? this.tagInteractions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
