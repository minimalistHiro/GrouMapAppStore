import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/news_model.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import 'news_create_view.dart';
import 'news_edit_view.dart';

class NewsManageView extends ConsumerWidget {
  const NewsManageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      body: SafeArea(
        child: Column(
          children: [
            const CommonHeader(title: 'ニュース管理'),
            Expanded(
              child: newsAsync.when(
                data: (newsList) {
                  if (newsList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.newspaper, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'ニュースがありません',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '新しいニュースを作成してみましょう！',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final news = newsList[index];
                      return _buildNewsCard(context, ref, news);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('データの取得に失敗しました'),
                    ],
                  ),
                ),
              ),
            ),
            // 新規作成ボタン
            Padding(
              padding: const EdgeInsets.all(16),
              child: CustomButton(
                text: '新規ニュースを作成',
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NewsCreateView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, WidgetRef ref, NewsModel news) {
    // ステータスの判定
    String statusText;
    Color statusColor;
    if (news.isPublishing) {
      statusText = '掲載中';
      statusColor = Colors.green;
    } else if (news.isBeforePublish) {
      statusText = '掲載前';
      statusColor = Colors.orange;
    } else {
      statusText = '掲載終了';
      statusColor = Colors.grey;
    }

    String formatDate(DateTime date) {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewsEditView(news: news),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 画像サムネイル
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: news.imageUrl != null && news.imageUrl!.isNotEmpty
                      ? Image.network(
                          news.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.newspaper, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // 情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ステータスバッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // タイトル
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 掲載期間
                    Text(
                      '${formatDate(news.publishStartDate)} 〜 ${formatDate(news.publishEndDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 削除ボタン
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                onPressed: () => _showDeleteDialog(context, ref, news),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, NewsModel news) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ニュースを削除'),
          content: const Text('このニュースを削除しますか？この操作は取り消せません。'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteNews(context, news);
              },
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteNews(BuildContext context, NewsModel news) async {
    try {
      // 画像がある場合はStorageから削除
      if (news.imageUrl != null &&
          news.imageUrl!.isNotEmpty &&
          !news.imageUrl!.startsWith('data:')) {
        try {
          await FirebaseStorage.instance.refFromURL(news.imageUrl!).delete();
        } catch (e) {
          debugPrint('ニュース画像削除エラー: $e');
        }
      }
      // Firestoreから削除
      await FirebaseFirestore.instance.collection('news').doc(news.id).delete();
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: Text('ニュースの削除に失敗しました: $e'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
