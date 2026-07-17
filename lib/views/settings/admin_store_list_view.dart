import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_store_provider.dart';
import 'admin_store_create_view.dart';

class AdminStoreListView extends ConsumerStatefulWidget {
  const AdminStoreListView({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminStoreListView> createState() => _AdminStoreListViewState();
}

class _AdminStoreListViewState extends ConsumerState<AdminStoreListView> {
  bool _isReorderMode = false;
  List<Map<String, dynamic>>? _reorderList;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(allStoresForAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('店舗管理', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (_isReorderMode) ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)))),
              )
            else ...[
              TextButton(
                onPressed: () => setState(() {
                  _isReorderMode = false;
                  _reorderList = null;
                }),
                child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: _saveOrder,
                child: const Text('保存', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
              ),
            ],
          ] else ...[
            IconButton(
              icon: const Icon(Icons.reorder, color: Color(0xFFFF6B35)),
              tooltip: '並び替え',
              onPressed: () {
                final stores = ref.read(allStoresForAdminProvider).valueOrNull;
                if (stores != null) {
                  setState(() {
                    _isReorderMode = true;
                    _reorderList = List.from(stores);
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_business_outlined, color: Color(0xFFFF6B35)),
              tooltip: '新規店舗を作成',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminStoreCreateView()),
                );
              },
            ),
          ],
        ],
      ),
      body: _isReorderMode
          ? _buildReorderBody()
          : storesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
              error: (e, _) => Center(child: Text('読み込みエラー: $e')),
              data: (stores) {
                if (stores.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('店舗が登録されていません', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdminStoreCreateView()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('最初の店舗を作成'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Text('${stores.length}店舗', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AdminStoreCreateView()),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('新規作成'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B35)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: stores.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          return _StoreListCard(store: store);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildReorderBody() {
    final list = _reorderList ?? [];
    return Column(
      children: [
        Container(
          color: const Color(0xFFFFF3E0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ドラッグして並び替え、「保存」で図鑑の順番に反映されます',
                  style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _reorderList!.removeAt(oldIndex);
                _reorderList!.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final store = list[index];
              final name = store['name'] as String? ?? '（店舗名なし）';
              final category = store['category'] as String? ?? '';
              return ListTile(
                key: ValueKey(store['id'] ?? index),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)),
                  ),
                ),
                title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: category.isNotEmpty ? Text(category, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
                trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                tileColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveOrder() async {
    if (_reorderList == null) return;
    setState(() => _isSaving = true);
    try {
      final service = ref.read(adminStoreServiceProvider);
      final ids = _reorderList!.map((s) => s['id'] as String).toList();
      await service.updateZukanOrder(ids);
      if (mounted) {
        setState(() {
          _isReorderMode = false;
          _reorderList = null;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('並び順を保存しました'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StoreListCard extends ConsumerWidget {
  final Map<String, dynamic> store;

  const _StoreListCard({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = store['name'] as String? ?? '（店舗名なし）';
    final category = store['category'] as String? ?? '';
    final isActive = store['isActive'] as bool? ?? false;
    final linkCode = store['linkCode'] as String?;
    final linkedUids = (store['linkedUids'] as List<dynamic>?) ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アイコン
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: Color(0xFFFF6B35), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (category.isNotEmpty)
                        Text(category, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // 公開状態バッジ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? Colors.green : Colors.grey, width: 1),
                  ),
                  child: Text(
                    isActive ? '公開中' : '非公開',
                    style: TextStyle(fontSize: 12, color: isActive ? Colors.green : Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // リンクコードセクション
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                const Text('リンクコード', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const Spacer(),
                if (linkedUids.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.green),
                        const SizedBox(width: 2),
                        Text('${linkedUids.length}件紐づけ済み', style: const TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () => _showLinkCodeBottomSheet(context, ref, store),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFFF6B35))),
                  ),
                  child: Text(
                    linkCode != null ? 'コードを確認' : 'コードを生成',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            if (linkCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      linkCode,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFFFF6B35)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Color(0xFFFF6B35)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: linkCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('リンクコードをコピーしました'), duration: Duration(seconds: 2)),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLinkCodeBottomSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> store) {
    final storeId = store['id'] as String? ?? '';
    final storeName = store['name'] as String? ?? '店舗';
    final linkCode = store['linkCode'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _LinkCodeBottomSheet(
        storeId: storeId,
        storeName: storeName,
        linkCode: linkCode,
      ),
    );
  }
}

class _LinkCodeBottomSheet extends ConsumerStatefulWidget {
  final String storeId;
  final String storeName;
  final String? linkCode;

  const _LinkCodeBottomSheet({
    required this.storeId,
    required this.storeName,
    required this.linkCode,
  });

  @override
  ConsumerState<_LinkCodeBottomSheet> createState() => _LinkCodeBottomSheetState();
}

class _LinkCodeBottomSheetState extends ConsumerState<_LinkCodeBottomSheet> {
  bool _isLoading = false;
  String? _currentCode;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.linkCode;
  }

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('リンクコードを再生成'),
        content: const Text('古いコードは無効になります。\n本当に再生成しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('再生成', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(adminStoreServiceProvider);
      final newCode = await service.regenerateLinkCode(widget.storeId);
      setState(() {
        _currentCode = newCode;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リンクコードを再生成しました'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('再生成に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'このリンクコードを店舗オーナーにお伝えください。\nアプリのアカウント作成後に店舗紐づけで使用します。',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            if (_currentCode != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF6B35), width: 2),
                  ),
                  child: Text(
                    _currentCode!,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFFFF6B35)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _currentCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('リンクコードをコピーしました'), duration: Duration(seconds: 2)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('コピー'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ] else
              Center(
                child: Text('リンクコードがありません', style: TextStyle(color: Colors.grey[600])),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _regenerate,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 18),
                label: Text(_currentCode != null ? 'コードを再生成' : 'コードを生成'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
