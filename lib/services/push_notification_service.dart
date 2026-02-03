import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastSavedToken;
  String? _lastSavedUserId;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Push notifications are not configured for web.');
      return;
    }

    try {
      await _messaging.setAutoInitEnabled(true);
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Push notifications initialized.');
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  void clearCurrentUser() {
    _currentUserId = null;
  }

  Future<void> registerForUser(String userId) async {
    await syncForUser(userId, force: true);
  }

  Future<void> syncForUser(String userId, {bool force = false}) async {
    _currentUserId = userId;
    await initialize();
    await _ensureTokenListener();

    final token = await _getFcmTokenWithRetry();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token is null/empty for user $userId');
      return;
    }

    if (!force && _lastSavedUserId == userId && _lastSavedToken == token) {
      debugPrint('FCM token unchanged for user $userId, skip save.');
      return;
    }

    await _saveToken(userId, token);
    _lastSavedUserId = userId;
    _lastSavedToken = token;
  }

  Future<void> _ensureTokenListener() async {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      if (_currentUserId == null) {
        return;
      }
      _saveToken(_currentUserId!, token);
    });
  }

  Future<String?> _getFcmTokenWithRetry() async {
    if (kIsWeb) {
      return null;
    }
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('Fetched FCM token: ${_previewToken(token)}');
        return token;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      final retryToken = await _messaging.getToken();
      if (retryToken != null) {
        debugPrint('Fetched FCM token (retry): ${_previewToken(retryToken)}');
      }
      return retryToken;
    } catch (e) {
      debugPrint('Failed to get/save FCM token: $e');
      return null;
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Saved FCM token for user $userId');
    } catch (e) {
      debugPrint('Failed to save FCM token for user $userId: $e');
    }
  }

  String _previewToken(String token) {
    if (token.length <= 12) return token;
    return '${token.substring(0, 12)}...';
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
