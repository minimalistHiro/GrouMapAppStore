import 'package:flutter/material.dart';

class CustomTopTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTopTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.backgroundColor = const Color(0xFFFF6B35),
    this.labelColor = Colors.white,
    this.unselectedLabelColor = Colors.white,
    this.indicatorColor = Colors.white,
  });

  final List<Tab> tabs;
  final TabController? controller;
  final Color backgroundColor;
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: TabBar(
        controller: controller,
        tabs: tabs,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        indicatorColor: indicatorColor,
      ),
    );
  }
}
