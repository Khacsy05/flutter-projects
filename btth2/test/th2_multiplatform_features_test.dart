import 'package:flutter_test/flutter_test.dart';
import 'package:btth1/models/cloud_document.dart';
import 'package:btth1/models/borrow_request.dart';
import 'package:btth1/models/user_preference.dart';
import 'package:btth1/services/recommendation_service.dart';
import 'package:btth1/services/notification_service.dart';

void main() {
  group('TH2 - Kiểm thử Mô hình Dữ liệu Đa nền tảng (Cloud Models)', () {
    test('CloudDoc hỗ trợ gắn thẻ (tags) và thông tin vị trí vật lý chính xác', () {
      final doc = CloudDoc(
        id: 'doc_101',
        title: 'Giáo trình Lập trình Flutter Chuyên sâu',
        courseName: 'Lập trình di động',
        note: 'Sách in tại Thư viện',
        type: 'lecture',
        ownerId: 'user_a',
        permission: 'owner',
        tags: ['flutter', 'dart', 'mobile', 'state-management'],
        isPhysical: true,
        locationName: 'Thư viện Cơ sở 1 - KHTN',
        latitude: 10.762622,
        longitude: 106.682334,
        roomShelf: 'Kệ A3 - Ngăn 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(doc.isPhysical, isTrue);
      expect(doc.tags.length, equals(4));
      expect(doc.tags.contains('flutter'), isTrue);
      expect(doc.locationName, equals('Thư viện Cơ sở 1 - KHTN'));
      expect(doc.latitude, equals(10.762622));

      // Test chuyển đổi sang Map và ngược lại
      final map = doc.toMap();
      expect(map['title'], equals('Giáo trình Lập trình Flutter Chuyên sâu'));
      expect(map['is_physical'], isTrue);

      final reconstructed = CloudDoc.fromMap(map, permission: 'owner');
      expect(reconstructed.id, equals('doc_101'));
      expect(reconstructed.tags, contains('dart'));
      expect(reconstructed.roomShelf, equals('Kệ A3 - Ngăn 2'));
    });

    test('BorrowRequest tính toán trạng thái quá hạn (isOverdue) chính xác', () {
      // Yêu cầu chưa quá hạn (hạn trả sau 5 ngày)
      final activeReq = BorrowRequest(
        id: 'br_1',
        documentId: 'doc_101',
        documentTitle: 'Giáo trình Flutter',
        requesterId: 'user_b',
        requesterEmail: 'user_b@gmail.com',
        ownerId: 'user_a',
        status: 'approved',
        borrowDate: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().add(const Duration(days: 5)),
        note: 'Mượn ôn thi',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(activeReq.isOverdue, isFalse);

      // Yêu cầu đã quá hạn (hạn trả cách đây 2 ngày)
      final overdueReq = BorrowRequest(
        id: 'br_2',
        documentId: 'doc_101',
        documentTitle: 'Giáo trình Flutter',
        requesterId: 'user_c',
        requesterEmail: 'user_c@gmail.com',
        ownerId: 'user_a',
        status: 'approved',
        borrowDate: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        note: 'Mượn làm đồ án',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(overdueReq.isOverdue, isTrue);

      // Nếu đã trả (status = 'returned') thì không tính quá hạn
      final returnedReq = overdueReq.copyWith(
        status: 'returned',
        returnDate: DateTime.now(),
      );
      expect(returnedReq.isOverdue, isFalse);
    });
  });

  group('TH2 - Kiểm thử Thuật toán Gợi ý Tài liệu (Recommendation Engine)', () {
    final testPref = UserPreference(
      userId: 'user_test',
      favoriteTags: ['flutter', 'mobile', 'sqlite'],
      preferredCourses: ['Lập trình di động'],
      updatedAt: DateTime.now(),
    );

    final docMatchingAll = CloudDoc(
      id: 'd_high',
      title: 'Xây dựng ứng dụng Flutter hoàn chỉnh',
      courseName: 'Lập trình di động',
      note: 'Hướng dẫn kiến trúc clean code',
      type: 'lecture',
      ownerId: 'user_x',
      permission: 'view',
      tags: ['flutter', 'mobile', 'sqlite'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docMatchingPartial = CloudDoc(
      id: 'd_med',
      title: 'Nhập môn Lập trình Di động',
      courseName: 'Lập trình di động',
      note: 'Tổng quan hệ điều hành Android',
      type: 'lecture',
      ownerId: 'user_y',
      permission: 'view',
      tags: ['mobile', 'java'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docNotMatching = CloudDoc(
      id: 'd_low',
      title: 'Hóa học đại cương và phản ứng oxi hóa',
      courseName: 'Hóa đại cương',
      note: 'Công thức hóa học vô cơ',
      type: 'reference',
      ownerId: 'user_z',
      permission: 'view',
      tags: ['chemistry', 'lab'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    test('Thuật toán xếp hạng tài liệu trùng khớp nhiều tags và môn học lên đầu', () {
      final results = RecommendationService.computeRecommendations(
        allDocuments: [docNotMatching, docMatchingPartial, docMatchingAll],
        preference: testPref,
      );

      expect(results.isNotEmpty, isTrue);
      // Tài liệu d_high phải xếp hạng thứ nhất với điểm số cao nhất
      expect(results.first.document.id, equals('d_high'));
      expect(results.first.matchPercentage, greaterThan(70));
      expect(results.first.matchedTags, contains('flutter'));

      // Điểm số của tài liệu thứ nhất phải cao hơn tài liệu thứ hai
      if (results.length > 1) {
        expect(results[0].score, greaterThan(results[1].score));
      }
    });

    test('Thuật toán tự động sinh lý do giải thích gợi ý minh bạch cho người dùng', () {
      final results = RecommendationService.computeRecommendations(
        allDocuments: [docMatchingAll],
        preference: testPref,
      );

      expect(results.length, equals(1));
      final rec = results.first;
      expect(rec.matchingReasons.any((r) => r.contains('thẻ sở thích')), isTrue);
      expect(rec.matchingReasons.any((r) => r.contains('Môn học trong danh sách quan tâm')), isTrue);
    });
  });

  group('TH2 - Kiểm thử Dịch vụ Thông báo Thời gian thực (Notification Service)', () {
    test('Hệ thống thông báo đẩy thông điệp và đếm số lượng chưa đọc chuẩn xác', () {
      NotificationService.clearAll();
      expect(NotificationService.unreadCount, equals(0));

      NotificationService.notify(
        title: 'Yêu cầu mượn tài liệu',
        message: 'Bạn nhận được yêu cầu mượn từ sinh viên B',
        type: 'borrow_request',
        relatedDocId: 'doc_101',
      );

      expect(NotificationService.unreadCount, equals(1));
      final firstNotif = NotificationService.allNotifications.first;
      expect(firstNotif.title, equals('Yêu cầu mượn tài liệu'));

      // Đánh dấu đã đọc
      NotificationService.markAsRead(firstNotif.id);
      expect(NotificationService.unreadCount, equals(0));
    });
  });
}
