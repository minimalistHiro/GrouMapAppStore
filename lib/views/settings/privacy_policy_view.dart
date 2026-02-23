import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _metaStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF757575),
  );

  static const _sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.7,
    color: Color(0xFF424242),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ぐるまっぷ店舗用 プライバシーポリシー', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2026年2月20日', style: _metaStyle),
            const Text('改定日: 2026年2月23日', style: _metaStyle),
            const SizedBox(height: 20),
            _buildSection(
              title: '1. 事業者情報',
              bullets: const [
                '事業者名: ぐるまっぷ Inc.',
                '代表者: 金子広樹',
                '所在地: 埼玉県川口市芝5-5-13',
                'サポートメール: info@groumapapp.com',
                '電話サポート: 080-6050-7194（平日 11:00-18:00）',
                '公式サイト: https://groumap.com',
              ],
            ),
            _buildSection(
              title: '2. 適用範囲',
              text:
                  '本ポリシーは、ぐるまっぷ店舗用アプリおよび関連機能（以下「本サービス」）における、加盟店舗および店舗関係者の情報取扱いに適用されます。',
            ),
            _buildSection(
              title: '3. 取得する情報',
              text: '当社は、次の情報を取得することがあります。',
              bullets: const [
                'アカウント情報: 氏名、メールアドレス、電話番号、認証プロバイダ情報',
                '店舗情報: 店舗名、経営形態、住所、営業時間、カテゴリ、連絡先、決済方法、設備情報、画像、SNS連携情報',
                '契約・請求情報: プラン、契約状態、請求関連情報、決済関連の識別情報（例: カードブランド・下4桁）',
                '操作情報: 管理画面操作履歴、通知設定、ログイン履歴',
                '利用実績情報: 来店記録、スタンプ付与履歴、クーポン発行・利用統計、分析データ',
                'ユーザー関連データ（店舗運営上必要な範囲）: 来店者集計、取引時の性別・年代・地域等のスナップショット情報',
                '端末・ログ情報: IPアドレス、OS、端末識別情報、アクセス日時、エラーログ、FCMトークン',
                'お問い合わせ情報: 問い合わせ内容、返信先情報',
              ],
            ),
            _buildSection(
              title: '4. 利用目的',
              text: '当社は、取得した情報を以下の目的で利用します。',
              bullets: const [
                '本サービスの提供、運営、保守、改善',
                '店舗管理機能（店舗情報管理、スタンプ運用、クーポン運用、投稿管理、分析表示等）の提供',
                '契約管理、請求関連手続、サポート対応',
                '通知配信および重要なお知らせ',
                '不正利用防止、セキュリティ対策、障害対応',
                '統計分析およびサービス品質向上',
                '法令に基づく対応',
              ],
            ),
            _buildSection(
              title: '5. 第三者提供',
              text: '当社は、次の場合を除き、個人情報を第三者に提供しません。',
              bullets: const [
                '本人の同意がある場合',
                '法令に基づく場合',
                '人の生命、身体または財産の保護のために必要な場合',
                '公衆衛生の向上または児童の健全育成の推進のために特に必要な場合',
                '国の機関等への協力が必要な場合',
                '利用目的達成に必要な範囲で業務委託する場合',
              ],
            ),
            _buildSection(
              title: '6. 委託および国外移転',
              text: '当社は、運営上必要な範囲で外部事業者へ業務委託を行います。',
              bullets: const [
                '主な委託先: Google LLC（Firebase関連サービス）',
                '当該委託に伴い、情報が外国（例: 米国その他、委託先提供体制に応じた国・地域）で取り扱われる場合があります。',
              ],
              footerText: '当社は、委託先の選定と監督を適切に行い、必要な安全管理措置を講じます。',
            ),
            _buildSection(
              title: '7. 安全管理措置',
              text: '当社は、情報の漏えい、滅失、毀損を防止するため、次の措置を講じます。',
              bullets: const [
                '通信の暗号化（TLS）',
                'アクセス権限管理、認証制御、多要素の本人確認手段',
                '監査ログ管理、不正アクセス監視',
                '脆弱性対策、セキュリティアップデート',
                '社内教育、取扱手順整備',
              ],
            ),
            _buildSection(
              title: '8. 保有期間',
              text: '当社は、利用目的に必要な期間または法令上必要な期間、情報を保有します。',
              bullets: const [
                '契約・請求関連情報は、会計・税務・監査等の法令対応のため、必要期間保管する場合があります。',
                '店舗からのアカウント削除申請時は、当社所定フローに従って利用停止・無効化を実施します。',
                '法令対応・紛争対応・不正対策上必要な範囲で、データを一定期間保持する場合があります。',
              ],
            ),
            _buildSection(
              title: '9. 開示・訂正・削除等',
              text:
                  '加盟店舗または情報主体は、当社所定の方法により、自己情報の開示、訂正、追加、削除、利用停止を請求できます。請求時には本人確認をお願いする場合があります。',
            ),
            _buildSection(
              title: '10. Cookie等・通知',
              text:
                  '当社は、利便性向上・利用分析のためにCookieまたは類似技術（ローカルストレージ等）を利用する場合があります。また、通知配信のためにFCMトークン等を利用します。',
            ),
            _buildSection(
              title: '11. ポリシーの変更',
              text:
                  '当社は、法令改正やサービス変更に応じて本ポリシーを改定することがあります。重要な変更時は、アプリ内通知その他相当な方法で周知します。',
            ),
            _buildSection(
              title: '12. お問い合わせ窓口',
              text: '本ポリシーに関するお問い合わせは、アプリ内のお問い合わせ窓口または以下までご連絡ください。',
              bullets: const [
                'メール: info@groumapapp.com',
                '公式サイト: https://groumap.com',
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? text,
    List<String>? bullets,
    String? footerText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _sectionTitleStyle),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(text, style: _bodyStyle),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 8),
            _buildBulletList(bullets),
          ],
          if (footerText != null) ...[
            const SizedBox(height: 8),
            Text(footerText, style: _bodyStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: _bodyStyle),
                  Expanded(child: Text(item, style: _bodyStyle)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
