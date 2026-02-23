import 'package:flutter/material.dart';

import '../theme/store_ui.dart';

class CustomSwitchListTile extends StatelessWidget {
  const CustomSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: StoreUi.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFE0E0E0),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}
