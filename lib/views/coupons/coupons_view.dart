import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../posts/create_post_view.dart';
import '../posts/edit_post_view.dart';
import 'create_coupon_view.dart';
import 'edit_coupon_view.dart';

class CouponsView extends ConsumerWidget {
  const CouponsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('クーポン管理'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインが必要です'),
            );
          }
          return _buildCouponsContent(context, ref, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildCouponsContent(BuildContext context, WidgetRef ref, String userId) {
    final userStoreIdAsync = ref.watch(userStoreIdProvider);

    return userStoreIdAsync.when(
      data: (storeId) {
        if (storeId == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('店舗情報が見つかりません'),
                SizedBox(height: 8),
                Text('先に店舗を作成してください'),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '投稿', icon: Icon(Icons.article)),
                  Tab(text: 'クーポン', icon: Icon(Icons.card_giftcard)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStorePosts(context, ref, storeId),
                    _buildStoreCoupons(context, ref, storeId),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラー: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePosts(BuildContext context, WidgetRef ref, String storeId) {
    final storePosts = ref.watch(storePostsProvider(storeId));

    return storePosts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.article, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('投稿がありません'),
                const SizedBox(height: 8),
                const Text('新しい投稿を作成してみましょう！'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: CustomButton(
                    text: '新規投稿を作成',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreatePostView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 新規投稿作成ボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: '新規投稿を作成',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreatePostView(),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 投稿一覧
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCardGrid(context, ref, post);
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
            SizedBox(height: 8),
            Text(
              '投稿を読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(storePostsProvider(storeId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCoupons(BuildContext context, WidgetRef ref, String storeId) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '公開中', icon: Icon(Icons.card_giftcard)),
              Tab(text: '非公開', icon: Icon(Icons.visibility_off)),
              Tab(text: '統計', icon: Icon(Icons.analytics)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActiveCoupons(context, ref, storeId),
                _buildInactiveCoupons(context, ref, storeId),
                _buildCouponStats(context, ref, storeId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCardGrid(BuildContext context, WidgetRef ref, Map<String, dynamic> post) {
    String formatDate() {
      final createdAt = post['createdAt']?.toDate();
      
      if (createdAt == null) return '日付不明';
      
      try {
        return '${createdAt.year}年${createdAt.month}月${createdAt.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    final isPublished = post['isPublished'] ?? false;
    final imageUrls = post['imageUrls'] as List<dynamic>?;
    final firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty) ? imageUrls[0] : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditPostView(postData: post),
          ),
        );
      },
      child: Container(
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
            AspectRatio(
              aspectRatio: 0.8,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 7, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: firstImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          firstImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.article,
                        size: 50,
                color: Colors.grey,
                      ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPublished ? Colors.green[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPublished ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isPublished ? '公開中' : '非公開',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isPublished ? Colors.green : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      post['title'] ?? 'タイトルなし',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      formatDate(),
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite, size: 10, color: Colors.red),
                        const SizedBox(width: 2),
                        Text(
                          '${post['likeCount'] ?? 0}',
                          style: const TextStyle(fontSize: 9),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.comment, size: 10, color: Colors.blue),
                        const SizedBox(width: 2),
                        Text(
                          '${post['commentCount'] ?? 0}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCoupons(BuildContext context, WidgetRef ref, String storeId) {
    final activeCoupons = ref.watch(activeCouponsProvider(storeId));
    
    return activeCoupons.when(
      data: (coupons) {
        
        if (coupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('公開中のクーポンがありません'),
                const SizedBox(height: 8),
                const Text('新しいクーポンを作成してみましょう！'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: CustomButton(
                    text: '新規クーポンを作成',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateCouponView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 新規クーポン作成ボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: '新規クーポンを作成',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateCouponView(),
                      ),
                    );
                  },
                ),
              ),
            ),
            // クーポン一覧
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return _buildCouponCardGrid(context, ref, coupon, storeId);
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF6B35),
            ),
            SizedBox(height: 8),
            Text(
              'クーポンを読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(storeCouponsProvider(storeId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveCoupons(BuildContext context, WidgetRef ref, String storeId) {
    final storeCoupons = ref.watch(storeCouponsProvider(storeId));
    
    return storeCoupons.when(
      data: (allCoupons) {
        // 非公開または期限切れクーポンのみをフィルタリング
        final now = DateTime.now();
        final inactiveCoupons = allCoupons.where((coupon) {
          final validUntil = coupon['validUntil']?.toDate();
          final isActive = coupon['isActive'] ?? true;
          return !isActive || (validUntil != null && validUntil.isBefore(now));
        }).toList();
        
        if (inactiveCoupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('非公開のクーポンがありません'),
                const SizedBox(height: 8),
                const Text('非公開または期限切れのクーポンが表示されます'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: CustomButton(
                    text: '新規クーポンを作成',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateCouponView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 新規クーポン作成ボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: '新規クーポンを作成',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateCouponView(),
                      ),
                    );
                  },
                ),
              ),
            ),
            // クーポン一覧
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: inactiveCoupons.length,
                  itemBuilder: (context, index) {
                    final coupon = inactiveCoupons[index];
                    return _buildInactiveCouponCardGrid(context, ref, coupon);
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(storeCouponsProvider(storeId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponStats(BuildContext context, WidgetRef ref, String storeId) {
    final storeCoupons = ref.watch(storeCouponsProvider(storeId));
    
    return storeCoupons.when(
      data: (coupons) {
        
        if (coupons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('クーポン統計がありません'),
                const SizedBox(height: 8),
                const Text('クーポンを作成すると統計が表示されます'),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: CustomButton(
                    text: '新規クーポンを作成',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateCouponView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        // 統計データの計算
        final totalCoupons = coupons.length;
        final now = DateTime.now();
        final activeCoupons = coupons.where((c) {
          final isActive = c['isActive'] ?? true;
          final validUntil = c['validUntil']?.toDate();
          return isActive && (validUntil?.isAfter(now) ?? false);
        }).length;
        final totalUsed = coupons.fold(0, (sum, coupon) => sum + (coupon['usedCount'] as int? ?? 0));
        final totalViews = coupons.fold(0, (sum, coupon) => sum + (coupon['viewCount'] as int? ?? 0));

        return Column(
          children: [
            // 新規クーポン作成ボタン
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: '新規クーポンを作成',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateCouponView(),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 統計カード
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('総クーポン数', totalCoupons.toString(), Icons.card_giftcard, Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('公開中', activeCoupons.toString(), Icons.visibility, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('使用回数', totalUsed.toString(), Icons.people, Colors.orange),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard('閲覧回数', totalViews.toString(), Icons.visibility, Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // クーポン一覧
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return _buildCouponStatsCard(context, ref, coupon);
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'データの取得に失敗しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ネットワーク接続を確認してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(storeCouponsProvider(storeId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCardGrid(BuildContext context, WidgetRef ref, Map<String, dynamic> coupon, String storeId) {
    String formatEndDate() {
      final endDate = coupon['validUntil']?.toDate();
      
      if (endDate == null) return '期限不明';
      
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final couponDate = DateTime(endDate.year, endDate.month, endDate.day);
        
        String dateText;
        if (couponDate.isAtSameMomentAs(today)) {
          dateText = '今日';
        } else if (couponDate.isAtSameMomentAs(tomorrow)) {
          dateText = '明日';
        } else {
          dateText = '${endDate.month}月${endDate.day}日';
        }
        
        return '$dateText ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}まで';
      } catch (e) {
        return '期限不明';
      }
    }

    String getDiscountText() {
      final discountType = coupon['discountType'];
      final discountValue = coupon['discountValue'];
      
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditCouponView(couponData: coupon),
          ),
        );
      },
      child: Container(
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
            AspectRatio(
              aspectRatio: 0.8,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 7, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: coupon['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          coupon['imageUrl'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '公開中',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      coupon['title'] ?? 'タイトルなし',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        getDiscountText(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      '使用: ${coupon['usedCount'] ?? 0}/${coupon['usageLimit'] ?? 0}',
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInactiveCouponCardGrid(BuildContext context, WidgetRef ref, Map<String, dynamic> coupon) {
    String getDiscountText() {
      final discountType = coupon['discountType'];
      final discountValue = coupon['discountValue'];
      
      if (discountType == 'percentage') {
        return '${discountValue.toInt()}%OFF';
      } else if (discountType == 'fixed_amount') {
        return '${discountValue.toInt()}円OFF';
      } else if (discountType == 'fixed_price') {
        return '${discountValue.toInt()}円';
      }
      return '特典あり';
    }

    final validUntil = coupon['validUntil']?.toDate();
    final isExpired = validUntil?.isBefore(DateTime.now()) ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditCouponView(couponData: coupon),
          ),
        );
      },
      child: Container(
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
            AspectRatio(
              aspectRatio: 0.8,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 7, bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(7),
                ),
                child: coupon['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          coupon['imageUrl'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red[100] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isExpired ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isExpired ? '期限切れ' : '非公開',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      coupon['title'] ?? 'タイトルなし',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        getDiscountText(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      '使用: ${coupon['usedCount'] ?? 0}/${coupon['usageLimit'] ?? 0}',
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponStatsCard(BuildContext context, WidgetRef ref, Map<String, dynamic> coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon['title'] ?? 'タイトルなし',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (coupon['isActive'] ?? true) && (coupon['validUntil']?.toDate()?.isAfter(DateTime.now()) ?? false)
                        ? Colors.green 
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (coupon['isActive'] ?? true) && (coupon['validUntil']?.toDate()?.isAfter(DateTime.now()) ?? false)
                        ? '公開中' 
                        : '非公開',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('使用回数', (coupon['usedCount'] ?? 0).toString(), Icons.people),
                ),
                Expanded(
                  child: _buildStatItem('閲覧回数', (coupon['viewCount'] ?? 0).toString(), Icons.visibility),
                ),
                Expanded(
                  child: _buildStatItem('残り', '${(coupon['usageLimit'] ?? 0) - (coupon['usedCount'] ?? 0)}', Icons.inventory),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('検索'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'クーポン名または投稿名を入力',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('公開中'),
              leading: Radio<String>(
                value: 'active',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('非公開'),
              leading: Radio<String>(
                value: 'inactive',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('期限切れ'),
              leading: Radio<String>(
                value: 'expired',
                groupValue: 'all',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }
}