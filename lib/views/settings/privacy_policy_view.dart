import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
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

            // プライバシーポリシー本文
            _buildPolicyContent(),

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
            Icons.privacy_tip,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'プライバシーポリシー',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ぐるまっぷ店舗用における個人情報の取り扱いについて',
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最終更新日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '2026年2月20日',
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

  Widget _buildPolicyContent() {
    final sections = [
      {
        'title': '1. 取得する情報',
        'content': '''当社は、ぐるまっぷ店舗用（以下「本サービス」）の提供にあたり、以下の情報を取得する場合があります。

• アカウント情報（氏名、メールアドレス、電話番号、認証プロバイダ情報等）
• 店舗情報（店舗名、住所、営業時間、連絡先、店舗画像、カテゴリ等）
• 契約・請求情報（加盟店舗プランの申込情報、決済情報等）
• 利用履歴（来店記録管理、スタンプ・ポイント付与履歴、クーポン発行・使用履歴、売上データ等）
• 行動情報（管理画面の操作ログ、通知確認状況等）
• 端末情報・ログ情報（IPアドレス、ブラウザ・OS情報、アクセス日時、FCMトークン等）''',
      },
      {
        'title': '2. 利用目的',
        'content': '''収集した情報は、以下の目的で利用します。

• 本サービスの提供、運営、保守、改善のため
• 店舗管理機能（メニュー管理、クーポン発行、スタンプカード管理等）の提供のため
• 加盟店舗への連絡、サポート対応のため
• プッシュ通知およびお知らせの配信のため
• 不正利用の防止、セキュリティ確保のため
• 売上分析・来店データの集計および表示のため
• 新機能やキャンペーン等の案内のため
• 統計情報の作成およびサービス改善のため（個人を特定しない形）
• 法令に基づく対応のため''',
      },
      {
        'title': '3. 第三者提供',
        'content': '''当社は、以下の場合を除き、個人情報を第三者に提供しません。

• 利用者の同意がある場合
• 法令に基づく場合
• 人の生命、身体または財産の保護のために必要な場合
• 公衆衛生の向上または児童の健全な育成の推進のために特に必要がある場合
• 業務委託先に必要な範囲で提供する場合（第4項参照）''',
      },
      {
        'title': '4. 委託',
        'content':
            '当社は、サービス運営に必要な範囲で、個人情報の取り扱いを外部事業者に委託することがあります。委託先には、Firebase（Google LLC）等のクラウドサービスを含みます。この場合、適切な委託先の選定および管理を行います。',
      },
      {
        'title': '5. 安全管理',
        'content': '''当社は、個人情報の漏えい、滅失、毀損の防止その他の安全管理のために必要かつ適切な措置を講じます。

• SSL/TLS暗号化による通信の保護
• アクセス制御による情報への不正アクセス防止
• 定期的なセキュリティ監査・脆弱性診断
• 従業員への個人情報保護教育
• 適切な保管期間の設定と期限切れデータの削除''',
      },
      {
        'title': '6. 位置情報の取り扱い',
        'content':
            '本サービスでは、店舗の位置登録・地図表示のために位置情報を利用します。店舗の住所から取得した緯度経度情報は、ユーザーアプリでの店舗表示や距離計算に使用されます。',
      },
      {
        'title': '7. プッシュ通知',
        'content':
            '本サービスでは、来店通知・予約通知・クーポン関連通知等のためにプッシュ通知を使用する場合があります。利用者はアプリ内の通知設定から通知項目ごとの受信可否を変更できます。',
      },
      {
        'title': '8. 保有期間',
        'content':
            '当社は、利用目的に必要な期間に限り個人情報を保有し、不要となった情報は適切な方法で削除または匿名化します。',
      },
      {
        'title': '9. 開示・訂正・削除等',
        'content':
            '利用者は、当社所定の方法により、自己の個人情報の開示、訂正、追加、削除、利用停止を求めることができます。また、利用者はアプリ内のアカウント設定からアカウント削除（退会）を行うことができ、この場合、関連する個人情報が削除されます。',
      },
      {
        'title': '10. クッキー等の利用',
        'content': '''当社は、利便性向上や利用状況分析のためにクッキーや類似技術（ローカルストレージ等）を使用する場合があります。

• Cookie：ユーザー設定の保存、利用状況の分析
• ローカルストレージ：アプリデータの一時保存
• アナリティクス：サービス利用状況の分析

これらにより収集される情報は、個人を特定しない形で処理されます。''',
      },
      {
        'title': '11. 未成年者の個人情報',
        'content':
            '未成年者（18歳未満）の個人情報については、保護者の同意を得た上で収集・利用いたします。保護者の方は、お子様の個人情報の開示・訂正・削除を求めることができます。',
      },
      {
        'title': '12. ポリシーの改定',
        'content':
            '当社は、法令の改正やサービス内容の変更等に応じて本ポリシーを改定することがあります。重要な変更の場合、当社はアプリ内通知等の合理的な方法で告知します。',
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
                Icon(Icons.description, color: const Color(0xFFFF6B35), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'プライバシーポリシー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sections.map((section) => _buildPolicySection(
              title: section['title']!,
              content: section['content']!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
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
                'お問い合わせ',
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
            '個人情報の取り扱いに関するご質問やご不明な点がございましたら、アプリ内のお問い合わせ窓口または当社が指定する方法にてご連絡ください。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            icon: Icons.email,
            title: 'サポートメール',
            content: 'support@groumap.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.access_time,
            title: '受付時間',
            content: '平日 9:00-18:00（土日祝日を除く）',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone,
            title: '電話サポート',
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
