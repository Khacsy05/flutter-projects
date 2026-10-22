class BorrowRequest {
  final String id;
  final String documentId;
  final String documentTitle;
  final String documentType;
  final String requesterId;
  final String requesterEmail;
  final String? requesterName;
  final String ownerId;
  final String? ownerEmail;
  final String status; // 'pending', 'approved', 'rejected', 'returned'
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String note;
  final DateTime createdAt;

  BorrowRequest({
    required this.id,
    required this.documentId,
    required this.documentTitle,
    this.documentType = 'lecture',
    required this.requesterId,
    required this.requesterEmail,
    this.requesterName,
    required this.ownerId,
    this.ownerEmail,
    required this.status,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.note,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isReturned => status == 'returned';

  bool get isOverdue {
    if (isApproved && returnDate == null) {
      return DateTime.now().isAfter(dueDate);
    }
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'document_title': documentTitle,
      'document_type': documentType,
      'requester_id': requesterId,
      'requester_email': requesterEmail,
      'requester_name': requesterName,
      'owner_id': ownerId,
      'owner_email': ownerEmail,
      'status': status,
      'borrow_date': borrowDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BorrowRequest.fromMap(Map<String, dynamic> map) {
    return BorrowRequest(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      documentTitle: map['document_title']?.toString() ?? 'Tài liệu',
      documentType: map['document_type']?.toString() ?? 'lecture',
      requesterId: map['requester_id']?.toString() ?? '',
      requesterEmail: map['requester_email']?.toString() ?? '',
      requesterName: map['requester_name']?.toString(),
      ownerId: map['owner_id']?.toString() ?? '',
      ownerEmail: map['owner_email']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      borrowDate: DateTime.tryParse(map['borrow_date']?.toString() ?? '') ?? DateTime.now(),
      dueDate: DateTime.tryParse(map['due_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 7)),
      returnDate: map['return_date'] != null ? DateTime.tryParse(map['return_date'].toString()) : null,
      note: map['note']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  BorrowRequest copyWith({
    String? id,
    String? documentId,
    String? documentTitle,
    String? documentType,
    String? requesterId,
    String? requesterEmail,
    String? requesterName,
    String? ownerId,
    String? ownerEmail,
    String? status,
    DateTime? borrowDate,
    DateTime? dueDate,
    DateTime? returnDate,
    String? note,
    DateTime? createdAt,
  }) {
    return BorrowRequest(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      documentType: documentType ?? this.documentType,
      requesterId: requesterId ?? this.requesterId,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      requesterName: requesterName ?? this.requesterName,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      status: status ?? this.status,
      borrowDate: borrowDate ?? this.borrowDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
