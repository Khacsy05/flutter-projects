import 'package:flutter/material.dart';
import 'package:btth1/services/cloud_document_service.dart';

class ShareDocumentDialog extends StatefulWidget {
  final CloudDoc doc;

  const ShareDocumentDialog({super.key, required this.doc});

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final _emailController = TextEditingController();
  String _selectedPermission = 'view';
  bool _isLoading = false;
  List<Map<String, dynamic>> _sharedUsers = [];
  bool _isLoadingList = true;

  @override
  void initState() {
    super.initState();
    _loadSharedUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedUsers() async {
    try {
      final list = await CloudDocumentService.getDocumentSharedUsers(widget.doc.id);
      if (mounted) {
        setState(() {
          _sharedUsers = list;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _handleShare() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email người nhận!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await CloudDocumentService.shareDocument(
        documentId: widget.doc.id,
        targetEmail: email,
        permissionLevel: _selectedPermission,
      );

      _emailController.clear();
      await _loadSharedUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cấp quyền "${_selectedPermission == 'edit' ? 'Được sửa' : 'Chỉ xem'}" cho $email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePermission(String permissionId, String newPerm, String email) async {
    try {
      await CloudDocumentService.updateSharePermission(
        permissionId: permissionId,
        newPermissionLevel: newPerm,
      );
      await _loadSharedUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đổi quyền của $email thành "${newPerm == 'edit' ? 'Được sửa' : 'Chỉ xem'}"'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _revokeShare(String permissionId, String email) async {
    try {
      await CloudDocumentService.revokeShare(permissionId);
      await _loadSharedUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thu hồi quyền của $email'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thu hồi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.share_rounded, color: Color(0xFF1E3C72)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chia sẻ: ${widget.doc.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Thêm người nhận mới:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Nhập email sinh viên...',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: _selectedPermission,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'view', child: Text('Chỉ xem')),
                        DropdownMenuItem(value: 'edit', child: Text('Được sửa')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPermission = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleShare,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Cấp quyền chia sẻ'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Danh sách người đã được chia sẻ (Có thể đổi quyền hoặc thu hồi):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoadingList
                    ? const Center(child: CircularProgressIndicator())
                    : _sharedUsers.isEmpty
                        ? Center(
                            child: Text(
                              'Chưa chia sẻ cho ai.\nTài liệu này hiện chỉ có bạn xem được.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _sharedUsers.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (ctx, index) {
                              final item = _sharedUsers[index];
                              final profile = item['profiles'] as Map<String, dynamic>?;
                              final email = profile?['email'] ?? 'Không rõ';
                              final displayName = profile?['display_name'] ?? email;
                              final perm = (item['permission_level'] ?? 'view') as String;
                              final permId = item['id'] as String;

                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(displayName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Dropdown trực tiếp thay đổi quyền (Chỉ xem <-> Được sửa)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        value: perm,
                                        underline: const SizedBox.shrink(),
                                        isDense: true,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'view',
                                            child: Text('Chỉ xem', style: TextStyle(fontSize: 12)),
                                          ),
                                          DropdownMenuItem(
                                            value: 'edit',
                                            child: Text('Được sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                          ),
                                        ],
                                        onChanged: (newPerm) {
                                          if (newPerm != null && newPerm != perm) {
                                            _updatePermission(permId, newPerm, email);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      tooltip: 'Thu hồi quyền',
                                      onPressed: () => _revokeShare(permId, email),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
