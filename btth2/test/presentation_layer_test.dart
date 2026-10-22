import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:btth1/main.dart';
import 'package:btth1/database/tables.dart';
import 'package:btth1/struct/database_global.dart';
import 'package:btth1/struct/document_enums.dart';

void main() {
  group('3. Presentation Layer Test (Tương tác UI và phản hồi theo luồng dữ liệu)', () {
    testWidgets('UI hiển thị đúng các thành phần phân lớp: Tìm kiếm, Bộ lọc môn học, Danh sách tài liệu', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyDocumentApp());
      await tester.pump();

      // Kiểm tra thanh tìm kiếm
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tìm kiếm theo tên tài liệu, ghi chú...'), findsOneWidget);

      // Kiểm tra filter chips
      expect(find.text('Tất cả môn'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Lập trình di động'), findsOneWidget);

      // Kiểm tra FloatingActionButton thêm tài liệu
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('UI tự động đồng bộ khi State Stream phát dữ liệu mới (Unidirectional Data Flow)', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyDocumentApp());
      await tester.pump();

      const uniqueTitle = 'Tài liệu UI Test Đồng Bộ';
      final testDoc = StudyDocument(
        id: 'ui_sync_test_id',
        title: uniqueTitle,
        courseId: '1',
        type: DocumentType.lecture,
        filePath: 'https://example.com/sync.pdf',
        status: ReadStatus.reading,
        note: 'Ghi chú cho UI test',
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      // Thêm tài liệu thông qua Database Global (Không can thiệp trực tiếp vào State của Widget)
      appDatabase.insertDocument(testDoc);
      await tester.pump();

      // Kiểm tra UI đã tự động nhận diện tài liệu mới qua StreamBuilder
      expect(find.text(uniqueTitle), findsOneWidget);

      // Xóa tài liệu khỏi Database
      appDatabase.deleteDocument('ui_sync_test_id');
      await tester.pump();

      // Kiểm tra UI tự động biến mất tài liệu đó
      expect(find.text(uniqueTitle), findsNothing);
    });
  });
}
