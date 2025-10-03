import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // バッジデータ
  Map<String, dynamic>? _badgeData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBadgeData();
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

  Future<void> _loadBadgeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // バッジデータを取得
      final badgesAsync = ref.read(badgesProvider);
      await badgesAsync.when(
        data: (badges) {
          final badge = badges.firstWhere(
            (b) => b['id'] == widget.badgeId,
            orElse: () => {},
          );
          
          if (badge.isNotEmpty) {
            _badgeData = badge;
            _populateForm();
          } else {
            setState(() {
              _error = 'バッジが見つかりません';
            });
          }
        },
        loading: () {},
        error: (error, _) {
          setState(() {
            _error = 'バッジの読み込みに失敗しました: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'バッジの読み込みに失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateForm() {
    if (_badgeData == null) return;

    _nameController.text = _badgeData!['name'] ?? '';
    _descriptionController.text = _badgeData!['description'] ?? '';
    _orderController.text = (_badgeData!['order'] ?? 0).toString();
    _requiredValueController.text = (_badgeData!['requiredValue'] ?? 0).toString();

    // フォームデータを更新（Future内で遅延実行）
    Future(() {
      ref.read(badgeFormProvider.notifier).updateName(_badgeData!['name'] ?? '');
      ref.read(badgeFormProvider.notifier).updateDescription(_badgeData!['description'] ?? '');
      ref.read(badgeFormProvider.notifier).updateRarity(_badgeData!['rarity'] ?? 'bronze');
      ref.read(badgeFormProvider.notifier).updateCategory(_badgeData!['category'] ?? 'basic');
      ref.read(badgeFormProvider.notifier).updateIsActive(_badgeData!['isActive'] ?? true);
      ref.read(badgeFormProvider.notifier).updateOrder(_badgeData!['order'] ?? 0);
      ref.read(badgeFormProvider.notifier).updateRequiredValue(_badgeData!['requiredValue'] ?? 0);

      // 条件データを設定
      final condition = _badgeData!['condition'] as Map<String, dynamic>? ?? {};
      if (condition['mode'] == 'typed') {
        ref.read(badgeFormProvider.notifier).updateConditionMode('typed');
        ref.read(badgeFormProvider.notifier).updateConditionType(condition['rule']?['type'] ?? '');
        ref.read(badgeFormProvider.notifier).updateConditionParams(condition['rule']?['params'] ?? {});
      } else if (condition['mode'] == 'jsonlogic') {
        ref.read(badgeFormProvider.notifier).updateConditionMode('jsonlogic');
        _jsonLogicController.text = json.encode(condition['rule'] ?? {});
        ref.read(badgeFormProvider.notifier).updateJsonLogicCondition(_jsonLogicController.text);
      }
    });
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

    if (_error != null) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'エラー',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadBadgeData(),
                child: const Text('再試行'),
              ),
            ],
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
          
          // 現在の画像または新しい画像プレビュー
          Center(
            child: GestureDetector(
              onTap: badgeCreateState.isLoading ? null : () => ref.read(badgeCreateProvider.notifier).pickImage(),
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
                child: badgeCreateState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                        ),
                      )
                    : badgeCreateState.selectedImage != null || badgeCreateState.webImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb && badgeCreateState.webImageBytes != null
                                ? Image.memory(
                                    badgeCreateState.webImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
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
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 32,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '画像読み込みエラー',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
          
          // エラーメッセージ表示
          if (badgeCreateState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      badgeCreateState.error!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(badgeCreateProvider.notifier).clearError(),
                    child: Icon(
                      Icons.close,
                      color: Colors.red[700],
                      size: 16,
                    ),
                  ),
                ],
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
            '獲得条件の設定方法を選択してください（モード切り替え時は内容がクリアされます）',
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
                  onTap: () {
                    if (formData.conditionMode != 'typed') {
                      // 高度モードから基本モードに切り替える時、JSON Logic内容をクリア
                      _jsonLogicController.clear();
                      ref.read(badgeFormProvider.notifier).updateJsonLogicCondition('');
                    }
                    ref.read(badgeFormProvider.notifier).updateConditionMode('typed');
                  },
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
                  onTap: () {
                    if (formData.conditionMode != 'jsonlogic') {
                      // 基本モードから高度モードに切り替える時、基本モードの内容をクリア
                      ref.read(badgeFormProvider.notifier).updateConditionType('');
                      ref.read(badgeFormProvider.notifier).updateConditionParams({});
                    }
                    ref.read(badgeFormProvider.notifier).updateConditionMode('jsonlogic');
                  },
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
    return Column(
      children: [
        Container(
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
        ),
        
        // JSON形式プレビュー
        if (formData.conditionType.isNotEmpty)
          _buildJsonPreview(formData),
      ],
    );
  }

  Widget _buildJsonPreview(BadgeFormData formData) {
    final jsonString = JsonEncoder.withIndent('  ').convert(formData.conditionData);
    
    // 条件タイプに応じた説明を生成
    String getConditionDescription() {
      switch (formData.conditionType) {
        case 'first_checkin':
          return '※ point_transactionsコレクションに初めてユーザーのuidが登録された時';
        case 'points_total':
          return '※ ユーザーの累計ポイントが閾値以上の時';
        case 'points_in_period':
          return '※ 指定期間内のポイント獲得数が閾値以上の時';
        case 'checkins_count':
          return '※ 指定期間内のチェックイン回数が閾値以上の時';
        case 'user_level':
          return '※ ユーザーのレベルが閾値以上の時';
        case 'badge_count':
          return '※ 獲得バッジ数が閾値以上の時';
        case 'payment_amount':
          return '※ 指定期間内の支払い総額が閾値以上の時';
        case 'day_of_week_count':
          return '※ 指定曜日の利用回数が閾値以上の時';
        case 'usage_count':
          return '※ 指定期間内の利用回数が閾値以上の時';
        case 'cities_count':
          return '※ 異なる市で利用した回数が閾値以上の時（例: 3つ以上の異なる市で利用）';
        case 'time_range_usage':
          return '※ 指定時間帯（例: 18時〜22時）での利用回数が閾値以上の時';
        case 'monthly_usage':
          return '※ 月間での利用回数が閾値以上の時（例: 月に5回以上利用）';
        case 'genre_usage':
          return '※ 指定ジャンルの店での利用回数が閾値以上の時（例: カフェで3回以上利用）';
        case 'same_city_usage':
          return '※ 同じ市での利用回数が閾値以上の時（例: 川口市で5回以上利用）';
        case 'same_store_usage':
          return '※ 同じ店での利用回数が閾値以上の時（例: 特定の店で3回以上利用）';
        case 'store_creation_within_months':
          return '※ 店の作成日から指定月数以内に来店した回数が閾値以上の時';
        case 'regular_store_count':
          return '※ スタンプカードを10個集めた店舗数が閾値以上の時（例: 3店舗で常連になる）';
        default:
          return '';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                'JSON形式プレビュー',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (getConditionDescription().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              getConditionDescription(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              jsonString,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
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
      case 'day_of_week':
        return DropdownButtonFormField<String>(
          value: value?.toString() ?? 'monday',
          decoration: const InputDecoration(
            labelText: '曜日',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: dayOfWeekOptions.map((option) {
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
      case 'start_hour':
        return TextFormField(
          decoration: const InputDecoration(
            labelText: '開始時刻（時） *',
            hintText: '18',
            border: OutlineInputBorder(),
            helperText: '0〜23の数値を入力',
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
              return '開始時刻を入力してください';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return '数値を入力してください';
            }
            if (intValue < 0 || intValue > 23) {
              return '0〜23の範囲で入力してください';
            }
            return null;
          },
        );
      case 'end_hour':
        return TextFormField(
          decoration: const InputDecoration(
            labelText: '終了時刻（時） *',
            hintText: '22',
            border: OutlineInputBorder(),
            helperText: '0〜23の数値を入力',
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
              return '終了時刻を入力してください';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return '数値を入力してください';
            }
            if (intValue < 0 || intValue > 23) {
              return '0〜23の範囲で入力してください';
            }
            return null;
          },
        );
      case 'genre':
        return DropdownButtonFormField<String>(
          value: value?.toString() ?? 'カフェ',
          decoration: const InputDecoration(
            labelText: 'ジャンル *',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: genreOptions.map((option) {
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
      case 'months':
        return TextFormField(
          decoration: const InputDecoration(
            labelText: '月数 *',
            hintText: '3',
            border: OutlineInputBorder(),
            helperText: '1〜12の数値を入力',
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
              return '月数を入力してください';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return '数値を入力してください';
            }
            if (intValue < 1 || intValue > 12) {
              return '1〜12の範囲で入力してください';
            }
            return null;
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

  bool _isFormValid(BadgeFormData formData) {
    // 基本情報の必須項目チェック
    if (formData.name.trim().isEmpty || formData.description.trim().isEmpty) {
      return false;
    }
    
    // 条件設定のチェック
    if (formData.conditionMode == 'typed') {
      if (formData.conditionType.isEmpty) {
        return false;
      }
      // 必須パラメータのチェック
      final selectedType = conditionTypeOptions.firstWhere(
        (option) => option['value'] == formData.conditionType,
        orElse: () => {'params': []},
      );
      final requiredParams = List<String>.from(selectedType['params'] ?? []);
      
      for (String param in requiredParams) {
        if (param == 'threshold' && (formData.conditionParams[param] == null || formData.conditionParams[param] == 0)) {
          return false;
        }
        if (param == 'start_hour' && (formData.conditionParams[param] == null || formData.conditionParams[param] == 0)) {
          return false;
        }
        if (param == 'end_hour' && (formData.conditionParams[param] == null || formData.conditionParams[param] == 0)) {
          return false;
        }
        if (param == 'months' && (formData.conditionParams[param] == null || formData.conditionParams[param] == 0)) {
          return false;
        }
        if (param == 'genre' && (formData.conditionParams[param] == null || formData.conditionParams[param].toString().isEmpty)) {
          return false;
        }
      }
    } else if (formData.conditionMode == 'jsonlogic') {
      if (formData.jsonLogicCondition.trim().isEmpty) {
        return false;
      }
      try {
        json.decode(formData.jsonLogicCondition);
      } catch (e) {
        return false;
      }
    }
    
    return true;
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
                  onPressed: (createState.isLoading || !_isFormValid(formData)) ? null : () => _updateBadge(formData, currentUser),
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

    try {
      // 条件データをFirestore用に変換
      Map<String, dynamic> conditionData;
      if (formData.conditionMode == 'jsonlogic') {
        // JSON Logicモードの場合、JSON文字列をパースしてオブジェクトに変換
        try {
          conditionData = json.decode(formData.jsonLogicCondition);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('JSON Logicの形式が正しくありません: $e')),
          );
          return;
        }
      } else {
        // 基本モードの場合、既存のconditionDataを使用
        conditionData = formData.conditionData;
      }

      // バッジデータを更新
      await FirebaseFirestore.instance.collection('badges').doc(widget.badgeId).update({
        'name': formData.name.trim(),
        'description': formData.description.trim(),
        'rarity': formData.rarity,
        'category': formData.category,
        'isActive': formData.isActive,
        'order': formData.order,
        'requiredValue': formData.requiredValue,
        'condition': conditionData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 画像が選択されている場合はアップロード
      final badgeCreateState = ref.read(badgeCreateProvider);
      if (badgeCreateState.selectedImage != null || badgeCreateState.webImageBytes != null) {
        final imageUrl = await ref.read(badgeCreateProvider.notifier).uploadImage(widget.badgeId);
        if (imageUrl != null) {
          await FirebaseFirestore.instance.collection('badges').doc(widget.badgeId).update({
            'imageUrl': imageUrl,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('バッジを更新しました'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 前の画面に戻る
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('バッジの更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}