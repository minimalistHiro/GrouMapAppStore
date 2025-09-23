import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルプ・サポート'),
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
            
            // よくある質問セクション
            _buildFAQSection(),
            
            const SizedBox(height: 24),
            
            // お問い合わせセクション
            _buildContactSection(),
            
            const SizedBox(height: 24),
            
            // アプリ情報セクション
            _buildAppInfoSection(context),
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
            Icons.help_outline,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'ヘルプ・サポート',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'よくある質問やサポート情報をご確認ください',
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

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'QRコードのスキャンができません',
        'answer': 'カメラの許可を確認し、QRコードが画面内に収まるように調整してください。また、照明が十分にあることを確認してください。',
      },
      {
        'question': '店舗情報を変更したい',
        'answer': '設定画面の「店舗プロフィール」から店舗情報を編集できます。',
      },
      {
        'question': 'クーポンの作成方法を教えて',
        'answer': 'ホーム画面の「新規クーポンを作成」ボタンから、またはクーポン管理画面から作成できます。',
      },
      {
        'question': 'ポイント付与の履歴を確認したい',
        'answer': 'ホーム画面の「ポイント履歴」から過去のポイント付与履歴を確認できます。',
      },
      {
        'question': 'アプリが正常に動作しません',
        'answer': 'アプリを再起動するか、ブラウザのキャッシュをクリアしてみてください。',
      },
      {
        'question': '店舗を切り替えたい',
        'answer': '設定画面の店舗情報カード右下の「店舗切り替え」ボタンから切り替えできます。',
      },
    ];

    return _buildSection(
      title: 'よくある質問',
      icon: Icons.quiz,
      children: faqs.map((faq) => _buildFAQItem(
        question: faq['question']!,
        answer: faq['answer']!,
      )).toList(),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
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

  Widget _buildContactSection() {
    return _buildSection(
      title: 'お問い合わせ',
      icon: Icons.contact_support,
      children: [
        _buildContactItem(
          icon: Icons.email,
          title: 'メールサポート',
          subtitle: 'support@groumap.com',
          onTap: () => _copyEmailToClipboard(),
        ),
        _buildContactItem(
          icon: Icons.phone,
          title: '電話サポート',
          subtitle: '平日 9:00-18:00',
          onTap: () => _showPhoneDialog(),
        ),
        _buildContactItem(
          icon: Icons.chat,
          title: 'ライブチャット',
          subtitle: 'オンラインで質問',
          onTap: () => _showChatDialog(),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
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

  Widget _buildAppInfoSection(BuildContext context) {
    return _buildSection(
      title: 'アプリ情報',
      icon: Icons.info,
      children: [
        _buildInfoItem(
          label: 'アプリバージョン',
          value: '1.0.0',
          copyable: false,
        ),
        _buildInfoItem(
          label: '最終更新日',
          value: '2024年12月',
          copyable: false,
        ),
        _buildInfoItem(
          label: 'プライバシーポリシー',
          value: 'プライバシーポリシーを確認',
          copyable: false,
          onTap: () => _navigateToPrivacyPolicy(context),
        ),
        _buildInfoItem(
          label: '利用規約',
          value: '利用規約を確認',
          copyable: false,
          onTap: () => _navigateToTermsOfService(context),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required bool copyable,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: copyable
          ? IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyToClipboard(value),
            )
          : onTap != null
              ? const Icon(Icons.chevron_right)
              : null,
      onTap: onTap,
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

  void _copyEmailToClipboard() {
    Clipboard.setData(const ClipboardData(text: 'support@groumap.com'));
    // 実際のアプリではスナックバーでコピー完了を通知
  }

  void _showPhoneDialog() {
    // 電話番号のダイアログを表示
    // 実際のアプリでは電話番号を表示
  }

  void _showChatDialog() {
    // ライブチャットのダイアログを表示
    // 実際のアプリではチャット機能を実装
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // コピー完了のスナックバーを表示
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(),
      ),
    );
  }

  void _navigateToTermsOfService(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceView(),
      ),
    );
  }


}
