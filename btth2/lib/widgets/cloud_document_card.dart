import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:btth1/services/cloud_document_service.dart';
import 'package:btth1/widgets/share_document_dialog.dart';
import 'package:btth1/widgets/borrow_request_dialog.dart';

class CloudDocumentCard extends StatelessWidget {
  final CloudDoc doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRefresh;

  const CloudDocumentCard({
    super.key,
    required this.doc,
    required this.onEdit,
    required this.onDelete,
    this.onRefresh,
  });

  Future<void> _openFile(BuildContext context) async {
    if (doc.fileUrl == null || doc.fileUrl!.isEmpty) return;

    // Ghi nhận tương tác học tập
    CloudDocumentService.trackTagInteraction(doc.tags);

    final uri = Uri.parse(doc.fileUrl!);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở tệp tin này'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở tệp: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ShareDocumentDialog(doc: doc),
    );
  }

  void _showBorrowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => BorrowRequestDialog(doc: doc),
    ).then((val) {
      if (val == true && onRefresh != null) onRefresh!();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hàng 1: Môn học + Badges sở hữu & phân quyền (Sử dụng Wrap để tự động xuống dòng không bị tràn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3C72).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          doc.courseName,
                          style: const TextStyle(
                            color: Color(0xFF1E3C72),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (doc.isPhysical)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 12, color: Colors.brown),
                              SizedBox(width: 4),
                              Text(
                                'Bản cứng',
                                style: TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      if (doc.isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Của tôi',
                                style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: doc.permission == 'edit' ? Colors.orange.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: doc.permission == 'edit' ? Colors.orange.shade300 : Colors.green.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                doc.permission == 'edit' ? Icons.edit_note_rounded : Icons.visibility_rounded,
                                size: 12,
                                color: doc.permission == 'edit' ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doc.permission == 'edit'
                                    ? 'Được chia sẻ (Được sửa)'
                                    : (doc.permission == 'public_view' ? 'Thư viện chung' : 'Được chia sẻ (Chỉ xem)'),
                                style: TextStyle(
                                  color: doc.permission == 'edit' ? Colors.orange.shade900 : Colors.green.shade900,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${doc.updatedAt.day}/${doc.updatedAt.month}/${doc.updatedAt.year}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tiêu đề tài liệu
            Text(
              doc.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C3E50),
              ),
            ),

            if (!doc.isOwner && doc.ownerEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                'Chủ sở hữu: ${doc.ownerEmail}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ],

            // Địa chỉ vật lý nếu có
            if (doc.isPhysical && doc.locationName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_rounded, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${doc.locationName} ${doc.roomShelf != null ? "• ${doc.roomShelf}" : ""}',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],

            // Hiển thị danh sách Tags
            if (doc.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: doc.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Ghi chú
            if (doc.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                doc.note,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Tệp đính kèm
            if (doc.fileName != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openFile(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF1E3C72)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          doc.fileName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E3C72),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 8),

            // Nút hành động
            Row(
              children: [
                if (doc.isOwner) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3C72),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Chia sẻ', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showShareDialog(context),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.front_hand_rounded, size: 14),
                    label: const Text('Yêu cầu mượn'),
                    onPressed: () => _showBorrowDialog(context),
                  ),
                ],

                const Spacer(),

                if (doc.canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                    tooltip: 'Chỉnh sửa tài liệu',
                    onPressed: onEdit,
                  ),

                if (doc.isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Xóa tài liệu',
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
