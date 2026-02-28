import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_switch_tile.dart';

class MenuOptionGroupEditView extends ConsumerStatefulWidget {
  final String storeId;
  final Map<String, dynamic>? existingGroup;

  const MenuOptionGroupEditView({
    Key? key,
    required this.storeId,
    this.existingGroup,
  }) : super(key: key);

  @override
  ConsumerState<MenuOptionGroupEditView> createState() =>
      _MenuOptionGroupEditViewState();
}

class _MenuOptionGroupEditViewState
    extends ConsumerState<MenuOptionGroupEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;
  bool _perMenuPricing = false;

  // 選択肢のリスト（名前と追加料金のペア）
  List<_OptionChoice> _choices = [];

  bool get _isEditing => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingData();
    } else {
      // 新規作成: 初期値として空の選択肢を2つ用意
      _choices = [
        _OptionChoice(),
        _OptionChoice(),
      ];
    }
  }

  void _loadExistingData() {
    final group = widget.existingGroup!;
    _nameController.text = group['name'] ?? '';
    _perMenuPricing = group['perMenuPricing'] ?? false;

    final options = (group['options'] as List<dynamic>?) ?? [];
    _choices = options.map((opt) {
      return _OptionChoice()
        ..nameController.text = (opt['name'] ?? '').toString()
        ..priceController.text =
            ((opt['priceModifier'] ?? 0) as num).toInt().toString();
    }).toList();

    // 最低2つの選択肢を確保
    while (_choices.length < 2) {
      _choices.add(_OptionChoice());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final choice in _choices) {
      choice.dispose();
    }
    super.dispose();
  }

  void _addChoice() {
    setState(() {
      _choices.add(_OptionChoice());
    });
  }

  void _removeChoice(int index) {
    if (_choices.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選択肢は最低2つ必要です'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _choices[index].dispose();
      _choices.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // 選択肢のバリデーション
    final validChoices = _choices
        .where((c) => c.nameController.text.trim().isNotEmpty)
        .toList();
    if (validChoices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選択肢を最低2つ入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final options = validChoices.map((choice) {
        final price = int.tryParse(choice.priceController.text.trim()) ?? 0;
        return {
          'name': choice.nameController.text.trim(),
          'priceModifier': price,
        };
      }).toList();

      if (_isEditing) {
        // 既存グループを更新
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('menu_option_groups')
            .doc(widget.existingGroup!['id'])
            .update({
          'name': _nameController.text.trim(),
          'options': options,
          'perMenuPricing': _perMenuPricing,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 新規グループを作成
        final docRef = FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('menu_option_groups')
            .doc();

        // 現在のグループ数を取得してsortOrderに使用
        final existing = await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('menu_option_groups')
            .get();

        await docRef.set({
          'id': docRef.id,
          'name': _nameController.text.trim(),
          'isDefault': false,
          'perMenuPricing': _perMenuPricing,
          'options': options,
          'sortOrder': existing.docs.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'オプションを更新しました' : 'オプションを作成しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: CommonHeader(title: _isEditing ? 'オプション編集' : 'オプション作成'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // グループ名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'オプション名 *',
                  hintText: '例: サイズ、温度、トッピング',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'オプション名を入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // メニューごとの料金設定スイッチ
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: CustomSwitchListTile(
                  title: const Text(
                    '各メニューごとに追加料金を設定',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _perMenuPricing
                        ? 'メニューごとに個別の追加料金を設定します'
                        : '全メニューで同じ追加料金を使用します',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: _perMenuPricing,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() => _perMenuPricing = value);
                        },
                ),
              ),

              const SizedBox(height: 24),

              // 選択肢セクション
              const Text(
                '選択肢',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '最低2つの選択肢が必要です',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              // 選択肢リスト
              ...List.generate(_choices.length, (index) {
                return _buildChoiceRow(index);
              }),

              const SizedBox(height: 8),

              // 選択肢追加ボタン
              TextButton.icon(
                onPressed: _addChoice,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('選択肢を追加'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                ),
              ),

              const SizedBox(height: 24),

              // 保存ボタン
              CustomButton(
                text: _isSaving
                    ? '保存中...'
                    : (_isEditing ? 'オプションを更新' : 'オプションを作成'),
                onPressed: _isSaving ? () {} : _save,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceRow(int index) {
    final choice = _choices[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 選択肢名
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: choice.nameController,
              decoration: InputDecoration(
                labelText: '選択肢${index + 1}',
                hintText: '例: 普通、大盛り',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 追加料金
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: choice.priceController,
              enabled: !_perMenuPricing,
              decoration: InputDecoration(
                labelText: _perMenuPricing ? 'デフォルト料金' : '追加料金',
                hintText: _perMenuPricing ? 'メニューごとに設定' : '0',
                border: const OutlineInputBorder(),
                prefixText: _perMenuPricing ? null : '¥',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: _perMenuPricing,
                fillColor: _perMenuPricing ? Colors.grey[100] : null,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          // 削除ボタン
          SizedBox(
            width: 36,
            child: IconButton(
              onPressed: () => _removeChoice(index),
              icon: Icon(
                Icons.close,
                color: _choices.length > 2 ? Colors.red : Colors.grey[300],
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

/// 選択肢の入力フィールドを管理するヘルパークラス
class _OptionChoice {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController(text: '0');

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}
