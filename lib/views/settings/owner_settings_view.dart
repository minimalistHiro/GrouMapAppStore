import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/owner_settings_provider.dart';
import '../../models/owner_settings_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class OwnerSettingsView extends ConsumerStatefulWidget {
  const OwnerSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<OwnerSettingsView> createState() => _OwnerSettingsViewState();
}

class _OwnerSettingsViewState extends ConsumerState<OwnerSettingsView> {
  final _friendCampaignPointsController = TextEditingController();
  final _storeCampaignPointsController = TextEditingController();
  DateTime? _friendCampaignStartDate;
  DateTime? _friendCampaignEndDate;
  DateTime? _storeCampaignStartDate;
  DateTime? _storeCampaignEndDate;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _hasInitialized = false;
  bool _hasLocalEdits = false;

  @override
  void dispose() {
    _friendCampaignPointsController.dispose();
    _storeCampaignPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwnerAsync = ref.watch(userIsOwnerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('オーナー設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: ref.watch(ownerSettingsProvider).when(
        data: (settings) {
          _maybeInitialize(settings);
          final isOwner = isOwnerAsync.maybeWhen(
            data: (value) => value,
            orElse: () => false,
          );
          final hasSettings = settings != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isOwner)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'この設定は閲覧のみ可能です',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildSectionCard(
                  title: '友達紹介キャンペーン',
                  subtitle: '開始日と終了日を設定してください',
                  icon: Icons.group,
                  children: [
                    _buildDatePickerRow(
                      label: '開始日',
                      value: _friendCampaignStartDate,
                      onTap: () => _pickDate(
                        context: context,
                        initialDate: _friendCampaignStartDate,
                        onSelected: (date) {
                          setState(() {
                            _friendCampaignStartDate = date;
                            _hasLocalEdits = true;
                          });
                        },
                      ),
                    ),
                    _buildDatePickerRow(
                      label: '終了日',
                      value: _friendCampaignEndDate,
                      onTap: () => _pickDate(
                        context: context,
                        initialDate: _friendCampaignEndDate,
                        onSelected: (date) {
                          setState(() {
                            _friendCampaignEndDate = date;
                            _hasLocalEdits = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _friendCampaignPointsController,
                      labelText: '付与ポイント',
                      hintText: '例: 100',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.stars),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text('pt'),
                      ),
                      onChanged: (_) {
                        _hasLocalEdits = true;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: '店舗紹介キャンペーン',
                  subtitle: '開始日と終了日を設定してください',
                  icon: Icons.store,
                  children: [
                    _buildDatePickerRow(
                      label: '開始日',
                      value: _storeCampaignStartDate,
                      onTap: () => _pickDate(
                        context: context,
                        initialDate: _storeCampaignStartDate,
                        onSelected: (date) {
                          setState(() {
                            _storeCampaignStartDate = date;
                            _hasLocalEdits = true;
                          });
                        },
                      ),
                    ),
                    _buildDatePickerRow(
                      label: '終了日',
                      value: _storeCampaignEndDate,
                      onTap: () => _pickDate(
                        context: context,
                        initialDate: _storeCampaignEndDate,
                        onSelected: (date) {
                          setState(() {
                            _storeCampaignEndDate = date;
                            _hasLocalEdits = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _storeCampaignPointsController,
                      labelText: '付与ポイント',
                      hintText: '例: 50',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.stars),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text('pt'),
                      ),
                      onChanged: (_) {
                        _hasLocalEdits = true;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: '設定を保存',
                  onPressed: (!isOwner || _isSaving || _isDeleting)
                      ? null
                      : () => _saveSettings(context),
                  backgroundColor: const Color(0xFFFF6B35),
                  isLoading: _isSaving,
                ),
                if (isOwner) ...[
                  const SizedBox(height: 12),
                  CustomButton(
                    text: '設定を削除',
                    onPressed: (!hasSettings || _isSaving || _isDeleting)
                        ? null
                        : () => _confirmDelete(context),
                    backgroundColor: Colors.red,
                    isLoading: _isDeleting,
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('読み込みに失敗しました: $error'),
        ),
      ),
    );
  }

  void _maybeInitialize(OwnerSettings? settings) {
    if (settings == null) {
      if (_hasLocalEdits) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _friendCampaignStartDate = null;
          _friendCampaignEndDate = null;
          _storeCampaignStartDate = null;
          _storeCampaignEndDate = null;
          _friendCampaignPointsController.text = '';
          _storeCampaignPointsController.text = '';
          _hasInitialized = true;
        });
      });
      return;
    }
    if (_hasInitialized && _hasLocalEdits) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (_hasInitialized && _hasLocalEdits)) {
        return;
      }
      setState(() {
        _friendCampaignStartDate = settings.friendCampaignStartDate;
        _friendCampaignEndDate = settings.friendCampaignEndDate;
        _storeCampaignStartDate = settings.storeCampaignStartDate;
        _storeCampaignEndDate = settings.storeCampaignEndDate;
        _friendCampaignPointsController.text =
            settings.friendCampaignPoints?.toString() ?? '';
        _storeCampaignPointsController.text =
            settings.storeCampaignPoints?.toString() ?? '';
        _hasInitialized = true;
      });
    });
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      onSelected(selectedDate);
    }
  }

  Future<void> _saveSettings(BuildContext context) async {
    if (_hasInvalidDateRange(_friendCampaignStartDate, _friendCampaignEndDate)) {
      _showSnackBar(context, '友達紹介キャンペーンの終了日は開始日以降にしてください');
      return;
    }
    if (_hasInvalidDateRange(_storeCampaignStartDate, _storeCampaignEndDate)) {
      _showSnackBar(context, '店舗紹介キャンペーンの終了日は開始日以降にしてください');
      return;
    }

    final friendPointsText = _friendCampaignPointsController.text.trim();
    final storePointsText = _storeCampaignPointsController.text.trim();
    final friendPoints = _parsePoints(friendPointsText, context, '友達紹介');
    if (friendPointsText.isNotEmpty && friendPoints == null) {
      return;
    }
    final storePoints = _parsePoints(storePointsText, context, '店舗紹介');
    if (storePointsText.isNotEmpty && storePoints == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final settings = OwnerSettings(
        friendCampaignStartDate: _friendCampaignStartDate,
        friendCampaignEndDate: _friendCampaignEndDate,
        friendCampaignPoints: friendPoints,
        storeCampaignStartDate: _storeCampaignStartDate,
        storeCampaignEndDate: _storeCampaignEndDate,
        storeCampaignPoints: storePoints,
      );

      final service = ref.read(ownerSettingsServiceProvider);
      await service.saveOwnerSettings(settings: settings);

      if (mounted) {
        _showSnackBar(context, 'オーナー設定を保存しました', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, '保存に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('設定を削除しますか？'),
        content: const Text('キャンペーン期間の設定が全て削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteSettings(context);
    }
  }

  Future<void> _deleteSettings(BuildContext context) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final service = ref.read(ownerSettingsServiceProvider);
      await service.deleteOwnerSettings();

      if (mounted) {
        _showSnackBar(context, 'オーナー設定を削除しました', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, '削除に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  bool _hasInvalidDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return false;
    }
    return end.isBefore(start);
  }

  int? _parsePoints(String value, BuildContext context, String label) {
    if (value.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      _showSnackBar(context, '$labelの付与ポイントは0以上の数字で入力してください');
      return null;
    }
    return parsed;
  }

  void _showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFF6B35)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value == null ? '未設定' : _formatDate(value),
        style: TextStyle(
          color: value == null ? Colors.grey[500] : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.calendar_today, color: Color(0xFFFF6B35)),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }
}
