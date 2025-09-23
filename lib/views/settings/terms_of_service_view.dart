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
            'GrouMap Storeサービスの利用条件について',
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

  Widget _buildTermsContent() {
    final sections = [
      {
        'title': '第1条（適用）',
        'content': '''本利用規約（以下「本規約」といいます。）は、GrouMap Inc.（以下「当社」といいます。）が提供するGrouMap Storeサービス（以下「本サービス」といいます。）の利用条件を定めるものです。登録ユーザーの皆さま（以下「ユーザー」といいます。）には、本規約に従って、本サービスをご利用いただきます。''',
      },
      {
        'title': '第2条（利用登録）',
        'content': '''本サービスにおいては、登録希望者が本規約に同意の上、当社の定める方法によって利用登録を申請し、当社がこれを承認することによって、利用登録が完了するものとします。

当社は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあり、その理由については一切の開示義務を負わないものとします：

• 利用登録の申請に際して虚偽の事項を届け出た場合
• 本規約に違反したことがある者からの申請である場合
• その他、当社が利用登録を相当でないと判断した場合''',
      },
      {
        'title': '第3条（ユーザーIDおよびパスワードの管理）',
        'content': '''ユーザーは、自己の責任において、本サービスのユーザーIDおよびパスワードを適切に管理するものとします。

ユーザーは、いかなる場合にも、ユーザーIDおよびパスワードを第三者に譲渡または貸与し、もしくは第三者と共用することはできません。当社は、ユーザーIDとパスワードの組み合わせが登録情報と一致してログインされた場合には、そのユーザーIDを登録しているユーザー自身による利用とみなします。''',
      },
      {
        'title': '第4条（禁止事項）',
        'content': '''ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません：

• 法令または公序良俗に違反する行為
• 犯罪行為に関連する行為
• 本サービスの内容等、本サービスに含まれる著作権、商標権ほか知的財産権を侵害する行為
• 当社、ほかのユーザー、またはその他第三者のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
• 本サービスによって得られた情報を商業的に利用する行為
• 当社のサービスの運営を妨害するおそれのある行為
• 不正アクセスをし、またはこれを試みる行為
• 他のユーザーに関する個人情報等を収集または蓄積する行為
• 不正な目的を持って本サービスを利用する行為
• 本サービスの他のユーザーまたはその他の第三者に不利益、損害、不快感を与える行為
• その他当社が不適切と判断する行為''',
      },
      {
        'title': '第5条（本サービスの提供の停止等）',
        'content': '''当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします：

• 本サービスにかかるコンピュータシステムの保守点検または更新を行う場合
• 地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合
• コンピュータまたは通信回線等が事故により停止した場合
• その他、当社が本サービスの提供が困難と判断した場合''',
      },
      {
        'title': '第6条（利用制限および登録抹消）',
        'content': '''当社は、ユーザーが以下のいずれかに該当する場合には、事前の通知なく、ユーザーに対して、本サービスの全部もしくは一部の利用を制限し、またはユーザーとしての登録を抹消することができるものとします：

• 本規約のいずれかの条項に違反した場合
• 登録事項に虚偽の事実があることが判明した場合
• 決済手段として当該ユーザーが届け出たクレジットカードが利用停止となった場合
• 料金等の支払債務の不履行があった場合
• 当社からの連絡に対し、一定期間返答がない場合
• 本サービスについて、最終の利用から一定期間利用がない場合
• その他、当社が本サービスの利用を適当でないと判断した場合''',
      },
      {
        'title': '第7条（退会）',
        'content': '''ユーザーは、当社の定める退会手続により、本サービスから退会できるものとします。''',
      },
      {
        'title': '第8条（保証の否認および免責事項）',
        'content': '''当社は、本サービスに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。

当社は、本サービスに起因してユーザーに生じたあらゆる損害について、当社の故意又は重過失による場合を除き、一切の責任を負いません。''',
      },
      {
        'title': '第9条（サービス内容の変更等）',
        'content': '''当社は、ユーザーへの事前の告知をもって、本サービスの内容を変更、追加または廃止することがあり、ユーザーはこれに同意するものとします。''',
      },
      {
        'title': '第10条（利用規約の変更）',
        'content': '''当社は以下の場合には、ユーザーの個別の同意を要することなく、本規約を変更することができるものとします：

• 本規約の変更がユーザーの一般の利益に適合するとき
• 本規約の変更が本サービス利用契約の目的に反せず、かつ、変更の必要性、変更後の内容の相当性その他の変更に係る事情に照らして合理的なものであるとき''',
      },
      {
        'title': '第11条（個人情報の取扱い）',
        'content': '''当社は、本サービスの利用によって取得する個人情報については、当社「プライバシーポリシー」に従い適切に取り扱うものとします。''',
      },
      {
        'title': '第12条（通知または連絡）',
        'content': '''ユーザーと当社との間の通知または連絡は、当社の定める方法によって行うものとします。当社は、ユーザーから、当社が別途定める方式に従った変更届け出がない限り、現在登録されている連絡先が有効なものとみなして当該連絡先へ通知または連絡を行い、これらは、発信時にユーザーへ到達したものとみなします。''',
      },
      {
        'title': '第13条（権利義務の譲渡の禁止）',
        'content': '''ユーザーは、当社の書面による事前の承諾なく、利用契約上の地位または本規約に基づく権利もしくは義務を第三者に譲渡し、または担保に供することはできません。''',
      },
      {
        'title': '第14条（準拠法・裁判管轄）',
        'content': '''本規約の解釈にあたっては、日本法を準拠法とします。本サービスに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。''',
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
            '本利用規約に関するご質問やご不明な点がございましたら、以下までお気軽にお問い合わせください。',
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
