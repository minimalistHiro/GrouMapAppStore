import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

