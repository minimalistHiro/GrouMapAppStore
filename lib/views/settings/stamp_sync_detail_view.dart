import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';

class StampSyncDetailView extends StatelessWidget {
  final List<Map<String, dynamic>> mismatches;

  const StampSyncDetailView({Key? key, required this.mismatches})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: CommonHeader(
        title: const Text('不整合ユーザー一覧'),
      ),
      body: mismatches.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    '不整合はありません',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mismatches.length,
              itemBuilder: (context, index) {
                final item = mismatches[index];
                return _buildMismatchCard(item);
              },
            ),
    );
  }

  Widget _buildMismatchCard(Map<String, dynamic> item) {
    final displayName = (item['displayName'] as String?) ?? 'Unknown';
    final profileImageUrl = item['profileImageUrl'] as String?;
    final storeName = (item['storeName'] as String?) ?? '';
    final totalVisits = item['totalVisits'] as int? ?? 0;
    final stamps = item['stamps'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // プロフィールアイコン
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(24),
              ),
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        profileImageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackAvatar(displayName);
                        },
                      ),
                    )
                  : _buildFallbackAvatar(displayName),
            ),
            const SizedBox(width: 12),
            // ユーザー名・店舗名
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (storeName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 来店回数 / スタンプ数
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '来店: $totalVisits回',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'スタンプ: $stamps個',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '客',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
