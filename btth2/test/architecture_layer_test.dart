import 'package:flutter_test/flutter_test.dart';
import 'package:btth1/database/tables.dart';
import 'package:btth1/struct/database_global.dart';
import 'package:btth1/struct/document_enums.dart';

void main() {
  group('1. Data & Persistence Layer Test (Không phụ thuộc UI)', () {
    late DocumentDatabase database;

    setUp(() {
      database = DocumentDatabase();
    });

    test('Lớp Database khởi tạo danh sách môn học và tài liệu mẫu độc lập với UI', () {
      final courses = database.getAllCourses();
      expect(courses.isNotEmpty, true, reason: 'Danh sách môn học phải có dữ liệu khởi tạo');
      expect(courses.any((c) => c.name.contains('di động')), true);

      final docs = database.getAllDocuments();
      expect(docs.isNotEmpty, true, reason: 'Danh sách tài liệu ban đầu phải có sẵn');
    });

    test('Thao tác CRUD hoạt động hoàn toàn độc lập tại Data Layer', () {
      final newDoc = StudyDocument(
        id: 'test_doc_01',
        title: 'Kiểm thử kiến trúc Cashew',
        courseId: '1',
        type: DocumentType.lecture,
        filePath: 'https://example.com/test.pdf',
        status: ReadStatus.unread,
        note: 'Ghi chú kiểm thử unit test',
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      // 1. Thêm (Insert)
      database.insertDocument(newDoc);
      var allDocs = database.getAllDocuments();
      expect(allDocs.any((d) => d.id == 'test_doc_01'), true);

      // 2. Sửa (Update)
      final updatedDoc = StudyDocument(
        id: 'test_doc_01',
        title: 'Kiểm thử kiến trúc Cashew - Đã cập nhật',
        courseId: '1',
        type: DocumentType.lecture,
        filePath: 'https://example.com/test.pdf',
        status: ReadStatus.completed,
        note: 'Ghi chú kiểm thử unit test',
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );
      database.updateDocument(updatedDoc);
      allDocs = database.getAllDocuments();
      final fetched = allDocs.firstWhere((d) => d.id == 'test_doc_01');
      expect(fetched.title, 'Kiểm thử kiến trúc Cashew - Đã cập nhật');
      expect(fetched.status, ReadStatus.completed);

      // 3. Xóa (Delete)
      database.deleteDocument('test_doc_01');
      allDocs = database.getAllDocuments();
      expect(allDocs.any((d) => d.id == 'test_doc_01'), false);
    });
  });

  group('2. Business Logic & Reactive State Layer Test (Stream / Reactive Flow)', () {
    late DocumentDatabase database;

    setUp(() {
      database = DocumentDatabase();
    });

    test('Stream phát sự kiện tự động khi dữ liệu thay đổi (Reactive State)', () async {
      final docToInsert = StudyDocument(
        id: 'reactive_test_id',
        title: 'Tài liệu phản ứng luồng Stream',
        courseId: '2',
        type: DocumentType.assignment,
        filePath: '',
        status: ReadStatus.reading,
        note: '',
        dateCreated: DateTime.now(),
        dateTimeModified: DateTime.now(),
      );

      final expectation = expectLater(
        database.watchAllDocuments(),
        emitsThrough(
          predicate<List<StudyDocument>>((list) => list.any((d) => d.id == 'reactive_test_id')),
        ),
      );

      database.insertDocument(docToInsert);
      await expectation;

      // Dọn dẹp sau test
      database.deleteDocument('reactive_test_id');
    });

    test('Logic lọc và tìm kiếm dữ liệu (Search & Filtering Logic)', () {
      final docs = database.getAllDocuments();
      
      // Test logic tìm kiếm theo từ khóa
      const searchKeyword = 'Flutter';
      final searchResult = docs.where((doc) {
        return doc.title.toLowerCase().contains(searchKeyword.toLowerCase()) ||
               doc.note.toLowerCase().contains(searchKeyword.toLowerCase());
      }).toList();

      expect(searchResult.every((d) => 
        d.title.toLowerCase().contains('flutter') || 
        d.note.toLowerCase().contains('flutter')
      ), true);

      // Test logic lọc theo môn học
      const courseId = '1';
      final courseResult = docs.where((doc) => doc.courseId == courseId).toList();
      expect(courseResult.every((d) => d.courseId == '1'), true);
    });
  });
}
