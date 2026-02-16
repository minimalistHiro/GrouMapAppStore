import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

/// ニュース一覧（全件、作成日降順）
final newsListProvider = StreamProvider<List<NewsModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('news')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NewsModel.fromMap(doc.data(), doc.id))
          .toList());
});
