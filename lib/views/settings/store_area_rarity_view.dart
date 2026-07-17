import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/area_admin_provider.dart';
import '../../models/area_model.dart';

/// 全承認済み店舗の一覧（isApproved=true かつ isOwner=false）
final allApprovedStoresProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('stores')
      .where('isApproved', isEqualTo: true)
      .where('isOwner', isEqualTo: false)
      .snapshots()
      .map((snap) {
    final docs = snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['storeId'] = d.id;
      return data;
    }).toList();
    docs.sort((a, b) {
      final nameA = (a['name'] as String? ?? '');
      final nameB = (b['name'] as String? ?? '');
      return nameA.compareTo(nameB);
    });
    return docs;
  });
});

/// 店舗エリア・レア度設定画面
class StoreAreaRarityView extends ConsumerStatefulWidget {
  const StoreAreaRarityView({super.key});

  @override
  ConsumerState<StoreAreaRarityView> createState() =>
      _StoreAreaRarityViewState();
}

class _StoreAreaRarityViewState extends ConsumerState<StoreAreaRarityView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(allApprovedStoresProvider);
    final areasAsync = ref.watch(areasAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗エリア・レア度設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '店舗名で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // 店舗一覧
          Expanded(
            child: storesAsync.when(
              data: (stores) {
                final filtered = _searchQuery.isEmpty
                    ? stores
                    : stores
                        .where((s) => (s['name'] as String? ?? '')
                            .toLowerCase()
                            .contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('店舗が見つかりません'));
                }

                return areasAsync.when(
                  data: (areas) {
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final store = filtered[index];
                        return _StoreAreaRarityTile(
                          store: store,
                          areas: areas,
                          onTap: () => _showEditBottomSheet(
                            context,
                            store: store,
                            areas: areas,
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('エラー: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
        ],
      ),
    );
  }

  /// 編集ボトムシートを表示する
  void _showEditBottomSheet(
    BuildContext context, {
    required Map<String, dynamic> store,
    required List<AreaModel> areas,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _StoreEditBottomSheet(
        store: store,
        areas: areas,
      ),
    );
  }
}

/// 店舗リストタイル
class _StoreAreaRarityTile extends StatelessWidget {
  final Map<String, dynamic> store;
  final List<AreaModel> areas;
  final VoidCallback onTap;

  const _StoreAreaRarityTile({
    required this.store,
    required this.areas,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final storeName = store['name'] as String? ?? '不明';
    final areaId = store['areaId'] as String?;
    final rarityOverride = store['rarityOverride'] as int?;

    final areaName = areaId != null
        ? areas.where((a) => a.areaId == areaId).map((a) => a.name).firstOrNull
            ?? '不明エリア'
        : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
        child: Text(
          storeName.isNotEmpty ? storeName[0] : '?',
          style: const TextStyle(color: Color(0xFFFF6B35)),
        ),
      ),
      title: Text(storeName),
      subtitle: Row(
        children: [
          // エリアチップ
          _buildChip(
            areaId != null ? areaName ?? '不明エリア' : '秘境スポット',
            areaId != null ? Colors.blue : Colors.purple,
          ),
          const SizedBox(width: 6),
          // レア度チップ
          _buildChip(
            rarityOverride != null
                ? _rarityLabel(rarityOverride)
                : '自動',
            rarityOverride != null ? Colors.orange : Colors.grey,
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  String _rarityLabel(int rarity) {
    switch (rarity) {
      case 1:
        return '★ コモン';
      case 2:
        return '★★ レア';
      case 3:
        return '★★★ エピック';
      case 4:
        return '★★★★ レジェンド';
      default:
        return '自動';
    }
  }
}

/// 編集ボトムシート
class _StoreEditBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> store;
  final List<AreaModel> areas;

  const _StoreEditBottomSheet({
    required this.store,
    required this.areas,
  });

  @override
  ConsumerState<_StoreEditBottomSheet> createState() =>
      _StoreEditBottomSheetState();
}

class _StoreEditBottomSheetState
    extends ConsumerState<_StoreEditBottomSheet> {
  late String? _selectedAreaId;
  late int? _selectedRarity; // null = 自動
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAreaId = widget.store['areaId'] as String?;
    _selectedRarity = widget.store['rarityOverride'] as int?;
  }

  @override
  Widget build(BuildContext context) {
    final storeName = widget.store['name'] as String? ?? '不明';
    final discoveredCount = widget.store['discoveredCount'] as int? ?? 0;
    final autoRarity = _calcAutoRarity(discoveredCount);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              children: [
                const Icon(Icons.tune_outlined, color: Color(0xFFFF6B35)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // 来店者数（参考情報）
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '来店者数: $discoveredCount人（自動計算: $autoRarity）',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // エリア選択
            const Text(
              'エリア',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedAreaId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('未設定（秘境スポット）'),
                ),
                ...widget.areas.map((area) => DropdownMenuItem<String?>(
                      value: area.areaId,
                      child: Text(area.name),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAreaId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // レア度手動設定
            const Text(
              'レア度（手動設定）',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ..._buildRarityOptions(),
            const SizedBox(height: 20),

            // ボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRarityOptions() {
    final options = [
      (null, '自動（discoveredCount から計算）'),
      (1, '★ コモン'),
      (2, '★★ レア'),
      (3, '★★★ エピック'),
      (4, '★★★★ レジェンド'),
    ];
    return options.map((entry) {
      final value = entry.$1;
      final label = entry.$2;
      return RadioListTile<int?>(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 13)),
        value: value,
        groupValue: _selectedRarity,
        activeColor: const Color(0xFFFF6B35),
        onChanged: (v) => setState(() => _selectedRarity = v),
      );
    }).toList();
  }

  /// discoveredCount から自動レア度を算出する（参考表示用）
  String _calcAutoRarity(int count) {
    if (count == 0) return '★ コモン';
    if (count < 5) return '★★ レア';
    if (count < 15) return '★★★ エピック';
    return '★★★★ レジェンド';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final storeId = widget.store['storeId'] as String;
      await FirebaseFirestore.instance.collection('stores').doc(storeId).update({
        'areaId': _selectedAreaId,
        'rarityOverride': _selectedRarity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存しました'),
            backgroundColor: Colors.green,
          ),
        );
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
        setState(() => _isSaving = false);
      }
    }
  }
}
