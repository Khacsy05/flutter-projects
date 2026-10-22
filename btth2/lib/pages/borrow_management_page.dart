import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:btth1/services/cloud_document_service.dart';

class BorrowManagementPage extends StatefulWidget {
  const BorrowManagementPage({super.key});

  @override
  State<BorrowManagementPage> createState() => _BorrowManagementPageState();
}

class _BorrowManagementPageState extends State<BorrowManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<BorrowRequest> _sentRequests = [];
  List<BorrowRequest> _receivedRequests = [];

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final sent = await CloudDocumentService.fetchSentBorrowRequests();
      final received = await CloudDocumentService.fetchReceivedBorrowRequests();
      if (mounted) {
        setState(() {
          _sentRequests = sent;
          _receivedRequests = received;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách mượn/trả: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleUpdateStatus(BorrowRequest req, String newStatus) async {
    try {
      await CloudDocumentService.updateBorrowStatus(
        requestId: req.id,
        newStatus: newStatus,
        request: req,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'approved'
                ? 'Đã duyệt cho mượn tài liệu!'
                : (newStatus == 'rejected' ? 'Đã từ chối yêu cầu mượn.' : 'Đã xác nhận trả tài liệu!')),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.blue,
          ),
        );
      }
      _loadRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thao tác thất bại: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusBadge(BorrowRequest req) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    if (req.isOverdue) {
      bg = Colors.red.shade100;
      text = Colors.red.shade900;
      label = 'QUÁ HẠN TRẢ';
      icon = Icons.warning_amber_rounded;
    } else {
      switch (req.status) {
        case 'approved':
          bg = Colors.green.shade100;
          text = Colors.green.shade900;
          label = 'Đang mượn (Đã duyệt)';
          icon = Icons.check_circle_outline;
          break;
        case 'rejected':
          bg = Colors.grey.shade200;
          text = Colors.grey.shade700;
          label = 'Đã từ chối';
          icon = Icons.cancel_outlined;
          break;
        case 'returned':
          bg = Colors.blue.shade100;
          text = Colors.blue.shade900;
          label = 'Đã trả hoàn tất';
          icon = Icons.assignment_turned_in_outlined;
          break;
        case 'pending':
        default:
          bg = Colors.amber.shade100;
          text = Colors.amber.shade900;
          label = 'Chờ duyệt';
          icon = Icons.hourglass_top_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BorrowRequest req, {required bool isReceived}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    req.documentTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3C72)),
                  ),
                ),
                _buildStatusBadge(req),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(isReceived ? Icons.person_outline : Icons.person_pin, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  isReceived ? 'Người yêu cầu: ${req.requesterEmail}' : 'Chủ tài liệu: ${req.ownerEmail ?? "Cộng đồng"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.date_range, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Từ ${_dateFormat.format(req.borrowDate)} đến ${_dateFormat.format(req.dueDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            if (req.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lời nhắn: "${req.note}"',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Nút thao tác tương ứng
            if (isReceived && req.isPending) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Từ chối'),
                    onPressed: () => _handleUpdateStatus(req, 'rejected'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Phê duyệt'),
                    onPressed: () => _handleUpdateStatus(req, 'approved'),
                  ),
                ],
              ),
            ] else if (isReceived && req.isApproved) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.assignment_turned_in, size: 16),
                    label: const Text('Xác nhận đã nhận lại tài liệu'),
                    onPressed: () => _handleUpdateStatus(req, 'returned'),
                  ),
                ],
              ),
            ] else if (!isReceived && req.isApproved) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                    icon: const Icon(Icons.keyboard_return, size: 16),
                    label: const Text('Đã trả tài liệu cho chủ sở hữu'),
                    onPressed: () => _handleUpdateStatus(req, 'returned'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản lý Mượn & Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.outbox_rounded),
              text: 'Yêu cầu đã gửi (${_sentRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.move_to_inbox_rounded),
              text: 'Yêu cầu nhận được (${_receivedRequests.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Yêu cầu đã gửi
                RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: _sentRequests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Bạn chưa gửi yêu cầu mượn tài liệu nào', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: _sentRequests.length,
                          itemBuilder: (ctx, i) => _buildRequestCard(_sentRequests[i], isReceived: false),
                        ),
                ),

                // Tab 2: Yêu cầu nhận được
                RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: _receivedRequests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Chưa có ai gửi yêu cầu mượn tài liệu của bạn', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: _receivedRequests.length,
                          itemBuilder: (ctx, i) => _buildRequestCard(_receivedRequests[i], isReceived: true),
                        ),
                ),
              ],
            ),
    );
  }
}
