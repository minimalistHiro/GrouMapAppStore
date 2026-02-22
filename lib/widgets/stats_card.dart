import 'package:flutter/material.dart';

/// 統計項目のデータモデル
class StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// 統計情報を表示する共通カードウィジェット
///
/// ホーム画面の「今日の統計」、分析画面の「月間来店者数」、
/// データ画面の「統計情報」で共通利用する。
class StatsCard extends StatelessWidget {
  /// カードのタイトル
  final String title;

  /// タイトル横のアイコン（nullの場合はアイコンなし）
  final IconData? titleIcon;

  /// 表示する統計項目のリスト
  final List<StatItem> items;

  /// カードに影を付けるかどうか（デフォルト: true）
  final bool showShadow;

  /// 外側のマージン（nullの場合はマージンなし）
  final EdgeInsetsGeometry? margin;

  /// itemsの代わりにカスタムコンテンツを表示する場合に使用
  final Widget? child;

  const StatsCard({
    super.key,
    required this.title,
    this.titleIcon,
    this.items = const [],
    this.showShadow = true,
    this.margin,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 12),
          child ?? StatsRow(items: items),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    if (titleIcon != null) {
      return Row(
        children: [
          Icon(titleIcon, color: const Color(0xFFFF6B35), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      );
    }
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// 統計項目を横一列に並べるウィジェット（カードなしで単独利用可能）
class StatsRow extends StatelessWidget {
  final List<StatItem> items;

  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final dividerColor = Colors.grey[200];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isOdd) {
            return SizedBox(
              height: 56,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: dividerColor,
              ),
            );
          }
          final item = items[index ~/ 2];
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: item.color, size: 18),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
