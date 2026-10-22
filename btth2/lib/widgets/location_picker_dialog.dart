import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerDialog extends StatefulWidget {
  final String? initialLocationName;
  final double? initialLat;
  final double? initialLng;
  final String? initialRoomShelf;

  const LocationPickerDialog({
    super.key,
    this.initialLocationName,
    this.initialLat,
    this.initialLng,
    this.initialRoomShelf,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _roomShelfController;
  late LatLng _selectedPoint;
  final MapController _mapController = MapController();

  static const LatLng defaultCampus = LatLng(10.762622, 106.682334);

  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Thư viện Cơ sở 1 (KHTN - Q5)',
      'lat': 10.762622,
      'lng': 106.682334,
    },
    {
      'name': 'Thư viện Trung tâm ĐHQG (Thủ Đức)',
      'lat': 10.870024,
      'lng': 106.803097,
    },
    {
      'name': 'Phòng Lab Trí tuệ Nhân tạo & Di động',
      'lat': 10.762950,
      'lng': 106.682850,
    },
    {
      'name': 'Ký túc xá Sinh viên ĐHQG (Khu A)',
      'lat': 10.878500,
      'lng': 106.806200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialLocationName ?? 'Thư viện Cơ sở 1 (KHTN - Q5)');
    _roomShelfController = TextEditingController(text: widget.initialRoomShelf ?? 'Kệ A2 - Tầng 2');
    _selectedPoint = widget.initialLat != null && widget.initialLng != null
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : defaultCampus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomShelfController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'];
      _selectedPoint = LatLng(preset['lat'], preset['lng']);
      _mapController.move(_selectedPoint, 16.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: Color(0xFF1E3C72), size: 24),
                  const SizedBox(width: 8),
                  const Text('Chọn vị trí lưu trữ vật lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),

              // Gợi ý địa điểm quen thuộc
              const Text('Địa điểm mẫu trong khuôn viên:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _presets.map((p) {
                    final isCurrent = _nameController.text == p['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: Icon(Icons.business, size: 14, color: isCurrent ? Colors.white : const Color(0xFF1E3C72)),
                        label: Text(p['name']),
                        backgroundColor: isCurrent ? const Color(0xFF1E3C72) : Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isCurrent ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        onPressed: () => _applyPreset(p),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Bản đồ trực quan để chọn vị trí
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedPoint,
                          initialZoom: 15.0,
                          onTap: (_, point) {
                            setState(() => _selectedPoint = point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.study.btth1',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPoint,
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 42,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Chạm vào bản đồ để chọn tọa độ: (${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nhập tên địa điểm & Kệ / Phòng
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên địa điểm / Tòa nhà',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _roomShelfController,
                      decoration: const InputDecoration(
                        labelText: 'Phòng / Kệ sách',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút hoàn tất
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'locationName': _nameController.text.trim(),
                        'latitude': _selectedPoint.latitude,
                        'longitude': _selectedPoint.longitude,
                        'roomShelf': _roomShelfController.text.trim(),
                      });
                    },
                    child: const Text('XÁC NHẬN VỊ TRÍ'),
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
