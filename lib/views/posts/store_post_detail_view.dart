import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../widgets/common_header.dart';

class StorePostDetailView extends ConsumerStatefulWidget {
  final PostModel post;

  const StorePostDetailView({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  ConsumerState<StorePostDetailView> createState() => _StorePostDetailViewState();
}

class _StorePostDetailViewState extends ConsumerState<StorePostDetailView> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  int _likeCount = 0;
  int _viewCount = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  late final bool _isInstagramPost;
  String? _storeIconUrl;

  DocumentReference<Map<String, dynamic>> _postDocRef() {
    final storeId = widget.post.storeId;
    if (storeId == null || storeId.isEmpty) {
      throw Exception('storeIdが取得できません');
    }
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(storeId)
        .collection('posts')
        .doc(widget.post.id);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isInstagramPost = widget.post.source == 'instagram';
    _storeIconUrl = widget.post.storeIconImageUrl;
    _loadStoreIcon();
    if (!_isInstagramPost) {
      _loadLikeCount();
      _loadViewCount();
      _loadComments();
    }
  }

  Future<void> _loadStoreIcon() async {
    if (_storeIconUrl != null && _storeIconUrl!.isNotEmpty) return;
    final storeId = widget.post.storeId;
    if (storeId == null || storeId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .get();
      if (doc.exists && mounted) {
        final iconUrl = doc.data()?['iconImageUrl']?.toString();
        if (iconUrl != null && iconUrl.isNotEmpty) {
          setState(() {
            _storeIconUrl = iconUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('店舗アイコン取得エラー: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeCount() async {
    try {
      final snapshot = await _postDocRef().collection('likes').get();
      setState(() {
        _likeCount = snapshot.docs.length;
      });
    } catch (e) {
      debugPrint('いいね数取得エラー: $e');
    }
  }

  Future<void> _loadViewCount() async {
    try {
      final snapshot = await _postDocRef().collection('views').get();
      setState(() {
        _viewCount = snapshot.docs.length;
      });
    } catch (e) {
      debugPrint('閲覧数取得エラー: $e');
    }
  }

  Future<void> _loadComments() async {
    try {
      final snapshot = await _postDocRef()
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _comments = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'userId': data['userId'],
            'userName': data['userName'],
            'content': data['content'],
            'createdAt': data['createdAt'],
          };
        }).toList();
        _isLoadingComments = false;
      });
    } catch (e) {
      debugPrint('コメント読み込みエラー: $e');
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonHeader(title: '投稿'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 画像スライダー
            SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildImageSlider(),
              ),
            ),
            // 店舗名・日付
            SliverToBoxAdapter(child: _buildStoreAndDate()),
            // 投稿情報
            SliverToBoxAdapter(child: _buildPostInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider() {
    if (widget.post.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.image,
            color: Colors.grey,
            size: 80,
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: widget.post.imageUrls.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.post.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                );
              },
            );
          },
        ),

        // 画像インジケーター
        if (widget.post.imageUrls.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${widget.post.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStoreAndDate() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (widget.post.storeName != null && widget.post.storeName!.isNotEmpty) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
              backgroundImage: _storeIconUrl != null && _storeIconUrl!.isNotEmpty
                  ? NetworkImage(_storeIconUrl!)
                  : null,
              child: _storeIconUrl == null || _storeIconUrl!.isEmpty
                  ? const Icon(Icons.store, size: 20, color: Color(0xFFFF6B35))
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.storeName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (widget.post.storeName == null || widget.post.storeName!.isEmpty) ...[
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.post.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 統計情報（いいね数・閲覧数）
          if (!_isInstagramPost)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_likeCount件のいいね',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.visibility, color: Colors.grey, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_viewCount回の閲覧',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // 投稿内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル（店舗名と同じ場合は非表示）
                if (widget.post.title != widget.post.storeName) ...[
                  Text(
                    widget.post.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 本文
                Text(
                  widget.post.content,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // コメントセクション（通常投稿のみ）
                if (!_isInstagramPost) _buildCommentsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 8),
        const Text(
          'コメント',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        if (_isLoadingComments)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            ),
          )
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'コメントはまだありません',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          )
        else
          ListView.builder(
            itemCount: _comments.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: const Color(0xFFFF6B35),
                      child: Text(
                        (comment['userName'] ?? '?').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${comment['userName'] ?? '匿名'} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: comment['content'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (comment['createdAt'] != null)
                            Text(
                              _formatDate((comment['createdAt'] as Timestamp).toDate()),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
