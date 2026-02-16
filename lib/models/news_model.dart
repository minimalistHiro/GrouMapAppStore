import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime publishStartDate;
  final DateTime publishEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.publishStartDate,
    required this.publishEndDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory NewsModel.fromMap(Map<String, dynamic> data, String id) {
    return NewsModel(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      publishStartDate: _parseDateTime(data['publishStartDate']),
      publishEndDate: _parseDateTime(data['publishEndDate']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'publishStartDate': Timestamp.fromDate(publishStartDate),
      'publishEndDate': Timestamp.fromDate(publishEndDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  /// 掲載中かどうか
  bool get isPublishing {
    final now = DateTime.now();
    return now.isAfter(publishStartDate) && now.isBefore(publishEndDate);
  }

  /// 掲載前かどうか
  bool get isBeforePublish {
    return DateTime.now().isBefore(publishStartDate);
  }

  /// 掲載終了かどうか
  bool get isExpired {
    return DateTime.now().isAfter(publishEndDate);
  }
}
