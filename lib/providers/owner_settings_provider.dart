import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/owner_settings_model.dart';

final ownerSettingsServiceProvider = Provider<OwnerSettingsService>((ref) {
  return OwnerSettingsService();
});

final ownerSettingsProvider = StreamProvider<OwnerSettings?>((ref) {
  final service = ref.watch(ownerSettingsServiceProvider);
  return service.watchOwnerSettings();
});

class OwnerSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<OwnerSettings?> watchOwnerSettings() {
    try {
      return _firestore.collection('owner_settings').doc('current').snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        final data = snapshot.data();
        if (data == null) {
          return null;
        }
        try {
          return OwnerSettings.fromMap(data);
        } catch (e) {
          debugPrint('Error parsing owner settings: $e');
          return null;
        }
      });
    } catch (e) {
      debugPrint('Error watching owner settings: $e');
      return Stream.value(null);
    }
  }

  Future<void> saveOwnerSettings({
    required OwnerSettings settings,
  }) async {
    final docRef = _firestore.collection('owner_settings').doc('current');
    final data = settings.toMap();

    try {
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        await docRef.update({
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error saving owner settings: $e');
      rethrow;
    }
  }

  Future<void> deleteOwnerSettings() async {
    final docRef = _firestore.collection('owner_settings').doc('current');
    try {
      await docRef.delete();
    } catch (e) {
      debugPrint('Error deleting owner settings: $e');
      rethrow;
    }
  }
}
