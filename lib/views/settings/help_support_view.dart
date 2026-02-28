import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_support_view.dart';
import 'phone_support_view.dart';
import 'live_chat_user_list_view.dart';
import '../account_deletion/account_deletion_request_view.dart';

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
            _buildFAQSection(context),
            
            const SizedBox(height: 24),
            
            // お問い合わせセクション
            _buildContactSection(context),
            
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

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'QRコードのスキャンができません',
        'answer': 'カメラの許可を確認し、QRコードが画面内に収まるよう調整してください。照明が十分にあることもご確認ください。読み取れない場合はホーム画面のQRスキャンボタンから「手動入力」もお試しいただけます。',
      },
      {
        'question': '店舗情報を変更したい',
        'answer': '設定画面の「店舗設定」→「店舗プロフィール」から店舗名・カテゴリ・営業時間・説明などを編集できます。位置情報の変更は「店舗設定」→「位置情報」から行えます。',
      },
      {
        'question': 'クーポンの作成方法を教えて',
        'answer': 'クーポン管理画面を開き、画面下部固定の「新規クーポンを作成」ボタンからタイトル・タイプ・有効期限・画像を設定して発行できます。1店舗あたり最大3枚まで同時発行可能です。スタンプ達成特典は「必要スタンプ数」を設定したクーポンが自動付与されます。',
      },
      {
        'question': 'スタンプ押印の履歴を確認したい',
        'answer': 'ホーム画面の「スタンプ履歴」から過去の押印履歴を確認できます。今日の来店者数・付与スタンプ数はホームのサマリーカードにもリアルタイム表示されます。',
      },
      {
        'question': 'アプリが正常に動作しません',
        'answer': 'アプリを一度終了して再起動してみてください。改善しない場合は端末を再起動するか、アプリを最新バージョンにアップデートしてください。それでも解消しない場合はサポートまでお問い合わせください。',
      },
      {
        'question': '店舗を切り替えたい',
        'answer': '設定画面の上部にある店舗情報カードの「切り替え」ボタンから、管理する店舗を変更できます。複数店舗を登録している場合に利用できます。',
      },
      {
        'question': '店舗が承認されない・審査中のままです',
        'answer': '店舗登録後、運営チームが内容を確認します。通常は最短当日中に審査が完了しますが、混雑時はお時間をいただく場合があります。承認後にメールでお知らせしますので、しばらくお待ちください。',
      },
    ];

    return _buildSection(
      title: 'よくある質問',
      icon: Icons.quiz,
      children: [
        ...faqs.map((faq) => _buildFAQItem(
          question: faq['question']!,
          answer: faq['answer']!,
        )).toList(),
        _buildFAQItemWithWidget(
          question: 'アカウントを削除したい',
          answer: '以下のページよりアカウント削除申請をしてください。',
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AccountDeletionRequestView(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('アカウント削除申請ページへ'),
            ),
          ),
        ),
      ],
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

  Widget _buildFAQItemWithWidget({
    required String question,
    required String answer,
    required Widget child,
  }) {
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: child,
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return _buildSection(
      title: 'お問い合わせ',
      icon: Icons.contact_support,
      children: [
        _buildContactItem(
          icon: Icons.email,
          title: 'メールサポート',
          subtitle: 'お問い合わせフォームを開く',
          onTap: () => _navigateToEmailSupport(context),
        ),
        _buildContactItem(
          icon: Icons.phone,
          title: '電話サポート',
          subtitle: '080-6050-7194（月〜金 11:00〜18:00）',
          onTap: () => _navigateToPhoneSupport(context),
        ),
        _buildContactItem(
          icon: Icons.chat,
          title: 'ライブチャット',
          subtitle: 'ユーザーとのチャット一覧を開く',
          trailing: _buildLiveChatUnreadTrailing(),
          onTap: () => _navigateToLiveChat(context),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
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
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLiveChatUnreadTrailing() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.data == null) {
          return const Icon(Icons.chevron_right);
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('messages')
              .where('senderRole', isEqualTo: 'user')
              .where('readByOwnerAt', isNull: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Icon(Icons.chevron_right);
            }
            final totalUnread = snapshot.data?.docs.length ?? 0;

            if (totalUnread <= 0) {
              return const Icon(Icons.chevron_right);
            }

            final badgeText = totalUnread > 99 ? '99+' : totalUnread.toString();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            );
          },
        );
      },
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

  void _navigateToEmailSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmailSupportView(),
      ),
    );
  }

  void _navigateToPhoneSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhoneSupportView(),
      ),
    );
  }

  void _navigateToLiveChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LiveChatUserListView(),
      ),
    );
  }



}
