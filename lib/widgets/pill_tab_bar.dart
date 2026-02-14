import 'package:flutter/material.dart';

/// ピル型カテゴリ選択バー
///
/// 灰色の角丸背景に、選択中のアイテムがピル型で強調されるタブバー。
/// [labels] にタブのラベル一覧、[selectedIndex] に現在の選択位置、
/// [onChanged] で選択変更を通知する。
class PillTabBar extends StatelessWidget {
  const PillTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.activeColor = const Color(0xFFFF6B35),
    this.activeTextColor = Colors.white,
    this.inactiveTextColor,
    this.backgroundColor,
    this.fontSize = 14,
    this.verticalPadding = 10,
    this.disabledIndices = const {},
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color activeColor;
  final Color activeTextColor;
  final Color? inactiveTextColor;
  final Color? backgroundColor;
  final double fontSize;
  final double verticalPadding;
  final Set<int> disabledIndices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          final isDisabled = disabledIndices.contains(index);
          return Expanded(
            child: GestureDetector(
              onTap: isDisabled ? null : () => onChanged(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                decoration: BoxDecoration(
                  color: isSelected && !isDisabled
                      ? activeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey[350]
                          : isSelected
                              ? activeTextColor
                              : (inactiveTextColor ?? Colors.grey[600]),
                      fontWeight:
                          isSelected && !isDisabled
                              ? FontWeight.bold
                              : FontWeight.normal,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
