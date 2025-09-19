import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/coupon_provider.dart';
import '../widgets/custom_button.dart';
import 'auth/login_view.dart';
import 'feedback/feedback_send_view.dart';
import 'feedback/feedback_manage_view.dart';
import 'posts/create_post_view.dart';
import 'coupons/create_coupon_view.dart';
import 'posts/posts_manage_view.dart';
import 'coupons/coupons_manage_view.dart';
import 'stores/pending_stores_view.dart';
import 'points/points_history_view.dart';
import 'notifications/notifications_view.dart';
import 'notifications/create_announcement_view.dart';
import 'qr/qr_scanner_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // ログイン済みの場合は店舗ホーム画面を表示
          return _buildStoreHomeContent(context, ref, user.uid);
        } else {
          // 未ログインの場合はログイン画面を表示
          return const LoginView();
        }
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(authStateProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHomeContent(BuildContext context, WidgetRef ref, String storeId) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ヘッダー部分
              _buildHeader(context, ref, storeId),
              
              const SizedBox(height: 24),
              
              // QRスキャンボタン
              _buildQRScanButton(context, ref, storeId),
              
              const SizedBox(height: 16),
              
              // 新規作成ボタン
              _buildCreateButtons(context, ref, storeId),
              
              const SizedBox(height: 24),
              
              // 統計カード部分
              _buildStatsCard(context, ref, storeId),
              
              const SizedBox(height: 24),
              
              // その他のコンテンツ
              _buildAdditionalContent(context, ref, storeId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 左側：アプリアイコン&サービス名
          Row(
            children: [
              Image.asset(
                'assets/images/groumap_store_icon.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.store, size: 40, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text(
                'GrouMap Store',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // 右側：お知らせボタン
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              size: 28,
              color: Colors.black87,
            ),
            onPressed: () {
              // お知らせ画面に遷移
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsView(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanButton(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // QRスキャンボタン
          GestureDetector(
            onTap: () {
              // QRスキャン画面に遷移
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QRScannerView(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 115,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 左側：QRコードアイコン
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              size: 35,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 右側：テキスト
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QRスキャン',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'お客様のQRコードをスキャンして\nポイント付与',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'タップしてスキャン',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '店舗統計',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // 店舗統計情報
          ref.watch(storeStatsProvider(storeId)).when(
            data: (stats) {
              if (stats != null) {
                return Column(
                  children: [
                    // 今日の訪問者数とポイント
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            '今日の訪問者',
                            '${stats['totalVisits'] ?? 0}',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            '配布ポイント',
                            '${stats['totalPoints'] ?? 0}',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'アクティブユーザー',
                            '${stats['activeUsers'] ?? 0}',
                            Icons.person,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            '使用クーポン',
                            '${stats['couponsUsed'] ?? 0}',
                            Icons.local_offer,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return const Text(
                  '統計情報を取得できませんでした',
                  style: TextStyle(color: Colors.grey),
                );
              }
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text(
              '統計情報の取得に失敗しました',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalContent(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // 店舗メニューグリッド
          _buildStoreMenuGrid(context, ref, storeId),
          
          const SizedBox(height: 20),
          
          // 今日の訪問者セクション
          _buildTodayVisitorsSection(context, ref, storeId),
          
          const SizedBox(height: 20),
          
          // アクティブクーポンセクション
          _buildActiveCouponsSection(context, ref, storeId),
        ],
      ),
    );
  }

  Widget _buildStoreMenuGrid(BuildContext context, WidgetRef ref, String storeId) {
    final menuItems = [
      {'icon': Icons.history, 'label': 'ポイント履歴'},
      {'icon': Icons.local_offer, 'label': 'クーポン管理'},
      {'icon': Icons.article, 'label': '投稿管理'},
      {'icon': Icons.analytics, 'label': '顧客分析'},
      {'icon': Icons.trending_up, 'label': '売上データ'},
      {'icon': Icons.business, 'label': 'プラン・契約情報'},
      {'icon': Icons.feedback, 'label': 'フィードバック送信'},
      {'icon': Icons.storefront, 'label': '未承認店舗一覧'},
      {'icon': Icons.manage_accounts, 'label': 'フィードバック管理'},
      {'icon': Icons.announcement, 'label': 'お知らせ作成'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 画面幅に基づいてアイコンサイズとグリッドサイズを動的に調整
            final screenWidth = constraints.maxWidth;
            final iconSize = (screenWidth * 0.08).clamp(20.0, 32.0);
            final fontSize = (screenWidth * 0.03).clamp(8.0, 12.0);
            
            // より安定したアスペクト比の計算
            final itemHeight = 100.0; // 固定の高さを使用
            final aspectRatio = constraints.maxWidth / (itemHeight * 2); // 4列なので2倍
            
            return GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: aspectRatio,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: menuItems.map((item) => _buildStoreMenuButton(
                    context,
                    item['label'] as String,
                    item['icon'] as IconData,
                    iconSize: iconSize,
                    fontSize: fontSize,
                  )).toList(),
                );
          },
        ),
      ),
    );
  }

  Widget _buildCreateButtons(BuildContext context, WidgetRef ref, String storeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 新規投稿を作成
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostView(),
                  ),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.post_add,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '新規投稿を作成',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 新規クーポンを作成
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateCouponView(),
                  ),
                );
              },
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '新規クーポンを作成',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreMenuButton(BuildContext context, String title, IconData icon, {double? iconSize, double? fontSize}) {
    return GestureDetector(
      onTap: () {
        // 各メニュー項目の処理
        if (title == 'フィードバック送信') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FeedbackSendView(),
            ),
          );
        } else if (title == 'フィードバック管理') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FeedbackManageView(),
            ),
          );
        } else if (title == '投稿管理') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PostsManageView(),
            ),
          );
        } else if (title == 'クーポン管理') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CouponsManageView(),
            ),
          );
        } else if (title == '未承認店舗一覧') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PendingStoresView(),
            ),
          );
        } else if (title == 'ポイント履歴') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PointsHistoryView(),
            ),
          );
        } else if (title == 'お知らせ作成') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateAnnouncementView(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title は準備中です')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Icon(
                icon,
                size: iconSize ?? 24,
                color: const Color(0xFFFF6B35),
              ),
            ),
            SizedBox(height: (iconSize ?? 24) * 0.3),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSize ?? 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayVisitorsSection(BuildContext context, WidgetRef ref, String storeId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                '今日の訪問者',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // 訪問者一覧画面に遷移
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('訪問者一覧画面は準備中です')),
                  );
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ref.watch(todayVisitorsProvider(storeId)).when(
            data: (visitors) {
              if (visitors.isEmpty) {
                return const Center(
                  child: Text(
                    '今日の訪問者はいません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: visitors.length,
                itemBuilder: (context, index) {
                  final visitor = visitors[index];
                  return _buildVisitorCard(visitor);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => const Center(
              child: Text(
                '訪問者情報の取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCouponsSection(BuildContext context, WidgetRef ref, String storeId) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text(
                'アクティブクーポン',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // クーポン管理画面に遷移
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('クーポン管理画面は準備中です')),
                  );
                },
                child: const Text(
                  '全て見る＞',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ref.watch(activeCouponsProvider(storeId)).when(
            data: (coupons) {
              if (coupons.isEmpty) {
                return const Center(
                  child: Text(
                    'アクティブなクーポンがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coupons.length,
                itemBuilder: (context, index) {
                  final coupon = coupons[index];
                  return _buildCouponCard(coupon);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
            error: (error, _) => const Center(
              child: Text(
                'クーポン情報の取得に失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisitorCard(Map<String, dynamic> visitor) {
    // 訪問時間の表示用フォーマット
    String formatVisitTime() {
      try {
        final timestamp = visitor['timestamp'];
        if (timestamp == null) return '時間不明';
        
        final date = timestamp is DateTime ? timestamp : timestamp.toDate();
        final now = DateTime.now();
        final difference = now.difference(date).inMinutes;
        
        if (difference < 1) return 'たった今';
        if (difference < 60) return '${difference}分前';
        if (difference < 1440) return '${(difference / 60).floor()}時間前';
        
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return '時間不明';
      }
    }

    return Container(
      width: 150,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ユーザーアイコン
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 24,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // ユーザー名
            Text(
              visitor['userName'] ?? 'ゲストユーザー',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // 獲得ポイント
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${visitor['pointsEarned'] ?? 0}pt',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 訪問時間
            Text(
              formatVisitTime(),
              style: const TextStyle(
                fontSize: 8,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    // 終了日の表示用フォーマット
    String formatEndDate() {
      final endDate = coupon['validUntil'];
      if (endDate == null) return '期限不明';
      
      try {
        final date = endDate is DateTime ? endDate : endDate.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(date.year, date.month, date.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${date.month}月${date.day}日';
        }
        
        return '$dateText ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    // 割引表示用テキスト
    String getDiscountText() {
      final discountType = coupon['discountType'] ?? 'percentage';
      final discountValue = coupon['discountValue'] ?? 0.0;
      
      if (discountType == 'percentage') {
        return '${discountValue.toInt()}%OFF';
      } else if (discountType == 'fixed_amount') {
        return '${discountValue.toInt()}円OFF';
      } else if (discountType == 'fixed_price') {
        return '${discountValue.toInt()}円';
      }
      return '特典あり';
    }

    return GestureDetector(
      onTap: () {
        // クーポン詳細画面に遷移
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('クーポン詳細画面は準備中です')),
        // );
      },
      child: Container(
        width: 170,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // 画像
            Container(
              width: 150,
              height: 80,
              margin: const EdgeInsets.only(top: 5, bottom: 5),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(7),
              ),
              child: coupon['imageUrl'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        coupon['imageUrl'],
                        width: 150,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
            
            // 期限
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                formatEndDate(),
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // タイトル
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                coupon['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 割引情報
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                ),
              ),
              child: Text(
                getDiscountText(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ロゴ
            Image.asset(
              'assets/images/groumap_store_icon.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.store, size: 200, color: Colors.orange),
            ),
            
            const SizedBox(height: 32),
            
            // アプリ名
            const Text(
              'GrouMap Store',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // サブタイトル
            const Text(
              '店舗管理アプリにログインして、\nお客様との接点を管理しましょう！',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // 機能説明
            _buildFeatureCard(
              icon: Icons.analytics,
              title: 'リアルタイム統計',
              description: '訪問者数やポイント配布状況をリアルタイムで確認',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.local_offer,
              title: 'クーポン管理',
              description: 'クーポンの作成・編集・配布状況を一元管理',
            ),
            
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.people,
              title: '顧客管理',
              description: 'お客様の訪問履歴やポイント獲得状況を確認',
            ),
            
            const SizedBox(height: 48),
            
            // ログインボタン
            CustomButton(
              text: '店舗ログイン',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ログイン機能は準備中です')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
