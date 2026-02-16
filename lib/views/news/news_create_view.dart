import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dismiss_keyboard.dart';

class NewsCreateView extends ConsumerStatefulWidget {
  const NewsCreateView({Key? key}) : super(key: key);

  @override
  ConsumerState<NewsCreateView> createState() => _NewsCreateViewState();
}

class _NewsCreateViewState extends ConsumerState<NewsCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  Uint8List? _selectedImage;
  DateTime? _publishStartDate;
  DateTime? _publishEndDate;

  final ImagePicker _picker = ImagePicker();

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImage = imageBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: Text('画像の選択に失敗しました: $e'),
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
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_publishStartDate ?? DateTime.now())
        : (_publishEndDate ?? (_publishStartDate ?? DateTime.now()).add(const Duration(days: 7)));
    final firstDate = isStart ? DateTime.now() : (_publishStartDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _publishStartDate = picked;
          // 終了日が開始日より前の場合はリセット
          if (_publishEndDate != null && _publishEndDate!.isBefore(picked)) {
            _publishEndDate = null;
          }
        } else {
          _publishEndDate = picked;
        }
      });
    }
  }

  Future<void> _createNews() async {
    if (!_formKey.currentState!.validate()) return;

    if (_publishStartDate == null || _publishEndDate == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('入力不備'),
          content: const Text('掲載開始日と掲載終了日を設定してください。'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーがログインしていません');

      final newsRef = FirebaseFirestore.instance.collection('news').doc();
      final newsId = newsRef.id;

      // 画像アップロード
      String? imageUrl;
      if (_selectedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'news/$newsId/image_$timestamp.jpg';
        try {
          final ref = FirebaseStorage.instance.ref().child(fileName);
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'newsId': newsId,
              'uploadedBy': user.uid,
              'uploadedAt': timestamp.toString(),
            },
          );
          final uploadTask = ref.putData(_selectedImage!, metadata);
          final snapshot = await uploadTask;
          imageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          // フォールバック: Base64
          try {
            final base64String = base64Encode(_selectedImage!);
            imageUrl = 'data:image/jpeg;base64,$base64String';
          } catch (_) {
            imageUrl = null;
          }
        }
      }

      // 掲載終了日は当日23:59:59に設定
      final endOfDay = DateTime(
        _publishEndDate!.year,
        _publishEndDate!.month,
        _publishEndDate!.day,
        23, 59, 59,
      );

      await newsRef.set({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': imageUrl,
        'publishStartDate': Timestamp.fromDate(_publishStartDate!),
        'publishEndDate': Timestamp.fromDate(endOfDay),
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
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
            content: Text('ニュースの作成に失敗しました: $e'),
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

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF6F2),
        body: SafeArea(
          child: Column(
            children: [
              const CommonHeader(title: 'ニュースを作成'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 画像選択
                        _buildImageSection(),
                        const SizedBox(height: 20),

                        // タイトル
                        _buildInputField(
                          controller: _titleController,
                          label: 'タイトル *',
                          hint: 'ニュースのタイトルを入力',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'タイトルを入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // テキスト
                        _buildInputField(
                          controller: _contentController,
                          label: 'テキスト *',
                          hint: 'ニュースの内容を入力',
                          icon: Icons.description,
                          maxLines: 6,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'テキストを入力してください';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 掲載開始日
                        _buildDateField(
                          label: '掲載開始日 *',
                          date: _publishStartDate,
                          onTap: () => _selectDate(context, true),
                        ),
                        const SizedBox(height: 20),

                        // 掲載終了日
                        _buildDateField(
                          label: '掲載終了日 *',
                          date: _publishEndDate,
                          onTap: () => _selectDate(context, false),
                        ),
                        const SizedBox(height: 32),

                        // 作成ボタン
                        CustomButton(
                          text: 'ニュースを作成',
                          onPressed: _isLoading ? null : _createNews,
                          isLoading: _isLoading,
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '画像（1:1）',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Image.memory(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: 1.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'タップして画像を選択',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  date != null ? _formatDate(date) : '日付を選択',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
