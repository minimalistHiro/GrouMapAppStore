import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'create_post_view.dart';
import 'edit_post_view.dart';

class PostsManageView extends ConsumerStatefulWidget {
  const PostsManageView({Key? key}) : super(key: key);

  @override
  ConsumerState<PostsManageView> createState() => _PostsManageViewState();
}

class _PostsManageViewState extends ConsumerState<PostsManageView> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = [
    'all',
    'お知らせ',
    'イベント',
    'キャンペーン',
    'メニュー',
    'その他'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: '投稿管理'),
      body: Consumer(
        builder: (context, ref, child) {
          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ログインが必要です'),
                ],
              ),
            );
          }

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
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // フィルター
                  _buildFilterSection(),

                  // 投稿一覧
                  Expanded(
                    child: _buildPostsList(storeId),
                  ),

                  // 下部固定の作成ボタン
                  _buildCreatePostButton(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('エラー: $error'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Text(
            'カテゴリ:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                style: const TextStyle(color: Colors.black87),
                items: _filterOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option == 'all' ? '全て' : option),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(String storeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(storeId)
          .collection('posts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('データの取得に失敗しました'),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        // クライアントサイドでフィルタリングとソート
        List<QueryDocumentSnapshot> filteredPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (_selectedFilter == 'all') return true;
          return data['category'] == _selectedFilter;
        }).toList();

        // 作成日時で降順ソート
        filteredPosts.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ??
                  DateTime(1970);
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ??
                  DateTime(1970);
          return bTime.compareTo(aTime);
        });

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.article, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('投稿がありません'),
                const SizedBox(height: 8),
                const Text('新しい投稿を作成してみましょう！'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: filteredPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            final data = post.data() as Map<String, dynamic>;
            return _buildPostCard(data, storeId);
          },
        );
      },
    );
  }

  Widget _buildCreatePostButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6F2),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: CustomButton(
        text: '新規投稿を作成',
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreatePostView(),
            ),
          );
        },
        height: 48,
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String storeId) {
    // 作成日の表示用フォーマット
    String formatDate() {
      try {
        final timestamp = post['createdAt'];
        if (timestamp == null) return '日付不明';

        final date = timestamp is DateTime ? timestamp : timestamp.toDate();
        final now = DateTime.now();
        final difference = now.difference(date).inDays;

        if (difference == 0) return '今日';
        if (difference == 1) return '昨日';
        if (difference < 7) return '${difference}日前';

        return '${date.month}月${date.day}日';
      } catch (e) {
        return '日付不明';
      }
    }

    final imageUrls = (post['imageUrls'] as List?)?.whereType<String>().toList() ?? [];
    final firstImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
    final isPublished = post['isPublished'] == true;

    return InkWell(
      onTap: () {
        // 投稿詳細画面に遷移（実装予定）
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿詳細画面は準備中です')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像 (86x86)
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: firstImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        firstImageUrl,
                        fit: BoxFit.cover,
                        width: 86,
                        height: 86,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 32,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.article,
                      size: 32,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 12),
            // コンテンツ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリバッジ + ステータスバッジ + アクションボタン
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post['category'] ?? 'お知らせ',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPublished ? '公開中' : '下書き',
                          style: TextStyle(
                            fontSize: 11,
                            color: isPublished ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditPostView(postData: post),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        onPressed: () {
                          _showDeleteDialog(post['postId'], storeId, imageUrls);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // タイトル
                  Text(
                    post['title'] ?? 'タイトルなし',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 内容
                  Text(
                    post['content'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // フッター（いいね・コメント・閲覧数・日付）
                  FutureBuilder<Map<String, int>>(
                    future: _getPostStats(storeId, post['postId'] ?? ''),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {};
                      final likeCount = stats['likes'] ?? 0;
                      final commentCount = stats['comments'] ?? 0;
                      final viewCount = stats['views'] ?? 0;
                      return Row(
                        children: [
                          const Icon(Icons.favorite, size: 13, color: Colors.red),
                          const SizedBox(width: 3),
                          Text(
                            '$likeCount',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            '$commentCount',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.visibility_outlined, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            '$viewCount',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.access_time,
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text(
                            formatDate(),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getPostStats(String storeId, String postId) async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(storeId)
          .collection('posts')
          .doc(postId);

      final results = await Future.wait([
        postRef.collection('likes').get(),
        postRef.collection('comments').get(),
        postRef.collection('views').get(),
      ]);

      return {
        'likes': results[0].docs.length,
        'comments': results[1].docs.length,
        'views': results[2].docs.length,
      };
    } catch (e) {
      return {'likes': 0, 'comments': 0, 'views': 0};
    }
  }

  void _showDeleteDialog(
      String postId, String storeId, List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('投稿を削除'),
          content: const Text('この投稿を削除しますか？この操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePost(postId, storeId, imageUrls);
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<int> _deletePostImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return 0;

    int failedCount = 0;
    final storage = FirebaseStorage.instance;

    for (final imageUrl in imageUrls) {
      if (imageUrl.startsWith('data:') || imageUrl.startsWith('error:')) {
        continue;
      }
      try {
        await storage.refFromURL(imageUrl).delete();
      } catch (e) {
        failedCount += 1;
        debugPrint('画像削除エラー: $e');
      }
    }

    return failedCount;
  }

  Future<void> _deletePost(
      String postId, String storeId, List<String> imageUrls) async {
    try {
      final failedImageDeletes = await _deletePostImages(imageUrls);
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(storeId)
          .collection('posts')
          .doc(postId)
          .delete();
      await FirebaseFirestore.instance
          .collection('public_posts')
          .doc(postId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedImageDeletes > 0
                  ? '投稿を削除しました（画像${failedImageDeletes}件の削除に失敗）'
                  : '投稿を削除しました',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }
}
