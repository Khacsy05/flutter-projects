import 'package:flutter/material.dart';
import 'package:btth1/services/cloud_document_service.dart';

class UserPreferenceDialog extends StatefulWidget {
  final UserPreference preference;
  final VoidCallback onSaved;

  const UserPreferenceDialog({
    super.key,
    required this.preference,
    required this.onSaved,
  });

  @override
  State<UserPreferenceDialog> createState() => _UserPreferenceDialogState();
}

class _UserPreferenceDialogState extends State<UserPreferenceDialog> {
  late List<String> _selectedTags;
  late List<String> _selectedCourses;
  final _customTagController = TextEditingController();
  bool _isSaving = false;

  final List<String> _popularTags = [
    'flutter',
    'mobile',
    'database',
    'sqlite',
    'ai',
    'machine-learning',
    'network',
    'backend',
    'exam',
    'slide',
    'assignment',
    'security',
    'react',
    'cloud',
  ];

  final List<String> _allCourses = [
    'Lập trình di động',
    'Cấu trúc dữ liệu',
    'Trí tuệ nhân tạo',
    'Cơ sở dữ liệu',
    'Mạng máy tính',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.preference.favoriteTags);
    _selectedCourses = List.from(widget.preference.preferredCourses);
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _addCustomTag() {
    final text = _customTagController.text.trim().toLowerCase().replaceAll('#', '');
    if (text.isNotEmpty && !_selectedTags.contains(text)) {
      setState(() {
        _selectedTags.add(text);
        _customTagController.clear();
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final updated = widget.preference.copyWith(
      favoriteTags: _selectedTags,
      preferredCourses: _selectedCourses,
      updatedAt: DateTime.now(),
    );

    await CloudDocumentService.saveUserPreference(updated);
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hồ sơ sở thích! Thuật toán đã tối ưu lại danh sách gợi ý.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF1E3C72)),
          SizedBox(width: 8),
          Text('Tùy chỉnh Sở thích & Gợi ý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn các chủ đề và thẻ (tags) bạn quan tâm để hệ thống tự động đề xuất tài liệu phù hợp nhất:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),

              // Thẻ sở thích
              const Text('Thẻ quan tâm (Favorite Tags):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: {
                  ..._popularTags,
                  ..._selectedTags,
                }.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text('#$tag'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1E3C72).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF1E3C72),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF1E3C72) : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Thêm thẻ tự tạo
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagController,
                      decoration: InputDecoration(
                        hintText: 'Thêm thẻ mới (vd: react, docker)...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _addCustomTag,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Môn học ưu tiên
              const Text('Môn học ưu tiên (Preferred Courses):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _allCourses.map((c) {
                  final isSelected = _selectedCourses.contains(c);
                  return FilterChip(
                    label: Text(c),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade50,
                    checkmarkColor: Colors.teal.shade800,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.teal.shade900 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCourses.add(c);
                        } else {
                          _selectedCourses.remove(c);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3C72),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('LƯU & ÁP DỤNG'),
        ),
      ],
    );
  }
}
