import 'package:btth1/struct/document_enums.dart';

class Course {
  final String id;
  final String name;
  final String code;
  final int colorValue;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.colorValue,
  });
}

class Topic {
  final String id;
  final String name;
  final String courseId;

  Topic({
    required this.id,
    required this.name,
    required this.courseId,
  });
}

class StudyDocument {
  final String id;
  final String title;
  final String courseId;
  final String? topicId;
  final String? filePath;
  final String note;
  final DocumentType type;
  final ReadStatus status;
  final DateTime dateCreated;
  final DateTime dateTimeModified;

  StudyDocument({
    required this.id,
    required this.title,
    required this.courseId,
    this.topicId,
    this.filePath,
    this.note = '',
    required this.type,
    this.status = ReadStatus.unread,
    required this.dateCreated,
    required this.dateTimeModified,
  });
}
