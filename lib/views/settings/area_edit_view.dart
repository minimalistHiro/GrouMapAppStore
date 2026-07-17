import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/area_model.dart';
import '../../providers/area_admin_provider.dart';

/// エリア色プリセット
const List<Map<String, dynamic>> _colorPresets = [
  {'label': 'オレンジ（デフォルト）', 'value': '#FF6B35'},
  {'label': 'ブルー', 'value': '#4A90E2'},
  {'label': 'グリーン', 'value': '#27AE60'},
  {'label': 'パープル', 'value': '#8E44AD'},
  {'label': 'レッド', 'value': '#E74C3C'},
];

class AreaEditView extends ConsumerStatefulWidget {
  const AreaEditView({Key? key, this.area}) : super(key: key);

  /// null の場合は新規作成、非 null の場合は編集
  final AreaModel? area;

  @override
  ConsumerState<AreaEditView> createState() => _AreaEditViewState();
}

class _AreaEditViewState extends ConsumerState<AreaEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();
  final _orderController = TextEditingController();

  String _selectedColor = '#FF6B35';
  bool _isActive = true;
  bool _isSaving = false;
  bool _isLocating = false;

  // マッププレビュー用コントローラー
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final area = widget.area;
    if (area != null) {
      _nameController.text = area.name;
      _descriptionController.text = area.description ?? '';
      _latController.text = area.centerLatitude.toString();
      _lngController.text = area.centerLongitude.toString();
      _radiusController.text = area.radiusMeters.toInt().toString();
      _orderController.text = (area.order ?? 1).toString();
      _selectedColor = area.color ?? '#FF6B35';
      _isActive = area.isActive;
    } else {
      // 新規作成時のデフォルト（蕨駅周辺）
      _latController.text = '35.8238';
      _lngController.text = '139.6789';
      _radiusController.text = '700';
      _orderController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _orderController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  double? get _previewLat => double.tryParse(_latController.text);
  double? get _previewLng => double.tryParse(_lngController.text);
  double? get _previewRadius => double.tryParse(_radiusController.text);

  Color get _previewColor =>
      AreaModel.parseHexColor(_selectedColor, defaultColor: const Color(0xFFFF6B35));

  @override
  Widget build(BuildContext context) {
    final isNew = widget.area == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'エリアを追加' : 'エリアを編集'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined),
              tooltip: '無効化（非表示）',
              onPressed: _isSaving ? null : _confirmDeactivate,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMapPreview(),
              const SizedBox(height: 20),
              _buildFormFields(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isNew ? '作成する' : '保存する'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    final lat = _previewLat;
    final lng = _previewLng;
    final radius = _previewRadius;

    if (lat == null || lng == null || radius == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '座標と半径を入力するとプレビューが表示されます',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final center = LatLng(lat, lng);
    // 半径からズームレベルを自動計算（おおよその値）
    final zoom = _radiusToZoom(radius);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.groumapapp_store',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: radius,
                  useRadiusInMeter: true,
                  color: _previewColor.withOpacity(0.2),
                  borderColor: _previewColor,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.location_on,
                    color: _previewColor,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'エリア名 *',
            hintText: '例: 蕨駅周辺',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label_outline),
          ),
          maxLength: 10,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'エリア名は必須です';
            if (v.trim().length > 10) return '10文字以内で入力してください';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '説明',
            hintText: '任意・50文字以内',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes_outlined),
          ),
          maxLength: 50,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _latController,
                decoration: const InputDecoration(
                  labelText: '緯度 *',
                  hintText: '例: 35.8238',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null) return '数値を入力してください';
                  if (d < -90 || d > 90) return '-90〜90';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lngController,
                decoration: const InputDecoration(
                  labelText: '経度 *',
                  hintText: '例: 139.6789',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null) return '数値を入力してください';
                  if (d < -180 || d > 180) return '-180〜180';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: _isLocating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: const Text('現在地を使用'),
          onPressed: _isLocating ? null : _useCurrentLocation,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _radiusController,
          decoration: const InputDecoration(
            labelText: '半径（メートル） *',
            hintText: '例: 700',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.radio_button_unchecked),
            suffixText: 'm',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          validator: (v) {
            final d = double.tryParse(v ?? '');
            if (d == null) return '数値を入力してください';
            if (d < 100 || d > 5000) return '100〜5000m';
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedColor,
          decoration: const InputDecoration(
            labelText: '表示色',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.color_lens_outlined),
          ),
          items: _colorPresets.map((preset) {
            final color = AreaModel.parseHexColor(
              preset['value'] as String,
              defaultColor: const Color(0xFFFF6B35),
            );
            return DropdownMenuItem<String>(
              value: preset['value'] as String,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(preset['label'] as String),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedColor = v);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _orderController,
          decoration: const InputDecoration(
            labelText: '表示順',
            hintText: '例: 1（小さいほど先に表示）',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.sort),
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final i = int.tryParse(v);
            if (i == null || i < 1) return '1以上の整数';
            return null;
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('表示する'),
          subtitle: const Text('オフにするとマップに表示されません'),
          value: _isActive,
          activeThumbColor: const Color(0xFFFF6B35),
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _isActive = v),
        ),
      ],
    );
  }

  double _radiusToZoom(double radiusMeters) {
    // 半径からズームレベルを大まかに計算
    // radiusMeters が大きいほどズームアウト
    if (radiusMeters <= 200) return 16.0;
    if (radiusMeters <= 500) return 15.0;
    if (radiusMeters <= 1000) return 14.0;
    if (radiusMeters <= 2000) return 13.0;
    return 12.0;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('位置情報の権限が必要です')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _latController.text =
              pos.latitude.toStringAsFixed(6);
          _lngController.text =
              pos.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('現在地の取得に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(areaAdminServiceProvider);
      final lat = double.parse(_latController.text.trim());
      final lng = double.parse(_lngController.text.trim());
      final radius = double.parse(_radiusController.text.trim());
      final order = int.tryParse(_orderController.text.trim()) ?? 1;

      if (widget.area == null) {
        await service.createArea(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          latitude: lat,
          longitude: lng,
          radiusMeters: radius,
          color: _selectedColor,
          order: order,
          isActive: _isActive,
        );
      } else {
        await service.updateArea(
          areaId: widget.area!.areaId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          latitude: lat,
          longitude: lng,
          radiusMeters: radius,
          color: _selectedColor,
          order: order,
          isActive: _isActive,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.area == null ? 'エリアを作成しました' : 'エリアを更新しました'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エリアを非表示にする'),
        content: Text(
          '「${widget.area!.name}」を非表示にします。\nマップに表示されなくなりますが、データは保持されます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('非表示にする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(areaAdminServiceProvider);
      await service.deactivateArea(widget.area!.areaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('エリアを非表示にしました'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
