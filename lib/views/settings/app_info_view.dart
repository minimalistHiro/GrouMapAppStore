import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'privacy_policy_view.dart';
import 'terms_of_service_view.dart';
import 'security_policy_view.dart';
import 'email_support_view.dart';

class AppInfoView extends StatelessWidget {
  const AppInfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリについて'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アプリ情報セクション
            _buildAppInfoSection(),
            
            const SizedBox(height: 24),
            
            // 開発者情報セクション
            _buildDeveloperSection(),
            
            const SizedBox(height: 24),
            
            // ライセンス・法的事項セクション
            _buildLegalSection(context),
            
            const SizedBox(height: 24),
            
            // ソーシャルリンクセクション
            _buildSocialLinksSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return _buildSection(
      title: 'アプリ情報',
      icon: Icons.info,
      children: [
        _buildInfoItem(
          label: 'アプリ名',
          value: 'ぐるまっぷ店舗用',
          copyable: true,
        ),
        _buildInfoItem(
          label: 'バージョン',
          value: '1.2.0',
          copyable: true,
        ),
        _buildInfoItem(
          label: '最終更新日',
          value: '2026年3月1日',
          copyable: false,
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return _buildSection(
      title: '開発者情報',
      icon: Icons.developer_mode,
      children: [
        _buildInfoItem(
          label: '開発会社',
          value: 'ぐるまっぷ Inc.',
          copyable: true,
        ),
        _buildInfoItem(
          label: '代表者',
          value: '金子広樹',
          copyable: false,
        ),
        _buildInfoItem(
          label: '設立日',
          value: '2026年2月1日',
          copyable: false,
        ),
        _buildInfoItem(
          label: '所在地',
          value: '埼玉県川口市芝5-5-13',
          copyable: false,
        ),
        _buildInfoItem(
          label: '開発チーム',
          value: 'ぐるまっぷ Development Team',
          copyable: false,
        ),
        _buildInfoItem(
          label: 'サポートメール',
          value: 'info@groumapapp.com',
          copyable: true,
        ),
        _buildInfoItem(
          label: '電話サポート',
          value: '080-6050-7194（月〜金 11:00〜18:00）',
          copyable: true,
        ),
        _buildInfoItem(
          label: '公式ウェブサイト',
          value: 'https://groumap.com',
          copyable: true,
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return _buildSection(
      title: 'ライセンス・法的事項',
      icon: Icons.gavel,
      children: [
        _buildActionItem(
          icon: Icons.privacy_tip,
          title: 'プライバシーポリシー',
          subtitle: '個人情報の取り扱いについて',
          onTap: () => _navigateToPrivacyPolicy(context),
        ),
        _buildActionItem(
          icon: Icons.description,
          title: '利用規約',
          subtitle: 'サービスの利用条件について',
          onTap: () => _navigateToTermsOfService(context),
        ),
        _buildActionItem(
          icon: Icons.security,
          title: 'セキュリティポリシー',
          subtitle: 'データ保護とセキュリティ',
          onTap: () => _navigateToSecurityPolicy(context),
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection(BuildContext context) {
    return _buildSection(
      title: '公式アカウント',
      icon: Icons.share,
      children: [
        _buildActionItem(
          icon: Icons.language,
          title: '公式ウェブサイト',
          subtitle: 'https://groumap.com',
          onTap: () => _copyToClipboard('https://groumap.com'),
        ),
        _buildActionItem(
          icon: Icons.email,
          title: 'メールサポート',
          subtitle: 'お問い合わせフォームを開く',
          onTap: () => _navigateToEmailSupport(context),
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

  Widget _buildInfoItem({
    required String label,
    required String value,
    required bool copyable,
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
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
      trailing: copyable
          ? IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => _copyToClipboard(value),
            )
          : null,
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    // 実際のアプリではスナックバーでコピー完了を通知
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

  void _navigateToSecurityPolicy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SecurityPolicyView(),
      ),
    );
  }

  void _navigateToEmailSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailSupportView(),
      ),
    );
  }

  void _showLicenseInfo() {
    // ライセンス情報を表示
    // 実際のアプリではライセンスページを表示
  }

}
