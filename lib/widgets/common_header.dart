import 'package:flutter/material.dart';

class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool showBack;
  final VoidCallback? onBack;

  const CommonHeader({
    super.key,
    required this.title,
    this.backgroundColor = const Color(0xFFFF6B35),
    this.foregroundColor = Colors.white,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 36,
              ),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
    );
  }
}
