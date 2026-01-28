import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/custom_button.dart';

class StoreLocationPickerView extends StatefulWidget {
  const StoreLocationPickerView({Key? key}) : super(key: key);

  @override
  State<StoreLocationPickerView> createState() => _StoreLocationPickerViewState();
}

class _StoreLocationPickerViewState extends State<StoreLocationPickerView> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _isLoading = true;

  // デフォルトの座標（東京駅周辺）
  static const LatLng _defaultLocation = LatLng(35.6812, 139.7671);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _ensureLocationPermission();
    await _getCurrentLocation();

    _selectedLocation = _currentLocation ?? _defaultLocation;

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedLocation == null) {
        return;
      }
      _mapController.move(_selectedLocation!, 15.0);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // 位置情報取得に失敗しても地図表示は続行する
    }
  }

  Future<void> _ensureLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) {
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await _showPermissionDialog();
      }
    } catch (e) {
      // 権限確認に失敗しても画面は表示する
    }
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('位置情報の許可が必要です'),
          content: const Text('端末の設定から位置情報の権限を許可してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('設定を開く'),
            ),
          ],
        );
      },
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  void _onCurrentLocationPressed() async {
    await _getCurrentLocation();
    if (_currentLocation == null) {
      return;
    }

    setState(() {
      _selectedLocation = _currentLocation;
    });
    _mapController.move(_currentLocation!, 15.0);
  }

  void _onConfirmPressed() {
    if (_selectedLocation == null) {
      return;
    }
    Navigator.of(context).pop(_selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '店舗位置情報',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation ?? _defaultLocation,
                          initialZoom: 15.0,
                          onTap: _onMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.groumap.groumapappstore',
                            subdomains: const ['a', 'b', 'c'],
                            additionalOptions: const {
                              'attribution': '&copy; OpenStreetMap contributors',
                            },
                          ),
                          MarkerLayer(
                            markers: [
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                ),
                              if (_selectedLocation != null)
                                Marker(
                                  point: _selectedLocation!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          heroTag: 'current_location_picker',
                          onPressed: _onCurrentLocationPressed,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  color: Colors.white,
                  child: const Text(
                    '地図をタップして店舗の位置を設定してください。赤いピンが店舗の位置を示します。',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: _buildLocationInfoCard(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: CustomButton(
                    text: 'この位置を確定',
                    onPressed: _selectedLocation == null ? null : _onConfirmPressed,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationInfoCard() {
    if (_selectedLocation == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '位置情報が未設定です。',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '緯度: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '経度: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
