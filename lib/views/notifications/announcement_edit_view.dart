import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common_header.dart';
import '../../widgets/dismiss_keyboard.dart';

class AnnouncementEditView extends ConsumerStatefulWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementEditView({Key? key, required this.announcement}) : super(key: key);

  @override
  ConsumerState<AnnouncementEditView> createState() => _AnnouncementEditViewState();
}

class _AnnouncementEditViewState extends ConsumerState<AnnouncementEditView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  late String _selectedCategory;
  late String _selectedPriority;
  bool _isLoading = false;
  DateTime? _scheduledDate;
  bool _schedulePublish = false;

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
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement['title'] ?? '');
    _contentController = TextEditingController(text: widget.announcement['content'] ?? '');
    _selectedCategory = widget.announcement['category'] ?? '一般';
    _selectedPriority = widget.announcement['priority'] ?? '通常';

    // カテゴリ・優先度がリストにない場合はデフォルト値にする
    if (!_categories.contains(_selectedCategory)) _selectedCategory = '一般';
    if (!_priorities.contains(_selectedPriority)) _selectedPriority = '通常';

    // 予約投稿の復元
    final dynamic scheduledDateData = widget.announcement['scheduledDate'];
    if (scheduledDateData != null) {
      _schedulePublish = true;
      if (scheduledDateData is Timestamp) {
        _scheduledDate = scheduledDateData.toDate();
      } else if (scheduledDateData is DateTime) {
        _scheduledDate = scheduledDateData;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    if (_schedulePublish && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('予約投稿日時を選択してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.announcement['id'])
          .update({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'isPublished': !_schedulePublish,
        'scheduledDate': _schedulePublish ? Timestamp.fromDate(_scheduledDate!) : null,
        'publishedAt': !_schedulePublish ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: Text('お知らせの更新に失敗しました: $e'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
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

  Future<void> _selectScheduledDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _scheduledDate != null
            ? TimeOfDay.fromDateTime(_scheduledDate!)
            : TimeOfDay.now(),
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
    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF6F2),
        body: SafeArea(
          child: Column(
            children: [
              const CommonHeader(title: 'お知らせを編集'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

                        // 保存ボタン
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateAnnouncement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
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
                                : const Text(
                                    '保存',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
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
            prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey[600]) : null,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
