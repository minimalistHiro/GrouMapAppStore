import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/auth_provider.dart';

// scheduleOverrides の type 定数
const String _kClosed = 'closed';
const String _kOpen = 'open';
const String _kSpecialHours = 'special_hours';

class ScheduleCalendarView extends ConsumerStatefulWidget {
  const ScheduleCalendarView({super.key});

  @override
  ConsumerState<ScheduleCalendarView> createState() =>
      _ScheduleCalendarViewState();
}

class _ScheduleCalendarViewState extends ConsumerState<ScheduleCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, Map<String, dynamic>> _scheduleOverrides = {};
  Map<String, Map<String, dynamic>> _businessHours = {};
  bool _isRegularHoliday = false;
  bool _isLoading = true;
  String? _storeId;

  static const List<String> _dayKeys = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  @override
  void initState() {
    super.initState();
    // 日本語ロケールを初期化してから店舗データを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initializeDateFormatting('ja_JP', null);
      if (mounted) _loadStoreData();
    });
  }

  Future<void> _loadStoreData() async {
    // StreamProvider の現在値を取得
    final storeIdValue = ref.read(userStoreIdProvider);
    final storeId = storeIdValue.valueOrNull;
    if (storeId == null) {
      setState(() => _isLoading = false);
      return;
    }
    _storeId = storeId;

    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
    if (!doc.exists || !mounted) return;
    final data = doc.data()!;

    final rawOverrides = data['scheduleOverrides'];
    final rawHours = data['businessHours'];

    setState(() {
      _isRegularHoliday = data['isRegularHoliday'] ?? false;
      if (rawOverrides is Map) {
        _scheduleOverrides = Map<String, Map<String, dynamic>>.from(
          rawOverrides.map(
            (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
          ),
        );
      }
      if (rawHours is Map) {
        _businessHours = Map<String, Map<String, dynamic>>.from(
          rawHours.map(
            (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
          ),
        );
      }
      _isLoading = false;
    });
  }

  // 日付キー（yyyy-MM-dd）を返す
  String _dateKey(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  // 指定日がデフォルトで営業日かを曜日から判定
  bool _isDefaultOpen(DateTime day) {
    if (_isRegularHoliday) return false;
    final dayKey = _dayKeys[day.weekday - 1];
    final dayData = _businessHours[dayKey];
    if (dayData == null) return false;
    return dayData['isOpen'] == true;
  }

  // 指定日のオーバーライドを取得
  Map<String, dynamic>? _getOverride(DateTime day) {
    return _scheduleOverrides[_dateKey(day)];
  }

  // Firestore にオーバーライドを保存
  Future<void> _saveOverride(
    DateTime day,
    String type, {
    String? note,
    String? open,
    String? close,
  }) async {
    if (_storeId == null) return;
    final key = _dateKey(day);
    final Map<String, dynamic> value = {'type': type};
    if (note != null && note.isNotEmpty) value['note'] = note;
    if (open != null && open.isNotEmpty) value['open'] = open;
    if (close != null && close.isNotEmpty) value['close'] = close;

    await FirebaseFirestore.instance
        .collection('stores')
        .doc(_storeId)
        .update({'scheduleOverrides.$key': value});

    setState(() {
      _scheduleOverrides[key] = value;
    });
  }

  // Firestore からオーバーライドを削除
  Future<void> _deleteOverride(DateTime day) async {
    if (_storeId == null) return;
    final key = _dateKey(day);
    await FirebaseFirestore.instance
        .collection('stores')
        .doc(_storeId)
        .update({'scheduleOverrides.$key': FieldValue.delete()});

    setState(() {
      _scheduleOverrides.remove(key);
    });
  }

  // 日付マーカーの色を返す
  Color? _markerColor(DateTime day) {
    final override = _getOverride(day);
    if (override != null) {
      switch (override['type']) {
        case _kClosed:
          return Colors.red;
        case _kOpen:
          return Colors.green;
        case _kSpecialHours:
          return Colors.blue;
      }
    }
    return null;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) return; // 過去日は操作不可
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _showOverrideSheet(selectedDay);
  }

  void _showOverrideSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ScheduleOverrideSheet(
        day: day,
        isRegularHoliday: _isRegularHoliday,
        currentOverride: _getOverride(day),
        isDefaultOpen: _isDefaultOpen(day),
        businessHours: _businessHours,
        dayKey: _dayKeys[day.weekday - 1],
        onSave: (type, note, open, close) async {
          Navigator.pop(context);
          await _saveOverride(day, type, note: note, open: open, close: close);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('スケジュールを保存しました')),
            );
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteOverride(day);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('設定を削除しました（通常営業に戻しました）')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('営業カレンダー'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 凡例
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _legendDot(Colors.red, '臨時休業'),
                      const SizedBox(width: 16),
                      _legendDot(Colors.blue, '時間変更'),
                      const SizedBox(width: 16),
                      _legendDot(Colors.green,
                          _isRegularHoliday ? '通常営業' : '臨時営業'),
                    ],
                  ),
                ),

                // カレンダー
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 180)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  locale: 'ja_JP',
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(fontSize: 14),
                    weekendTextStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final color = _markerColor(day);
                      if (color == null) return const SizedBox.shrink();
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                    // 定休日は背景をグレーに
                    defaultBuilder: (context, day, focusedDay) {
                      if (!_isDefaultOpen(day) && _getOverride(day) == null) {
                        return _grayDayCell(day);
                      }
                      return null;
                    },
                    outsideBuilder: (context, day, focusedDay) => null,
                  ),
                ),

                const Divider(height: 1),

                // 設定済みスケジュール一覧
                Expanded(
                  child: _buildOverrideList(),
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _grayDayCell(DateTime day) {
    return Center(
      child: Text(
        day.day.toString(),
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOverrideList() {
    // 今日以降のオーバーライドを日付順でソート
    final today = DateTime.now();
    final entries = _scheduleOverrides.entries
        .where((e) {
          final d = DateTime.tryParse(e.key);
          return d != null &&
              !d.isBefore(DateTime(today.year, today.month, today.day));
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'スケジュール変更の登録がありません\nカレンダーの日付をタップして追加できます',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final day = DateTime.parse(entry.key);
        final override = entry.value;
        final type = override['type'] as String? ?? '';
        final note = override['note'] as String? ?? '';
        final open = override['open'] as String? ?? '';
        final close = override['close'] as String? ?? '';

        Color chipColor;
        String typeLabel;
        IconData typeIcon;
        switch (type) {
          case _kClosed:
            chipColor = Colors.red;
            typeLabel = '臨時休業';
            typeIcon = Icons.cancel;
            break;
          case _kOpen:
            chipColor = Colors.green;
            typeLabel = '臨時営業';
            typeIcon = Icons.check_circle;
            break;
          default:
            chipColor = Colors.blue;
            typeLabel = '時間変更';
            typeIcon = Icons.schedule;
        }

        final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
        final dateStr =
            '${day.year}/${day.month.toString().padLeft(2, '0')}/${day.day.toString().padLeft(2, '0')}（${weekdays[day.weekday - 1]}）';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: chipColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: chipColor, size: 20),
          ),
          title: Text(dateStr,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: chipColor.withOpacity(0.4)),
                ),
                child: Text(
                  type == _kSpecialHours && open.isNotEmpty && close.isNotEmpty
                      ? '$typeLabel  $open〜$close'
                      : type == _kOpen && open.isNotEmpty && close.isNotEmpty
                          ? '$typeLabel  $open〜$close'
                          : typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: chipColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(note,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _deleteOverride(day),
            tooltip: '削除',
          ),
          onTap: () => _showOverrideSheet(day),
        );
      },
    );
  }
}

