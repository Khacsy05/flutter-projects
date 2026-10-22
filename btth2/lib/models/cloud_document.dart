class CloudDoc {
  final String id;
  final String title;
  final String courseName;
  final String note;
  final String type; // 'lecture', 'assignment', 'reference', 'exam'
  final String? fileUrl;
  final String? fileName;
  final String ownerId;
  final String? ownerEmail;
  final String permission; // 'owner', 'view', 'edit'
  final List<String> tags;
  final bool isPhysical;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? roomShelf;
  final String borrowStatus; // 'available', 'borrowed', 'none'
  final DateTime createdAt;
  final DateTime updatedAt;

  CloudDoc({
    required this.id,
    required this.title,
    required this.courseName,
    required this.note,
    required this.type,
    this.fileUrl,
    this.fileName,
    required this.ownerId,
    this.ownerEmail,
    required this.permission,
    this.tags = const [],
    this.isPhysical = false,
    this.locationName,
    this.latitude,
    this.longitude,
    this.roomShelf,
    this.borrowStatus = 'available',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOwner => permission == 'owner';
  bool get canEdit => permission == 'owner' || permission == 'edit';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'course_name': courseName,
      'note': note,
      'type': type,
      'file_url': fileUrl,
      'file_name': fileName,
      'owner_id': ownerId,
      'tags': tags,
      'is_physical': isPhysical,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'room_shelf': roomShelf,
      'borrow_status': borrowStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CloudDoc.fromMap(Map<String, dynamic> map, {String permission = 'owner', String? ownerEmail}) {
    List<String> parsedTags = [];
    final rawTags = map['tags'];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      parsedTags = rawTags
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    double? parseCoord(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return CloudDoc(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      courseName: map['course_name']?.toString() ?? 'Chung',
      note: map['note']?.toString() ?? '',
      type: map['type']?.toString() ?? 'lecture',
      fileUrl: map['file_url']?.toString(),
      fileName: map['file_name']?.toString(),
      ownerId: map['owner_id']?.toString() ?? '',
      ownerEmail: ownerEmail ?? (map['profiles'] is Map ? map['profiles']['email']?.toString() : null),
      permission: permission,
      tags: parsedTags,
      isPhysical: map['is_physical'] == true || map['is_physical'] == 1 || map['is_physical'] == 'true',
      locationName: map['location_name']?.toString(),
      latitude: parseCoord(map['latitude']),
      longitude: parseCoord(map['longitude']),
      roomShelf: map['room_shelf']?.toString(),
      borrowStatus: map['borrow_status']?.toString() ?? 'available',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  CloudDoc copyWith({
    String? id,
    String? title,
    String? courseName,
    String? note,
    String? type,
    String? fileUrl,
    String? fileName,
    String? ownerId,
    String? ownerEmail,
    String? permission,
    List<String>? tags,
    bool? isPhysical,
    String? locationName,
    double? latitude,
    double? longitude,
    String? roomShelf,
    String? borrowStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CloudDoc(
      id: id ?? this.id,
      title: title ?? this.title,
      courseName: courseName ?? this.courseName,
      note: note ?? this.note,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      permission: permission ?? this.permission,
      tags: tags ?? this.tags,
      isPhysical: isPhysical ?? this.isPhysical,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      roomShelf: roomShelf ?? this.roomShelf,
      borrowStatus: borrowStatus ?? this.borrowStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
