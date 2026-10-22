import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:btth1/services/cloud_document_service.dart';

class BorrowRequestDialog extends StatefulWidget {
  final CloudDoc doc;

  const BorrowRequestDialog({super.key, required this.doc});

  @override
  State<BorrowRequestDialog> createState() => _BorrowRequestDialogState();
}

class _BorrowRequestDialogState extends State<BorrowRequestDialog> {
  final _messageController = TextEditingController(text: 'Chào bạn, mình muốn mượn tài liệu này để phục vụ nghiên cứu và ôn tập.');
  late DateTime _borrowDate;
  late DateTime _dueDate;
  bool _isSubmitting = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _borrowDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickBorrowDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _borrowDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _borrowDate = picked;
        if (_dueDate.isBefore(_borrowDate)) {
          _dueDate = _borrowDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _borrowDate,
      lastDate: _borrowDate.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    try {
      await CloudDocumentService.createBorrowRequest(
        doc: widget.doc,
        borrowDate: _borrowDate,
        dueDate: _dueDate,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu mượn thành công! Vui lòng chờ phản hồi từ chủ sở hữu.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E3C72),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Row(
          children: [
            Icon(Icons.front_hand_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Yêu cầu Mượn Tài liệu',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin tài liệu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doc.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3C72)),
                  ),
                  const SizedBox(height: 4),
                  Text('Môn học: ${widget.doc.courseName}', style: const TextStyle(fontSize: 12)),
                  if (widget.doc.ownerEmail != null)
                    Text('Chủ sở hữu: ${widget.doc.ownerEmail}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (widget.doc.isPhysical) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.doc.locationName ?? "Thư viện"} (${widget.doc.roomShelf ?? "Kệ chung"})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chọn ngày mượn & ngày trả
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickBorrowDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Ngày mượn',
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      child: Text(_dateFormat.format(_borrowDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Hạn trả',
                        prefixIcon: const Icon(Icons.event, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      child: Text(_dateFormat.format(_dueDate), style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Lời nhắn mượn
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Lời nhắn gửi chủ tài liệu',
                hintText: 'Nhập mục đích hoặc thỏa thuận mượn trả...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('HỦY'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3C72),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSubmitting ? null : _submitRequest,
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('GỬI YÊU CẦU'),
        ),
      ],
    );
  }
}
