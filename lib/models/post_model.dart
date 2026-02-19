import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String title;
  final String content;
  final String? storeId;
  final String? storeName;
  final String? category;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int viewCount;
  final String source;
  final String? storeIconImageUrl;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.storeId,
    this.storeName,
    this.category,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.viewCount,
    this.source = 'app',
    this.storeIconImageUrl,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String id) {
    return PostModel(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      storeId: data['storeId'],
      storeName: data['storeName'],
      category: data['category'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      viewCount: data['viewCount'] ?? 0,
      source: data['source'] ?? 'app',
      storeIconImageUrl: data['storeIconImageUrl']?.toString(),
    );
  }

  factory PostModel.fromInstagramMap(Map<String, dynamic> data, String id) {
    final mediaType = (data['mediaType'] ?? '').toString();
    final mediaUrl = (data['mediaUrl'] ?? '').toString();
    final thumbnailUrl = (data['thumbnailUrl'] ?? '').toString();
    final rawImageUrls = data['imageUrls'];
    final imageUrls = <String>[];

    if (rawImageUrls is List) {
      for (final url in rawImageUrls) {
        final parsed = url?.toString() ?? '';
        if (parsed.isNotEmpty) {
          imageUrls.add(parsed);
        }
      }
    }

    if (imageUrls.isEmpty) {
      if (mediaType == 'VIDEO') {
        if (thumbnailUrl.isNotEmpty) {
          imageUrls.add(thumbnailUrl);
        }
      } else if (mediaUrl.isNotEmpty) {
        imageUrls.add(mediaUrl);
      }
    }

    return PostModel(
      id: id,
      title: (data['storeName'] ?? 'Instagramの投稿').toString(),
      content: (data['caption'] ?? '').toString(),
      storeId: data['storeId']?.toString(),
      storeName: data['storeName']?.toString(),
      category: data['category']?.toString() ?? 'Instagram',
      imageUrls: imageUrls,
      createdAt: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      viewCount: data['viewCount'] ?? 0,
      source: 'instagram',
      storeIconImageUrl: data['storeIconImageUrl']?.toString(),
    );
  }
}