// ボトムシート：スケジュールオーバーライドの設定
class _ScheduleOverrideSheet extends StatefulWidget {
  final DateTime day;
  final bool isRegularHoliday;
  final Map<String, dynamic>? currentOverride;
  final bool isDefaultOpen;
  final Map<String, Map<String, dynamic>> businessHours;
  final String dayKey;
  final Future<void> Function(String type, String? note, String? open, String? close) onSave;
  final Future<void> Function() onDelete;

  const _ScheduleOverrideSheet({
    required this.day,
    required this.isRegularHoliday,
    required this.currentOverride,
    required this.isDefaultOpen,
    required this.businessHours,
    required this.dayKey,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_ScheduleOverrideSheet> createState() => _ScheduleOverrideSheetState();
}

class _ScheduleOverrideSheetState extends State<_ScheduleOverrideSheet> {
  String _selectedType = '';
  final _noteController = TextEditingController();
  String _openTime = '09:00';
  String _closeTime = '18:00';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final override = widget.currentOverride;
    if (override != null) {
      _selectedType = override['type'] as String? ?? '';
      _noteController.text = override['note'] as String? ?? '';
      _openTime = override['open'] as String? ?? '09:00';
      _closeTime = override['close'] as String? ?? '18:00';
    } else {
      // デフォルトの時間を営業時間から取得
      final dayData = widget.businessHours[widget.dayKey];
      if (dayData != null) {
        _openTime = dayData['open'] as String? ?? '09:00';
        _closeTime = dayData['close'] as String? ?? '18:00';
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpen) async {
    final parts = (isOpen ? _openTime : _closeTime).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) {
          _openTime = formatted;
        } else {
          _closeTime = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dateStr =
        '${widget.day.month}月${widget.day.day}日（${weekdays[widget.day.weekday - 1]}）';

    final bool needsTime =
        _selectedType == _kOpen || _selectedType == _kSpecialHours;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 日付タイトル
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            // 現在のデフォルト状態
            const SizedBox(height: 4),
            Text(
              widget.isRegularHoliday
                  ? '通常：定休日（不定休）'
                  : widget.isDefaultOpen
                      ? '通常：営業日'
                      : '通常：定休日',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            // 選択肢
            _buildOption(
              type: '',
              label: '通常通り（設定なし）',
              icon: Icons.refresh,
              color: Colors.grey,
            ),

            if (!widget.isRegularHoliday && widget.isDefaultOpen) ...[
              const SizedBox(height: 8),
              _buildOption(
                type: _kClosed,
                label: '臨時休業',
                icon: Icons.cancel,
                color: Colors.red,
              ),
              const SizedBox(height: 8),
              _buildOption(
                type: _kSpecialHours,
                label: '時間変更',
                icon: Icons.schedule,
                color: Colors.blue,
              ),
            ],

            if (!widget.isRegularHoliday && !widget.isDefaultOpen) ...[
              const SizedBox(height: 8),
              _buildOption(
                type: _kOpen,
                label: '臨時営業',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],

            if (widget.isRegularHoliday) ...[
              const SizedBox(height: 8),
              _buildOption(
                type: _kOpen,
                label: '通常営業',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ],

            // 時間入力（open / special_hours の場合）
            if (needsTime) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      label: '開始',
                      value: _openTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('〜', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: _buildTimeTile(
                      label: '終了',
                      value: _closeTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ],

            // メモ入力
            if (_selectedType.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'メモ（任意）',
                  hintText: '例：棚卸しのため',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                maxLength: 40,
                textInputAction: TextInputAction.done,
              ),
            ],

            const SizedBox(height: 20),

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        if (_selectedType.isEmpty) {
                          await widget.onDelete();
                        } else {
                          await widget.onSave(
                            _selectedType,
                            _noteController.text.trim(),
                            needsTime ? _openTime : null,
                            needsTime ? _closeTime : null,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        '保存',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
