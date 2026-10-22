import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:btth1/models/cloud_document.dart';
import 'package:btth1/widgets/borrow_request_dialog.dart';

class DocumentMapView extends StatefulWidget {
  final List<CloudDoc> documents;
  final Function(CloudDoc) onDocumentSelected;

  const DocumentMapView({
    super.key,
    required this.documents,
    required this.onDocumentSelected,
  });

  @override
  State<DocumentMapView> createState() => _DocumentMapViewState();
}

class _DocumentMapViewState extends State<DocumentMapView> {
  final MapController _mapController = MapController();
  CloudDoc? _selectedDoc;
  String _locationFilter = 'all';

  // Tọa độ trung tâm mặc định: Khu đô thị ĐHQG / Đại học KHTN TP.HCM
  static const LatLng defaultCenter = LatLng(10.762622, 106.682334);

  List<CloudDoc> get _physicalDocs {
    var list = widget.documents.where((d) => d.isPhysical).toList();
    if (_locationFilter != 'all') {
      list = list.where((d) => (d.locationName ?? '').contains(_locationFilter)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final physicalDocs = _physicalDocs;

    return Column(
      children: [
        // Thanh công cụ bộ lọc địa điểm
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF1E3C72), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tài liệu vật lý (${physicalDocs.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _locationFilter == 'all',
                    onSelected: (val) => setState(() => _locationFilter = 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('Thư viện'),
                    selected: _locationFilter == 'Thư viện',
                    onSelected: (val) => setState(() => _locationFilter = val ? 'Thư viện' : 'all'),
                  ),
                  ChoiceChip(
                    label: const Text('Phòng Lab'),
                    selected: _locationFilter == 'Lab',
                    onSelected: (val) => setState(() => _locationFilter = val ? 'Lab' : 'all'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bản đồ tương tác
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: physicalDocs.isNotEmpty && physicalDocs.first.latitude != null
                      ? LatLng(physicalDocs.first.latitude!, physicalDocs.first.longitude!)
                      : defaultCenter,
                  initialZoom: 15.0,
                  onTap: (_, __) {
                    if (_selectedDoc != null) {
                      setState(() => _selectedDoc = null);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.study.btth1',
                  ),
                  MarkerLayer(
                    markers: physicalDocs.map((doc) {
                      final lat = doc.latitude ?? defaultCenter.latitude;
                      final lng = doc.longitude ?? defaultCenter.longitude;
                      final isSelected = _selectedDoc?.id == doc.id;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: isSelected ? 60 : 45,
                        height: isSelected ? 60 : 45,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedDoc = doc);
                            _mapController.move(LatLng(lat, lng), 16.0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE53935) : const Color(0xFF1E3C72),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              isSelected ? Icons.menu_book_rounded : Icons.location_pin,
                              color: Colors.white,
                              size: isSelected ? 30 : 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Điều khiển thu phóng (+ / -)
              Positioned(
                right: 16,
                top: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3C72),
                      onPressed: () {
                        final z = _mapController.camera.zoom + 1;
                        _mapController.move(_mapController.camera.center, z);
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3C72),
                      onPressed: () {
                        final z = _mapController.camera.zoom - 1;
                        _mapController.move(_mapController.camera.center, z);
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),

              // Card thông tin tài liệu được chọn ghim ở dưới đáy bản đồ
              if (_selectedDoc != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3C72).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedDoc!.courseName,
                                  style: const TextStyle(
                                    color: Color(0xFF1E3C72),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 12, color: Colors.brown),
                                    SizedBox(width: 4),
                                    Text('Bản cứng vật lý', style: TextStyle(fontSize: 11, color: Colors.brown)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => _selectedDoc = null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedDoc!.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_rounded, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${_selectedDoc!.locationName ?? "Chưa rõ vị trí"} ${_selectedDoc!.roomShelf != null ? "• Kệ ${_selectedDoc!.roomShelf}" : ""}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text('Xem chi tiết'),
                                  onPressed: () {
                                    widget.onDocumentSelected(_selectedDoc!);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3C72),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.front_hand_rounded, size: 16),
                                  label: const Text('Mượn tài liệu'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => BorrowRequestDialog(doc: _selectedDoc!),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
