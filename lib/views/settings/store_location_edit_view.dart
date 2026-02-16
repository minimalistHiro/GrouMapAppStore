import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';

class StoreLocationEditView extends ConsumerStatefulWidget {
  final String? storeId;
  const StoreLocationEditView({Key? key, this.storeId}) : super(key: key);

  @override
  ConsumerState<StoreLocationEditView> createState() => _StoreLocationEditViewState();
}

class _StoreLocationEditViewState extends ConsumerState<StoreLocationEditView> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  String? _selectedStoreId;
  bool _isLoading = false;
  bool _isSaving = false;
  String _address = '';
  bool _mapReady = false;
  LatLng? _pendingMoveLocation;
  
  // デフォルトの座標（東京駅周辺）
  static const LatLng _defaultLocation = LatLng(35.6812, 139.7671);
  

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 店舗IDを取得
      final storeId = widget.storeId ?? ref.read(userStoreIdProvider).when(
        data: (data) => data,
        loading: () => null,
        error: (error, stackTrace) => null,
      );

      if (storeId == null) {
        throw Exception('店舗情報が見つかりません');
      }

      _selectedStoreId = storeId;

      // 店舗データを取得
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();

      if (storeDoc.exists) {
        final storeData = storeDoc.data()!;
        
        // 既存の位置情報を設定
        if (storeData['location'] != null) {
          final location = storeData['location'];
          if (location['latitude'] != null && location['longitude'] != null) {
            _selectedLocation = LatLng(
              location['latitude'].toDouble(),
              location['longitude'].toDouble(),
            );
          }
        }
        
        // 住所を設定
        _address = storeData['address'] ?? '';
      }

      // 現在地を取得
      await _getCurrentLocation();
      
      // 既存の位置情報がない場合は現在地を使用
      if (_selectedLocation == null) {
        _selectedLocation = _currentLocation ?? _defaultLocation;
      }
      
      // 地図を選択された位置に移動
      if (_selectedLocation != null) {
        _moveMapTo(_selectedLocation!, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('店舗データの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 現在地を取得
  Future<void> _getCurrentLocation() async {
    try {
      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('位置情報サービスが無効です');
        return;
      }

      // 位置情報の権限を確認
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          print('位置情報権限が拒否されました');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('位置情報権限が永続的に拒否されています');
        return;
      }
      
      // 現在地を取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('現在地の取得に失敗しました: $e');
    }
  }

  // 位置情報を保存
  Future<void> _saveLocation() async {
    if (_selectedLocation == null || _selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('位置情報が設定されていません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 住所を逆ジオコーディングで取得（簡易版）
      final address = await _getAddressFromLocation(_selectedLocation!);
      
      // Firestoreに保存
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_selectedStoreId)
          .update({
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('位置情報を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // 座標から住所を取得（簡易版）
  Future<String> _getAddressFromLocation(LatLng location) async {
    // 実際の実装ではGeocoding APIを使用
    // ここでは簡易版として固定の住所を返す
    return '緯度: ${location.latitude.toStringAsFixed(6)}, 経度: ${location.longitude.toStringAsFixed(6)}';
  }

  // マーカーを作成
  List<Marker> _createMarkers() {
    final List<Marker> markers = [];
    
    // 現在地マーカー（青い円）
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

    // 選択された位置のマーカー（赤いピン）
    if (_selectedLocation != null) {
      markers.add(
        Marker(
          point: _selectedLocation!,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              // マーカータップ時の処理（必要に応じて）
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }
    
    return markers;
  }

  // 地図をタップした時の処理
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  // 現在地ボタンの処理
  void _onCurrentLocationPressed() async {
    try {
      await _getCurrentLocation();
      if (_currentLocation != null) {
        setState(() {
          _selectedLocation = _currentLocation;
        });
        _moveMapTo(_currentLocation!, 15.0);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('現在地の取得に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _moveMapTo(LatLng location, double zoom) {
    if (_mapReady) {
      _mapController.move(location, zoom);
    } else {
      _pendingMoveLocation = location;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('店舗位置情報'),
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗位置情報'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _currentLocation ?? _defaultLocation,
              initialZoom: 15.0,
              onTap: _onMapTap,
              onMapReady: () {
                _mapReady = true;
                if (_pendingMoveLocation != null) {
                  _mapController.move(_pendingMoveLocation!, 15.0);
                  _pendingMoveLocation = null;
                }
              },
            ),
            children: [
              // OpenStreetMapタイルレイヤー
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.groumap.groumapappstore',
                additionalOptions: const {
                  'attribution': '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                },
              ),
              // マーカーレイヤー
              MarkerLayer(markers: _createMarkers()),
            ],
          ),
          
          // 説明カード
          _buildInstructionCard(),
          
          // 現在地ボタン
          _buildCurrentLocationButton(),
          
          
          // 確定ボタン
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '位置情報の設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '地図をタップして店舗の位置を設定してください。赤いピンが店舗の位置を示します。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Positioned(
      bottom: 90, // 確定ボタンの上に配置
      right: 16,
      child: FloatingActionButton(
        onPressed: _onCurrentLocationPressed,
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.my_location,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard() {
    return Positioned(
      bottom: 100, // 確定ボタンの分だけ上に移動
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '選択された位置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '緯度: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '経度: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
            if (_address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '住所: $_address',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '保存中...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '位置を確定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
