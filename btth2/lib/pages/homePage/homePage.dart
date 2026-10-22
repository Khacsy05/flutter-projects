import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:btth1/services/cloud_document_service.dart';
import 'package:btth1/services/recommendation_service.dart';
import 'package:btth1/services/notification_service.dart';
import 'package:btth1/widgets/cloud_document_card.dart';
import 'package:btth1/widgets/document_map_view.dart';
import 'package:btth1/widgets/user_preference_dialog.dart';
import 'package:btth1/pages/addDocumentPage.dart';
import 'package:btth1/pages/borrow_management_page.dart';
import 'package:btth1/pages/loginPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedCourseFilter;
  String? _selectedTagFilter;
  int _activeNavIndex = 0; // 0: Tất cả, 1: Của tôi, 2: Chia sẻ, 3: Gợi ý AI, 4: Bản đồ vị trí

  bool _isLoading = true;
  List<CloudDoc> _documents = [];
  List<CloudDoc> _allSystemDocs = [];
  UserPreference? _userPreference;
  List<RecommendationResult> _recommendations = [];

  final List<String> _courses = [
    'Lập trình di động',
    'Cấu trúc dữ liệu',
    'Trí tuệ nhân tạo',
    'Cơ sở dữ liệu',
    'Mạng máy tính',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final docs = await CloudDocumentService.fetchDocuments(
        searchQuery: _searchQuery,
        courseFilter: _selectedCourseFilter,
        tagFilter: _selectedTagFilter,
      );
      final systemDocs = await CloudDocumentService.fetchAllPublicDocuments();
      final pref = await CloudDocumentService.fetchUserPreference();

      final recs = RecommendationService.computeRecommendations(
        allDocuments: systemDocs.isNotEmpty ? systemDocs : docs,
        preference: pref,
        currentUserId: user?.uid,
      );

      if (mounted) {
        setState(() {
          _documents = docs;
          _allSystemDocs = systemDocs;
          _userPreference = pref;
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu Cloud: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDelete(CloudDoc doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn tài liệu "${doc.title}" trên Supabase?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HỦY')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('XÓA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CloudDocumentService.deleteDocument(doc.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài liệu thành công!'), backgroundColor: Colors.green),
          );
        }
        _loadAllData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể xóa: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final notifs = NotificationService.allNotifications;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Color(0xFF1E3C72)),
                      const SizedBox(width: 8),
                      const Text(
                        'Thông báo Hoạt động & Mượn trả',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      if (notifs.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            NotificationService.markAllAsRead();
                            setSheetState(() {});
                            setState(() {});
                          },
                          child: const Text('Đã đọc tất cả', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: notifs.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Chưa có thông báo mới', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: notifs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final item = notifs[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: item.isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                                  child: Icon(
                                    item.type.contains('borrow') ? Icons.front_hand_rounded : Icons.info_outline,
                                    color: const Color(0xFF1E3C72),
                                    size: 20,
                                  ),
                                ),
                                title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold)),
                                subtitle: Text(item.message, style: const TextStyle(fontSize: 12)),
                                trailing: Text(
                                  '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                onTap: () {
                                  NotificationService.markAsRead(item.id);
                                  setSheetState(() {});
                                  setState(() {});
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPreferenceDialog() {
    if (_userPreference == null) return;
    showDialog(
      context: context,
      builder: (ctx) => UserPreferenceDialog(
        preference: _userPreference!,
        onSaved: _loadAllData,
      ),
    );
  }

  List<String> get _allTags {
    final set = <String>{};
    for (final doc in _documents) {
      set.addAll(doc.tags);
    }
    for (final doc in _allSystemDocs) {
      set.addAll(doc.tags);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Lọc theo Tab đang chọn
    List<CloudDoc> displayDocs = _documents;
    if (_activeNavIndex == 1) {
      displayDocs = displayDocs.where((d) => d.isOwner).toList();
    } else if (_activeNavIndex == 2) {
      displayDocs = displayDocs.where((d) => !d.isOwner).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.folder_shared_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Quản lý Tài liệu Đa nền tảng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          // Nút Quản lý Mượn/Trả
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Quản lý Mượn / Trả',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BorrowManagementPage()),
              ).then((_) => _loadAllData());
            },
          ),

          // Nút Chuông Thông báo
          StreamBuilder<List<InAppNotification>>(
            stream: NotificationService.notificationStream,
            builder: (context, snapshot) {
              final unread = NotificationService.unreadCount;
              return Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: IconButton(
                  icon: const Icon(Icons.notifications_rounded),
                  tooltip: 'Thông báo',
                  onPressed: _showNotificationSheet,
                ),
              );
            },
          ),

          // Nút Tải lại dữ liệu
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadAllData,
          ),

          // Tài khoản Menu
          if (user != null)
            PopupMenuButton<String>(
              tooltip: 'Tài khoản',
              icon: CircleAvatar(
                radius: 16,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person, size: 20) : null,
              ),
              onSelected: (val) async {
                if (val == 'pref') {
                  _showPreferenceDialog();
                } else if (val == 'borrow') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BorrowManagementPage()));
                } else if (val == 'logout') {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName ?? 'Sinh viên', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(user.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'pref',
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF1E3C72), size: 18),
                      SizedBox(width: 8),
                      Text('Tùy chỉnh gợi ý AI'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'borrow',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.teal, size: 18),
                      SizedBox(width: 8),
                      Text('Quản lý Mượn / Trả'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),

      // Thanh điều hướng chính (Top Navigation Bar)
      body: Column(
        children: [
          // Top Navigation Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavChip(0, 'Tất cả (${_documents.length})', Icons.folder_open_rounded),
                  _buildNavChip(1, 'Của tôi', Icons.person_outline),
                  _buildNavChip(2, 'Được chia sẻ', Icons.people_alt_outlined),
                  _buildNavChip(3, 'Gợi ý AI (${_recommendations.length})', Icons.auto_awesome, badgeColor: Colors.amber),
                  _buildNavChip(4, 'Bản đồ vị trí', Icons.map_rounded),
                ],
              ),
            ),
          ),

          // Thanh Tìm kiếm & Lọc (hiển thị khi ở các tab danh sách)
          if (_activeNavIndex != 4)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo tên, tag, môn học, vị trí...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() => _searchQuery = '');
                                      _loadAllData();
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            fillColor: const Color(0xFFF8F9FA),
                            filled: true,
                          ),
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                            _loadAllData();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dropdown lọc môn học
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCourseFilter,
                            hint: const Text('Môn học', style: TextStyle(fontSize: 13)),
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Tất cả môn học', style: TextStyle(fontSize: 13))),
                              ..._courses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedCourseFilter = val);
                              _loadAllData();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Thanh cuộn chọn Tags nếu có
                  if (_allTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả tags', style: TextStyle(fontSize: 11)),
                            selected: _selectedTagFilter == null,
                            onSelected: (_) {
                              setState(() => _selectedTagFilter = null);
                              _loadAllData();
                            },
                          ),
                          const SizedBox(width: 6),
                          ..._allTags.map((t) {
                            final isSelected = _selectedTagFilter == t;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text('#$t', style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                selectedColor: const Color(0xFF1E3C72).withOpacity(0.15),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFF1E3C72) : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  setState(() => _selectedTagFilter = val ? t : null);
                                  _loadAllData();
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Nội dung chính
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildActiveContentView(displayDocs, isDesktop, isTablet),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDocumentPage()),
          );
          if (res == true) _loadAllData();
        },
      ),
    );
  }

  Widget _buildNavChip(int index, String label, IconData icon, {Color? badgeColor}) {
    final isSelected = _activeNavIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : (badgeColor ?? const Color(0xFF1E3C72)),
        ),
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF1E3C72),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (val) {
          if (val) setState(() => _activeNavIndex = index);
        },
      ),
    );
  }

  Widget _buildActiveContentView(List<CloudDoc> docs, bool isDesktop, bool isTablet) {
    // 1. Tab Bản đồ vị trí
    if (_activeNavIndex == 4) {
      return DocumentMapView(
        documents: _allSystemDocs.isNotEmpty ? _allSystemDocs : _documents,
        onDocumentSelected: (selected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddDocumentPage(document: selected)),
          ).then((_) => _loadAllData());
        },
      );
    }

    // 2. Tab Gợi ý thông minh (AI Recommendations)
    if (_activeNavIndex == 3) {
      return _buildRecommendationView(isDesktop, isTablet);
    }

    // 3. Tab Danh sách thông thường (Tất cả / Của tôi / Được chia sẻ)
    if (docs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty ? 'Không tìm thấy tài liệu phù hợp từ khóa' : 'Chưa có tài liệu nào trong danh mục này',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Responsive Grid trên Desktop / Tablet và ListView trên Mobile
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    if (crossAxisCount == 1) {
      return RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            return CloudDocumentCard(
              doc: doc,
              onRefresh: _loadAllData,
              onEdit: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddDocumentPage(document: doc)),
                );
                if (res == true) _loadAllData();
              },
              onDelete: () => _handleDelete(doc),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 330,
        ),
        itemCount: docs.length,
        itemBuilder: (ctx, i) {
          final doc = docs[i];
          return CloudDocumentCard(
            doc: doc,
            onRefresh: _loadAllData,
            onEdit: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddDocumentPage(document: doc)),
              );
              if (res == true) _loadAllData();
            },
            onDelete: () => _handleDelete(doc),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationView(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        // Banner thuật toán đề xuất
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.blue.shade900.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thuật toán Gợi ý Cá nhân hóa (Recommendation Engine)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phân tích chỉ số Jaccard Similarity trên tập Tag, độ tương thích môn học và lịch sử đọc để đề xuất tài liệu tối ưu nhất cho bạn.',
                      style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3C72),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Tùy chỉnh'),
                onPressed: _showPreferenceDialog,
              ),
            ],
          ),
        ),

        // Danh sách các mục được gợi ý
        Expanded(
          child: _recommendations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có đủ dữ liệu để xếp hạng gợi ý.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _showPreferenceDialog,
                        child: const Text('Chọn thẻ & môn học yêu thích ngay'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: _recommendations.length,
                  itemBuilder: (ctx, i) {
                    final item = _recommendations[i];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Huy hiệu Match Score %
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.stars_rounded, size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.matchPercentage}% Phù hợp',
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.document.courseName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3C72)),
                                ),
                                const Spacer(),
                                if (item.document.isPhysical)
                                  const Chip(
                                    label: Text('Bản cứng vật lý', style: TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Tiêu đề
                            Text(
                              item.document.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),

                            // Lý do đề xuất
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: item.matchingReasons.map((r) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, size: 13, color: Colors.teal),
                                    const SizedBox(width: 4),
                                    Text(r, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  ],
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),
                            // Thẻ CloudDocumentCard nhúng nội dung
                            CloudDocumentCard(
                              doc: item.document,
                              onRefresh: _loadAllData,
                              onEdit: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddDocumentPage(document: item.document)),
                                );
                                if (res == true) _loadAllData();
                              },
                              onDelete: () => _handleDelete(item.document),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
