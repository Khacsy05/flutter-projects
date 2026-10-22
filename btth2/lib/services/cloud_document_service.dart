import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:btth1/models/cloud_document.dart';
import 'package:btth1/models/borrow_request.dart';
import 'package:btth1/models/user_preference.dart';
import 'package:btth1/services/notification_service.dart';

export 'package:btth1/models/cloud_document.dart';
export 'package:btth1/models/borrow_request.dart';
export 'package:btth1/models/user_preference.dart';

class CloudDocumentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Local fallback caches to guarantee zero-crash and offline-first resilience
  static final List<BorrowRequest> _localBorrowRequests = [];
  static final Map<String, UserPreference> _localUserPreferences = {};
  static final List<CloudDoc> _localCreatedDocs = [];
  static bool _hasSyncedProfile = false;

  /// Đồng bộ thông tin người dùng lên Supabase profiles
  static Future<void> syncCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _hasSyncedProfile) return;

    try {
      await _supabase.from('profiles').upsert({
        'id': user.uid,
        'email': (user.email ?? '').toLowerCase().trim(),
        'display_name': user.displayName ?? (user.email?.split('@').first ?? 'Người dùng'),
        'avatar_url': user.photoURL,
      }).timeout(const Duration(seconds: 4));
      _hasSyncedProfile = true;
      debugPrint('Đã đồng bộ user profile lên Supabase: ${user.email}');
    } catch (e) {
      debugPrint('Lỗi đồng bộ profile (tiếp tục chạy bình thường): $e');
    }
  }

  /// Chuyển đổi tệp thành chuỗi Data URL để lưu trực tiếp vào CSDL Supabase
  static String convertBytesToDataUrl(Uint8List bytes, String fileName) {
    String mime = 'application/octet-stream';
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') {
      mime = 'application/pdf';
    } else if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
      mime = 'image/$ext';
    } else if (['txt', 'csv'].contains(ext)) {
      mime = 'text/plain';
    } else if (['doc', 'docx'].contains(ext)) {
      mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    final base64String = base64Encode(bytes);
    return 'data:$mime;name=$fileName;base64,$base64String';
  }

  static bool _supportsExtendedColumns = true;

  /// Tạo tài liệu mới trên Supabase Database với Tags và Location
  static Future<void> createDocument({
    required String title,
    required String courseName,
    required String note,
    required String type,
    String? fileUrl,
    String? fileName,
    List<String> tags = const [],
    bool isPhysical = false,
    String? locationName,
    double? latitude,
    double? longitude,
    String? roomShelf,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập!');
    await syncCurrentUser();

    final localBackup = CloudDoc(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      courseName: courseName.trim(),
      note: note.trim(),
      type: type,
      fileUrl: fileUrl,
      fileName: fileName,
      ownerId: user.uid,
      ownerEmail: user.email,
      permission: 'owner',
      tags: tags,
      isPhysical: isPhysical,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      roomShelf: roomShelf,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (_supportsExtendedColumns) {
        final payload = <String, dynamic>{
          'title': title.trim(),
          'course_name': courseName.trim(),
          'note': note.trim(),
          'type': type,
          'file_url': fileUrl,
          'file_name': fileName,
          'owner_id': user.uid,
          'tags': tags,
          'is_physical': isPhysical,
          'location_name': locationName,
          'latitude': latitude,
          'longitude': longitude,
          'room_shelf': roomShelf,
          'borrow_status': 'available',
        };

        try {
          await _supabase.from('documents').insert(payload).timeout(const Duration(seconds: 8));
          return;
        } catch (e) {
          _supportsExtendedColumns = false;
          debugPrint('Thử cột mở rộng không khả dụng, chuyển sang chế độ tương thích.');
        }
      }

      // Chế độ tương thích (lưu metadata trực tiếp vào note)
      String encodedNote = note.trim();
      if (tags.isNotEmpty) {
        encodedNote = '[TAGS: ${tags.join(',')}] $encodedNote';
      }
      if (isPhysical) {
        encodedNote = '[VẬT LÝ @ ${locationName ?? "Thư viện"} | KỆ: ${roomShelf ?? "Chung"} | TOẠ ĐỘ: ${latitude ?? 10.762622},${longitude ?? 106.682334}] $encodedNote';
      }

      final fallbackPayload = <String, dynamic>{
        'title': title.trim(),
        'course_name': courseName.trim(),
        'note': encodedNote,
        'type': type,
        'file_url': fileUrl,
        'file_name': fileName,
        'owner_id': user.uid,
      };
      await _supabase.from('documents').insert(fallbackPayload).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Lỗi mạng/Timeout khi gửi lên Supabase, lưu trữ an toàn vào Local Cache: $e');
      _localCreatedDocs.insert(0, localBackup);
    }
  }

  /// Cập nhật tài liệu trên Supabase Database
  static Future<void> updateDocument({
    required String documentId,
    required String title,
    required String courseName,
    required String note,
    required String type,
    String? fileUrl,
    String? fileName,
    List<String>? tags,
    bool? isPhysical,
    String? locationName,
    double? latitude,
    double? longitude,
    String? roomShelf,
  }) async {
    await syncCurrentUser();

    final updateData = <String, dynamic>{
      'title': title.trim(),
      'course_name': courseName.trim(),
      'note': note.trim(),
      'type': type,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fileUrl != null) {
      updateData['file_url'] = fileUrl;
      updateData['file_name'] = fileName;
    }
    if (tags != null) updateData['tags'] = tags;
    if (isPhysical != null) updateData['is_physical'] = isPhysical;
    if (locationName != null) updateData['location_name'] = locationName;
    if (latitude != null) updateData['latitude'] = latitude;
    if (longitude != null) updateData['longitude'] = longitude;
    if (roomShelf != null) updateData['room_shelf'] = roomShelf;

    try {
      await _supabase.from('documents').update(updateData).eq('id', documentId).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Update lỗi schema, fallback cập nhật cơ bản: $e');
      final basicData = <String, dynamic>{
        'title': title.trim(),
        'course_name': courseName.trim(),
        'note': (isPhysical == true)
            ? '[VẬT LÝ @ $locationName] [TAGS: ${(tags ?? []).join(',')}] ${note.trim()}'
            : note.trim(),
        'type': type,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fileUrl != null) {
        basicData['file_url'] = fileUrl;
        basicData['file_name'] = fileName;
      }
      await _supabase.from('documents').update(basicData).eq('id', documentId).timeout(const Duration(seconds: 10));
    }
  }

  /// Xóa tài liệu khỏi Supabase
  static Future<void> deleteDocument(String documentId) async {
    await syncCurrentUser();
    await _supabase.from('documents').delete().eq('id', documentId).timeout(const Duration(seconds: 10));
  }

  /// Lấy danh sách tài liệu từ Supabase (gồm tài liệu sở hữu + được chia sẻ)
  static Future<List<CloudDoc>> fetchDocuments({
    String? searchQuery,
    String? courseFilter,
    String? tagFilter,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    await syncCurrentUser();

    final List<CloudDoc> allDocs = [];

    try {
      // 1. Lấy tài liệu sở hữu
      final ownedRows = await _supabase
          .from('documents')
          .select('*, profiles!documents_owner_id_fkey(email, display_name)')
          .eq('owner_id', user.uid)
          .timeout(const Duration(seconds: 8));

      for (final row in (ownedRows as List)) {
        final doc = _parseRowToCloudDoc(row, permission: 'owner');
        allDocs.add(doc);
      }
    } catch (e) {
      debugPrint('Lỗi tải tài liệu sở hữu từ Supabase: $e');
    }

    try {
      // 2. Lấy tài liệu được chia sẻ
      final sharedPermissions = await _supabase
          .from('document_permissions')
          .select('permission_level, documents(*, profiles!documents_owner_id_fkey(email, display_name))')
          .eq('user_id', user.uid)
          .timeout(const Duration(seconds: 8));

      for (final pRow in (sharedPermissions as List)) {
        final docRow = pRow['documents'] as Map<String, dynamic>?;
        if (docRow == null) continue;
        if (docRow['owner_id'] == user.uid) continue;

        final permLevel = pRow['permission_level'] ?? 'view';
        final doc = _parseRowToCloudDoc(docRow, permission: permLevel);
        allDocs.add(doc);
      }
    } catch (e) {
      debugPrint('Lỗi tải tài liệu chia sẻ từ Supabase: $e');
    }

    // Luôn hợp nhất tài liệu tạo gần nhất từ Local Cache (Offline-First)
    for (final ld in _localCreatedDocs) {
      if (!allDocs.any((d) => d.title == ld.title && d.courseName == ld.courseName)) {
        allDocs.add(ld);
      }
    }

    allDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    var filtered = allDocs;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      filtered = filtered.where((d) {
        return d.title.toLowerCase().contains(q) ||
            d.note.toLowerCase().contains(q) ||
            d.courseName.toLowerCase().contains(q) ||
            d.tags.any((t) => t.toLowerCase().contains(q)) ||
            (d.locationName != null && d.locationName!.toLowerCase().contains(q));
      }).toList();
    }

    if (courseFilter != null && courseFilter.trim().isNotEmpty) {
      filtered = filtered.where((d) => d.courseName == courseFilter).toList();
    }

    if (tagFilter != null && tagFilter.trim().isNotEmpty) {
      final tf = tagFilter.toLowerCase().trim();
      filtered = filtered.where((d) => d.tags.any((t) => t.toLowerCase() == tf)).toList();
    }

    return filtered;
  }

  /// Lấy danh sách tài liệu từ toàn bộ hệ thống (dùng cho Recommendation & Mượn tài liệu)
  static Future<List<CloudDoc>> fetchAllPublicDocuments() async {
    await syncCurrentUser();
    try {
      final rows = await _supabase
          .from('documents')
          .select('*, profiles!documents_owner_id_fkey(email, display_name)')
          .limit(100)
          .timeout(const Duration(seconds: 10));

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final List<CloudDoc> docs = [];

      for (final r in (rows as List)) {
        final isMe = r['owner_id'] == currentUid;
        docs.add(_parseRowToCloudDoc(r, permission: isMe ? 'owner' : 'public_view'));
      }
      return docs;
    } catch (e) {
      debugPrint('Lỗi fetchAllPublicDocuments: $e');
      return [];
    }
  }

  static CloudDoc _parseRowToCloudDoc(Map<String, dynamic> row, {required String permission}) {
    final ownerProfile = row['profiles'] as Map<String, dynamic>?;
    String rawNote = row['note'] ?? '';

    // Trích xuất tags và location từ note nếu schema chưa có cột riêng
    List<String> tags = [];
    final rawTags = row['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      tags = rawTags.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    // Parse fallback từ note
    if (tags.isEmpty && rawNote.contains('[TAGS:')) {
      final tagMatch = RegExp(r'\[TAGS:\s*([^\]]+)\]').firstMatch(rawNote);
      if (tagMatch != null) {
        tags = tagMatch.group(1)!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    bool isPhysical = row['is_physical'] == true || row['is_physical'] == 1 || row['is_physical'] == 'true';
    String? locationName = row['location_name'];
    String? roomShelf = row['room_shelf'];
    double? latitude = row['latitude'] != null ? double.tryParse(row['latitude'].toString()) : null;
    double? longitude = row['longitude'] != null ? double.tryParse(row['longitude'].toString()) : null;

    if (!isPhysical && rawNote.contains('[VẬT LÝ @')) {
      isPhysical = true;
      final locMatch = RegExp(r'\[VẬT LÝ @\s*([^\]|]+)').firstMatch(rawNote);
      if (locMatch != null) {
        locationName = locMatch.group(1)!.trim();
      }

      final shelfMatch = RegExp(r'KỆ:\s*([^\]|]+)').firstMatch(rawNote);
      if (shelfMatch != null) {
        roomShelf = shelfMatch.group(1)!.trim();
      }

      final coordMatch = RegExp(r'TOẠ ĐỘ:\s*([0-9.]+),([0-9.]+)').firstMatch(rawNote);
      if (coordMatch != null) {
        latitude = double.tryParse(coordMatch.group(1)!);
        longitude = double.tryParse(coordMatch.group(2)!);
      }
    }

    // Tọa độ mẫu mặc định cho các cơ sở trường đại học nếu chưa nhập
    if (isPhysical && latitude == null) {
      // Tọa độ Trường ĐHQG / KHTN TP.HCM
      latitude = 10.762622;
      longitude = 106.682334;
    }

    // Làm sạch chuỗi ghi chú hiển thị trên UI (loại bỏ các thẻ metadata kỹ thuật)
    String cleanNote = rawNote
        .replaceAll(RegExp(r'\[TAGS:[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[VẬT LÝ @[^\]]+\]'), '')
        .trim();

    return CloudDoc(
      id: row['id']?.toString() ?? '',
      title: row['title'] ?? '',
      courseName: row['course_name'] ?? 'Chung',
      note: cleanNote,
      type: row['type'] ?? 'lecture',
      fileUrl: row['file_url'],
      fileName: row['file_name'],
      ownerId: row['owner_id'] ?? '',
      ownerEmail: ownerProfile?['email'],
      permission: permission,
      tags: tags,
      isPhysical: isPhysical,
      locationName: locationName ?? (isPhysical ? 'Thư viện Trung tâm' : null),
      latitude: latitude,
      longitude: longitude,
      roomShelf: roomShelf ?? row['room_shelf'],
      borrowStatus: row['borrow_status'] ?? 'available',
      createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  // ========================================================
  // QUY TRÌNH MƯỢN / TRẢ TÀI LIỆU (BORROW & LOAN WORKFLOW)
  // ========================================================

  /// Gửi yêu cầu mượn tài liệu
  static Future<void> createBorrowRequest({
    required CloudDoc doc,
    required DateTime borrowDate,
    required DateTime dueDate,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập!');
    if (user.uid == doc.ownerId) throw Exception('Bạn không thể tự mượn tài liệu của chính mình!');

    await syncCurrentUser();

    final req = BorrowRequest(
      id: 'br_${DateTime.now().millisecondsSinceEpoch}',
      documentId: doc.id,
      documentTitle: doc.title,
      documentType: doc.type,
      requesterId: user.uid,
      requesterEmail: user.email ?? 'Ẩn danh',
      requesterName: user.displayName,
      ownerId: doc.ownerId,
      ownerEmail: doc.ownerEmail,
      status: 'pending',
      borrowDate: borrowDate,
      dueDate: dueDate,
      note: message,
      createdAt: DateTime.now(),
    );

    try {
      await _supabase.from('borrow_requests').insert(req.toMap()).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Chèn vào bảng borrow_requests thất bại, lưu bộ đệm local: $e');
      _localBorrowRequests.insert(0, req);
    }

    // Phát thông báo in-app
    NotificationService.notify(
      title: 'Đã gửi yêu cầu mượn',
      message: 'Bạn đã gửi yêu cầu mượn "${doc.title}" tới ${doc.ownerEmail ?? "chủ sở hữu"}.',
      type: 'borrow_request',
      relatedDocId: doc.id,
    );
  }

  /// Lấy danh sách yêu cầu mượn do tôi gửi
  static Future<List<BorrowRequest>> fetchSentBorrowRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase
          .from('borrow_requests')
          .select()
          .eq('requester_id', user.uid)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));
      return (res as List).map((m) => BorrowRequest.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Fetch sent borrow requests fallback local: $e');
      return _localBorrowRequests.where((r) => r.requesterId == user.uid).toList();
    }
  }

  /// Lấy danh sách yêu cầu mượn gửi tới tôi (với tư cách chủ tài liệu)
  static Future<List<BorrowRequest>> fetchReceivedBorrowRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase
          .from('borrow_requests')
          .select()
          .eq('owner_id', user.uid)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));
      return (res as List).map((m) => BorrowRequest.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Fetch received borrow requests fallback local: $e');
      return _localBorrowRequests.where((r) => r.ownerId == user.uid).toList();
    }
  }

  /// Cập nhật trạng thái yêu cầu mượn ('approved', 'rejected', 'returned')
  static Future<void> updateBorrowStatus({
    required String requestId,
    required String newStatus,
    required BorrowRequest request,
  }) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus};
      if (newStatus == 'returned') {
        updateData['return_date'] = DateTime.now().toIso8601String();
      }
      await _supabase.from('borrow_requests').update(updateData).eq('id', requestId).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Cập nhật borrow status online lỗi, cập nhật local: $e');
      final idx = _localBorrowRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        _localBorrowRequests[idx] = _localBorrowRequests[idx].copyWith(
          status: newStatus,
          returnDate: newStatus == 'returned' ? DateTime.now() : null,
        );
      }
    }

    // Nếu phê duyệt mượn -> Tự động cấp quyền 'view' cho người mượn trên bảng document_permissions
    if (newStatus == 'approved') {
      try {
        await shareDocument(
          documentId: request.documentId,
          targetEmail: request.requesterEmail,
          permissionLevel: 'view',
        );
      } catch (e) {
        debugPrint('Không thể tự động cấp quyền chia sẻ khi duyệt: $e');
      }

      NotificationService.notify(
        title: 'Yêu cầu mượn đã được duyệt!',
        message: 'Tài liệu "${request.documentTitle}" đã sẵn sàng cho bạn đọc.',
        type: 'borrow_approved',
        relatedDocId: request.documentId,
      );
    } else if (newStatus == 'rejected') {
      NotificationService.notify(
        title: 'Yêu cầu mượn bị từ chối',
        message: 'Yêu cầu mượn "${request.documentTitle}" đã bị từ chối.',
        type: 'borrow_rejected',
        relatedDocId: request.documentId,
      );
    } else if (newStatus == 'returned') {
      NotificationService.notify(
        title: 'Đã hoàn tất trả tài liệu',
        message: 'Tài liệu "${request.documentTitle}" đã được xác nhận trả thành công.',
        type: 'borrow_returned',
        relatedDocId: request.documentId,
      );
    }
  }

  // ========================================================
  // QUẢN LÝ SỞ THÍCH NGƯỜI DÙNG CHO RECOMMENDATION
  // ========================================================

  /// Lấy thông tin sở thích của người dùng hiện tại
  static Future<UserPreference> fetchUserPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackId = user?.uid ?? 'guest';

    if (_localUserPreferences.containsKey(fallbackId)) {
      return _localUserPreferences[fallbackId]!;
    }

    try {
      final res = await _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', fallbackId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (res != null) {
        final pref = UserPreference.fromMap(res, fallbackUserId: fallbackId);
        _localUserPreferences[fallbackId] = pref;
        return pref;
      }
    } catch (e) {
      debugPrint('Không thể tải user_preference online: $e');
    }

    final defaultPref = UserPreference(
      userId: fallbackId,
      favoriteTags: ['flutter', 'mobile', 'sqlite', 'database', 'ai'],
      preferredCourses: ['Lập trình di động', 'Cơ sở dữ liệu'],
      updatedAt: DateTime.now(),
    );
    _localUserPreferences[fallbackId] = defaultPref;
    return defaultPref;
  }

  /// Cập nhật sở thích người dùng
  static Future<void> saveUserPreference(UserPreference pref) async {
    _localUserPreferences[pref.userId] = pref;
    try {
      await _supabase.from('user_preferences').upsert(pref.toMap()).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Không thể lưu user_preferences online: $e');
    }
  }

  /// Ghi nhận tương tác tag khi người dùng xem tài liệu
  static Future<void> trackTagInteraction(List<String> tags) async {
    if (tags.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pref = await fetchUserPreference();
    final updatedInteractions = Map<String, int>.from(pref.tagInteractions);
    for (final t in tags) {
      final clean = t.toLowerCase().trim();
      updatedInteractions[clean] = (updatedInteractions[clean] ?? 0) + 1;
    }

    final updated = pref.copyWith(
      tagInteractions: updatedInteractions,
      updatedAt: DateTime.now(),
    );
    await saveUserPreference(updated);
  }

  // ========================================================
  // CHIA SẺ VÀ PHÂN QUYỀN TRUY CẬP (SHARING & PERMISSIONS)
  // ========================================================

  /// Chia sẻ tài liệu cho người khác qua Email
  static Future<void> shareDocument({
    required String documentId,
    required String targetEmail,
    required String permissionLevel,
  }) async {
    await syncCurrentUser();
    final cleanEmail = targetEmail.trim().toLowerCase();

    final userRes = await _supabase
        .from('profiles')
        .select('id, email, display_name')
        .eq('email', cleanEmail)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    if (userRes == null) {
      throw Exception(
        'Không tìm thấy tài khoản có email "$cleanEmail".\n'
        'Lưu ý: Người dùng đó phải đăng nhập vào ứng dụng ít nhất 1 lần để hệ thống ghi nhận.',
      );
    }

    final targetUserId = userRes['id'] as String;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (targetUserId == currentUserId) {
      throw Exception('Bạn là chủ sở hữu của tài liệu này rồi!');
    }

    await _supabase.from('document_permissions').upsert({
      'document_id': documentId,
      'user_id': targetUserId,
      'permission_level': permissionLevel,
      'shared_at': DateTime.now().toIso8601String(),
    }, onConflict: 'document_id,user_id').timeout(const Duration(seconds: 10));
  }

  /// Lấy danh sách người đã được chia sẻ
  static Future<List<Map<String, dynamic>>> getDocumentSharedUsers(String documentId) async {
    await syncCurrentUser();
    final res = await _supabase
        .from('document_permissions')
        .select('id, permission_level, shared_at, profiles!document_permissions_user_id_fkey(id, email, display_name)')
        .eq('document_id', documentId)
        .timeout(const Duration(seconds: 10));

    return List<Map<String, dynamic>>.from(res);
  }

  /// Thu hồi quyền
  static Future<void> revokeShare(String permissionId) async {
    await syncCurrentUser();
    await _supabase.from('document_permissions').delete().eq('id', permissionId).timeout(const Duration(seconds: 10));
  }

  /// Cập nhật quyền chia sẻ (view <-> edit)
  static Future<void> updateSharePermission({
    required String permissionId,
    required String newPermissionLevel,
  }) async {
    await syncCurrentUser();
    await _supabase
        .from('document_permissions')
        .update({'permission_level': newPermissionLevel})
        .eq('id', permissionId)
        .timeout(const Duration(seconds: 10));
  }
}
