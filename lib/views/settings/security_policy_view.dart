import 'package:flutter/material.dart';

class SecurityPolicyView extends StatelessWidget {
  const SecurityPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('セキュリティポリシー'),
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
            
            // 更新日セクション
            _buildUpdateSection(),
            
            const SizedBox(height: 24),
            
            // セキュリティポリシー本文
            _buildSecurityContent(),
            
            const SizedBox(height: 24),
            
            // お問い合わせセクション
            _buildContactSection(),
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
            Icons.security,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'セキュリティポリシー',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ぐるまっぷ店舗用における情報セキュリティについて',
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

  Widget _buildUpdateSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最終更新日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '2024年12月1日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityContent() {
    final sections = [
      {
        'title': '1. 情報セキュリティの基本方針',
        'content': '''ぐるまっぷ Inc.（以下「当社」）は、お客様の大切な情報を保護するため、情報セキュリティマネジメントシステム（ISMS）を構築し、継続的な改善を行っています。

当社は以下の基本方針に基づき、情報セキュリティを推進します：

• 機密性：許可されたユーザーのみが情報にアクセスできる
• 完全性：情報が正確かつ完全な状態で維持される
• 可用性：必要時に適切に情報を利用できる''',
      },
      {
        'title': '2. 技術的セキュリティ対策',
        'content': '''当社は以下の技術的セキュリティ対策を実装しています：

**データ暗号化**
• SSL/TLS 1.3による通信の暗号化
• AES-256によるデータ保存時の暗号化
• パスワードのハッシュ化（bcrypt）

**アクセス制御**
• 多要素認証（MFA）の導入
• ロールベースアクセス制御（RBAC）
• 最小権限の原則に基づく権限管理

**ネットワークセキュリティ**
• ファイアウォールによる通信制御
• 侵入検知システム（IDS）
• DDoS攻撃対策

**アプリケーションセキュリティ**
• セキュアコーディングの実践
• 定期的な脆弱性診断
• セキュリティテストの実施''',
      },
      {
        'title': '3. 物理的セキュリティ対策',
        'content': '''当社は以下の物理的セキュリティ対策を実施しています：

**データセンター**
• 24時間365日の監視・警備
• 生体認証による入退室管理
• 耐震・防火設備の完備
• バックアップ電源の確保

**オフィス**
• 入館管理システムの導入
• 重要エリアへの入退室ログ
• デスクロッキングの徹底
• 廃棄物の適切な処理''',
      },
      {
        'title': '4. 組織的セキュリティ対策',
        'content': '''当社は以下の組織的セキュリティ対策を実施しています：

**従業員教育**
• 定期的なセキュリティ研修
• フィッシング対策訓練
• インシデント対応訓練

**アクセス管理**
• 入退社時のアカウント管理
• 定期的なアクセス権限の見直し
• 第三者への情報開示管理

**監査・評価**
• 内部監査の実施
• 外部セキュリティ監査の受審
• 継続的な改善活動''',
      },
      {
        'title': '5. インシデント対応',
        'content': '''当社は以下のインシデント対応体制を構築しています：

**24時間監視体制**
• セキュリティオペレーションセンター（SOC）
• 異常検知システムの監視
• 自動アラート機能

**インシデント対応プロセス**
• 初期対応（1時間以内）
• 影響範囲の特定・封じ込め
• 原因調査・分析
• 復旧作業の実施
• 再発防止策の策定

**報告・通知**
• 関係者への迅速な報告
• 必要に応じた公的機関への報告
• お客様への適切な通知''',
      },
      {
        'title': '6. データ保護・プライバシー',
        'content': '''当社は以下のデータ保護・プライバシー対策を実施しています：

**データ分類**
• 機密レベルに応じたデータ分類
• 適切な保存期間の設定
• 期限切れデータの自動削除

**データ処理**
• 目的外利用の禁止
• 最小限のデータ収集
• 匿名化・仮名化の実施

**第三者管理**
• 委託先のセキュリティ評価
• 契約書でのセキュリティ要件明記
• 定期的な監査・評価''',
      },
      {
        'title': '7. コンプライアンス・認証',
        'content': '''当社は以下のコンプライアンス・認証を取得・維持しています：

**国際標準**
• ISO/IEC 27001（情報セキュリティマネジメント）
• ISO/IEC 27017（クラウドセキュリティ）
• ISO/IEC 27018（クラウドプライバシー）

**業界標準**
• SOC 2 Type II
• PCI DSS（決済カード業界）

**法的要件**
• 個人情報保護法への準拠
• GDPR（EU一般データ保護規則）への準拠
• 各業界の規制要件への対応''',
      },
      {
        'title': '8. セキュリティ意識向上',
        'content': '''当社は従業員のセキュリティ意識向上に取り組んでいます：

**定期的な教育**
• 月次セキュリティ研修
• 最新脅威情報の共有
• ケーススタディの実施

**実践的な訓練**
• フィッシングメールの模擬訓練
• ランサムウェア対策訓練
• インシデント対応シミュレーション

**意識向上活動**
• セキュリティポスターの掲示
• セキュリティニュースレターの発行
• ベストプラクティスの共有''',
      },
      {
        'title': '9. 継続的改善',
        'content': '''当社はセキュリティレベルを継続的に向上させています：

**定期的な評価**
• 年次セキュリティ評価
• 脅威インテリジェンスの活用
• ベンチマーキングの実施

**技術革新への対応**
• 新技術の評価・導入
• セキュリティツールの更新
• アーキテクチャの改善

**フィードバックの活用**
• お客様からのフィードバック
• 内部監査結果の活用
• インシデントからの学習''',
      },
      {
        'title': '10. お客様への協力要請',
        'content': '''セキュリティの向上には、お客様のご協力も不可欠です：

**アカウント管理**
• 強力なパスワードの設定
• 多要素認証の有効化
• 定期的なパスワード変更

**デバイス管理**
• 最新のセキュリティアップデート
• ウイルス対策ソフトの導入
• 不審なリンクのクリック回避

**情報共有**
• セキュリティインシデントの報告
• 不審な活動の通報
• フィードバックの提供''',
      },
    ];

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'セキュリティポリシー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sections.map((section) => _buildSecuritySection(
              title: section['title']!,
              content: section['content']!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.contact_support, color: const Color(0xFFFF6B35), size: 24),
              const SizedBox(width: 8),
              const Text(
                'セキュリティお問い合わせ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'セキュリティに関するご質問や、不審な活動を発見された場合は、以下までお気軽にお問い合わせください。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'セキュリティサポート',
            content: 'security@groumap.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.report_problem,
            title: 'インシデント報告',
            content: 'incident@groumap.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            title: '受付時間',
            content: '24時間365日対応',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            title: '緊急時連絡先',
            content: '03-1234-5678',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6B35),
          size: 20,
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
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
