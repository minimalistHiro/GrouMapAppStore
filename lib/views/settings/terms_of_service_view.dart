import 'package:flutter/material.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

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
        title: const Text('利用規約'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ぐるまっぷ店舗用 利用規約', style: _titleStyle),
            const SizedBox(height: 6),
            const Text('制定日: 2026年2月20日', style: _metaStyle),
            const Text('改定日: 2026年2月23日', style: _metaStyle),
            const SizedBox(height: 20),
            _buildSection(
              title: '第1条（適用）',
              text:
                  '本規約は、ぐるまっぷ店舗用（以下「本サービス」）の提供条件および利用に関する当社と利用者との間の権利義務を定めます。利用者は本規約に同意のうえ本サービスを利用するものとします。',
            ),
            _buildSection(
              title: '第2条（定義）',
              bullets: const [
                '「利用者」: 本サービスを利用する加盟店舗、店舗管理者、会社管理者その他の関係者',
                '「加盟店舗」: 当社所定の審査・登録を経て本サービスを利用する店舗',
                '「店舗管理者」: 個別店舗の運用権限を有する者',
                '「会社管理者」: 複数店舗を統括管理する権限を有する者',
                '「ユーザー」: ぐるまっぷユーザー向けサービスの利用者',
              ],
            ),
            _buildSection(
              title: '第3条（サービス内容）',
              text:
                  '本サービスは、加盟店舗向けに、店舗情報管理、スタンプ運用、クーポン運用、投稿管理、分析表示、通知配信、サポート機能等を提供します。機能詳細は当社が別途定めます。',
            ),
            _buildSection(
              title: '第4条（登録・アカウント管理）',
              bullets: const [
                '1. 利用者は、登録情報を真実かつ最新に保つものとします。',
                '2. 利用者は、自己の責任でアカウントを管理し、第三者への譲渡・貸与を行ってはなりません。',
                '3. 当社は、虚偽申請、規約違反歴、その他不適切な事情がある場合、登録を拒否または取消すことができます。',
              ],
            ),
            _buildSection(
              title: '第5条（店舗情報および法令遵守）',
              bullets: const [
                '1. 加盟店舗は、店舗情報（名称、住所、営業時間、連絡先、クーポン条件等）の正確性を保証するものとします。',
                '2. 加盟店舗は、景品表示法、特定商取引法、食品衛生関連法令その他適用法令を遵守して本サービスを利用するものとします。',
                '3. 加盟店舗は、法令または公序良俗に反する表示・投稿・勧誘を行ってはなりません。',
              ],
            ),
            _buildSection(
              title: '第6条（スタンプ・クーポン運用）',
              bullets: const [
                '1. 加盟店舗は、当社所定ルールに従い、スタンプ付与およびクーポン発行・管理を行えます。',
                '2. スタンプ達成特典は、当社仕様により値引型に制限される場合があります。',
                '3. クーポン内容（割引条件、有効期限、対象範囲等）に関する責任は加盟店舗が負います。',
                '4. ユーザーとのトラブルは、当社に故意または重過失がある場合を除き、加盟店舗と当該ユーザーの間で解決するものとします。',
              ],
            ),
            _buildSection(
              title: '第7条（コイン交換クーポンに関する特則）',
              bullets: const [
                '1. ユーザー向けコインは無償付与のみで運用され、有償販売・払戻し・現金化は行われません。',
                '2. コイン交換クーポン（例: 未訪問店舗向けクーポン）は、当社が定める条件で配布・利用されます。',
                '3. 当社と加盟店舗間で、コイン自体の精算は行いません（現時点）。',
              ],
            ),
            _buildSection(
              title: '第8条（料金・支払い）',
              bullets: const [
                '1. 本サービスの料金体系は、当社が別途提示するプラン（無料枠/有料枠を含む）に従います。',
                '2. 請求開始日、請求周期、決済手段、更新・解約条件等は、プラン画面または別途通知で定めます。',
                '3. 利用者が支払義務を履行しない場合、当社は機能制限、契約停止その他必要な措置を講じることができます。',
              ],
            ),
            _buildSection(
              title: '第9条（禁止事項）',
              text: '利用者は、次の行為をしてはなりません。',
              bullets: const [
                '法令または公序良俗に反する行為',
                '虚偽情報登録、なりすまし、権限外操作',
                'QRコード偽造、不正アクセス、解析、スクレイピング等',
                'ユーザー情報の不正取得、不適切な二次利用',
                '当社システムへの過度な負荷または運営妨害',
                '当社または第三者の権利侵害',
                'その他当社が不適切と判断する行為',
              ],
            ),
            _buildSection(
              title: '第10条（知的財産権）',
              text: '本サービスおよび関連資料・プログラム等に関する知的財産権は当社または正当な権利者に帰属します。',
            ),
            _buildSection(
              title: '第11条（秘密保持）',
              text:
                  '利用者は、本サービス利用を通じて知り得た当社または第三者の非公知情報を、当社の事前承諾なく第三者へ開示・漏えいしてはなりません。',
            ),
            _buildSection(
              title: '第12条（個人情報・ユーザーデータの取扱い）',
              bullets: const [
                '1. 利用者は、ユーザー情報を本サービス運用目的の範囲でのみ利用し、適用法令を遵守して適切に管理するものとします。',
                '2. 当社は、利用者に関する情報を別途定めるプライバシーポリシーに従って取り扱います。',
              ],
            ),
            _buildSection(
              title: '第13条（アカウント削除申請・契約終了）',
              bullets: const [
                '1. 利用者は、当社所定の方法でアカウント削除申請または解約申請を行えます。',
                '2. 申請後の処理は、当社審査・運用フローに従って実施され、必要に応じて店舗公開停止または機能停止を行います。',
                '3. 法令対応・会計監査・紛争対応等のため、必要なデータを一定期間保有する場合があります。',
              ],
            ),
            _buildSection(
              title: '第14条（サービスの変更・中断・終了）',
              bullets: const [
                '1. 当社は、必要に応じて本サービスの全部または一部を変更、中断、終了できます。',
                '2. 保守、障害、災害、通信障害その他やむを得ない事由により、事前通知なく中断する場合があります。',
              ],
            ),
            _buildSection(
              title: '第15条（利用停止）',
              text:
                  '利用者が本規約に違反した場合、当社は事前通知なく、アカウント停止、店舗機能停止、契約解除等の措置を行うことができます。',
            ),
            _buildSection(
              title: '第16条（免責）',
              bullets: const [
                '1. 当社は、本サービスが特定目的に適合すること、継続的に利用可能であること、無瑕疵であることを保証しません。',
                '2. 当社は、当社の故意または重過失による場合を除き、利用者に生じた損害について責任を負いません。',
                '3. ユーザーとの個別紛争、店舗の営業上損失、第三者サービス障害等について、当社は責任を負いません。',
              ],
            ),
            _buildSection(
              title: '第17条（規約の変更）',
              text:
                  '当社は、法令改正またはサービス変更等に応じて本規約を変更できるものとします。重要な変更時は、アプリ内通知その他相当な方法で周知します。',
            ),
            _buildSection(
              title: '第18条（分離可能性）',
              text: '本規約の一部が無効または執行不能と判断されても、その他の規定は有効に存続します。',
            ),
            _buildSection(
              title: '第19条（準拠法・管轄）',
              text:
                  '本規約は日本法に準拠し、本サービスに関して紛争が生じた場合、当社所在地を管轄する裁判所を第一審の専属的合意管轄裁判所とします。',
            ),
            _buildSection(
              title: '第20条（事業者情報・お問い合わせ）',
              bullets: const [
                '事業者名: ぐるまっぷ Inc.',
                '代表者: 金子広樹',
                '所在地: 埼玉県川口市芝5-5-13',
                'メール: info@groumapapp.com',
                '公式サイト: https://groumap.com',
              ],
              footerText: 'お問い合わせは、アプリ内のお問い合わせ窓口または上記連絡先までご連絡ください。',
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
