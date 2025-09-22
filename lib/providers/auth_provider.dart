import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 認証状態プロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 現在のユーザープロバイダー
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// 認証サービスプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 現在のユーザーの店舗IDを取得するプロバイダー（現在選択中の店舗を優先）
final userStoreIdProvider = StreamProvider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data();
      // 現在選択中の店舗IDを優先
      final currentStoreId = data?['currentStoreId'] as String?;
      if (currentStoreId != null) {
        return currentStoreId;
      }
      // 選択中の店舗がない場合は、作成した店舗の最初のものを返す
      final createdStores = data?['createdStores'] as List<dynamic>?;
      if (createdStores != null && createdStores.isNotEmpty) {
        return createdStores.first as String;
      }
    }
    return null;
  }).handleError((error) {
    debugPrint('Error fetching user store ID: $error');
    return null;
  });
});

// ユーザーが作成した店舗リストを取得するプロバイダー
final userCreatedStoresProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data();
      final createdStores = data?['createdStores'] as List<dynamic>?;
      if (createdStores != null) {
        return createdStores.cast<String>();
      }
    }
    return <String>[];
  }).handleError((error) {
    debugPrint('Error fetching user created stores: $error');
    return <String>[];
  });
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // メールアドレスとパスワードでログイン
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // メールアドレスとパスワードで新規登録（店舗情報付き）
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email, 
    String password, 
    Map<String, dynamic>? storeInfo,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );
      
      // 店舗情報がある場合はFirestoreに保存
      if (storeInfo != null && userCredential.user != null) {
        await _createStoreDocument(userCredential.user!.uid, storeInfo);
      }
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 店舗ドキュメントを作成
  Future<void> _createStoreDocument(String uid, Map<String, dynamic> storeInfo) async {
    try {
      final storeId = FirebaseFirestore.instance.collection('stores').doc().id;
      
      await FirebaseFirestore.instance.collection('stores').doc(storeId).set({
        'storeId': storeId,
        'name': storeInfo['name'],
        'category': storeInfo['category'],
        'address': storeInfo['address'],
        'phone': storeInfo['phone'] ?? '',
        'description': storeInfo['description'] ?? '',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isApproved': false,
        'goldStamps': 0,
        'totalVisitors': 0,
        'averageRating': 0.0,
        'totalRatings': 0,
        'location': storeInfo['location'] ?? {
          'latitude': 0.0,
          'longitude': 0.0,
        },
        'businessHours': storeInfo['businessHours'] ?? {
          'monday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
          'tuesday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
          'wednesday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
          'thursday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
          'friday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
          'saturday': {'open': '09:00', 'close': '18:00', 'isOpen': true},
          'sunday': {'open': '09:00', 'close': '18:00', 'isOpen': false},
        },
        'tags': storeInfo['tags'] ?? [],
        'socialMedia': storeInfo['socialMedia'] ?? {
          'instagram': '',
          'x': '',
          'facebook': '',
          'website': '',
        },
        'iconImageUrl': storeInfo['iconImageUrl'],
        'storeImageUrl': storeInfo['storeImageUrl'],
      });
      
             // 作成者の店舗リストにも追加
             await FirebaseFirestore.instance.collection('users').doc(uid).set({
               'createdStores': [storeId],
               'email': _auth.currentUser?.email,
               'displayName': storeInfo['name'], // 店舗名をdisplayNameに設定
               'createdAt': FieldValue.serverTimestamp(),
               'isOwner': false, // デフォルトでfalse（一般店舗）
             }, SetOptions(merge: true));
      
    } catch (e) {
      print('Error creating store document: $e');
      rethrow;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // パスワードリセット
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ユーザープロフィール更新
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    }
  }

  // アカウント削除（退会）
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    try {
      // ユーザーの店舗情報を取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final createdStores = List<String>.from(userData?['createdStores'] ?? []);

        // 作成した店舗を削除
        for (String storeId in createdStores) {
          await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .delete();
        }

        // ユーザードキュメントを削除
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      }

      // Firebase Authのユーザーアカウントを削除
      await user.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
