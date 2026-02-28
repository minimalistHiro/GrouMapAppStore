import 'package:flutter/material.dart';

import '../theme/store_ui.dart';

class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final Object title;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool? showBack;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final double elevation;

  const CommonHeader({
    super.key,
    required this.title,
    this.backgroundColor = StoreUi.surface,
    this.foregroundColor = Colors.black,
    this.showBack,
    this.automaticallyImplyLeading = true,
    this.onBack,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final shouldShowBack = showBack ?? automaticallyImplyLeading;

    return AppBar(
      title: title is Widget ? title as Widget : Text(title.toString()),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      leading: leading ??
          (shouldShowBack
              ? IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 36,
                  ),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                )
              : null),
      actions: actions,
      bottom: bottom,
    );
  }
}
