import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAnnouncementView extends StatefulWidget {
  const CreateAnnouncementView({super.key});

  @override
  State<CreateAnnouncementView> createState() => _CreateAnnouncementViewState();
}

class _CreateAnnouncementViewState extends State<CreateAnnouncementView> {
  final _formKey = GlobalKey<FormState>();
  
  // コントローラー
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  // 状態管理
  String _selectedCategory = '一般';
  String _selectedPriority = '通常';
  bool _isLoading = false;
  DateTime? _scheduledDate;
  bool _schedulePublish = false;

  // Firebase関連
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _categories = [
    '一般',
    'システム',
    'メンテナンス',
    'キャンペーン',
    'アップデート',
    'その他',
  ];

  final List<String> _priorities = [
    '低',
    '通常',
    '高',
    '緊急',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // お知らせを作成
  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // お知らせIDを生成
      final announcementId = _firestore.collection('announcements').doc().id;
      
      // Firestoreにお知らせ情報を保存
      await _firestore.collection('announcements').doc(announcementId).set({
        'id': announcementId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isPublished': !_schedulePublish, // 予約投稿でない場合は即座に公開
        'scheduledDate': _schedulePublish ? Timestamp.fromDate(_scheduledDate!) : null,
        'publishedAt': !_schedulePublish ? FieldValue.serverTimestamp() : null,
        'readCount': 0,
        'totalViews': 0,
        'tags': [], // 将来的にタグ機能を追加する場合
      });

      if (mounted) {
        // 成功ダイアログを表示
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'お知らせ作成完了',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '「${_titleController.text.trim()}」が正常に作成されました！',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'お知らせID: $announcementId',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _schedulePublish 
                        ? '※ 指定した日時に自動公開されます。'
                        : '※ お知らせは即座に公開されました。',
                    style: TextStyle(
                      fontSize: 12,
                      color: _schedulePublish ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 前の画面に戻る
                  },
                  child: const Text('OK'),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('お知らせ作成に失敗しました: $e'),
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

  // 予約投稿日時を選択
  Future<void> _selectScheduledDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _scheduledDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '新規お知らせ作成',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.announcement,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '新しいお知らせを作成',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ユーザーに重要な情報をお届けしましょう',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // タイトル
              _buildInputField(
                controller: _titleController,
                label: 'タイトル *',
                hint: '例：アプリメンテナンスのお知らせ',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.trim().length < 3) {
                    return 'タイトルは3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // カテゴリ・優先度
              Row(
                children: [
                  Expanded(child: _buildCategoryDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPriorityDropdown()),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 内容
              _buildInputField(
                controller: _contentController,
                label: '内容 *',
                hint: 'お知らせの詳細内容を入力してください',
                icon: Icons.description,
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '内容を入力してください';
                  }
                  if (value.trim().length < 10) {
                    return '内容は10文字以上で入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // 予約投稿設定
              _buildScheduleSection(),
              
              const SizedBox(height: 32),
              
              // 作成ボタン
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _schedulePublish ? 'お知らせを予約投稿' : 'お知らせを即座に公開',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 注意事項
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'お知らせは全ユーザーに表示されます。内容を十分確認してから公開してください。',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリ *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '優先度 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPriority,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: _priorities.map((String priority) {
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        size: 16,
                        color: _getPriorityColor(priority),
                      ),
                      const SizedBox(width: 8),
                      Text(priority),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPriority = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
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
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                '公開設定',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: _schedulePublish,
                onChanged: (value) {
                  setState(() {
                    _schedulePublish = value;
                    if (!value) {
                      _scheduledDate = null;
                    }
                  });
                },
                activeColor: const Color(0xFFFF6B35),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _schedulePublish ? '予約投稿する' : '即座に公開する',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          if (_schedulePublish) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectScheduledDate,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _scheduledDate == null
                      ? '公開日時を選択'
                      : '${_scheduledDate!.year}/${_scheduledDate!.month}/${_scheduledDate!.day} ${_scheduledDate!.hour.toString().padLeft(2, '0')}:${_scheduledDate!.minute.toString().padLeft(2, '0')}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_scheduledDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '指定した日時に自動公開されます',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case '低':
        return Icons.keyboard_arrow_down;
      case '通常':
        return Icons.remove;
      case '高':
        return Icons.keyboard_arrow_up;
      case '緊急':
        return Icons.warning;
      default:
        return Icons.remove;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case '低':
        return Colors.grey;
      case '通常':
        return Colors.blue;
      case '高':
        return Colors.orange;
      case '緊急':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
