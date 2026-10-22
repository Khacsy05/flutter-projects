import 'dart:async';
import 'package:btth1/database/tables.dart';
import 'package:btth1/struct/document_enums.dart';

class DocumentDatabase {
  final List<Course> _courses = [
    Course(id: '1', name: 'Lập trình di động', code: 'MOB101', colorValue: 0xFF1E88E5),
    Course(id: '2', name: 'Cấu trúc dữ liệu', code: 'CS201', colorValue: 0xFF43A047),
    Course(id: '3', name: 'Trí tuệ nhân tạo', code: 'AI301', colorValue: 0xFFE53935),
  ];

  final List<StudyDocument> _documents = [
    StudyDocument(
      id: 'd1',
      title: 'Slide Bài giảng 1: Giới thiệu Flutter',
      courseId: '1',
      note: 'Xem kỹ kiến trúc Widget Tree',
      type: DocumentType.lecture,
      status: ReadStatus.completed,
      dateCreated: DateTime.now().subtract(const Duration(days: 2)),
      dateTimeModified: DateTime.now(),
    ),
    StudyDocument(
      id: 'd2',
      title: 'Bài tập tuần 2: Phân lớp Cashew',
      courseId: '1',
      note: 'Hạn nộp cuối tuần',
      type: DocumentType.assignment,
      status: ReadStatus.reading,
      dateCreated: DateTime.now().subtract(const Duration(days: 1)),
      dateTimeModified: DateTime.now(),
    ),
  ];

  late final StreamController<List<StudyDocument>> _docStreamController;

  DocumentDatabase() {
    _docStreamController = StreamController<List<StudyDocument>>.broadcast(
      onListen: () {
        _docStreamController.add(List.unmodifiable(_documents));
      },
    );
  }

  Stream<List<StudyDocument>> watchAllDocuments() => _docStreamController.stream;

  List<Course> getAllCourses() => List.unmodifiable(_courses);
  List<StudyDocument> getAllDocuments() => List.unmodifiable(_documents);

  void _notify() {
    _docStreamController.add(List.unmodifiable(_documents));
  }

  void insertDocument(StudyDocument doc) {
    _documents.add(doc);
    _notify();
  }

  void updateDocument(StudyDocument doc) {
    final idx = _documents.indexWhere((element) => element.id == doc.id);
    if (idx != -1) {
      _documents[idx] = doc;
      _notify();
    }
  }

  void deleteDocument(String id) {
    _documents.removeWhere((item) => item.id == id);
    _notify();
  }
}

final DocumentDatabase appDatabase = DocumentDatabase();
