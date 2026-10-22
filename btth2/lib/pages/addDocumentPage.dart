import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:btth1/services/cloud_document_service.dart';
import 'package:btth1/widgets/location_picker_dialog.dart';

class AddDocumentPage extends StatefulWidget {
  final CloudDoc? document;

  const AddDocumentPage({super.key, this.document});

  @override
  State<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _courseController;
  final _tagInputController = TextEditingController();

  final List<String> _courseSuggestions = [
    'Lập trình di động',
    'Cấu trúc dữ liệu',
    'Trí tuệ nhân tạo',
    'Cơ sở dữ liệu',
    'Mạng máy tính',
    'Khác',
  ];

  String _selectedType = 'lecture';
  final Map<String, String> _typeLabels = {
    'lecture': 'Bài giảng / Slide',
    'assignment': 'Bài tập / Đồ án',
    'reference': 'Tài liệu tham khảo',
    'exam': 'Đề thi / Đề cương',
  };

  // Tags & Phân loại
  List<String> _tags = [];
  final List<String> _suggestedTags = [
    'flutter',
    'mobile',
    'database',
    'sqlite',
    'ai',
    'exam',
    'slide',
    'network',
    'lab',
  ];

  // Định vị vật lý
  bool _isPhysical = false;
  String? _locationName;
  double? _latitude;
  double? _longitude;
  String? _roomShelf;

  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  String? _existingFileUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _noteController = TextEditingController(text: doc?.note ?? '');
    _courseController = TextEditingController(text: doc?.courseName ?? 'Lập trình di động');
    _selectedType = doc?.type ?? 'lecture';
    _existingFileUrl = doc?.fileUrl;
    _pickedFileName = doc?.fileName;

    if (doc != null) {
      _tags = List.from(doc.tags);
      _isPhysical = doc.isPhysical;
      _locationName = doc.locationName;
      _latitude = doc.latitude;
      _longitude = doc.longitude;
      _roomShelf = doc.roomShelf;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _courseController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final clean = raw.trim().toLowerCase().replaceAll('#', '');
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _tagInputController.clear();
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => LocationPickerDialog(
        initialLocationName: _locationName,
        initialLat: _latitude,
        initialLng: _longitude,
        initialRoomShelf: _roomShelf,
      ),
    );

