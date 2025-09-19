import 'package:cloud_firestore/cloud_firestore.dart';

class SampleDataCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // サンプルお知らせデータを作成（notificationsコレクションに）
  static Future<void> createSampleAnnouncements(String storeId) async {
    try {
      final announcements = [
        {
          'storeId': storeId,
          'userId': storeId,
          'title': 'システムメンテナンスのお知らせ',
          'body': '2024年1月15日（月）の午前2時から午前4時まで、システムメンテナンスを実施いたします。メンテナンス中は一部機能がご利用いただけません。ご不便をおかけして申し訳ございません。',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'isRead': false,
          'isDelivered': true,
          'data': {
            'category': 'メンテナンス',
            'priority': '高',
            'totalViews': 45,
            'readCount': 12,
          },
          'tags': ['メンテナンス', 'システム'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': '新機能リリースのお知らせ',
          'body': '店舗管理機能に新しい分析レポート機能を追加しました。売上データの詳細分析や顧客行動の可視化が可能になります。ぜひご活用ください。',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          'isRead': false,
          'isDelivered': true,
          'data': {
            'category': 'アップデート',
            'priority': '通常',
            'totalViews': 78,
            'readCount': 23,
          },
          'tags': ['新機能', '分析'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': 'キャンペーン開催のお知らせ',
          'body': '新春キャンペーンを開催いたします！1月31日まで、ポイント付与率が通常の1.5倍になります。この機会にぜひご利用ください。',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          'isRead': false,
          'isDelivered': true,
          'data': {
            'category': 'キャンペーン',
            'priority': '高',
            'totalViews': 156,
            'readCount': 45,
          },
          'tags': ['キャンペーン', 'ポイント'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': '利用規約の更新について',
          'body': 'サービス向上のため、利用規約を更新いたしました。主な変更点は、データ保護に関する条項の追加と、利用制限の明確化です。詳細はアプリ内の利用規約をご確認ください。',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          'isRead': true,
          'isDelivered': true,
          'data': {
            'category': '一般',
            'priority': '通常',
            'totalViews': 34,
            'readCount': 8,
          },
          'tags': ['利用規約', '更新'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': '年末年始の営業時間について',
          'body': '年末年始期間中（12月29日〜1月3日）は、サポートセンターの営業時間を短縮いたします。緊急時のお問い合わせは、アプリ内のサポート機能をご利用ください。',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
          'isRead': true,
          'isDelivered': true,
          'data': {
            'category': '一般',
            'priority': '低',
            'totalViews': 67,
            'readCount': 19,
          },
          'tags': ['営業時間', '年末年始'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': 'セキュリティ強化のお知らせ',
          'body': 'お客様のデータをより安全に保護するため、セキュリティ機能を強化いたしました。ログイン時の二段階認証が必須となります。設定方法はアプリ内のヘルプをご参照ください。',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 12))),
          'isRead': false,
          'isDelivered': true,
          'data': {
            'category': 'システム',
            'priority': '高',
            'totalViews': 89,
            'readCount': 31,
          },
          'tags': ['セキュリティ', '認証'],
        },
      ];

      for (final announcement in announcements) {
        await _firestore.collection('notifications').add(announcement);
        print('お知らせを作成しました: ${announcement['title']}');
      }

      print('サンプルお知らせデータの作成が完了しました');
    } catch (e) {
      print('サンプルデータの作成でエラーが発生しました: $e');
    }
  }

  // サンプル通知データを作成
  static Future<void> createSampleNotifications(String storeId) async {
    try {
      final notifications = [
        {
          'storeId': storeId,
          'userId': storeId,
          'title': '新しい顧客が訪問しました',
          'body': '田中太郎さんが店舗を訪問し、10ポイントを獲得しました',
          'type': 'customer_visit',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
          'isRead': false,
          'isDelivered': true,
          'data': {
            'customerName': '田中太郎',
            'pointsEarned': 10,
          },
          'tags': ['顧客', '訪問'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': 'クーポンが更新されました',
          'body': '「新春セール」クーポンが有効になりました',
          'type': 'coupon_update',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
          'isRead': false,
          'isDelivered': true,
          'data': {
            'couponTitle': '新春セール',
            'action': '有効化',
          },
          'tags': ['クーポン', '更新'],
        },
        {
          'storeId': storeId,
          'userId': storeId,
          'title': '店舗お知らせ',
          'body': 'システムメンテナンスのお知らせが公開されました',
          'type': 'store_announcement',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'isRead': true,
          'isDelivered': true,
          'data': {
            'category': 'メンテナンス',
            'priority': '高',
          },
          'tags': ['お知らせ', 'メンテナンス'],
        },
      ];

      for (final notification in notifications) {
        await _firestore.collection('notifications').add(notification);
        print('通知を作成しました: ${notification['title']}');
      }

      print('サンプル通知データの作成が完了しました');
    } catch (e) {
      print('サンプル通知データの作成でエラーが発生しました: $e');
    }
  }

  // すべてのサンプルデータを作成
  static Future<void> createAllSampleData(String storeId) async {
    await createSampleAnnouncements(storeId);
    await createSampleNotifications(storeId);
  }
}
