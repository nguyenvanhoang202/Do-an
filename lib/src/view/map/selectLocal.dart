import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';

class SelectLocation extends StatefulWidget {
  final String storeId;

  const SelectLocation({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  State<SelectLocation> createState() => _SelectLocationState();
}

class _SelectLocationState extends State<SelectLocation> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  LatLng? _selectedLocation;
  final List<Marker> _markers = [];
  final MapController _mapController = MapController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  //yêu cầu quyền truy cập vị trí, lấy vị trí hiện tại, cập nhật marker và di chuyển bản đồ.
  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final permission = await Permission.location.request();

    if (permission.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final location = LatLng(position.latitude, position.longitude);

        if (!mounted) return;

        setState(() {
          _selectedLocation = location;
          _markers.clear();
          _markers.add(
            Marker(
              point: location,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          );
          _isLoading = false;
        });

        _mapController.move(location, 15); // Di chuyển bản đồ đến vị trí mới
      } catch (e) {
        debugPrint('Lỗi khi lấy vị trí: $e');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
  //Xử lý khi chạm vào bản đồ, cập nhật vị trí được chọn và marker.
  void _handleTapMap(TapPosition tapPosition, LatLng point) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = point;
      _markers.clear();
      _markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });
  }
  // Lưu tọa độ vị trí được chọn vào Firebase
  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    try {
      await _database.child('stores').child(widget.storeId).child('local').set({
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật vị trí thành công!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('Lỗi khi lưu vị trí: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lỗi khi cập nhật vị trí!'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true, // Đảm bảo vùng trên cùng không bị che bởi thanh trạng thái
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 10),
                        child: Text(
                          'Chọn vị trí cửa hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:10),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation ?? const LatLng(0, 0),
                          initialZoom: 14,
                          onTap: _handleTapMap,
                          maxZoom: 18,
                          minZoom: 10,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                            maxZoom: 18,
                            minZoom: 10,
                          ),
                          MarkerLayer(
                            markers: _markers,
                          ),
                        ],
                      ),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: constraints.maxWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: _selectedLocation == null ? null : _saveLocation,
                          child: const Text(
                            'Xác nhận vị trí',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.my_location, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}