import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/default_menu_option_groups.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'menu_option_group_edit_view.dart';

class MenuOptionGroupsView extends ConsumerStatefulWidget {
  final String storeId;

  const MenuOptionGroupsView({Key? key, required this.storeId})
      : super(key: key);

  @override
  ConsumerState<MenuOptionGroupsView> createState() =>
      _MenuOptionGroupsViewState();
}

class _MenuOptionGroupsViewState extends ConsumerState<MenuOptionGroupsView> {
  List<Map<String, dynamic>> _optionGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptionGroups();
  }

  Future<void> _loadOptionGroups() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('menu_option_groups')
          .orderBy('sortOrder')
          .get();

      final groups = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      if (mounted) {
        setState(() {
          _optionGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('オプションの読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// まだ追加されていないデフォルトテンプレートを取得
  List<Map<String, dynamic>> _getUnavailableTemplates() {
    final addedTemplateIds = _optionGroups
        .where((g) => g['defaultTemplateId'] != null)
        .map((g) => g['defaultTemplateId'] as String)
        .toSet();

    return DefaultMenuOptionGroups.templates
        .where((t) => !addedTemplateIds.contains(t['templateId']))
        .toList();
  }

  Future<void> _addDefaultTemplate(Map<String, dynamic> template) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('menu_option_groups')
          .doc();

      final nextSortOrder = _optionGroups.length;

      await docRef.set({
        'id': docRef.id,
        'name': template['name'],
        'isDefault': true,
        'defaultTemplateId': template['templateId'],
        'options': template['options'],
        'sortOrder': nextSortOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadOptionGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${template['name']}」を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('追加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteOptionGroup(Map<String, dynamic> group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('オプションを削除'),
        content: Text(
            '「${group['name']}」を削除しますか？\nこのオプションを使用しているメニューからも自動的に除去されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final groupId = group['id'] as String;

      // このオプショングループを使用しているメニューを検索
      final menuSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('menu')
          .where('optionGroupIds', arrayContains: groupId)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      // 各メニューからこのグループIDとオプション料金オーバーライドを除去
      for (final doc in menuSnapshot.docs) {
        batch.update(doc.reference, {
          'optionGroupIds': FieldValue.arrayRemove([groupId]),
          'optionPriceOverrides.$groupId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // オプショングループ自体を削除
      batch.delete(FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('menu_option_groups')
          .doc(groupId));

      await batch.commit();
      await _loadOptionGroups();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${group['name']}」を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuOptionGroupEditView(
          storeId: widget.storeId,
        ),
      ),
    );
    if (result == true) {
      await _loadOptionGroups();
    }
  }

  Future<void> _navigateToEdit(Map<String, dynamic> group) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuOptionGroupEditView(
          storeId: widget.storeId,
          existingGroup: group,
        ),
      ),
    );
    if (result == true) {
      await _loadOptionGroups();
    }
  }

  String _buildOptionsPreview(Map<String, dynamic> group) {
    final options = (group['options'] as List<dynamic>?) ?? [];
    return options.map((opt) {
      final name = opt['name'] ?? '';
      final modifier = (opt['priceModifier'] ?? 0) as num;
      if (modifier > 0) {
        return '$name(+¥${modifier.toInt()})';
      }
      return name;
    }).join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final unavailableTemplates = _getUnavailableTemplates();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: 'オプション管理'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 新規作成ボタン
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: '新規オプションを作成',
                      onPressed: _navigateToCreate,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 追加済みオプション
                  if (_optionGroups.isNotEmpty) ...[
                    const Text(
                      '追加済みオプション',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._optionGroups
                        .map((group) => _buildOptionGroupCard(group)),
                    const SizedBox(height: 24),
                  ],

                  // 未追加のデフォルトテンプレート
                  if (unavailableTemplates.isNotEmpty) ...[
                    const Text(
                      'デフォルトテンプレート（未追加）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...unavailableTemplates
                        .map((template) => _buildTemplateCard(template)),
                  ],

                  // 何もない場合
                  if (_optionGroups.isEmpty &&
                      unavailableTemplates.isEmpty) ...[
                    const Center(
                      child: Text(
                        'オプションはありません',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildOptionGroupCard(Map<String, dynamic> group) {
    final preview = _buildOptionsPreview(group);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _navigateToEdit(group),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          group['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (group['isDefault'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'デフォルト',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        if (group['perMenuPricing'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'メニュー別料金',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteOptionGroup(group),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final options = (template['options'] as List<dynamic>?) ?? [];
    final preview = options.map((opt) {
      final name = opt['name'] ?? '';
      final modifier = (opt['priceModifier'] ?? 0) as num;
      if (modifier > 0) return '$name(+¥${modifier.toInt()})';
      return name;
    }).join(' / ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _addDefaultTemplate(template),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('追加', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
