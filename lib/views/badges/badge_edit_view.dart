import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../providers/badge_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class BadgeEditView extends ConsumerStatefulWidget {
  final String badgeId;
  
  const BadgeEditView({Key? key, required this.badgeId}) : super(key: key);

  @override
  ConsumerState<BadgeEditView> createState() => _BadgeEditViewState();
}

class _BadgeEditViewState extends ConsumerState<BadgeEditView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // テキストコントローラー
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderController = TextEditingController();
  final _requiredValueController = TextEditingController();
  final _jsonLogicController = TextEditingController();

  Map<String, dynamic>? _badgeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBadgeData();
  }

  Future<void> _loadBadgeData() async {
    try {
      // TODO: Firestoreからバッジデータを取得
      // 現在は仮のデータを使用
      setState(() {
        _badgeData = {
          'id': widget.badgeId,
          'name': 'サンプルバッジ',
          'description': 'サンプルの説明',
          'rarity': 'bronze',
          'category': 'basic',
          'isActive': true,
          'order': 0,
          'requiredValue': 100,
          'imageUrl': null,
          'condition': {
            'mode': 'typed',
            'rule': {
              'type': 'points_total',
              'params': {'threshold': 50}
            }
          }
        };
        _isLoading = false;
      });
      
      // フォームにデータを設定
      _nameController.text = _badgeData!['name'] ?? '';
      _descriptionController.text = _badgeData!['description'] ?? '';
      _orderController.text = (_badgeData!['order'] ?? 0).toString();
      _requiredValueController.text = (_badgeData!['requiredValue'] ?? 0).toString();
      
      // 条件データを設定
      final condition = _badgeData!['condition'] as Map<String, dynamic>? ?? {};
      if (condition['mode'] == 'jsonlogic') {
        _jsonLogicController.text = json.encode(condition['rule']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('バッジデータの取得に失敗しました: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    _requiredValueController.dispose();
    _jsonLogicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('バッジ編集'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    }

    final badgeCreateState = ref.watch(badgeCreateProvider);
    final badgeFormData = ref.watch(badgeFormProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'バッジ編集',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (badgeCreateState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // タブバー
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF6B35),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF6B35),
                tabs: const [
                  Tab(text: '基本情報'),
                  Tab(text: '獲得条件'),
                ],
              ),
            ),
            
            // タブコンテンツ
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(badgeFormData),
                  _buildConditionTab(badgeFormData),
                ],
              ),
            ),
            
            // 保存ボタン
            _buildSaveButton(badgeCreateState, badgeFormData, currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(BadgeFormData formData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 画像選択セクション
          _buildImageSection(),
          
          const SizedBox(height: 24),
          
          // 基本情報セクション
          _buildBasicInfoSection(formData),
          
          const SizedBox(height: 24),
          
          // 表示設定セクション
          _buildDisplaySection(formData),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final badgeCreateState = ref.watch(badgeCreateProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'バッジ画像',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '画像を選択してください（任意）',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // 画像プレビュー
          Center(
            child: GestureDetector(
              onTap: () => ref.read(badgeCreateProvider.notifier).pickImage(),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: badgeCreateState.selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          badgeCreateState.selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _badgeData?['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _badgeData!['imageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.workspace_premium,
                                  size: 32,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '画像を選択',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BadgeFormData formData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // バッジ名
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'バッジ名 *',
              hintText: '例: 初回訪問バッジ',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ref.read(badgeFormProvider.notifier).updateName(value),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'バッジ名を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 説明
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '説明 *',
              hintText: '例: 初回訪問時に獲得できるバッジです',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => ref.read(badgeFormProvider.notifier).updateDescription(value),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '説明を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // レア度
          _buildRaritySelector(formData),
          
          const SizedBox(height: 16),
          
          // カテゴリ
          _buildCategorySelector(formData),
        ],
      ),
    );
  }

  Widget _buildRaritySelector(BadgeFormData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'レア度',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rarityOptions.map((rarity) {
            final isSelected = formData.rarity == rarity['value'];
            return GestureDetector(
              onTap: () => ref.read(badgeFormProvider.notifier).updateRarity(rarity['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? rarity['color'].withOpacity(0.2) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? rarity['color'] : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: rarity['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rarity['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? rarity['color'] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(BadgeFormData formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: formData.category.isEmpty ? null : formData.category,
          decoration: const InputDecoration(
            labelText: 'カテゴリを選択',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: categoryOptions.map((category) {
            return DropdownMenuItem<String>(
              value: category['value'] as String,
              child: Text(category['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(badgeFormProvider.notifier).updateCategory(value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'カテゴリを選択してください';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySection(BadgeFormData formData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '表示設定',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 表示順
          TextFormField(
            controller: _orderController,
            decoration: const InputDecoration(
              labelText: '表示順 *',
              hintText: '0',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final order = int.tryParse(value) ?? 0;
              ref.read(badgeFormProvider.notifier).updateOrder(order);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '表示順を入力してください';
              }
              if (int.tryParse(value) == null) {
                return '数値を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 要求値
          TextFormField(
            controller: _requiredValueController,
            decoration: const InputDecoration(
              labelText: '要求値 *',
              hintText: '100',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final requiredValue = int.tryParse(value) ?? 0;
              ref.read(badgeFormProvider.notifier).updateRequiredValue(requiredValue);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '要求値を入力してください';
              }
              if (int.tryParse(value) == null) {
                return '数値を入力してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 有効フラグ
          Row(
            children: [
              Checkbox(
                value: formData.isActive,
                onChanged: (value) => ref.read(badgeFormProvider.notifier).updateIsActive(value ?? false),
                activeColor: const Color(0xFFFF6B35),
              ),
              const Text(
                'バッジを有効にする',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionTab(BadgeFormData formData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 条件モード選択
          _buildConditionModeSelector(formData),
          
          const SizedBox(height: 24),
          
          // 条件設定
          if (formData.conditionMode == 'typed')
            _buildTypedConditionSection(formData)
          else
            _buildJsonLogicConditionSection(formData),
        ],
      ),
    );
  }

  Widget _buildConditionModeSelector(BadgeFormData formData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '条件モード',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '獲得条件の設定方法を選択してください',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(badgeFormProvider.notifier).updateConditionMode('typed'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: formData.conditionMode == 'typed' 
                          ? const Color(0xFFFF6B35).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: formData.conditionMode == 'typed' 
                            ? const Color(0xFFFF6B35)
                            : Colors.grey[300]!,
                        width: formData.conditionMode == 'typed' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.settings,
                          color: formData.conditionMode == 'typed' 
                              ? const Color(0xFFFF6B35)
                              : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '基本モード',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: formData.conditionMode == 'typed' 
                                ? const Color(0xFFFF6B35)
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '簡単な条件設定',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(badgeFormProvider.notifier).updateConditionMode('jsonlogic'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: formData.conditionMode == 'jsonlogic' 
                          ? const Color(0xFFFF6B35).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: formData.conditionMode == 'jsonlogic' 
                            ? const Color(0xFFFF6B35)
                            : Colors.grey[300]!,
                        width: formData.conditionMode == 'jsonlogic' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.code,
                          color: formData.conditionMode == 'jsonlogic' 
                              ? const Color(0xFFFF6B35)
                              : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '高度モード',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: formData.conditionMode == 'jsonlogic' 
                                ? const Color(0xFFFF6B35)
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JSON Logic式',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypedConditionSection(BadgeFormData formData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '条件設定',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 条件タイプ選択
          DropdownButtonFormField<String>(
            value: formData.conditionType.isEmpty ? null : formData.conditionType,
            decoration: const InputDecoration(
              labelText: '条件タイプ',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: conditionTypeOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'] as String,
                child: Text(option['label'] as String),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(badgeFormProvider.notifier).updateConditionType(value);
                // パラメータをリセット
                ref.read(badgeFormProvider.notifier).updateConditionParams({});
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '条件タイプを選択してください';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // 条件パラメータ
          if (formData.conditionType.isNotEmpty)
            _buildConditionParams(formData),
        ],
      ),
    );
  }

  Widget _buildConditionParams(BadgeFormData formData) {
    final selectedType = conditionTypeOptions.firstWhere(
      (option) => option['value'] == formData.conditionType,
      orElse: () => {'params': []},
    );
    final requiredParams = List<String>.from(selectedType['params'] ?? []);

    if (requiredParams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '条件パラメータ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        ...requiredParams.map((param) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildParamField(param, formData.conditionParams[param], formData),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildParamField(String param, dynamic value, BadgeFormData formData) {
    switch (param) {
      case 'threshold':
        return TextFormField(
          decoration: InputDecoration(
            labelText: '閾値 *',
            hintText: '100',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          initialValue: value?.toString() ?? '',
          onChanged: (val) {
            final intValue = int.tryParse(val) ?? 0;
            final newParams = Map<String, dynamic>.from(formData.conditionParams);
            newParams[param] = intValue;
            ref.read(badgeFormProvider.notifier).updateConditionParams(newParams);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '閾値を入力してください';
            }
            if (int.tryParse(value) == null) {
              return '数値を入力してください';
            }
            return null;
          },
        );
      case 'period':
        return DropdownButtonFormField<String>(
          value: value?.toString() ?? 'day',
          decoration: const InputDecoration(
            labelText: '期間',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: periodOptions.map((option) {
            return DropdownMenuItem<String>(
              value: option['value'] as String,
              child: Text(option['label'] as String),
            );
          }).toList(),
          onChanged: (val) {
            final newParams = Map<String, dynamic>.from(formData.conditionParams);
            newParams[param] = val;
            ref.read(badgeFormProvider.notifier).updateConditionParams(newParams);
          },
        );
      case 'tz':
        return TextFormField(
          decoration: const InputDecoration(
            labelText: 'タイムゾーン',
            hintText: 'Asia/Tokyo',
            border: OutlineInputBorder(),
          ),
          initialValue: value?.toString() ?? 'Asia/Tokyo',
          onChanged: (val) {
            final newParams = Map<String, dynamic>.from(formData.conditionParams);
            newParams[param] = val;
            ref.read(badgeFormProvider.notifier).updateConditionParams(newParams);
          },
        );
      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: param,
            border: const OutlineInputBorder(),
          ),
          initialValue: value?.toString() ?? '',
          onChanged: (val) {
            final newParams = Map<String, dynamic>.from(formData.conditionParams);
            newParams[param] = val;
            ref.read(badgeFormProvider.notifier).updateConditionParams(newParams);
          },
        );
    }
  }

  Widget _buildJsonLogicConditionSection(BadgeFormData formData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JSON Logic式',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'JSON Logic形式で条件を記述してください',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _jsonLogicController,
            onChanged: (value) => ref.read(badgeFormProvider.notifier).updateJsonLogicCondition(value),
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '例: {"and": [{"\u003e=": [{"var": "metrics.points.month"}, 40]}]}',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'JSON Logic式を入力してください';
              }
              try {
                json.decode(value);
                return null;
              } catch (e) {
                return '有効なJSON形式で入力してください';
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _formatJsonLogic(),
                  icon: const Icon(Icons.format_align_left, size: 16),
                  label: const Text('整形'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _validateJsonLogic(),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('検証'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _formatJsonLogic() {
    final currentValue = _jsonLogicController.text;
    try {
      final jsonData = json.decode(currentValue);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(jsonData);
      _jsonLogicController.text = formatted;
      ref.read(badgeFormProvider.notifier).updateJsonLogicCondition(formatted);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSONを整形しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSONの整形に失敗しました: $e')),
      );
    }
  }

  void _validateJsonLogic() {
    final currentValue = _jsonLogicController.text;
    try {
      json.decode(currentValue);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSONは有効です')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSONが無効です: $e')),
      );
    }
  }

  Widget _buildSaveButton(BadgeCreateState createState, BadgeFormData formData, currentUser) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // エラー表示
          if (createState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                createState.error!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
          
          // 保存ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: createState.isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: const Text('キャンセル'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: createState.isLoading ? '更新中...' : 'バッジを更新',
                  onPressed: createState.isLoading ? null : () => _updateBadge(formData, currentUser),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateBadge(BadgeFormData formData, currentUser) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!formData.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('条件設定が不完全です')),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインが必要です')),
      );
      return;
    }

    // TODO: バッジ更新処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('バッジを更新しました'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.of(context).pop();
  }
}
