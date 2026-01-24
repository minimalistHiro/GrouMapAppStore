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
  final _basePointReturnRateController = TextEditingController();
  final List<_LevelRateRangeControllers> _levelRateRanges = [];
  final List<_LevelRateRangeControllers> _pendingDisposals = [];
  DateTime? _friendCampaignStartDate;
  DateTime? _friendCampaignEndDate;
  DateTime? _storeCampaignStartDate;
  DateTime? _storeCampaignEndDate;
  DateTime? _maintenanceStartDate;
  DateTime? _maintenanceEndDate;
  String? _maintenanceStartTime;
  String? _maintenanceEndTime;
  bool _isSaving = false;
  bool _hasInitialized = false;
  bool _hasLocalEdits = false;

  @override
  void dispose() {
    _friendCampaignPointsController.dispose();
    _storeCampaignPointsController.dispose();
    _basePointReturnRateController.dispose();
    _clearLevelRateRanges(deferDispose: false);
    _disposePendingRanges();
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
                  title: 'ポイント還元率',
                  subtitle: '一律の還元率(%)を設定します',
                  icon: Icons.percent,
                  children: [
                    CustomTextField(
                      controller: _basePointReturnRateController,
                      labelText: 'ポイント還元率(%)',
                      hintText: '例: 1.0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.percent),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Text('%'),
                      ),
                      onChanged: (_) {
                        _hasLocalEdits = true;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'レベル別ポイント還元率',
                  subtitle: 'レベル範囲ごとの還元率(%)を設定します',
                  icon: Icons.stacked_line_chart,
                  children: [
                    for (var i = 0; i < _levelRateRanges.length; i++)
                      _buildLevelRateRangeRow(
                        index: i,
                        controllers: _levelRateRanges[i],
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _addLevelRateRange();
                            _hasLocalEdits = true;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('範囲を追加'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'メンテナンス時間',
                  subtitle: '開始日/終了日と開始時間/終了時間を設定してください',
                  icon: Icons.build,
                  children: [
                    _buildDateTimePickerRow(
                      label: '開始',
                      date: _maintenanceStartDate,
                      time: _maintenanceStartTime,
                      onTap: () => _pickDateTime(
                        context: context,
                        initialDate: _maintenanceStartDate,
                        initialTime: _maintenanceStartTime,
                        onSelected: (date, time) {
                          setState(() {
                            _maintenanceStartDate = date;
                            _maintenanceStartTime = time;
                            _hasLocalEdits = true;
                          });
                        },
                      ),
                    ),
                    _buildDateTimePickerRow(
                      label: '終了',
                      date: _maintenanceEndDate,
                      time: _maintenanceEndTime,
                      onTap: () => _pickDateTime(
                        context: context,
                        initialDate: _maintenanceEndDate,
                        initialTime: _maintenanceEndTime,
                        onSelected: (date, time) {
                          setState(() {
                            _maintenanceEndDate = date;
                            _maintenanceEndTime = time;
                            _hasLocalEdits = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: '設定を保存',
                  onPressed: (!isOwner || _isSaving)
                      ? null
                      : () => _saveSettings(context),
                  backgroundColor: const Color(0xFFFF6B35),
                  isLoading: _isSaving,
                ),
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
          _maintenanceStartDate = null;
          _maintenanceEndDate = null;
          _maintenanceStartTime = null;
          _maintenanceEndTime = null;
          _friendCampaignPointsController.text = '';
          _storeCampaignPointsController.text = '';
          _basePointReturnRateController.text = '';
          _setLevelRateRanges(null);
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
        _basePointReturnRateController.text =
            settings.basePointReturnRate?.toString() ?? '';
        _setLevelRateRanges(settings.levelPointReturnRateRanges);
        _maintenanceStartDate = settings.maintenanceStartDate;
        _maintenanceEndDate = settings.maintenanceEndDate;
        _maintenanceStartTime = settings.maintenanceStartTime;
        _maintenanceEndTime = settings.maintenanceEndTime;
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

  Future<void> _pickDateTime({
    required BuildContext context,
    required DateTime? initialDate,
    required String? initialTime,
    required void Function(DateTime date, String time) onSelected,
  }) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    final parsedTime = _parseTime(initialTime);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: parsedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) {
      return;
    }

    onSelected(selectedDate, _formatTime(selectedTime));
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
    if (_hasInvalidMaintenanceRange()) {
      _showSnackBar(context, 'メンテナンス終了は開始以降にしてください');
      return;
    }

    final baseRateText = _basePointReturnRateController.text.trim();
    final basePointReturnRate = _parseRate(baseRateText, context);
    if (baseRateText.isNotEmpty && basePointReturnRate == null) {
      return;
    }
    final levelRateRanges = _parseLevelRateRanges(context);
    if (levelRateRanges == null) {
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
        basePointReturnRate: basePointReturnRate,
        levelPointReturnRateRanges:
            levelRateRanges.isEmpty ? null : levelRateRanges,
        maintenanceStartDate: _maintenanceStartDate,
        maintenanceEndDate: _maintenanceEndDate,
        maintenanceStartTime: _maintenanceStartTime,
        maintenanceEndTime: _maintenanceEndTime,
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

  bool _hasInvalidDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return false;
    }
    return end.isBefore(start);
  }

  bool _hasInvalidMaintenanceRange() {
    if (_maintenanceStartDate == null ||
        _maintenanceEndDate == null ||
        _maintenanceStartTime == null ||
        _maintenanceEndTime == null) {
      return false;
    }
    final start = _combineDateTime(
      _maintenanceStartDate!,
      _maintenanceStartTime!,
    );
    final end = _combineDateTime(
      _maintenanceEndDate!,
      _maintenanceEndTime!,
    );
    if (start == null || end == null) {
      return false;
    }
    return end.isBefore(start);
  }

  double? _parseRate(String value, BuildContext context) {
    if (value.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) {
      _showSnackBar(context, 'ポイント還元率は0以上の数字で入力してください');
      return null;
    }
    return parsed;
  }

  List<LevelPointReturnRateRange>? _parseLevelRateRanges(BuildContext context) {
    final List<LevelPointReturnRateRange> result = [];
    for (var i = 0; i < _levelRateRanges.length; i++) {
      final controllers = _levelRateRanges[i];
      final minText = controllers.minLevel.text.trim();
      final maxText = controllers.maxLevel.text.trim();
      final rateText = controllers.rate.text.trim();
      if (minText.isEmpty && maxText.isEmpty && rateText.isEmpty) {
        continue;
      }
      final minLevel = int.tryParse(minText);
      final maxLevel = controllers.noUpperLimit ? null : int.tryParse(maxText);
      final rate = double.tryParse(rateText);
      if (minLevel == null || minLevel < 1) {
        _showSnackBar(context, '範囲${i + 1}の開始レベルは1以上で入力してください');
        return null;
      }
      if (!controllers.noUpperLimit) {
        if (maxLevel == null || maxLevel < minLevel) {
          _showSnackBar(context, '範囲${i + 1}の終了レベルは開始以上で入力してください');
          return null;
        }
      }
      if (rate == null || rate < 0) {
        _showSnackBar(context, '範囲${i + 1}の還元率は0以上の数字で入力してください');
        return null;
      }
      result.add(LevelPointReturnRateRange(
        minLevel: minLevel,
        maxLevel: maxLevel,
        rate: rate,
      ));
    }
    if (!_validateLevelRateOverlap(result, context)) {
      return null;
    }
    return result;
  }

  bool _validateLevelRateOverlap(
    List<LevelPointReturnRateRange> ranges,
    BuildContext context,
  ) {
    if (ranges.length <= 1) {
      return true;
    }
    final sorted = [...ranges]
      ..sort((a, b) {
        if (a.minLevel != b.minLevel) {
          return a.minLevel.compareTo(b.minLevel);
        }
        final aMax = a.maxLevel ?? 1 << 30;
        final bMax = b.maxLevel ?? 1 << 30;
        return aMax.compareTo(bMax);
      });
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final current = sorted[i];
      final prevMax = prev.maxLevel ?? 1 << 30;
      if (current.minLevel <= prevMax) {
        _showSnackBar(context, 'レベル範囲が重複しています（範囲${i}と範囲${i + 1}）');
        return false;
      }
    }
    return true;
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

  Widget _buildLevelRateRangeRow({
    required int index,
    required _LevelRateRangeControllers controllers,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '範囲${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controllers.minLevel,
                    labelText: '開始レベル',
                    hintText: '例: 1',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.arrow_upward),
                    onChanged: (_) {
                      _hasLocalEdits = true;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: controllers.maxLevel,
                    labelText: '終了レベル',
                    hintText: '例: 10',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.arrow_downward),
                    enabled: !controllers.noUpperLimit,
                    onChanged: (_) {
                      _hasLocalEdits = true;
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: controllers.noUpperLimit,
                  onChanged: (value) {
                    setState(() {
                      controllers.noUpperLimit = value ?? false;
                      if (controllers.noUpperLimit) {
                        controllers.maxLevel.text = '';
                      }
                      _hasLocalEdits = true;
                    });
                  },
                ),
                const Text('上限なし（例: 101以上）'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controllers.rate,
                    labelText: '還元率(%)',
                    hintText: '例: 1.0',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.percent),
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text('%'),
                    ),
                    onChanged: (_) {
                      _hasLocalEdits = true;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _levelRateRanges.length <= 1
                      ? null
                      : () {
                          setState(() {
                            _removeLevelRateRange(index);
                            _hasLocalEdits = true;
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  tooltip: '削除',
                ),
              ],
            ),
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

  Widget _buildDateTimePickerRow({
    required String label,
    required DateTime? date,
    required String? time,
    required VoidCallback onTap,
  }) {
    final value = (date != null && time != null) ? _formatDateTime(date, time) : '未設定';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(
          color: value == '未設定' ? Colors.grey[500] : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.schedule, color: Color(0xFFFF6B35)),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime date, String time) {
    return '${_formatDate(date)} $time';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _combineDateTime(DateTime date, String time) {
    final parsed = _parseTime(time);
    if (parsed == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  }

  void _setLevelRateRanges(List<LevelPointReturnRateRange>? ranges) {
    _clearLevelRateRanges(deferDispose: true);
    if (ranges == null || ranges.isEmpty) {
      _addLevelRateRange();
      return;
    }
    for (final range in ranges) {
      _levelRateRanges.add(_LevelRateRangeControllers(
        minLevel: range.minLevel.toString(),
        maxLevel: range.maxLevel?.toString(),
        rate: range.rate.toString(),
        noUpperLimit: range.maxLevel == null,
      ));
    }
  }

  void _addLevelRateRange() {
    _levelRateRanges.add(_LevelRateRangeControllers());
  }

  void _removeLevelRateRange(int index) {
    final controllers = _levelRateRanges.removeAt(index);
    _queueRangeForDisposal(controllers);
    if (_levelRateRanges.isEmpty) {
      _addLevelRateRange();
    }
  }

  void _clearLevelRateRanges({required bool deferDispose}) {
    for (final controllers in _levelRateRanges) {
      if (deferDispose) {
        _queueRangeForDisposal(controllers);
      } else {
        controllers.dispose();
      }
    }
    _levelRateRanges.clear();
  }

  void _queueRangeForDisposal(_LevelRateRangeControllers controllers) {
    _pendingDisposals.add(controllers);
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _disposePendingRanges();
    });
  }

  void _disposePendingRanges() {
    for (final controllers in _pendingDisposals) {
      controllers.dispose();
    }
    _pendingDisposals.clear();
  }
}

class _LevelRateRangeControllers {
  final TextEditingController minLevel;
  final TextEditingController maxLevel;
  final TextEditingController rate;
  bool noUpperLimit;

  _LevelRateRangeControllers({
    String? minLevel,
    String? maxLevel,
    String? rate,
    this.noUpperLimit = false,
  })  : minLevel = TextEditingController(text: minLevel ?? ''),
        maxLevel = TextEditingController(text: maxLevel ?? ''),
        rate = TextEditingController(text: rate ?? '');

  void dispose() {
    minLevel.dispose();
    maxLevel.dispose();
    rate.dispose();
  }
}
