import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';

class StampMigrationCompleteView extends StatelessWidget {
  final String displayName;
  final int stampsBefore;
  final int stampsAfter;
  final int completedCards;

  const StampMigrationCompleteView({
    super.key,
    required this.displayName,
    required this.stampsBefore,
    required this.stampsAfter,
    required this.completedCards,
  });

  @override
  Widget build(BuildContext context) {
    final physicalStamps = stampsAfter - stampsBefore;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: '移行完了'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                '移行が完了しました',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$displayName さんの物理スタンプカードを移行しました',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildResultRow('移行前スタンプ', '$stampsBefore 個'),
                      _buildResultRow('物理カードから移行', '+ $physicalStamps 個'),
                      const Divider(),
                      _buildResultRow(
                        '移行後合計',
                        '$stampsAfter 個',
                        highlight: true,
                      ),
                      if (completedCards > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.card_giftcard, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'スタンプカード $completedCards 枚達成！\nスタンプ特典クーポンを付与しました',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('完了', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? const Color(0xFFFF6B35) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
