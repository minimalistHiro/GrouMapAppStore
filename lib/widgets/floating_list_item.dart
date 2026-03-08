import 'package:flutter/material.dart';
import '../theme/store_ui.dart';

/// コンテンツリスト向けフローティングカード型リスト項目。
/// お知らせ・履歴など、タイトル・サブテキスト・日付を持つ複数行リストに使用する。
class FloatingListItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final String? trailingText;
  final Widget? leading;
  final Widget? trailing;
  final bool isUnread;

  const FloatingListItem({
    Key? key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingText,
    this.leading,
    this.trailing,
    this.isUnread = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // リーディングウィジェット（未読ドット or カスタム）
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 10),
                    child: leading!,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 10),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isUnread ? StoreUi.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                // テキストコンテンツ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                      if (trailingText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          trailingText!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(Icons.chevron_right,
                        color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
