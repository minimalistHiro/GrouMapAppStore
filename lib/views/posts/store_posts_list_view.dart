import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import 'store_post_detail_view.dart';

class StorePostsListView extends ConsumerWidget {
  const StorePostsListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeIdAsync = ref.watch(userStoreIdProvider);

    return Scaffold(
      appBar: const CommonHeader(title: '投稿一覧'),
      backgroundColor: Colors.white,
      body: storeIdAsync.when(
        data: (storeId) {
          if (storeId == null) {
            return const Center(child: Text('店舗情報が見つかりません'));
          }
          return _buildUnifiedPostsGrid(context, ref, storeId);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
        ),
        error: (e, _) => Center(
          child: Text('エラーが発生しました: $e'),
        ),
      ),
    );
  }

  Widget _buildUnifiedPostsGrid(BuildContext context, WidgetRef ref, String storeId) {
    final postsValue = ref.watch(unifiedStorePostsListProvider(storeId));

    return postsValue.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  '投稿がありません',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostGridCard(context, post, storeId);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      ),
      error: (e, _) => Center(
        child: Text('投稿の取得に失敗しました: $e'),
      ),
    );
  }

  Widget _buildPostGridCard(BuildContext context, PostModel post, String storeId) {
    final isInstagramPost = post.source == 'instagram';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StorePostDetailView(post: post),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: post.imageUrls.isNotEmpty
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      post.imageUrls[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 複数画像インジケーター
                  if (post.imageUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.grid_on,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${post.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // いいね数オーバーレイ（通常投稿のみ）
                  if (!isInstagramPost)
                    FutureBuilder<int>(
                      future: _getLikeCount(storeId, post.id),
                      builder: (context, snapshot) {
                        final likeCount = snapshot.data ?? 0;
                        if (likeCount > 0) {
                          return Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$likeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              )
            : Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
      ),
    );
  }

  Future<int> _getLikeCount(String storeId, String postId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(storeId)
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
