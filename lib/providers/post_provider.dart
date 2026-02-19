import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

// 店舗の投稿プロバイダー
final storePostsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(storeId)
        .collection('posts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList()
        ..sort((a, b) {
          final aTime = a['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = b['createdAt']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // 降順ソート（新しい順）
        });
    }).handleError((error) {
      debugPrint('Error fetching store posts: $error');
      return [];
    });
  } catch (e) {
    debugPrint('Error creating store posts stream: $e');
    return Stream.value([]);
  }
});

// 店舗のInstagram投稿プロバイダー（ホーム用）
final storeInstagramPostsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('instagram_posts')
        .where('isVideo', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    }).handleError((error) {
      debugPrint('Error fetching store instagram posts: $error');
      return <Map<String, dynamic>>[];
    });
  } catch (e) {
    debugPrint('Error creating store instagram posts stream: $e');
    return Stream.value(<Map<String, dynamic>>[]);
  }
});

// 店舗のInstagram投稿プロバイダー（一覧画面用、全件取得）
final allStoreInstagramPostsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('instagram_posts')
        .where('isVideo', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();
    }).handleError((error) {
      debugPrint('Error fetching all store instagram posts: $error');
      return <Map<String, dynamic>>[];
    });
  } catch (e) {
    debugPrint('Error creating all store instagram posts stream: $e');
    return Stream.value(<Map<String, dynamic>>[]);
  }
});

// 通常投稿（PostModel版、統一プロバイダー用、limit 50）
final _storePostsModelProvider = StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(storeId)
        .collection('posts')
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((p) => p.isActive)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    }).handleError((error) {
      debugPrint('Error fetching store posts model: $error');
      return <PostModel>[];
    });
  } catch (e) {
    debugPrint('Error creating store posts model stream: $e');
    return Stream.value(<PostModel>[]);
  }
});

// Instagram投稿（PostModel版、統一プロバイダー用、limit 50）
final _storeInstagramPostsModelProvider = StreamProvider.family<List<PostModel>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('instagram_posts')
        .where('isVideo', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromInstagramMap(doc.data(), doc.id))
          .where((p) => p.isActive)
          .toList();
    }).handleError((error) {
      debugPrint('Error fetching store instagram posts model: $error');
      return <PostModel>[];
    });
  } catch (e) {
    debugPrint('Error creating store instagram posts model stream: $e');
    return Stream.value(<PostModel>[]);
  }
});

// 店舗の統一投稿プロバイダー（ホーム用: Instagram + 通常投稿を混合、最大10件）
final unifiedStorePostsHomeProvider = Provider.family<AsyncValue<List<PostModel>>, String>((ref, storeId) {
  final ig = ref.watch(_storeInstagramPostsModelProvider(storeId));
  final regular = ref.watch(_storePostsModelProvider(storeId));

  if (ig is AsyncLoading<List<PostModel>> && regular is AsyncLoading<List<PostModel>>) {
    return const AsyncValue.loading();
  }

  final igList = ig.valueOrNull ?? [];
  final regularList = regular.valueOrNull ?? [];
  final merged = [...igList, ...regularList];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(merged.take(10).toList());
});

// 店舗の統一投稿プロバイダー（一覧用: Instagram + 通常投稿を混合、最大50件）
final unifiedStorePostsListProvider = Provider.family<AsyncValue<List<PostModel>>, String>((ref, storeId) {
  final ig = ref.watch(_storeInstagramPostsModelProvider(storeId));
  final regular = ref.watch(_storePostsModelProvider(storeId));

  if (ig is AsyncLoading<List<PostModel>> && regular is AsyncLoading<List<PostModel>>) {
    return const AsyncValue.loading();
  }

  final igList = ig.valueOrNull ?? [];
  final regularList = regular.valueOrNull ?? [];
  final merged = [...igList, ...regularList];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(merged.take(51).toList());
});

// 公開中の投稿プロバイダー
final activePostsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, storeId) {
  try {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(storeId)
        .collection('posts')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList()
        ..sort((a, b) {
          final aTime = a['createdAt']?.toDate() ?? DateTime(1970);
          final bTime = b['createdAt']?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
    }).handleError((error) {
      debugPrint('Error fetching active posts: $error');
      return [];
    });
  } catch (e) {
    debugPrint('Error creating active posts stream: $e');
    return Stream.value([]);
  }
});

