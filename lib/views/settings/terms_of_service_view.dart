import 'package:flutter/material.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
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

            // 利用規約本文
            _buildTermsContent(),

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
            Icons.description,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            '利用規約',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ぐるまっぷ店舗用サービスの利用条件について',
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

  Widget _buildTermsContent() {
    final sections = [
      {
        'title': '第1条（適用）',
        'content':
            '本規約は、ぐるまっぷ店舗用（以下「本サービス」）の提供条件および本サービスの利用に関する当社（本サービス運営者）と利用者との間の権利義務関係を定めるものです。利用者は本規約に同意の上、本サービスを利用するものとします。',
      },
      {
        'title': '第2条（定義）',
        'content': '''本規約において使用する用語の定義は以下の通りです。

• 「利用者」とは、本サービスを利用するすべての方をいいます。
• 「加盟店舗」とは、当社と契約し本サービスに登録・利用する飲食店等をいいます。
• 「店舗管理者」とは、加盟店舗の運営・管理を行う権限を持つ利用者をいいます。
• 「会社管理者」とは、複数の加盟店舗を統括管理する権限を持つ利用者をいいます。
• 「スタンプカード」とは、来店客のチェックイン管理および特典付与のための機能をいいます。
• 「クーポン」とは、加盟店舗が発行する割引・特典券をいいます。''',
      },
      {
        'title': '第3条（サービス内容）',
        'content': '''本サービスは、飲食店等の加盟店舗向けに以下の機能を提供するプラットフォームサービスです。

• 店舗情報の登録・管理（メニュー、営業時間、写真等）
• スタンプカードの作成・管理
• クーポンの発行・管理
• 来店客のチェックイン管理（QRコード生成）
• 売上・来店データの分析
• お知らせ・通知の配信
• ユーザーアプリとの連携機能''',
      },
      {
        'title': '第4条（アカウント登録）',
        'content': '''1. 本サービスの利用にあたり、当社が指定する情報の登録が必要となります。登録情報は正確かつ最新の状態で維持してください。
2. 利用者は、メールアドレス/パスワード、Googleアカウント、またはApple IDにより登録・ログインできます。
3. 利用者は、自己の責任においてアカウント情報を適切に管理するものとし、第三者に譲渡または貸与することはできません。
4. 当社は、利用登録の申請者に虚偽の事項がある場合、本規約に違反したことがある場合、その他相当でないと判断した場合、利用登録を承認しないことがあります。''',
      },
      {
        'title': '第5条（店舗情報の管理）',
        'content': '''1. 加盟店舗は、登録する店舗情報（店舗名、住所、営業時間、メニュー、写真等）が正確であることを保証するものとします。
2. 店舗情報に変更が生じた場合、速やかに本サービス上で情報を更新してください。
3. 虚偽または誤解を招く店舗情報の登録は禁止されています。''',
      },
      {
        'title': '第6条（スタンプカード・クーポンの取扱い）',
        'content': '''1. 加盟店舗は、本サービスを通じてスタンプカードの作成およびクーポンの発行を行うことができます。
2. スタンプカードおよびクーポンの内容（特典、有効期限、利用条件等）は、各加盟店舗が設定するものとし、その内容について責任を負います。
3. 発行済みクーポンに関するユーザーとのトラブルは、原則として加盟店舗が対応するものとします。''',
      },
      {
        'title': '第7条（料金および支払い）',
        'content': '''1. 本サービスの基本機能は、5店舗まで無料でご利用いただけます。
2. 6店舗目以降の登録には、月額課金プラン（ベーシック等）への加入が必要です。
3. 料金プランの詳細は、別途当社が提示する条件に従います。
4. 決済手段として届け出たクレジットカードが利用停止となった場合や、支払債務の不履行があった場合、サービスの利用を制限することがあります。''',
      },
      {
        'title': '第8条（禁止事項）',
        'content': '''利用者は、本サービスの利用にあたり、以下の行為をしてはなりません。

• 法令または公序良俗に違反する行為
• 虚偽情報の登録、なりすまし、第三者の権利侵害
• QRコードの不正利用、偽造・複製
• 来店データやユーザー情報の不正な収集・蓄積・利用
• 本サービスの運営を妨害する行為（不正アクセスを含む）
• 本サービスによって得られた情報を不正に商業的に利用する行為
• 当社が不適切と判断する行為''',
      },
      {
        'title': '第9条（知的財産権）',
        'content':
            '本サービスに関する一切の知的財産権は当社または正当な権利者に帰属します。利用者は、当社の許諾なくこれらを利用することはできません。',
      },
      {
        'title': '第10条（サービスの変更・停止）',
        'content': '''1. 当社は、必要に応じて本サービスの内容変更、提供の中断または終了を行うことがあります。
2. システム保守、天災、通信障害等のやむを得ない事由により、事前の通知なくサービスを一時停止する場合があります。
3. これにより利用者に損害が生じた場合でも、当社は責任を負いません。''',
      },
      {
        'title': '第11条（利用停止・退会）',
        'content': '''1. 利用者が本規約に違反した場合、当社は事前通知なく利用停止またはアカウント削除を行うことがあります。
2. 利用者は、当社の定める退会手続によりアカウントを削除できます。
3. 退会に伴い、店舗情報・スタンプカード・クーポン・売上データその他の関連データは削除されます。''',
      },
      {
        'title': '第12条（免責）',
        'content': '''1. 当社は、本サービスに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティ等に関する欠陥、エラーやバグ、権利侵害等を含みます）がないことを保証しません。
2. 利用者が被った損害について、当社は当社の故意または重過失による場合を除き責任を負いません。
3. ユーザーアプリ利用者との間で生じた紛争は、利用者と当該ユーザーとの間で解決するものとし、当社は一切の責任を負いません。''',
      },
      {
        'title': '第13条（個人情報の取扱い）',
        'content':
            '当社は、本サービスの利用によって取得する個人情報については、当社「プライバシーポリシー」に従い適切に取り扱うものとします。',
      },
      {
        'title': '第14条（規約の変更）',
        'content':
            '当社は、必要に応じて本規約を変更できます。重要な変更の場合、当社はアプリ内通知等の合理的な方法で告知します。変更後に利用者が本サービスを利用した場合、変更後の規約に同意したものとみなします。',
      },
      {
        'title': '第15条（準拠法・管轄）',
        'content':
            '本規約は日本法に準拠し、本サービスに関して紛争が生じた場合、当社の所在地を管轄する裁判所を専属的合意管轄とします。',
      },
      {
        'title': '第16条（お問い合わせ）',
        'content':
            '本サービスに関するお問い合わせは、アプリ内のお問い合わせ窓口または当社が指定する方法にてご連絡ください。',
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
                  '利用規約',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sections.map((section) => _buildTermsSection(
              title: section['title']!,
              content: section['content']!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection({required String title, required String content}) {
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
            '本利用規約に関するご質問やご不明な点がございましたら、アプリ内のお問い合わせ窓口または当社が指定する方法にてご連絡ください。',
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
