import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsView extends ConsumerStatefulWidget {
  const NotificationSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends ConsumerState<NotificationSettingsView> {
  // 通知設定の状態管理
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  
  // 各種通知の設定
  bool _newVisitorNotifications = true;
  bool _couponUsageNotifications = true;
  bool _paymentNotifications = true;
  bool _systemNotifications = true;
  bool _promotionNotifications = false;
  bool _feedbackNotifications = true;
  
  // 通知時間の設定
  String _notificationTime = '09:00';
  bool _quietHours = false;
  String _quietStartTime = '22:00';
  String _quietEndTime = '08:00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            _buildHeaderSection(),
            
            const SizedBox(height: 24),
            
            // 通知方法セクション
            _buildNotificationMethodSection(),
            
            const SizedBox(height: 24),
            
            // 通知内容セクション
            _buildNotificationContentSection(),
            
            const SizedBox(height: 24),
            
            // 通知時間セクション
            _buildNotificationTimeSection(),
            
            const SizedBox(height: 24),
            
            // プライバシーセクション
            _buildPrivacySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '通知設定',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'お好みに合わせて通知をカスタマイズ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationMethodSection() {
    return _buildSection(
      title: '通知方法',
      icon: Icons.settings,
      children: [
        _buildSwitchItem(
          title: 'プッシュ通知',
          subtitle: 'アプリ内での通知を受け取る',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: 'メール通知',
          subtitle: '重要な通知をメールで受け取る',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: 'SMS通知',
          subtitle: '緊急の通知をSMSで受け取る',
          value: _smsNotifications,
          onChanged: (value) {
            setState(() {
              _smsNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationContentSection() {
    return _buildSection(
      title: '通知内容',
      icon: Icons.notifications_active,
      children: [
        _buildSwitchItem(
          title: '新規来店者通知',
          subtitle: 'お客様が来店した時に通知',
          value: _newVisitorNotifications,
          onChanged: (value) {
            setState(() {
              _newVisitorNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: 'クーポン使用通知',
          subtitle: 'クーポンが使用された時に通知',
          value: _couponUsageNotifications,
          onChanged: (value) {
            setState(() {
              _couponUsageNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: '支払い通知',
          subtitle: '支払いが完了した時に通知',
          value: _paymentNotifications,
          onChanged: (value) {
            setState(() {
              _paymentNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: 'システム通知',
          subtitle: 'アプリの更新やメンテナンス情報',
          value: _systemNotifications,
          onChanged: (value) {
            setState(() {
              _systemNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: 'プロモーション通知',
          subtitle: '新機能やキャンペーンのお知らせ',
          value: _promotionNotifications,
          onChanged: (value) {
            setState(() {
              _promotionNotifications = value;
            });
          },
        ),
        _buildSwitchItem(
          title: 'フィードバック通知',
          subtitle: 'お客様からのフィードバックが届いた時に通知',
          value: _feedbackNotifications,
          onChanged: (value) {
            setState(() {
              _feedbackNotifications = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationTimeSection() {
    return _buildSection(
      title: '通知時間',
      icon: Icons.access_time,
      children: [
        _buildTimePickerItem(
          title: 'デフォルト通知時間',
          subtitle: '毎日の通知を送る時間',
          time: _notificationTime,
          onTap: () => _selectTime('notification'),
        ),
        _buildSwitchItem(
          title: 'おやすみ時間を設定',
          subtitle: '指定時間内は通知を停止',
          value: _quietHours,
          onChanged: (value) {
            setState(() {
              _quietHours = value;
            });
          },
        ),
        if (_quietHours) ...[
          _buildTimePickerItem(
            title: 'おやすみ開始時間',
            subtitle: '通知を停止する時間',
            time: _quietStartTime,
            onTap: () => _selectTime('quietStart'),
          ),
          _buildTimePickerItem(
            title: 'おやすみ終了時間',
            subtitle: '通知を再開する時間',
            time: _quietEndTime,
            onTap: () => _selectTime('quietEnd'),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'プライバシー',
      icon: Icons.privacy_tip,
      children: [
        _buildActionItem(
          icon: Icons.delete,
          title: '通知履歴をクリア',
          subtitle: '過去の通知履歴をすべて削除',
          onTap: _clearNotificationHistory,
        ),
        _buildActionItem(
          icon: Icons.block,
          title: 'すべての通知を停止',
          subtitle: '一時的にすべての通知を無効にする',
          onTap: _disableAllNotifications,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFF6B35),
      ),
    );
  }

  Widget _buildTimePickerItem({
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.red,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _selectTime(String type) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

    if (picked != null) {
      setState(() {
        final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        switch (type) {
          case 'notification':
            _notificationTime = timeString;
            break;
          case 'quietStart':
            _quietStartTime = timeString;
            break;
          case 'quietEnd':
            _quietEndTime = timeString;
            break;
        }
      });
    }
  }

  void _saveSettings() {
    // 設定を保存する処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('通知設定を保存しました'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearNotificationHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知履歴をクリア'),
        content: const Text('過去の通知履歴をすべて削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('通知履歴をクリアしました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _disableAllNotifications() {
    setState(() {
      _pushNotifications = false;
      _emailNotifications = false;
      _smsNotifications = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('すべての通知を無効にしました'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
