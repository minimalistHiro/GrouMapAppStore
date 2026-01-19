import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import 'create_post_view.dart';
import 'edit_post_view.dart';

class PostsManageView extends ConsumerStatefulWidget {
  const PostsManageView({Key? key}) : super(key: key);

  @override
  ConsumerState<PostsManageView> createState() => _PostsManageViewState();
}

class _PostsManageViewState extends ConsumerState<PostsManageView> {
  String _selectedFilter = 'all';
  final List<String> _filterOptions = ['all', 'お知らせ', 'イベント', 'キャンペーン', 'メニュー', 'その他'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '投稿管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreatePostView(),
                ),
              );
            },
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
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
          final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime(1970);
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
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreatePostView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新規投稿を作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final post = filteredPosts[index];
            final data = post.data() as Map<String, dynamic>;
            return _buildPostCard(data, storeId);
          },
        );
      },
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // 投稿詳細画面に遷移（実装予定）
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('投稿詳細画面は準備中です')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  // カテゴリバッジ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      post['category'] ?? 'お知らせ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // ステータス
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: post['isPublished'] == true ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: post['isPublished'] == true ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      post['isPublished'] == true ? '公開中' : '下書き',
                      style: TextStyle(
                        fontSize: 12,
                        color: post['isPublished'] == true ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // タイトル
              Text(
                post['title'] ?? 'タイトルなし',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // 内容
              Text(
                post['content'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 画像がある場合
              if (post['imageUrls'] != null && (post['imageUrls'] as List).isNotEmpty)
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (post['imageUrls'] as List).length,
                    itemBuilder: (context, index) {
                      final imageUrl = (post['imageUrls'] as List)[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // フッター部分
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${post['views'] ?? 0}回閲覧',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // アクションボタン
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditPostView(postData: post),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () {
                          _showDeleteDialog(post['postId'], storeId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String postId, String storeId) {
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
                await _deletePost(postId, storeId);
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(String postId, String storeId) async {
    try {
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
          const SnackBar(content: Text('投稿を削除しました')),
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
