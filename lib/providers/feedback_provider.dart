import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// フィードバック送信プロバイダー
final feedbackProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // フィードバックを送信
  Future<void> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String message,
    required String category,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'subject': subject,
        'message': message,
        'category': category,
        'status': 'pending', // pending, reviewed, resolved
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      rethrow;
    }
  }

  // フィードバック一覧を取得
  Stream<List<Map<String, dynamic>>> getFeedbackList() {
    try {
      return _firestore
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }).handleError((error) {
        debugPrint('Error fetching feedback list: $error');
        return [];
      });
    } catch (e) {
      debugPrint('Error creating feedback stream: $e');
      return Stream.value([]);
    }
  }

  // フィードバックのステータスを更新
  Future<void> updateFeedbackStatus(String feedbackId, String status) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating feedback status: $e');
      rethrow;
    }
  }
}

// フィードバック一覧プロバイダー
final feedbackListProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final feedbackService = ref.read(feedbackProvider);
  return feedbackService.getFeedbackList();
});