    if (result != null) {
      setState(() {
        _locationName = result['locationName'];
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _roomShelf = result['roomShelf'];
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt', 'docx', 'doc', 'zip', 'pptx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Không thể đọc dữ liệu file!');
      }

      setState(() {
        _pickedFileBytes = file.bytes;
        _pickedFileName = file.name;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = file.name.split('.').first;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chọn file: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      String? fileUrl = _existingFileUrl;
      String? fileName = _pickedFileName;

      if (_pickedFileBytes != null && _pickedFileName != null) {
        fileUrl = CloudDocumentService.convertBytesToDataUrl(
          _pickedFileBytes!,
          _pickedFileName!,
        );
      }

      final isEdit = widget.document != null;
      if (isEdit) {
        await CloudDocumentService.updateDocument(
          documentId: widget.document!.id,
          title: _titleController.text,
          courseName: _courseController.text,
          note: _noteController.text,
          type: _selectedType,
          fileUrl: fileUrl,
          fileName: fileName,
          tags: _tags,
          isPhysical: _isPhysical,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
          roomShelf: _roomShelf,
        );
      } else {
        await CloudDocumentService.createDocument(
          title: _titleController.text,
          courseName: _courseController.text,
          note: _noteController.text,
          type: _selectedType,
          fileUrl: fileUrl,
          fileName: fileName,
          tags: _tags,
          isPhysical: _isPhysical,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
          roomShelf: _roomShelf,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Cập nhật tài liệu thành công!' : 'Đã tạo tài liệu và lưu Cloud!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu tài liệu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.document != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isEdit ? 'Chỉnh sửa Tài liệu' : 'Thêm mới Tài liệu Cloud'),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Lưu tài liệu',
            onPressed: _isUploading ? null : _handleSave,
          ),
        ],
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang đồng bộ dữ liệu lên Supabase Cloud...', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nhập tiêu đề
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề tài liệu *',
                        hintText: 'VD: Slide Bài giảng Tuần 1 - Flutter State',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF1E3C72)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 16),

                    // Môn học & Loại tài liệu
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _courseController,
                            decoration: InputDecoration(
                              labelText: 'Môn học / Học phần *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF1E3C72)),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập môn học' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              labelText: 'Phân loại',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _typeLabels.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Gợi ý nhanh môn học
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _courseSuggestions.map((c) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ActionChip(
                              label: Text(c, style: const TextStyle(fontSize: 11)),
                              onPressed: () => setState(() => _courseController.text = c),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // MỤC PHÂN LOẠI TAGS (GẮN THẺ TÀI LIỆU)
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.label_rounded, color: Color(0xFF1E3C72), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Thẻ phân loại (Tags)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Gắn thẻ để dễ dàng tìm kiếm và thuật toán AI tự động gợi ý cho người học phù hợp:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),

                          // Hiển thị các tag đã chọn
                          if (_tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _tags.map((t) {
                                  return Chip(
                                    label: Text('#$t', style: const TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold, fontSize: 12)),
                                    backgroundColor: const Color(0xFF1E3C72).withOpacity(0.1),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () => setState(() => _tags.remove(t)),
                                  );
                                }).toList(),
                              ),
                            ),

                          // Ô nhập tag tự do
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagInputController,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập tên thẻ rồi bấm Thêm (VD: exam, slide, clean-code)...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    isDense: true,
                                  ),
                                  onSubmitted: (v) => _addTag(v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3C72),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _addTag(_tagInputController.text),
                                child: const Text('Thêm thẻ'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Gợi ý tag phổ biến
                          Wrap(
                            spacing: 6,
                            children: _suggestedTags.map((st) {
                              final isAdded = _tags.contains(st);
                              return ActionChip(
                                label: Text('+#$st', style: TextStyle(fontSize: 11, color: isAdded ? Colors.grey : const Color(0xFF1E3C72))),
                                onPressed: isAdded ? null : () => _addTag(st),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ==========================================
                    // MỤC ĐỊNH VỊ TÀI LIỆU VẬT LÝ & BẢN ĐỒ
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Tài liệu vật lý (Sách in / Giáo trình giấy / Kệ thư viện)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'Đánh dấu tài liệu có bản cứng thực tế để sinh viên có thể định vị và mượn trả',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _isPhysical,
                            activeColor: const Color(0xFF1E3C72),
                            onChanged: (val) {
                              setState(() {
                                _isPhysical = val;
                                if (_isPhysical && _locationName == null) {
                                  _locationName = 'Thư viện Cơ sở 1 (KHTN - Q5)';
                                  _latitude = 10.762622;
                                  _longitude = 106.682334;
                                  _roomShelf = 'Kệ A2 - Tầng 2';
                                }
                              });
                            },
                          ),

                          if (_isPhysical) ...[
                            const Divider(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.place_rounded, color: Colors.red, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _locationName ?? 'Chưa chọn địa điểm',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          'Vị trí lưu trữ: ${_roomShelf ?? "Chưa rõ kệ/phòng"}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                        ),
                                        if (_latitude != null && _longitude != null)
                                          Text(
                                            'Tọa độ: (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1E3C72),
                                      elevation: 1,
                                    ),
                                    icon: const Icon(Icons.map_rounded, size: 16),
                                    label: const Text('Bản đồ'),
                                    onPressed: _pickLocation,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Ghi chú
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú tóm tắt',
                        hintText: 'Nhập nội dung ngắn, lưu ý quan trọng...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF1E3C72)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tệp đính kèm
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.cloud_upload_rounded, color: Color(0xFF1E3C72)),
                              SizedBox(width: 8),
                              Text('Tệp tài liệu đính kèm (File Cloud)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_pickedFileName != null || _existingFileUrl != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF1E3C72)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _pickedFileName ?? 'Tệp tin đã lưu trên Cloud',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _pickedFileBytes = null;
                                        _pickedFileName = null;
                                        _existingFileUrl = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Chọn tệp từ thiết bị (PDF, Word, Ảnh, Zip...)'),
                              onPressed: _pickFile,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nút Lưu hoàn tất
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3C72),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      onPressed: _isUploading ? null : _handleSave,
                      child: Text(
                        isEdit ? 'LƯU THAY ĐỔI' : 'TẠO VÀ LƯU TÀI LIỆU CLOUD',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
