import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneSupportView extends StatelessWidget {
  const PhoneSupportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('電話サポート'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーセクション
            _buildHeaderSection(),
            
            const SizedBox(height: 24),
            
            // 電話番号セクション
            _buildPhoneNumberSection(context),
            
            const SizedBox(height: 24),
            
            // 営業時間セクション
            _buildBusinessHoursSection(),
            
            const SizedBox(height: 24),
            
            // 対応内容セクション
            _buildSupportContentSection(),
            
            const SizedBox(height: 24),
            
            // 注意事項セクション
            _buildNoticeSection(),
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
            Icons.phone,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '電話サポート',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '専門スタッフがお客様のお困りごとをサポートいたします',
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

  Widget _buildPhoneNumberSection(BuildContext context) {
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.phone_in_talk, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'サポート電話番号',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6B35).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '080-6050-7194',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _copyPhoneNumber(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('コピー'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _callPhoneNumber(context),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('電話をかける'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.access_time, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  '営業時間',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                _buildBusinessHoursItem(
                  day: '平日',
                  time: '9:00 - 18:00',
                  isToday: _isWeekday(),
                ),
                const SizedBox(height: 12),
                _buildBusinessHoursItem(
                  day: '土曜日',
                  time: '9:00 - 15:00',
                  isToday: _isSaturday(),
                ),
                const SizedBox(height: 12),
                _buildBusinessHoursItem(
                  day: '日曜日・祝日',
                  time: '休業',
                  isToday: _isSundayOrHoliday(),
                  isHoliday: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursItem({
    required String day,
    required String time,
    required bool isToday,
    bool isHoliday = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday 
            ? const Color(0xFFFF6B35).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday 
              ? const Color(0xFFFF6B35).withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isToday ? const Color(0xFFFF6B35) : Colors.black87,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isHoliday 
                  ? Colors.red[600]
                  : isToday 
                      ? const Color(0xFFFF6B35)
                      : Colors.black87,
            ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '今日',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportContentSection() {
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.support_agent, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  '対応内容',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                _buildSupportItem(
                  icon: Icons.bug_report,
                  title: 'アプリの不具合',
                  description: 'アプリの動作に関する問題やエラーについて',
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  icon: Icons.help_outline,
                  title: '機能の使い方',
                  description: 'アプリの操作方法や機能について',
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  icon: Icons.account_circle,
                  title: 'アカウント関連',
                  description: 'ログインやアカウント設定について',
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  icon: Icons.payment,
                  title: '支払い・請求',
                  description: '料金や支払い方法について',
                ),
                const SizedBox(height: 12),
                _buildSupportItem(
                  icon: Icons.security,
                  title: 'セキュリティ',
                  description: 'セキュリティやプライバシーについて',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6B35),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeSection() {
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'ご注意事項',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNoticeItem(
                  '営業時間外のお電話は、翌営業日に順次対応させていただきます。',
                ),
                const SizedBox(height: 8),
                _buildNoticeItem(
                  '混雑時はお待ちいただく場合がございます。ご了承ください。',
                ),
                const SizedBox(height: 8),
                _buildNoticeItem(
                  'お問い合わせの際は、お客様のアカウント情報をお手元にご用意ください。',
                ),
                const SizedBox(height: 8),
                _buildNoticeItem(
                  '通話料金はお客様のご負担となります。',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B35),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _copyPhoneNumber(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: '080-6050-7194'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('電話番号をクリップボードにコピーしました'),
        backgroundColor: Color(0xFFFF6B35),
      ),
    );
  }

  void _callPhoneNumber(BuildContext context) async {
    final phoneNumber = 'tel:08060507194';
    try {
      if (await canLaunchUrl(Uri.parse(phoneNumber))) {
        await launchUrl(Uri.parse(phoneNumber));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('電話アプリを開けませんでした'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('エラーが発生しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isWeekday() {
    final now = DateTime.now();
    return now.weekday >= 1 && now.weekday <= 5;
  }

  bool _isSaturday() {
    final now = DateTime.now();
    return now.weekday == 6;
  }

  bool _isSundayOrHoliday() {
    final now = DateTime.now();
    return now.weekday == 7; // 日曜日
    // 実際のアプリでは祝日判定も追加することをお勧めします
  }
}
