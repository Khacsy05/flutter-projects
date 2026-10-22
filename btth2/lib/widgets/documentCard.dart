import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:btth1/database/tables.dart';
import 'package:btth1/struct/document_enums.dart';

class DocumentCard extends StatelessWidget {
  final StudyDocument doc;
  final Course? course;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const DocumentCard({
    super.key,
    required this.doc,
    this.course,
    this.onTap,
    this.onDelete,
  });

  String _getTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.assignment:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tham khảo';
      case DocumentType.exam:
        return 'Đề thi';
    }
  }

  Color _getStatusColor(ReadStatus status) {
    switch (status) {
      case ReadStatus.completed:
        return Colors.green;
      case ReadStatus.reading:
        return Colors.orange;
      case ReadStatus.unread:
        return Colors.grey;
    }
  }

  String _getStatusLabel(ReadStatus status) {
    switch (status) {
      case ReadStatus.completed:
        return 'Đã xong';
      case ReadStatus.reading:
        return 'Đang đọc';
      case ReadStatus.unread:
        return 'Chưa đọc';
    }
  }

  // Hàm thông minh nhận diện và mở file / xem trước ảnh từ đường dẫn
  Future<void> _openDocumentOrImage(BuildContext context, String path) async {
    final lower = path.toLowerCase().trim();

    // 1. Trường hợp là Ảnh (Link web hoặc Data URL Base64)
    if (lower.startsWith('data:image/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp')) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        doc.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: lower.startsWith('data:image/')
                            ? Image.memory(
                                base64Decode(path.split(',').last),
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Text('Lỗi tải ảnh', style: TextStyle(color: Colors.white)),
                              )
                            : Image.network(
                                path,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Text('Lỗi tải ảnh', style: TextStyle(color: Colors.white)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 2. Trường hợp là Đường dẫn Web thông thường (Google Drive, Docs, Web link)
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.parse(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở liên kết này')),
          );
        }
      }
      return;
    }

    // 3. Trường hợp là Data URL PDF / Tệp nhị phân
    if (lower.startsWith('data:')) {
      final uri = Uri.parse(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tệp đính kèm'),
            content: Text('Tệp tin đã được lưu trữ an toàn trong tài liệu "${doc.title}".'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ĐÓNG')),
            ],
          ),
        );
      }
      return;
    }

    // Trường hợp khác
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đường dẫn: $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(doc.status);
    final hasFile = doc.filePath != null && doc.filePath!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (course != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(course!.colorValue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course!.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTypeLabel(doc.type),
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Xóa',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                doc.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (doc.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  doc.note,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusLabel(doc.status),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (hasFile)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        backgroundColor: const Color(0xFF1E3C72).withOpacity(0.08),
                        foregroundColor: const Color(0xFF1E3C72),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Mở tài liệu / Xem ảnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _openDocumentOrImage(context, doc.filePath!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
